-- TODO: integrate with other file tree plugins (oil, etc.)
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

local subscribe_to_nvimtree_events = function(nvimtree_api, opts)
  local Event = nvimtree_api.events.Event

  nvimtree_api.events.subscribe(Event.NodeRenamed, function(data)
    api.update_imports(data.old_name, data.new_name, opts)
  end)
end

M.setup = function()
  local neotree_installed, events = pcall(require, "neo-tree.events")
  if neotree_installed then
    log.info(
      "Found neo-tree installation, hooking up FILE_MOVED and FILE_RENAMED events"
    )
    subscribe_to_neotree_events(events, config.user_config.update_imports)
  end

  local nvimtree_installed, nvimtree_api = pcall(require, "nvim-tree.api")
  if nvimtree_installed then
    log.info(
      "Found nvim-tree installation, hooking up FILE_MOVED and FILE_RENAMED events"
    )
    subscribe_to_nvimtree_events(
      nvimtree_api,
      config.user_config.update_imports
    )
  end
end

return M
