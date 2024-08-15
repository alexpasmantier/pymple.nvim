local M = {}

local Menu = require("nui.menu")
local Popup = require("nui.popup")
local utils = require("pymple.utils")
local log = require("pymple.log")
local icons = require("nvim-web-devicons")
local udim_utils = require("pymple.update_imports.utils")
local udim = require("pymple.update_imports")
local udim_jobs = require("pymple.update_imports.jobs")

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
      link = "@keyword.function",
    }
  ),
  line_count = vim.api.nvim_set_hl(
    preview_window_ns,
    "PymplePreviewLineCount",
    {
      link = "@type",
    }
  ),
  lines_before = vim.api.nvim_set_hl(
    preview_window_ns,
    "PymplePreviewLinesBefore",
    {
      link = "Removed",
    }
  ),
  lines_after = vim.api.nvim_set_hl(
    preview_window_ns,
    "PymplePreviewLinesAfter",
    {
      link = "Added",
    }
  ),
  separators = vim.api.nvim_set_hl(
    preview_window_ns,
    "PymplePreviewSeparators",
    {
      link = "Comment",
    }
  ),
  ignored = vim.api.nvim_set_hl(preview_window_ns, "PymplePreviewIgnored", {
    link = "Comment",
  }),
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

function PreviewWindow:add_result_highlights(
  icon_hl,
  line_nr,
  file_count_len,
  icon_len,
  num_lines
)
  -- file count
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    preview_window_ns,
    "PymplePreviewLineCount",
    line_nr,
    0,
    file_count_len + 1
  )
  -- icon
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    preview_window_ns,
    icon_hl,
    line_nr,
    file_count_len + 1,
    file_count_len + 1 + icon_len
  )
  -- file path
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    preview_window_ns,
    "PymplePreviewFileHeader",
    line_nr,
    file_count_len + 1 + icon_len + 1,
    -1
  )
  -- separator
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    preview_window_ns,
    "PymplePreviewSeparators",
    line_nr + 1,
    0,
    -1
  )
  -- before
  for i = 0, num_lines - 1 do
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
      preview_window_ns,
      "PymplePreviewSeparators",
      line_nr + 2 + i,
      0,
      #SEPARATORS.diff_prefix + 1
    )
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
      preview_window_ns,
      "PymplePreviewSeparators",
      line_nr + 2 + i,
      self.size.width - 2,
      -1
    )
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
      preview_window_ns,
      "PymplePreviewLinesBefore",
      line_nr + 2 + i,
      #SEPARATORS.diff_prefix + 1,
      self.size.width - 2
    )
  end
  -- after
  for i = 0, num_lines - 1 do
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
      preview_window_ns,
      "PymplePreviewSeparators",
      line_nr + 2 + num_lines + i,
      0,
      #SEPARATORS.diff_prefix + 1
    )
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
      preview_window_ns,
      "PymplePreviewSeparators",
      line_nr + 2 + num_lines + i,
      self.size.width - 2,
      -1
    )
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
      preview_window_ns,
      "PymplePreviewLinesAfter",
      line_nr + 2 + num_lines + i,
      #SEPARATORS.diff_prefix + 1,
      self.size.width - 2
    )
  end
  -- bottom separator
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    preview_window_ns,
    "PymplePreviewSeparators",
    line_nr + 2 + num_lines * 2,
    0,
    -1
  )
end

