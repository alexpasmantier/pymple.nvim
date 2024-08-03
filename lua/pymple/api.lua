---@tag pymple.api
---@brief [[
--- Pymple's API module exposes some of the main functions used by the plugin.
---
--- At the moment, the following functions are exposed:
---  - `add_import_for_symbol_under_cursor`: Resolves import for symbol under cursor.
---  - `update_imports`: Update all imports in workspace after renaming `source` to `destination`.
---@brief ]]
local M = {}

local resolve_imports = require("pymple.resolve_imports")
local update_imports = require("pymple.update_imports")
local config = require("pymple.config")
local utils = require("pymple.utils")
local print_err = utils.print_err
local print_info = utils.print_info
local log = require("pymple.log")

---Resolves import for symbol under cursor.
---This will automatically find and add the corresponding import to the top of
---the file (below any existing doctsring)
M.add_import_for_symbol_under_cursor = function()
  local symbol = vim.fn.expand("<cword>")
  if symbol == "" then
    print_err("No symbol found under cursor")
    return
  end
  log.debug("Symbol under cursor: " .. symbol)

  local candidates = resolve_imports.resolve_python_import(symbol)
  log.debug("Candidates: " .. vim.inspect(candidates))

  if candidates == nil then
    return
  end
  if #candidates == 0 then
    print_err("No results found in workdir for the current symbol")
    return
  elseif #candidates == 1 then
    utils.add_import_to_current_buf(candidates[1], symbol)
    print_info("Added import for " .. symbol .. ": " .. candidates[1])
    return
  end

  local message = {}
  for i, import_path in ipairs(candidates) do
    table.insert(message, string.format("%s: ", i) .. import_path)
  end
  local user_input =
    vim.fn.input(table.concat(message, "\n") .. "\nSelect an import: ")
  local chosen_import = candidates[tonumber(user_input)]
  if chosen_import then
    utils.add_import_to_current_buf(chosen_import, symbol)
    print_info("Added import for " .. symbol .. ": " .. chosen_import)
  else
    print_err("Invalid selection")
  end
end

---Update all imports in workspace after renaming `source` to `destination`
---@param source string: The path to the source file/dir (before renaming/moving)
---@param destination string: The path to the destination file/dir (after renaming/moving)
---@param opts UpdateImportsOptions: Options for updating imports
M.update_imports = function(source, destination, opts)
  log.debug(
    "Updating imports from "
      .. source
      .. " to "
      .. destination
      .. " in filetypes: "
      .. vim.inspect(opts.filetypes)
  )
  update_imports.update_imports(source, destination, opts.filetypes)
end

return M
