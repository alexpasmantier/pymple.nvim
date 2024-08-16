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

local M = {}

--- Setup pymple.nvim with the provided configuration
---@param opts Config
local function setup(opts)
  opts = opts or {}

  local user_config = config.set_user_config(opts)

  -- Setup logging
  if user_config.logging.file ~= nil or user_config.logging.console ~= nil then
    log.new(user_config.logging, true)
    log.info("--------------------------------------------------------------")
    log.info("---                   NEW PYMPLE SESSION                   ---")
    log.info("--------------------------------------------------------------")
  else
    log.new(log.off_config, true)
  end

  -- Validate configuration
  if not config.validate_configuration(user_config) then
    return
  end

  -- Setup user commands
  vim.api.nvim_create_user_command("UpdatePythonImports", function(args)
    if #args.fargs < 2 then
      print_err("Usage: UpdatePythonImports <source> <destination>")
      return
    end
    api.update_imports(args.fargs[1], args.fargs[2], user_config.update_imports)
  end, {
    desc = [[Update all imports in workspace after renaming `source` to
    `destination`]],
    nargs = "+",
  })
  log.debug("Created UpdatePythonImports user command")

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

  keymaps.setup_keymaps(user_config.keymaps)
  log.debug("Set up keymaps")

  hooks.setup(user_config.update_imports)
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
