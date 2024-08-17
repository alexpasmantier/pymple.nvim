local print_err = require("pymple.utils").print_err
local api = require("pymple.api")
local config = require("pymple.config")
local log = require("pymple.log")

local M = {}

local function setup_update_imports()
  vim.api.nvim_create_user_command("UpdatePythonImports", function(args)
    if #args.fargs < 2 then
      print_err("Usage: UpdatePythonImports <source> <destination>")
      return
    end
    api.update_imports(
      args.fargs[1],
      args.fargs[2],
      config.user_config.update_imports
    )
  end, {
    desc = [[Update all imports in workspace after renaming `source` to
    `destination`]],
    nargs = "+",
  })
  log.debug("Created UpdatePythonImports user command")
end

local function setup_add_import()
  vim.api.nvim_create_user_command(
    "PympleAddImportForSymbolUnderCursor",
    function(_)
      require("pymple.api").add_import_for_symbol_under_cursor(
        config.user_config.add_import_to_buf.autosave
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

function M.setup()
  setup_update_imports()
  setup_add_import()
end

return M
