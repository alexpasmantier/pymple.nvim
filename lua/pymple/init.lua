---@tag pymple.nvim
---@brief [[
--- This plugin attempts to provide missing utilities when working with Python
--- imports inside Neovim.
---
--- These utilities include:
--- - automatic update of imports when renaming/moving a file or a folder
--- - automatic symbol import resolution based on your current workspace and
---   installed python packages
---@brief ]]

local config = require("pymple.config")
local keymaps = require("pymple.keymaps")
local user_commands = require("pymple.user_commands")
local log = require("pymple.log")
local hooks = require("pymple.hooks")

local M = {}

--- Setup pymple.nvim with the provided configuration
---@param opts Config
local function setup(opts)
  opts = opts or {}

  config:set_user_config(opts)

  -- Setup logging
  if
    config.user_config.logging.file ~= nil
    or config.user_config.logging.console ~= nil
  then
    log.new(config.user_config.logging, true)
    log.info("--------------------------------------------------------------")
    log.info("---                   NEW PYMPLE SESSION                   ---")
    log.info("--------------------------------------------------------------")
  else
    log.new(log.off_config, true)
  end

  log.debug("Current directory: ", vim.fn.getcwd())

  -- Validate configuration
  if not config:validate_configuration() then
    return
  end

  -- Setup user commands
  user_commands.setup()

  -- Setup keymaps
  keymaps.setup()

  -- Setup hooks
  hooks.setup()
end

--- Setup pymple.nvim with the provided configuration
---@param opts Config
function M.setup(opts)
  setup(opts)
  log.info("Pymple setup complete")
end

function M.install()
  log.info("Installing pymple.nvim dependencies...")
  require("pymple.build").build()
end

setmetatable(M, {
  __index = function(_, k)
    return require("pymple.api")[k]
  end,
})

return M
