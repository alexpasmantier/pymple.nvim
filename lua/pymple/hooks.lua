local log = require("pymple.log")
local api = require("pymple.api")
local config = require("pymple.config")

local M = {}

---@param events table
---@param opts UpdateImportsOptions
local subscribe_to_neotree_events = function(events, opts)
  events.subscribe({
    event = events.FILE_MOVED,
    handler = function(args)
      api.update_imports(args.source, args.destination, opts)
    end,
  })
  events.subscribe({
    event = events.FILE_RENAMED,
    handler = function(args)
      api.update_imports(args.source, args.destination, opts)
    end,
  })
end

-- TODO: integrate with other file tree plugins (nvim-tree, oil, etc.)

M.setup = function()
  local neotree_installed, events = pcall(require, "neo-tree.events")
  if neotree_installed then
    log.info(
      "Found neo-tree installation, hooking up FILE_MOVED and FILE_RENAMED events"
    )
    subscribe_to_neotree_events(events, config.user_config.update_imports)
  end
end

return M
