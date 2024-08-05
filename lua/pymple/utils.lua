M = {}

local filetype = require("plenary.filetype")
local cfg = require("pymple.config")
local log = require("pymple.log")

local _, ts_utils = pcall(require, "nvim-treesitter.ts_utils")

---@type number: The time to wait before refreshing open buffers
local DEFAULT_HANG_TIME = 1000
-- @param hang_time number: The time to wait before refreshing the buffers
function M.async_refresh_buffers(hang_time)
  vim.defer_fn(function()
    vim.api.nvim_command("checktime")
  end, hang_time or DEFAULT_HANG_TIME)
end

---gets the $SHELL env var
---@return string?
function M.get_user_shell()
  local shell = os.getenv("SHELL")
  if shell then
    return shell
  end
  -- otherwise check $0
  -- local obj = vim.system({ "echo", "$0" }, { text = true }):wait()
  -- local stdout = obj.stdout
  -- if stdout ~= nil then
  --   stdout = stdout:gsub("-", "")
  --   stdout = stdout:gsub("\n", "")
  -- end
  -- if stdout then
  --   return stdout
  -- end
  return "/bin/sh"
end

M.SHELL = M.get_user_shell()

---checks if a binary is available to use
---@param binary_name any
---@return boolean
function M.check_binary_installed(binary_name)
  return 1 == vim.fn.executable(binary_name)
end

local function lualib_installed(lib_name)
  local res, _ = pcall(require, lib_name)
  return res
end

---checks if a plugin is installed
---@param plugin_name string
---@return boolean
function M.check_plugin_installed(plugin_name)
  return lualib_installed(plugin_name)
end

---Converts a path to an import path
---@param module_path string: The path to a python module
---@return string: The import path for the module
function M.to_import_path(module_path)
  local result, _ = module_path:gsub("/", "."):gsub("%.py$", "")
  return result
end

---Splits an import path on the last separator
---@param import_path string: The import path to be split
---@return string | nil, string: The base path and the last part of the import path
function M.split_import_on_last_separator(import_path)
  local base_path, module_name = import_path:match("(.-)%.?([^%.]+)$")
  return base_path, module_name
end

---Escapes a string to be used in a regex
---@param import_path string: The import path to be escaped
function M.escape_import_path(import_path)
  return import_path:gsub("%.", [[\.]])
end

---Checks if a file is a python file
---@param path string: The path to the file
---@return boolean: Whether or not the file is a python file
local function is_python_file(path)
  return filetype.detect(path, {}) == "python"
end

M.is_python_file = is_python_file

---Recursively checks if a directory contains python files
---@param path string: The path to the directory
---@return boolean: Whether or not the directory contains python files
local function recursive_dir_contains_python_files(path)
  local files = vim.fn.readdir(path)
  for _, file in ipairs(files) do
    local full_path = path .. "/" .. file
    if vim.fn.isdirectory(full_path) == 1 then
      if recursive_dir_contains_python_files(full_path) then
        return true
      end
    elseif is_python_file(full_path) then
      return true
    end
  end
  return false
end

M.recursive_dir_contains_python_files = recursive_dir_contains_python_files

---Finds the end line number of a docstring in a list of lines
---@param lines string[]: The lines to search for a docstring
---@return number | nil: The height (in lines) of the docstring
local function find_docstring_end_line_number_in_lines(lines)
  -- if the first line does not contain a docstring, return 0
  if not lines[1]:match('^"""') then
    return 0
  elseif lines[1]:match('""".*"""$') then
    return 1
  else
    for i = 2, #lines do
      if lines[i]:match('"""') then
        return i
      end
    end
  end
  return nil
end

M.find_docstring_end_line_number_in_lines =
  find_docstring_end_line_number_in_lines

