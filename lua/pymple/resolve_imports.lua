local M = {}

local utils = require("pymple.utils")
local config = require("pymple.config")

-- classes, functions, and variables
local class_pattern = [['^class\s+%s\b']]
local function_pattern = [['^def\s+%s\b']]
local variable_pattern = [['^%s\s*=']]

local IMPORTABLE_SYMBOLS_PATTERNS = {
  class_pattern,
  function_pattern,
  variable_pattern,
}

function M.resolve_python_import()
  if not utils.is_python_file(vim.fn.expand("%")) then
    vim.api.nvim_echo(
      { { "Not a python file", config.HL_GROUPS.Error } },
      false,
      {}
    )
    return
  end
  local symbol = vim.fn.expand("<cword>")

  local command_args = { "-f", "-t", "py" }
  for _, pattern in ipairs(IMPORTABLE_SYMBOLS_PATTERNS) do
    table.insert(command_args, "-e")
    table.insert(command_args, string.format(pattern, symbol))
  end
  table.insert(command_args, ".")
end

return M
