local M = {}

-- to be formatted using the full import path to the renamed file/dir
local SPLIT_IMPORT_REGEX = [[from\s+%s\s+import\s+\(?\n?[\sa-zA-Z0-9_,\n]+\)?\s*$]]

---@param rg_args table: The arguments to pass to rg
---@param sed_args table: The arguments to pass to sed
---@param range boolean: Whether or not to call sed with a range specifier
local function rg_into_sed(rg_args, sed_args, range)
  Job:new({
    command = "zsh",
    args = { "-c", "rg " .. table.concat(rg_args, " ") },
    on_exit = function(job, _)
      if range then
        ranged_sed(job:result(), sed_args)
      else
        global_sed(job:result(), sed_args)
      end
    end,
  }):start()
end

local filetype = require("plenary.filetype")
local Path = require("plenary.path")

---@param path string: The path to the file
---@return boolean: Whether or not the file is a python file
local function is_python_file(path)
  return filetype.detect(path, {}) == "python"
end

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
      -- vim.fn.writefile({ "IS PYTHON FILE" }, "/tmp/neotree.log", "a")
      return true
    end
  end
  return false
end

---@type number: The time to wait before refreshing open buffers
DEFAULT_HANG_TIME = 1000
-- @param hang_time number: The time to wait before refreshing the buffers
local function async_refresh_buffers(hang_time)
  vim.defer_fn(function()
    vim.api.nvim_command("checktime")
  end, hang_time or DEFAULT_HANG_TIME)
end

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
  local source_import_path = to_import_path(source_relative)
  local destination_import_path = to_import_path(destination_relative)

  -- path.to and file/dir
  local source_base_path, source_module_name = split_import_on_last_separator(source_import_path)
  local destination_base_path, destination_module_name = split_import_on_last_separator(destination_import_path)

  local rg_args_split = {
    "--json",
    "-U",
    "-t",
    "py",
    "-t",
    "md",
    string.format("'%s'", SPLIT_IMPORT_REGEX:format(escape_import_path(source_base_path))),
    ".",
  }
  local sed_args_base = {
    "'%s,%ss/" .. escape_import_path(source_base_path) .. "/" .. escape_import_path(destination_base_path) .. "/'",
  }
  local sed_args_module = {
    "'%s,%ss/" .. escape_import_path(source_module_name) .. "/" .. escape_import_path(destination_module_name) .. "/'",
  }
  rg_into_sed(rg_args_split, sed_args_base, true)
  rg_into_sed(rg_args_split, sed_args_module, true)
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
  local source_import_path = to_import_path(source_relative)
  local destination_import_path = to_import_path(destination_relative)

  local rg_args =
    { "--json", "-t", "py", "-t", "md", string.format("'%s'", escape_import_path(source_import_path)), "." }
  local sed_args = {
    "'s/" .. escape_import_path(source_import_path) .. "/" .. escape_import_path(destination_import_path) .. "/'",
  }
  rg_into_sed(rg_args, sed_args, false)
end

---@param source string: The path to the source file/dir
---@param destination string: The path to the destination file/dir
function M.update_imports(source, destination)
  if is_python_file(source) and is_python_file(destination) then
    update_imports_split(source, destination)
    update_imports_monolithic(source, destination)
  elseif recursive_dir_contains_python_files(destination) then
    update_imports_monolithic(source, destination)
  end
  async_refresh_buffers(DEFAULT_HANG_TIME)
end

IGNORE_PATHS = {
  "./.venv",
  "./db_migrations",
}

---@param buf number: The buffer number
---@return number | nil: The height (in lines) of the docstring
local function find_docstring_end_line_number(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  -- if the first line does not contain a docstring, return 0
  if not lines[1]:match('^"""') then
    return 0
  elseif lines[1]:match('"""$') then
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

---@param import_path string: The import path to be added
---@param symbol string: The symbol to be imported
local function add_import_to_current_buf(import_path, symbol)
  local docstring_height = find_docstring_end_line_number(0)
  local insert_on_line
  if docstring_height == 0 then
    insert_on_line = 0
  else
    insert_on_line = docstring_height + 1
  end
  vim.api.nvim_buf_set_lines(
    0,
    insert_on_line,
    insert_on_line,
    false,
    { "from " .. import_path .. " import " .. symbol }
  )
end

---@type table<string, string>
local HL_GROUPS = {
  Error = "ErrorMsg",
  Warning = "WarningMsg",
  More = "MoreMsg",
  Mode = "ModeMsg",
}

function M.resolve_python_import()
  if not is_python_file(vim.fn.expand("%")) then
    vim.api.nvim_echo({ { "Not a python file", HL_GROUPS.Error } }, false, {})
    return
  end
  local symbol = vim.fn.expand("<cword>")

  local rg_args = { "-l", "-t", "py" }
  -- classes, functions, and variables
  local class_pattern = [['^class\s+%s\b']]
  local function_pattern = [['^def\s+%s\b']]
  local variable_pattern = [['^%s\s*=']]
  local patterns = { class_pattern, function_pattern, variable_pattern }
  for _, pattern in ipairs(patterns) do
    table.insert(rg_args, "-e")
    table.insert(rg_args, string.format(pattern, symbol))
  end
  table.insert(rg_args, ".")
  Job:new({
    command = "zsh",
    args = { "-c", "rg " .. table.concat(rg_args, " ") },
    on_exit = function(job, _)
      local results = job:result()
      if #results == 0 then
        vim.schedule(function()
          vim.api.nvim_echo({ { "No results found in current workdir", HL_GROUPS.Error } }, false, {})
        end)
        return
      elseif #results == 1 then
        vim.schedule(function()
          local path = string.gsub(results[1], "^%./", "")
          local import_path = to_import_path(path)
          add_import_to_current_buf(to_import_path(import_path), symbol)
        end)
        return
      end
      local potential_imports = {}
      for _, line in ipairs(results) do
        local path = string.gsub(line, "^%./", "")
        local import_path = to_import_path(path)
        table.insert(potential_imports, import_path)
      end
      -- sort imports by length
      table.sort(potential_imports, function(a, b)
        return #a < #b
      end)

      local message = {}
      for i, import_path in ipairs(potential_imports) do
        table.insert(message, string.format("%s: ", i) .. import_path)
      end
      vim.schedule(function()
        local user_input = vim.fn.input(table.concat(message, "\n") .. "\nSelect an import: ")
        local chosen_import = potential_imports[tonumber(user_input)]
        if chosen_import then
          add_import_to_current_buf(chosen_import, symbol)
        else
          vim.api.nvim_echo({ { "Invalid selection", HL_GROUPS.Error } }, false, {})
        end
      end)
    end,
  }):start()
end

return M
