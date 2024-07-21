M = {}

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

return M
