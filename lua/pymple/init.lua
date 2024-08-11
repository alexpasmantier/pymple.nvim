---@tag pymple.nvim
---@brief [[
--- This plugin attempts to provide missing utilities when working with Python
--- inside Neovim.
---
--- These utilities include:
--- - automatic renaming of imports when renaming/moving a file or a folder
--- - shortcuts to create usual python files (`tests`, `__init__`, etc.)
--- - automatic symbol import resolution based on your current workspace and
---   installed python packages
--- - automatic and configurable creation of test files that mirror your project
---   structure
---@brief ]]

local config = require("pymple.config")
local keymaps = require("pymple.keymaps")
local api = require("pymple.api")
local utils = require("pymple.utils")
local print_err = utils.print_err
local log = require("pymple.log")
local hooks = require("pymple.hooks")
local project = require("pymple.project")

local M = {}

--- Setup pymple.nvim with the provided configuration
---@param opts Config
local function setup(opts)
  opts = opts or {}

  local user_config = config.set_user_config(opts)

  -- P(user_config)
  if user_config.logging.enabled then
    log.new(user_config.logging, true)
    log.info("--------------------------------------------------------------")
    log.info("---                   NEW PYMPLE SESSION                   ---")
    log.info("--------------------------------------------------------------")
  else
    log.new(log.off_config, true)
  end

  if
    not utils.table_contains(user_config.update_imports.filetypes, "python")
  then
    print_err(
      "Your configuration is invalid: `update_imports.filetypes` must at least contain the value `python`."
    )
  end

  project:setup(user_config)

  if user_config.create_user_commands.update_imports then
    vim.api.nvim_create_user_command("UpdatePythonImports", function(args)
      api.update_imports(
        args.fargs[1],
        args.fargs[2],
        user_config.update_imports
      )
    end, {
      desc = [[Update all imports in workspace after renaming `source` to
      `destination`]],
      nargs = "+",
    })
    log.debug("Created UpdatePythonImports user command")
  end

  if user_config.create_user_commands.add_import_for_symbol_under_cursor then
    vim.api.nvim_create_user_command(
      "PympleAddImportForSymbolUnderCursor",
      function(_)
        require("pymple.api").add_import_for_symbol_under_cursor(
          user_config.add_import_to_buf.autosave
        )
      end,
      {
        desc = [[Resolves import for symbol under cursor. This will
        automatically find and add the corresponding import to the top of the
        file (below any existing doctsring)]],
      }
    )
    log.debug("Created PympleAddImportForSymbolUnderCursor user command")
  end

  keymaps.setup_keymaps(user_config.keymaps)
  log.debug("Set up keymaps")

  hooks.setup()
end

--- Setup pymple.nvim with the provided configuration
---@param opts Config
function M.setup(opts)
  setup(opts)
  log.debug("Pymple setup complete")
end

setmetatable(M, {
  __index = function(_, k)
    return require("pymple.api")[k]
  end,
})

return M
