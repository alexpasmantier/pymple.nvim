local utils = require("pymple.utils")

local M = {}

---@param job ReplaceJob
---@return number
local count_imports_in_rjob = function(job)
  local import_count = 0
  for _, target in ipairs(job.targets) do
    import_count = import_count + #target.results
  end
  return import_count
end

M.count_imports_in_rjob = count_imports_in_rjob

---@param jobs ReplaceJob[]
---@return number
local count_imports_in_rjobs = function(jobs)
  local import_count = 0
  for _, job in ipairs(jobs) do
    import_count = import_count + count_imports_in_rjob(job)
  end
  return import_count
end

M.count_imports_in_rjobs = count_imports_in_rjobs

-- ---@param job ReplaceJob
-- ---@return string[]
-- local get_files_from_rjob = function(job)
--   local files = {}
--   for _, target in ipairs(job.targets) do
--     table.insert(files, target.path)
--   end
--   return files
-- end
--
-- M.get_files_from_rjob = get_files_from_rjob

---@param jobs ReplaceJob[]
---@return string[]
local get_files_from_rjobs = function(jobs)
  local files = {}
  for _, job in ipairs(jobs) do
    for _, target in ipairs(job.targets) do
      table.insert(files, target.path)
    end
  end
  files = utils.deduplicate_list(files)
  return files
end

M.get_files_from_rjobs = get_files_from_rjobs

return M
