local print_err = require("pymple.utils").print_err
local api = require("pymple.api")
local config = require("pymple.config")
local log = require("pymple.log")

local M = {}

local function setup_update_imports()
  vim.api.nvim_create_user_command("PympleUpdateImports", function(args)
    if #args.fargs < 2 then
      print_err("Usage: PympleUpdateImports <source> <destination>")
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
  log.debug("Created PympleUpdateImports user command")
end

local function setup_add_import()
  vim.api.nvim_create_user_command("PympleResolveImport", function(_)
    require("pymple.api").resolve_import_under_cursor()
  end, {
    desc = [[Resolves import for symbol under cursor. This will
      automatically find and add the corresponding import to the top of the
      file (below any existing doctsring)]],
  })
  log.debug("Created PympleResolveImport user command")
end

local function setup_build()
  vim.api.nvim_create_user_command("PympleBuild", function(_)
    require("pymple.build").build()
  end, { desc = "Installs all dependencies needed to run Pymple" })
  log.debug("Created PympleBuild user command")
end

function M.setup()
  setup_update_imports()
  setup_add_import()
  setup_build()
end

return M
