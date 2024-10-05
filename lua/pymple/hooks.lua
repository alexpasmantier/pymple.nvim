local log = require("pymple.log")
local api = require("pymple.api")
local config = require("pymple.config")

local M = {}

---@param events table
---@param opts UpdateImportsOptions
local setup_neotree_hooks = function(events, opts)
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

---@param nvimtree_api table
---@param opts UpdateImportsOptions
local setup_nvimtree_hooks = function(nvimtree_api, opts)
  local Event = nvimtree_api.events.Event

  nvimtree_api.events.subscribe(Event.NodeRenamed, function(data)
    api.update_imports(data.old_name, data.new_name, opts)
  end)
end

local setup_oil_hooks = function(opts)
  vim.api.nvim_create_autocmd("User", {
    pattern = "OilActionsPost",
    callback = function(args)
      local parse_url = function(url)
        return url:match("^.*://(.*)$")
      end
      local data = args.data
      for _, action in ipairs(data.actions) do
        if action.type == "move" then
          local src_url = parse_url(action.src_url)
          local dest_url = parse_url(action.dest_url)
          api.update_imports(src_url, dest_url, opts)
        end
      end
    end,
  })
end

---@alias YaziNeovimEvent.YaziRenamedOrMovedData {changes: table<string, string>} # a table of old paths to new paths

local setup_yazi_hooks = function(opts)
  vim.api.nvim_create_autocmd("User", {
    pattern = "YaziRenamedOrMoved",
    ---@param event {data: YaziNeovimEvent.YaziRenamedOrMovedData}
    callback = function(event)
      for before, after in pairs(event.data.changes) do
        api.update_imports(before, after, opts)
      end
    end,
  })
end

M.setup = function()
  local neotree_installed, events = pcall(require, "neo-tree.events")
  if neotree_installed then
    log.info("Found neo-tree installation, hooking up events")
    setup_neotree_hooks(events, config.user_config.update_imports)
  end

  local nvimtree_installed, nvimtree_api = pcall(require, "nvim-tree.api")
  if nvimtree_installed then
    log.info("Found nvim-tree installation, hooking up events")
    setup_nvimtree_hooks(nvimtree_api, config.user_config.update_imports)
  end

  local oil_installed, _ = pcall(require, "oil")
  if oil_installed then
    log.info("Found oil installation, hooking up events")
    setup_oil_hooks(config.user_config.update_imports)
  end

  local yazi_installed, _ = pcall(require, "yazi")
  if yazi_installed then
    log.info("Found yazi installation, hooking up events")
    setup_yazi_hooks(config.user_config.update_imports)
  end
end

return M
