local M = {}

local Menu = require("nui.menu")
local Popup = require("nui.popup")
local utils = require("pymple.utils")
local log = require("pymple.log")
local icons = require("nvim-web-devicons")
local udim_utils = require("pymple.update_imports.utils")
local udim = require("pymple.update_imports")

-- TDOO: use user config for keymaps
function M.get_confirmation_dialog(
  number_of_imports,
  number_of_files,
  on_submit,
  on_close
)
  on_close = on_close or function() end
  on_submit = on_submit or function() end
  local menu = Menu({
    relative = "editor",
    position = "50%",
    size = {
      width = 60,
      height = 3,
    },
    border = {
      style = "rounded",
      text = {
        top = string.format(
          "Update %s imports in %s files?",
          number_of_imports,
          number_of_files
        ),
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    lines = {
      Menu.item("Yes"),
      Menu.item("No"),
      Menu.item("Preview changes"),
    },
    max_width = 30,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "q", "<C-c>" },
      submit = { "<CR>", "<Space>" },
    },
    on_close = function()
      on_close()
    end,
    on_submit = function(item)
      on_submit(item)
    end,
  })
  return menu
end

local preview_window_ns = vim.api.nvim_create_namespace("PymplePreviewWindow")

-- Highlight groups:
local preview_hl_groups = {
  stats = vim.api.nvim_set_hl(preview_window_ns, "PymplePreviewStats", {
    fg = "magenta",
  }),
  file_header = vim.api.nvim_set_hl(
    preview_window_ns,
    "PymplePreviewFileHeader",
    {
      fg = "grey",
      bold = true,
      italic = true,
    }
  ),
  lines_before = vim.api.nvim_set_hl(
    preview_window_ns,
    "PymplePreviewLinesBefore",
    {
      link = "Added",
    }
  ),
  lines_after = vim.api.nvim_set_hl(
    preview_window_ns,
    "PymplePreviewLinesAfter",
    {
      link = "Removed",
    }
  ),
  separators = vim.api.nvim_set_hl(
    preview_window_ns,
    "PymplePreviewSeparators",
    {
      link = "Comment",
    }
  ),
}

---@param bufnr number
---@param line_nr number
---@param hl_group string
---@param lines string[]
local function buf_add_lines_with_highlight(bufnr, line_nr, hl_group, lines)
  vim.api.nvim_buf_set_lines(bufnr, line_nr, -1, false, lines)
  for i = line_nr, line_nr + #lines - 1 do
    vim.api.nvim_buf_add_highlight(bufnr, preview_window_ns, hl_group, i, 0, -1)
  end
end

local function prefix_lines(lines, prefix)
  local prefixed_lines = {}
  for _, line in ipairs(lines) do
    table.insert(prefixed_lines, prefix .. line)
  end
  return prefixed_lines
end

