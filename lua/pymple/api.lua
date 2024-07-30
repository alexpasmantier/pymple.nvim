local M = {}

local resolve_imports = require("pymple.resolve_imports")
local update_imports = require("pymple.update_imports")
local config = require("pymple.config")
local utils = require("pymple.utils")

---Resolves import for symbol under cursor.
---This will automatically find and add the corresponding import to the top of
---the file (below any existing doctsring)
M.add_import_for_symbol_under_cursor = function()
  local symbol = vim.fn.expand("<cword>")
  local candidates = resolve_imports.resolve_python_import(symbol)

  if candidates == nil then
    return
  end
  if #candidates == 0 then
    vim.api.nvim_echo({
      {
        "No results found in current workdir",
        config.HL_GROUPS.Error,
      },
    }, false, {})
    return
  elseif #candidates == 1 then
    utils.add_import_to_current_buf(candidates[1], symbol)
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
  else
    vim.api.nvim_echo(
      { { "Invalid selection", config.HL_GROUPS.Error } },
      false,
      {}
    )
  end
end

---Update all imports in workspace after renaming `source` to `destination`
---@param source string: The path to the source file/dir (before renaming/moving)
---@param destination string: The path to the destination file/dir (after renaming/moving)
---@param opts UpdateImportsOptions: Options for updating imports
M.update_imports = function(source, destination, opts)
  update_imports.update_imports(source, destination, opts.filetypes)
end

return M
