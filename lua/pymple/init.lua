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
local M = {}

local config = require("pymple.config")
local keymaps = require("pymple.keymaps")
local api = require("pymple.api")
local utils = require("pymple.utils")
local print_err = utils.print_err
local log = require("pymple.log")

--- Setup pymple.nvim with the provided configuration
---@param opts Config
local function setup(opts)
  opts = opts or {}

  setmetatable(opts, { __index = config.default_config })
  config.set_user_config(opts)

  if opts.logging.enabled then
    opts.logging.enabled = nil
    log.new(opts.logging, true)
    log.debug("Logging enabled")
  else
    log.new(log.off_config, true)
  end

  if not utils.table_contains(opts.update_imports.filetypes, "python") then
    print_err(
      "Your configuration is invalid: `update_imports.filetypes` must at least contain the value `python`."
    )
  end
  local function _update_imports(source, destination)
    api.update_imports(source, destination, opts.update_imports)
  end

  if opts.create_user_commands.update_imports then
    vim.api.nvim_create_user_command("UpdatePythonImports", function(args)
      _update_imports(args.fargs[1], args.fargs[2])
    end, {
      desc = [[Update all imports in workspace after renaming `source` to
      `destination`]],
      nargs = "+",
    })
    log.debug("Created UpdatePythonImports user command")
  end

  if opts.create_user_commands.add_import_for_symbol_under_cursor then
    vim.api.nvim_create_user_command(
      "PympleAddImportForSymbolUnderCursor",
      function(_)
        require("pymple.api").add_import_for_symbol_under_cursor()
      end,
      {
        desc = [[Resolves import for symbol under cursor. This will
        automatically find and add the corresponding import to the top of the
        file (below any existing doctsring)]],
      }
    )
    log.debug("Created PympleAddImportForSymbolUnderCursor user command")
  end

  keymaps.setup_keymaps(opts.keymaps)
  log.debug("Set up keymaps")

  -- TODO: integrate with other file tree plugins (nvim-tree, oil, etc.)
  local neotree_installed, events = pcall(require, "neo-tree.events")
  if neotree_installed then
    log.debug(
      "Found neo-tree installation, hooking up FILE_MOVED and FILE_RENAMED events"
    )
    events.subscribe({
      event = events.FILE_MOVED,
      handler = function(args)
        _update_imports(args.source, args.destination)
      end,
    })
    events.subscribe({
      event = events.FILE_RENAMED,
      handler = function(args)
        _update_imports(args.source, args.destination)
      end,
    })
  end
end

--- Setup pymple.nvim with the provided configuration
---@param opts Config
function M.setup(opts)
  opts = opts or config.default_config
  setup(opts)
  log.debug("Pymple setup complete")
end

setmetatable(M, {
  __index = function(_, k)
    return require("pymple.api")[k]
  end,
})

return M