local function pad_and_suffix_lines(lines, length, suffix)
  local padded_lines = {}
  for _, line in ipairs(lines) do
    table.insert(
      padded_lines,
      line .. string.rep(" ", length - #line + 1) .. suffix
    )
  end
  return padded_lines
end

local PreviewWindow = Popup:extend("PreviewWindow")

local SEPARATORS = {
  diff_prefix = "│",
  above = "├",
  above_suffix = "┐",
  below = "└",
  below_suffix = "┘",
  line = "─",
}

function PreviewWindow:render_result(result, line_count, res_num)
  local icon, icon_hl =
    icons.get_icon(result.file_path, vim.fn.fnamemodify(result.file_path, ":e"))
  vim.api.nvim_buf_set_lines(self.bufnr, line_count, -1, false, {
    res_num .. "." .. icon .. " " .. result.file_path,
  })
  local res_num_str = tostring(res_num)
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    preview_window_ns,
    icon_hl,
    line_count,
    #res_num_str + 1,
    #res_num_str + 1 + #icon
  )
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    preview_window_ns,
    "PymplePreviewFileHeader",
    line_count,
    #res_num_str + 1 + #icon + 1,
    -1
  )
  buf_add_lines_with_highlight(
    self.bufnr,
    line_count + 1,
    "PymplePreviewSeparators",
    {
      SEPARATORS.above
        .. string.rep(SEPARATORS.line, 123)
        .. SEPARATORS.above_suffix,
    }
  )
  buf_add_lines_with_highlight(
    self.bufnr,
    line_count + 2,
    "PymplePreviewLinesBefore",
    result.lines_before
  )
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    preview_window_ns,
    "PymplePreviewSeparators",
    line_count + 2,
    0,
    #SEPARATORS.diff_prefix + 1
  )
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    preview_window_ns,
    "PymplePreviewSeparators",
    line_count + 2,
    123,
    -1
  )
  buf_add_lines_with_highlight(
    self.bufnr,
    line_count + #result.lines_before + 2,
    "PymplePreviewLinesAfter",
    result.lines_after
  )
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    preview_window_ns,
    "PymplePreviewSeparators",
    line_count + #result.lines_before + 2,
    0,
    #SEPARATORS.diff_prefix + 1
  )
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    preview_window_ns,
    "PymplePreviewSeparators",
    line_count + #result.lines_before + 2,
    123,
    -1
  )
  buf_add_lines_with_highlight(
    self.bufnr,
    line_count + #result.lines_before + #result.lines_after + 2,
    "PymplePreviewSeparators",
    {
      SEPARATORS.below
        .. string.rep(SEPARATORS.line, 123)
        .. SEPARATORS.below_suffix,
    }
  )
  -- add an empty line after the file
  vim.api.nvim_buf_set_lines(
    self.bufnr,
    line_count + #result.lines_before + #result.lines_after + 3,
    -1,
    false,
    { "" }
  )
end

-- ---@param rj_results ReplaceJobResult[]
function PreviewWindow:render_preview(r_channel)
  local cwd = vim.fn.getcwd()
  local w = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_hl_ns(w, preview_window_ns)
  local line_count = 0
  local res_num = 1
  while true do
    local rj_result = r_channel:recv()
    log.debug("Received result: " .. vim.inspect(rj_result))
    if not rj_result then
      break
    end
    local result = {
      file_path = utils.make_relative_to(rj_result.file_path, cwd),
      lines_before = pad_and_suffix_lines(
        udim_utils.truncate_lines(
          prefix_lines(
            utils.split_string(rj_result.line_before, "\n"),
            SEPARATORS.diff_prefix .. " "
          ),
          123
        ),
        125,
        SEPARATORS.diff_prefix
      ),
      lines_after = pad_and_suffix_lines(
        udim_utils.truncate_lines(
          prefix_lines(
            utils.split_string(rj_result.line_after, "\n"),
            SEPARATORS.diff_prefix .. " "
          ),
          123
        ),
        125,
        SEPARATORS.diff_prefix
      ),
    }
    self:render_result(result, line_count, res_num)
    line_count = line_count + #result.lines_before + #result.lines_after + 4
    res_num = res_num + 1
  end
end

function M.get_preview_window(r_jobs, num_results, num_files)
  local preview_window = PreviewWindow({
    enter = true,
    focusable = true,
    relative = "editor",
    position = "50%",
    size = {
      width = 125,
      height = 40,
    },
    border = {
      style = "rounded",
      text = {
        top = string.format(
          " [pymple.nvim] Preview changes (%s results in %s files) ",
          num_results,
          num_files
        ),
        top_align = "center",
        bottom = "[Enter]: Apply changes / [q]: Cancel",
      },
      padding = {
        top = 1,
        bottom = 1,
        left = 1,
        right = 1,
      },
    },
    buf_options = {
      modifiable = true,
    },
  })

  local _ = preview_window:map("n", "q", function(bufnr)
    preview_window:unmount()
  end, { noremap = true })

  local _ = preview_window:map("n", "<CR>", function(bufnr)
    preview_window:unmount()
    udim.run_jobs(r_jobs)
  end, { noremap = true })

  -- unmount the popup when leaving the buffer
  preview_window:on("BufLeave", function()
    preview_window:unmount()
  end, { once = true })

  return preview_window
end

return M
