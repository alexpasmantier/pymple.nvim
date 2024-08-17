local M = {}

local Menu = require("nui.menu")
local Popup = require("nui.popup")
local utils = require("pymple.utils")
local udim_utils = require("pymple.update_imports.utils")
local udim = require("pymple.update_imports")
local udim_jobs = require("pymple.update_imports.jobs")
local udim_highlights = require("pymple.update_imports.highlights")

local icons = nil
if utils.check_plugin_installed("nvim-web-devicons") then
  icons = require("nvim-web-devicons")
end

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
          "[pymple.nvim] Update %s imports in %s files?",
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
    udim_highlights.preview_window_ns,
    "PymplePreviewLineCount",
    line_nr,
    0,
    file_count_len + 1
  )
  -- icon
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    udim_highlights.preview_window_ns,
    icon_hl,
    line_nr,
    file_count_len + 1,
    file_count_len + 1 + icon_len
  )
  -- file path
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    udim_highlights.preview_window_ns,
    "PymplePreviewFileHeader",
    line_nr,
    file_count_len + 1 + icon_len + 1,
    -1
  )
  -- separator
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    udim_highlights.preview_window_ns,
    "PymplePreviewSeparators",
    line_nr + 1,
    0,
    -1
  )
  -- before
  for i = 0, num_lines - 1 do
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
      udim_highlights.preview_window_ns,
      "PymplePreviewSeparators",
      line_nr + 2 + i,
      0,
      #SEPARATORS.diff_prefix + 1
    )
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
      udim_highlights.preview_window_ns,
      "PymplePreviewSeparators",
      line_nr + 2 + i,
      self.size.width - 2,
      -1
    )
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
      udim_highlights.preview_window_ns,
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
      udim_highlights.preview_window_ns,
      "PymplePreviewSeparators",
      line_nr + 2 + num_lines + i,
      0,
      #SEPARATORS.diff_prefix + 1
    )
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
      udim_highlights.preview_window_ns,
      "PymplePreviewSeparators",
      line_nr + 2 + num_lines + i,
      self.size.width - 2,
      -1
    )
    vim.api.nvim_buf_add_highlight(
      self.bufnr,
      udim_highlights.preview_window_ns,
      "PymplePreviewLinesAfter",
      line_nr + 2 + num_lines + i,
      #SEPARATORS.diff_prefix + 1,
      self.size.width - 2
    )
  end
  -- bottom separator
  vim.api.nvim_buf_add_highlight(
    self.bufnr,
    udim_highlights.preview_window_ns,
    "PymplePreviewSeparators",
    line_nr + 2 + num_lines * 2,
    0,
    -1
  )
end

local function make_file_path_key(file_path, line_number)
  return file_path .. string.format(":%s:", line_number)
end

function PreviewWindow:render_filepath(
  file_path,
  line_count,
  icon,
  res_number,
  res_line_num
)
  local res_count = res_number .. "/" .. self.num_results
  local original_file_path_key = make_file_path_key(file_path, res_line_num)
  local maybe_shortened_key = utils.shorten_path(
    original_file_path_key,
    self.size.width - 2 - #res_count - #icon - 2
  )
  vim.api.nvim_buf_set_lines(self.bufnr, line_count, -1, false, {
    res_count .. " " .. icon .. " " .. maybe_shortened_key,
  })
  vim.api.nvim_buf_set_lines(self.bufnr, line_count + 1, -1, false, {
    SEPARATORS.above
      .. string.rep(SEPARATORS.line, self.size.width - 2)
      .. SEPARATORS.above_suffix,
  })
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

local DEFAULT_FILE_ICON = ""
local DEFAULT_FILE_ICON_HL = "PymplePreviewDefaultIcon"

function PreviewWindow:render_result(result, line_count, res_num)
  local line_start = line_count
  local icon, icon_hl = DEFAULT_FILE_ICON, DEFAULT_FILE_ICON_HL
  if icons then
    icon, icon_hl = icons.get_icon(
      result.file_path,
      vim.fn.fnamemodify(result.file_path, ":e")
    )
  end
  line_count = self:render_filepath(
    result.file_path,
    line_count,
    icon,
    res_num,
    result.line_num
  )
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
  local result_data = {
    file_path = result.file_path,
    line_start = line_start,
    line_end = line_end,
    icon_hl = icon_hl,
    file_count_len = #(res_num .. self.num_results),
    icon_len = #icon,
    num_lines = #result.lines_before,
    result_num = res_num,
    result_line_num = result.line_num,
  }
  self.results_map[res_num] = result_data
  self:add_result_highlights(
    icon_hl,
    line_start,
    #(res_num .. self.num_results),
    #icon,
    #result.lines_before
  )
end