---Finds the end line number of a file docstring
---@param buf number: The buffer number
---@return number | nil: The height (in lines) of the docstring
local function find_docstring_end_line_number(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return find_docstring_end_line_number_in_lines(lines)
end

M.find_docstring_end_line_number = find_docstring_end_line_number

---Adds an import to the current buffer
---@param import_path string: The import path to be added
---@param symbol string: The symbol to be imported
---@param buf number: The buffer number
---@param autosave boolean: Whether or not to autosave the buffer after adding the import
function M.add_import_to_buffer(import_path, symbol, buf, autosave)
  local docstring_height = find_docstring_end_line_number(buf)
  local insert_on_line = 0
  if docstring_height ~= 0 then
    -- add 2 to the docstring height to account for the empty line after the docstring
    insert_on_line = docstring_height + 1
  end
  vim.api.nvim_buf_set_lines(
    buf or 0,
    insert_on_line,
    insert_on_line,
    false,
    { "from " .. import_path .. " import " .. symbol, "" }
  )
  if autosave then
    vim.cmd.write()
  end
end

---@param path string: The path in which to search for a virtual environment
---@return string | nil: The path to the virtual environment, or nil if it doesn't exist
local function dir_contains_virtualenv(path)
  for _, venv_name in ipairs(cfg.user_config.python.virtual_env_names) do
    local venv_path = path .. "/" .. venv_name
    if vim.fn.isdirectory(venv_path) == 1 then
      return venv_path
    end
  end
  return nil
end

---Get the path to the current virtual environment, or nil if we can't find one
---@param from_path string: The path to start searching from
---@return string | nil: The path to the current virtual environment
function M.get_virtual_environment(from_path)
  local venv = os.getenv("VIRTUAL_ENV")
  if venv then
    return venv
  end
  local current_path = from_path
  while current_path ~= vim.fn.expand("~") do
    local venv_path = dir_contains_virtualenv(current_path)
    if venv_path then
      return venv_path
    end
    current_path = vim.fn.fnamemodify(current_path, ":h")
  end
  return nil
end

---Get the path to the site packages directory
---@return string | nil: The path to the site packages directory
function M.get_site_packages_location()
  local result = vim.fn.system(
    "python -c 'from distutils.sysconfig import get_python_lib; print(get_python_lib())'"
  )
  local location = result:gsub("\n", "")
  if vim.fn.isdirectory(location) == 1 then
    return location
  end
  return nil
end

---Check if a table contains a specific entry
---@param tbl table: The table to check
---@param entry any: The entry to check for
---@return boolean: Whether or not the table contains the entry
function M.table_contains(tbl, entry)
  for key, value in pairs(tbl) do
    if key == entry or value == entry then
      return true
    end
  end
  return false
end

local MSG_PREFIX = "[pymple.nvim]: "

---Print a message to the console
---@param msg string: The message to print
---@param hl_group string: The highlight group to use
local print_msg = function(msg, hl_group)
  vim.api.nvim_echo({ { MSG_PREFIX .. msg, hl_group } }, true, {})
end

M.print_msg = print_msg

---Print an error message to the console
---@param err_msg string: The error message to print
function M.print_err(err_msg)
  print_msg(err_msg, cfg.HL_GROUPS.Error)
  if log.error then
    log.error(err_msg)
  end
end

---Print an info message to the console
---@param info_msg string: The info message to print
function M.print_info(info_msg)
  print_msg(info_msg, cfg.HL_GROUPS.More)
  log.info(info_msg)
end

---Check if the current node is an identifier using tree-sitter
---@return boolean, string|nil: Whether or not the current node is an identifier
function M.is_cursor_node_identifier()
  if not ts_utils then
    return true, nil
  end
  local node = ts_utils.get_node_at_cursor()
  if not node then
    return false, nil
  end
  local node_type = node:type()
  return node_type == "identifier", node_type
end

---Get the longest string in a list
---@param list string[]: The list of strings
---@return string: The longest string in the list
function M.longest_string_in_list(list)
  local longest = ""
  for _, str in ipairs(list) do
    if #str > #longest then
      longest = str
    end
  end
  return longest
end

---Deduplicate a list of elements
---@param list any[]: The list of elements
---@return any[]: The deduplicated list
function M.deduplicate_list(list)
  local seen = {}
  local result = {}
  for _, item in ipairs(list) do
    if not seen[item] then
      table.insert(result, item)
      seen[item] = true
    end
  end
  return result
end

---Make a list of files relative to current directory
---@param files string[]: The list of files
function M.make_files_relative(files)
  local result = {}
  for _, file in ipairs(files) do
    table.insert(result, vim.fn.fnamemodify(file, ":."))
  end
  return result
end

---Map a function over a list
---@param func function: The function to map
---@param list any[]: The list to map over
---@return any[]: The mapped list
function M.map(func, list)
  local mapped = {}
  for _, item in ipairs(list) do
    table.insert(mapped, func(item))
  end
  return mapped
end

return M
