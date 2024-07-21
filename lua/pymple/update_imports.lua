M = {}

local Path = require("plenary.path")
local utils = require("pymple.utils")
local jobs = require("pymple.jobs")

-- to be formatted using the full import path to the renamed file/dir
local SPLIT_IMPORT_REGEX =
  [[from\s+%s\s+import\s+\(?\n?[\sa-zA-Z0-9_,\n]+\)?\s*$]]

--[[
from path.to.dir import file
from path.to.dir import (
    file1,
    file2,
)
from path.to.file import Something
--]]
---@param source string: The path to the source file/dir
---@param destination string: The path to the destination file/dir
local function update_imports_split(source, destination)
  local cwd = vim.fn.getcwd()

  local source_relative = Path:new(source):make_relative(cwd)
  local destination_relative = Path:new(destination):make_relative(cwd)

  -- path.to.file/dir
  local source_import_path = utils.to_import_path(source_relative)
  local destination_import_path = utils.to_import_path(destination_relative)

  -- path.to and file/dir
  local source_base_path, source_module_name =
    utils.split_import_on_last_separator(source_import_path)
  local destination_base_path, destination_module_name =
    utils.split_import_on_last_separator(destination_import_path)

  local gg_args_split = {
    "--json",
    "-U",
    "-t",
    "py",
    "-t",
    "md",
    string.format(
      "'%s'",
      SPLIT_IMPORT_REGEX:format(utils.escape_import_path(source_base_path))
    ),
    ".",
  }
  local sed_args_base = {
    "'%s,%ss/"
      .. utils.escape_import_path(source_base_path)
      .. "/"
      .. utils.escape_import_path(destination_base_path)
      .. "/'",
  }
  local sed_args_module = {
    "'%s,%ss/"
      .. utils.escape_import_path(source_module_name)
      .. "/"
      .. utils.escape_import_path(destination_module_name)
      .. "/'",
  }
  jobs.gg_into_sed(gg_args_split, sed_args_base, true)
  jobs.gg_into_sed(gg_args_split, sed_args_module, true)
end

--[[
from path.to.dir import file
from path.to.dir import (
   file1,
   file2,
)
]]
---@param source string: The path to the source file/dir
---@param destination string: The path to the destination file/dir
local function update_imports_monolithic(source, destination)
  local cwd = vim.fn.getcwd()

  -- path/to/here
  local source_relative = Path:new(source):make_relative(cwd)
  local destination_relative = Path:new(destination):make_relative(cwd)

  -- path.to.here
  local source_import_path = utils.to_import_path(source_relative)
  local destination_import_path = utils.to_import_path(destination_relative)

  local gg_args = {
    "--json",
    "-t",
    "py",
    "-t",
    "md",
    string.format("'%s'", utils.escape_import_path(source_import_path)),
    ".",
  }
  local sed_args = {
    "'s/"
      .. utils.escape_import_path(source_import_path)
      .. "/"
      .. utils.escape_import_path(destination_import_path)
      .. "/'",
  }
  jobs.gg_into_sed(gg_args, sed_args, false)
end

---@param source string: The path to the source file/dir
---@param destination string: The path to the destination file/dir
function M.update_imports(source, destination)
  if utils.is_python_file(source) and utils.is_python_file(destination) then
    update_imports_split(source, destination)
    update_imports_monolithic(source, destination)
  elseif utils.recursive_dir_contains_python_files(destination) then
    update_imports_monolithic(source, destination)
  end
  utils.async_refresh_buffers(DEFAULT_HANG_TIME)
end

return M
