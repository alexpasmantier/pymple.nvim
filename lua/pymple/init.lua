local M = {}

local config = require("pymple.config")
local keymaps = require("pymple.keymaps")
local api = require("pymple.api")

---@param opts Config
local function setup(opts)
  opts = opts or {}

  setmetatable(opts, { __index = config.default_config })

  if opts.create_user_commands.update_imports then
    vim.api.nvim_create_user_command("UpdatePythonImports", function(args)
      require("pymple.api").update_imports(args.fargs[1], args.fargs[2])
    end, {
      desc = "Update all imports in workspace after renaming `source` to `destination`",
      nargs = "+",
    })
  end

  if opts.create_user_commands.resolve_imports then
    vim.api.nvim_create_user_command("ResolvePythonImport", function(_)
      require("pymple.api").resolve_import()
    end, {
      desc = "Resolves import for symbol under cursor",
    })
  end

  keymaps.setup_keymaps(opts.keymaps)

  local neotree_installed, events = pcall(require, "neo-tree.events")
  if neotree_installed then
    events.subscribe({
      event = events.FILE_MOVED,
      handler = function(args)
        api.update_imports(args.source, args.destination)
      end,
    })
    events.subscribe({
      event = events.FILE_RENAMED,
      handler = function(args)
        api.update_imports(args.source, args.destination)
      end,
    })
  end
end

function M.setup(opts)
  opts = opts or config.default_config
  setup(opts)
end

return setmetatable(M, {
  __index = function(_, k)
    return require("pymple.api")[k]
  end,
})
