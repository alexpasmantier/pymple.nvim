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
local log = require("pymple.log")
local TELESCOPE_WIDTH_PADDING = 5
local TELESCOPE_HEIGHT_PADDING = 5
local TELESCOPE_MIN_HEIGHT = 8
local TELESCOPE_MAX_HEIGHT = 20

---Resolves import for symbol under cursor.
---This will automatically find and add the corresponding import to the top of
---the file (below any existing doctsring)
M.add_import_for_symbol_under_cursor = function()
  local autosave = config.user_config.add_import_to_buf.autosave
  local symbol = vim.fn.expand("<cword>")
  if symbol == "" then
    print_err("No symbol found under cursor.")
    return
  end
  log.debug("Symbol under cursor: " .. symbol)
  local is_identifier, node_type = utils.is_cursor_node_identifier()
  if not is_identifier then
    print_err(
      string.format(
        "Cursor must be on an importable symbol, not `%s`.",
        node_type
      )
    )
    return
  end

  local candidates =
    resolve_imports.resolve_python_import(symbol, vim.fn.expand("%"))
  log.debug("Candidates: " .. vim.inspect(candidates))

  if candidates == nil then
    return
  end
  if #candidates == 0 then
    print_err(
      string.format(
        "No results in the current environment for symbol `%s`.",
        symbol
      )
    )
    return
  elseif #candidates == 1 then
    local final_import = candidates[1]
    utils.add_import_to_buffer(final_import, symbol, 0, autosave)
    log.debug("Added import for " .. symbol .. ": " .. final_import)
  else
    local longest_candidate = utils.longest_string_in_list(candidates)
    vim.ui.select(candidates, {
      prompt = "Select an import",
      telescope = require("telescope.themes").get_cursor({
        layout_config = {
          width = #longest_candidate + TELESCOPE_WIDTH_PADDING,
          height = math.max(
            TELESCOPE_MIN_HEIGHT,
            math.min(
              #candidates + TELESCOPE_HEIGHT_PADDING,
              TELESCOPE_MAX_HEIGHT
            )
          ),
        },
      }),
    }, function(selected)
      if selected then
        local final_import = selected
        log.debug("Selected import: " .. final_import)
        utils.add_import_to_buffer(final_import, symbol, 0, autosave)
        log.debug("Added import for " .. symbol .. ": " .. final_import)
      end
    end)
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
