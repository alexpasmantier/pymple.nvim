local utils = require("pymple.utils")
local log = require("pymple.log")

---@class ProjectState
---@field venv_location string | nil
---@field project_root string | nil
local ProjectState = {}

function ProjectState:setup()
  local cwd = vim.fn.getcwd()
  self.venv_location = utils.get_virtual_environment(cwd)
  log.debug("Virtual environment: " .. (self.venv_location or "None"))
  local p_root = utils.find_project_root(cwd)
  log.debug("Project root: " .. (p_root or "None"))
  if p_root == nil then
    log.warn(
      "Unable to find project root, defaulting to current working directory."
    )
  end
  self.project_root = p_root or cwd
end

function ProjectState:setValue(key, value)
  self[key] = value
end

function ProjectState:getValue(key)
  return self[key]
end

return ProjectState
