---@tag pymple.api
---@brief [[
--- Pymple's API module exposes some of the main functions used by the plugin.
---
--- At the moment, the following functions are exposed:
---  - `add_import_for_symbol_under_cursor`: Resolves import for symbol under cursor.
---  - `update_imports`: Update all imports in workspace after renaming `source` to `destination`.
---@brief ]]

local resolve_imports = require("pymple.resolve_imports")
local utils = require("pymple.utils")
local print_err = utils.print_err
local log = require("pymple.log")
local TELESCOPE_WIDTH_PADDING = 5
local TELESCOPE_HEIGHT_PADDING = 5
local TELESCOPE_MIN_HEIGHT = 8
local TELESCOPE_MAX_HEIGHT = 20
local project = require("pymple.project")
local udim = require("pymple.update_imports")
local udim_utils = require("pymple.update_imports.utils")
local udim_ui = require("pymple.update_imports.ui")
local async = require("plenary.async")

local M = {}

---Resolves import for symbol under cursor.
---This will automatically find and add the corresponding import to the top of
---the file (below any existing doctsring)
---@param autosave boolean: Whether to autosave the buffer after adding the import
M.add_import_for_symbol_under_cursor = function(autosave)
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
---@param opts UpdateImportsOptions: Options for the update imports operation
M.update_imports = function(source, destination, opts)
  log.debug(
    "Updating imports from "
      .. source
      .. " to "
      .. destination
      .. " in filetypes: "
      .. vim.inspect(opts.filetypes)
  )
  local r_jobs =
    udim.prepare_jobs(source, destination, opts.filetypes, project.project_root)
  if #r_jobs == 0 then
    log.info("No jobs to run.")
    return
  end
  local imports_count = udim_utils.count_imports_in_rjobs(r_jobs)
  local files = udim_utils.get_files_from_rjobs(r_jobs)
  local confirmation_dialog = udim_ui.get_confirmation_dialog(
    imports_count,
    #files,
    function(item)
      if item.text == "Yes" then
        udim.run_jobs(r_jobs)
      elseif item.text == "Preview changes" then
        local sender, receiver = async.control.channel.mpsc()
        local preview_window =
          udim_ui.get_preview_window(r_jobs, imports_count, #files)
        preview_window:mount()
        udim.async_dry_run_jobs(r_jobs, sender)
        async.run(function()
          preview_window:render_preview(receiver)
        end)
        -- vim.api.nvim_buf_set_option(preview_window.bufnr, "modifiable", false)
      end
    end,
    function()
      log.debug("Confirmation dialog closed.")
    end
  )
  confirmation_dialog:mount()
end

return M