-- ---@param rj_results ReplaceJobResult[]
function PreviewWindow:render_preview(r_channel)
  local cwd = vim.fn.getcwd()
  local w = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_hl_ns(w, udim_highlights.preview_window_ns)
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
      line_num = rj_result.line_num,
    }
    self:render_result(result, line_count, res_num)
    line_count = line_count + #result.lines_before + #result.lines_after + 4
    res_num = res_num + 1
  end
end

function PreviewWindow:resolve_hover()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  for i, data in ipairs(self.results_map) do
    if data.line_start <= line and line <= data.line_end then
      return i, data
    end
  end
  return nil
end

function PreviewWindow:ignore_result()
  local _, data = self:resolve_hover()
  if not data then
    return
  end
  local res_key = make_file_path_key(data.file_path, data.result_line_num)
  if self.ignored_paths[res_key] then
    self.ignored_paths[res_key] = nil
    self:add_result_highlights(
      data.icon_hl,
      data.line_start,
      data.file_count_len,
      data.icon_len,
      data.num_lines
    )
  else
    self.ignored_paths[res_key] = true
    vim.api.nvim_buf_clear_highlight(
      self.bufnr,
      udim_highlights.preview_window_ns,
      data.line_start,
      data.line_end
    )
    for i = data.line_start, data.line_end - 1 do
      vim.api.nvim_buf_add_highlight(
        self.bufnr,
        udim_highlights.preview_window_ns,
        "PymplePreviewIgnored",
        i,
        0,
        -1
      )
    end
  end
end

function PreviewWindow:setup_mappings()
  local _ = self:map("n", "q", function(_)
    self:unmount()
  end, { noremap = true })
  local _ = self:map("n", "<C-c>", function(_)
    self:unmount()
  end, { noremap = true })

  local _ = self:map("n", "<CR>", function(_)
    local ignored_keys = {}
    for res_key, _ in pairs(self.ignored_paths) do
      table.insert(ignored_keys, res_key)
    end
    self:unmount()
    local filtered_jobs = {}
    for _, rj in ipairs(self.r_jobs) do
      local filtered_job = udim_jobs.filter_rjob_targets(rj, ignored_keys)
      if #filtered_job.targets > 0 then
        table.insert(filtered_jobs, filtered_job)
      end
    end
    udim.run_jobs(filtered_jobs)
  end, { noremap = true })

  local _ = self:map("n", "<C-j>", function(_)
    local res_index, _ = self:resolve_hover()
    if res_index then
      if res_index < self.num_results then
        local next_data = self.results_map[res_index + 1]
        vim.api.nvim_win_set_cursor(0, { next_data.line_start + 1, 0 })
        return
      end
    end
  end, { noremap = true })

  local _ = self:map("n", "<C-k>", function(_)
    local res_index, _ = self:resolve_hover()
    if res_index then
      if res_index > 1 then
        local prev_data = self.results_map[res_index - 1]
        vim.api.nvim_win_set_cursor(0, { prev_data.line_start + 1, 0 })
        return
      end
    end
  end, { noremap = true })

  local _ = self:map("n", "<C-i>", function()
    self:ignore_result()
  end, { noremap = true })

  local _ = self:map("n", "dd", function()
    self:ignore_result()
  end, { noremap = true })
end

local function get_editor_size()
  local editor_width = vim.api.nvim_get_option("columns")
  local editor_height = vim.api.nvim_get_option("lines")
  return {
    width = editor_width,
    height = editor_height,
  }
end

local PREVIEW_WINDOW_W_OFFSET = 30
local PREVIEW_WINDOW_H_OFFSET = 15

function M.get_preview_window(r_jobs, num_results, num_files)
  -- maybe inject these
  local editor_size = get_editor_size()
  local height = math.min(
    5 * num_results + 2,
    editor_size.height - 2 * PREVIEW_WINDOW_H_OFFSET
  )
  local width = math.min(120, editor_size.width - 2 * PREVIEW_WINDOW_W_OFFSET)
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
        bottom = "[C-j/C-k]: Next/Previous result / [Enter]: Apply changes / [C-i/dd]: Toggle ignore result / [q]: Cancel",
        bottom_align = "center",
      },
      padding = {
        top = 2,
        bottom = 2,
        left = 2,
        right = 2,
      },
    },
    buf_options = {
      modifiable = true,
    },
  })
  preview_window.num_results = num_results
  preview_window.size = {
    width = width,
    height = height,
  }
  preview_window.r_jobs = r_jobs
  preview_window.results_map = {}
  preview_window.ignored_paths = {}

  preview_window:setup_mappings()

  udim_highlights.setup()

  -- unmount the popup when leaving the buffer
  preview_window:on("BufLeave", function()
    preview_window:unmount()
  end, { once = true })

  return preview_window
end

return M
