local M = {}

local preview_window_ns = vim.api.nvim_create_namespace("PymplePreviewWindow")

local function get_existing_highlights()
  local highlights = {}
  highlights["Normal"] = vim.api.nvim_get_hl(0, { name = "Normal" })
  highlights["ErrorMsg"] = vim.api.nvim_get_hl(0, { name = "ErrorMsg" })
  highlights["Added"] = vim.api.nvim_get_hl(0, { name = "Added" })
  highlights["Removed"] = vim.api.nvim_get_hl(0, { name = "Removed" })
  highlights["LineNr"] = vim.api.nvim_get_hl(0, { name = "LineNr" })
  highlights["CursorLineNr"] = vim.api.nvim_get_hl(0, { name = "CursorLineNr" })
  highlights["Function"] = vim.api.nvim_get_hl(0, { name = "Function" })
  return highlights
end

M.setup = function()
  local existing_highlights = get_existing_highlights()

  vim.api.nvim_set_hl(preview_window_ns, "PymplePreviewFileHeader", {
    fg = existing_highlights["Normal"].fg,
    bg = existing_highlights["Normal"].bg,
    bold = true,
    italic = true,
  })
  vim.api.nvim_set_hl(preview_window_ns, "PymplePreviewLineCount", {
    fg = existing_highlights["ErrorMsg"].fg,
    bg = existing_highlights["ErrorMsg"].bg,
    italic = true,
    underline = true,
  })
  vim.api.nvim_set_hl(preview_window_ns, "PymplePreviewLinesBefore", {
    fg = existing_highlights["Removed"].fg,
    bg = existing_highlights["Removed"].bg,
  })
  vim.api.nvim_set_hl(preview_window_ns, "PymplePreviewLinesAfter", {
    fg = existing_highlights["Added"].fg,
    bg = existing_highlights["Added"].bg,
  })
  vim.api.nvim_set_hl(preview_window_ns, "PymplePreviewSeparators", {
    fg = existing_highlights["CursorLineNr"].fg,
    bg = existing_highlights["CursorLineNr"].bg,
  })
  vim.api.nvim_set_hl(preview_window_ns, "PymplePreviewIgnored", {
    fg = existing_highlights["LineNr"].fg,
    bg = existing_highlights["LineNr"].bg,
  })
  vim.api.nvim_set_hl(preview_window_ns, "PymplePreviewDefaultIcon", {
    fg = existing_highlights["Function"].fg,
    bg = existing_highlights["Function"].bg,
    bold = true,
  })
end

M.preview_window_ns = preview_window_ns

return M