function PreviewWindow:render_filepath(file_path, line_count, icon, res_number)
  local file_count = res_number .. "/" .. self.num_files
  vim.api.nvim_buf_set_lines(self.bufnr, line_count, -1, false, {
    file_count .. " " .. icon .. " " .. file_path,
  })
  vim.api.nvim_buf_set_lines(self.bufnr, line_count + 1, -1, false, {
    SEPARATORS.above
      .. string.rep(SEPARATORS.line, self.size.width - 2)
      .. SEPARATORS.above_suffix,
  })
  -- self:add_result_highlights(icon_hl, line_count, #file_count, #icon)
  return line_count + 2
end

function PreviewWindow:render_lines(lines, line_count)
  vim.api.nvim_buf_set_lines(self.bufnr, line_count, -1, false, lines)
  return line_count + #lines
end

function PreviewWindow:render_bottom_separator(line_count)
  vim.api.nvim_buf_set_lines(self.bufnr, line_count, -1, false, {
    SEPARATORS.below
      .. string.rep(SEPARATORS.line, self.size.width - 2)
      .. SEPARATORS.below_suffix,
  })
  return line_count + 1
end

function PreviewWindow:render_result(result, line_count, res_num)
  local line_start = line_count
  local icon, icon_hl =
    icons.get_icon(result.file_path, vim.fn.fnamemodify(result.file_path, ":e"))
  line_count = self:render_filepath(result.file_path, line_count, icon, res_num)
  line_count = self:render_lines(result.lines_before, line_count)
  line_count = self:render_lines(result.lines_after, line_count)
  line_count = self:render_bottom_separator(line_count)
  -- add an empty line after the file
  vim.api.nvim_buf_set_lines(
    self.bufnr,
    line_count + #result.lines_before + #result.lines_after + 3,
    -1,
    false,
    { "" }
  )
  local line_end = line_count + 1
  self.results_map[result.file_path] = {
    line_start = line_start,
    line_end = line_end,
    icon_hl = icon_hl,
    file_count_len = #(res_num .. self.num_files),
    icon_len = #icon,
    num_lines = #result.lines_before,
  }
  self:add_result_highlights(
    icon_hl,
    line_start,
    #(res_num .. self.num_files),
    #icon,
    #result.lines_before
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
          self.size.width - 2
        ),
        self.size.width,
        SEPARATORS.diff_prefix
      ),
      lines_after = pad_and_suffix_lines(
        udim_utils.truncate_lines(
          prefix_lines(
            utils.split_string(rj_result.line_after, "\n"),
            SEPARATORS.diff_prefix .. " "
          ),
          self.size.width - 2
        ),
        self.size.width,
        SEPARATORS.diff_prefix
      ),
    }
    self:render_result(result, line_count, res_num)
    local new_line_count = line_count
      + #result.lines_before
      + #result.lines_after
      + 4
    res_num = res_num + 1
    line_count = new_line_count
  end
end

local MAX_PREVIEW_HEIGHT = 50

function M.get_preview_window(r_jobs, num_results, num_files)
  -- maybe inject these
  local height = math.min(5 * num_results + 2, MAX_PREVIEW_HEIGHT)
  local width = 140
  local preview_window = PreviewWindow({
    enter = true,
    focusable = true,
    relative = "editor",
    position = "50%",
    size = {
      width = width,
      height = height,
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
  preview_window.num_files = num_files
  preview_window.size = {
    width = width,
    height = height,
  }
  preview_window.r_jobs = r_jobs
  preview_window.results_map = {}
  preview_window.ignored_paths = {}

  local _ = preview_window:map("n", "q", function(bufnr)
    preview_window:unmount()
  end, { noremap = true })
  local _ = preview_window:map("n", "<C-c>", function(bufnr)
    preview_window:unmount()
  end, { noremap = true })

  local _ = preview_window:map("n", "<CR>", function(bufnr)
    local ignored_paths = {}
    for file_path, _ in pairs(preview_window.ignored_paths) do
      table.insert(ignored_paths, file_path)
    end
    preview_window:unmount()
    local filtered_jobs = {}
    log.debug(r_jobs)
    for _, rj in ipairs(r_jobs) do
      local filtered_job = udim_jobs.filter_rjob_targets(rj, ignored_paths)
      log.debug(filtered_job)
      if #filtered_job.targets > 0 then
        table.insert(filtered_jobs, filtered_job)
      end
    end
    udim.run_jobs(filtered_jobs)
  end, { noremap = true })

  local _ = preview_window:map("n", "i", function(bufnr)
    local line = vim.api.nvim_win_get_cursor(0)[1]
    for file_path, data in pairs(preview_window.results_map) do
      if data.line_start <= line and line <= data.line_end then
        if preview_window.ignored_paths[file_path] then
          preview_window.ignored_paths[file_path] = nil
          preview_window:add_result_highlights(
            data.icon_hl,
            data.line_start,
            data.file_count_len,
            data.icon_len,
            data.num_lines
          )
        else
          preview_window.ignored_paths[file_path] = true
          vim.api.nvim_buf_clear_highlight(
            preview_window.bufnr,
            preview_window_ns,
            data.line_start,
            data.line_end
          )
          for i = data.line_start, data.line_end - 1 do
            vim.api.nvim_buf_add_highlight(
              preview_window.bufnr,
              preview_window_ns,
              "PymplePreviewIgnored",
              i,
              0,
              -1
            )
          end
        end
        break
      end
    end
  end, { noremap = true })

  -- unmount the popup when leaving the buffer
  preview_window:on("BufLeave", function()
    preview_window:unmount()
  end, { once = true })

  return preview_window
end

return M
