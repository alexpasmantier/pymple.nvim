M = {}

local filetype = require("plenary.filetype")

---@type number: The time to wait before refreshing open buffers
DEFAULT_HANG_TIME = 1000
-- @param hang_time number: The time to wait before refreshing the buffers
function M.async_refresh_buffers(hang_time)
  vim.defer_fn(function()
    vim.api.nvim_command("checktime")
  end, hang_time or DEFAULT_HANG_TIME)
end

---gets the $SHELL env var
---@return string?
function M.get_user_shell()
  return os.getenv("SHELL")
end

M.SHELL = M.get_user_shell()

---checks if a binary is available to use
---@param binary_name any
---@return boolean
function M.check_binary_installed(binary_name)
  return 1 == vim.fn.executable(binary_name)
end

---@param module_path string: The path to a python module
---@return string: The import path for the module
function M.to_import_path(module_path)
  local result, _ = module_path:gsub("/", "."):gsub("%.py$", "")
  return result
end

---@param import_path string: The import path to be split
---@return string, string: The base path and the last part of the import path
function M.split_import_on_last_separator(import_path)
  local base_path, module_name = import_path:match("(.-)%.?([^%.]+)$")
  return base_path, module_name
end

---@param import_path string: The import path to be escaped
function M.escape_import_path(import_path)
  return import_path:gsub("%.", [[\.]])
end

---@param path string: The path to the file
---@return boolean: Whether or not the file is a python file
function M.is_python_file(path)
  return filetype.detect(path, {}) == "python"
end

---@param path string: The path to the directory
---@return boolean: Whether or not the directory contains python files
function M.recursive_dir_contains_python_files(path)
  local files = vim.fn.readdir(path)
  for _, file in ipairs(files) do
    local full_path = path .. "/" .. file
    if vim.fn.isdirectory(full_path) == 1 then
      if M.recursive_dir_contains_python_files(full_path) then
        return true
      end
    elseif M.is_python_file(full_path) then
      -- vim.fn.writefile({ "IS PYTHON FILE" }, "/tmp/neotree.log", "a")
      return true
    end
  end
  return false
end

---@param buf number: The buffer number
---@return number | nil: The height (in lines) of the docstring
function M.find_docstring_end_line_number(buf)
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
function M.add_import_to_current_buf(import_path, symbol)
  local docstring_height = M.find_docstring_end_line_number(0)
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

return M
