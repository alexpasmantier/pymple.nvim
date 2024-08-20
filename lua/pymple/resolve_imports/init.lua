local M = {}

local utils = require("pymple.utils")
local jobs = require("pymple.resolve_imports.jobs")
local log = require("pymple.log")

-- classes, functions, and variables
local class_pattern = [['^class\s+%s\b']]
local function_pattern = [['^def\s+%s\b']]
local variable_pattern = [['^%s\s*=']]

local IMPORTABLE_SYMBOLS_PATTERNS = {
  class_pattern,
  function_pattern,
  variable_pattern,
}

---@param symbol string
---@param regexes string[]
---@return string
local function build_symbol_regexes(symbol, regexes)
  regexes = regexes or IMPORTABLE_SYMBOLS_PATTERNS
  local additional_args = ""
  for _, pattern in ipairs(regexes) do
    additional_args = additional_args
      .. "-e "
      .. string.format(pattern, symbol)
      .. " "
  end
  return additional_args
end

M.build_symbol_regexes = build_symbol_regexes

---@param symbol string: the symbol for which to resolve an import
---@param current_file_path string: the path to the current file
---@return string[] | nil: list of candidates
function M.resolve_python_import(symbol, current_file_path)
  local py_sys_paths = utils.get_python_sys_paths()
  local gg_args = "-fCHGA -t pystrict -I "
    .. current_file_path
    .. " "
    .. build_symbol_regexes(symbol, IMPORTABLE_SYMBOLS_PATTERNS)
  local candidate_paths = jobs.find_import_candidates(gg_args, py_sys_paths)
  log.debug("Candidates: " .. vim.inspect(candidate_paths))

  local import_candidates = {}
  for _, path in ipairs(candidate_paths) do
    local _path = string.gsub(path, "^%./", "")
    local import_path = utils.to_import_path(_path)
    table.insert(import_candidates, import_path)
  end
  -- sort imports by length
  table.sort(import_candidates, function(a, b)
    -- TODO: add other sorting rules (e.g. alphabetical, private modules, etc.)
    return #a < #b
  end)

  return import_candidates
end

return M
