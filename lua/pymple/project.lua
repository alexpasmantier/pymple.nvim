local utils = require("pymple.utils")
local config = require("pymple.config")
local log = require("pymple.log")

---@class Project
---@field root string
---@field venv string
local Project = {}

local cache = {}

---@return string | nil
local function venv()
  local venv_location = utils.get_virtual_environment(
    vim.fn.getcwd(),
    config.user_config.python.virtual_env_names
  )
  if venv_location == nil then
    log.warn("No virtual environment found.")
  end
  log.debug("Virtual environment: ", venv_location)
  return venv_location
end

---@return string
local function root_dir()
  local cwd = vim.fn.getcwd()
  local p_root =
    utils.find_project_root(cwd, config.user_config.python.root_markers)
  if p_root == nil then
    log.warn(
      "No project root found. Defaulting to current working directory: ",
      cwd
    )
  end
  log.debug("Project root: ", p_root or cwd)
  return p_root or cwd
end

setmetatable(Project, {
  __index = function(_, key)
    if cache[key] then
      return cache[key]
    end
    if key == "root" then
      cache[key] = root_dir()
      return cache[key]
    end
    if key == "venv" then
      cache[key] = venv()
      return cache[key]
    end
  end,
})

return Project
