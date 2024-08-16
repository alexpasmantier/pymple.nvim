local utils = require("pymple.utils")
local log = require("pymple.log")

local M = {}

-- TODO: finish refactoring project so that it lazyloads in the rest of the code

---@class ProjectConfig
---@field venv string
---@field root string
local ProjectConfig = {}

---@param config Config
---@return string | nil
local function venv(config)
  local venv_location = utils.get_virtual_environment(
    vim.fn.getcwd(),
    config.python.virtual_env_names
  )
  if venv_location == nil then
    log.warn("No virtual environment found.")
  end
  return venv_location
end

---@param config Config
---@return string
local function project_root(config)
  local cwd = vim.fn.getcwd()
  local p_root = utils.find_project_root(cwd, config.python.root_markers)
  if p_root == nil then
    log.warn(
      "No project root found. Defaulting to current working directory: ",
      cwd
    )
  end
  return p_root or cwd
end

setmetatable(ProjectConfig, {
  __index = function(tbl, key)
    if key == "venv" then
      return venv(tbl)
    elseif key == "root" then
      return project_root(tbl)
    end
  end,
})

return M
