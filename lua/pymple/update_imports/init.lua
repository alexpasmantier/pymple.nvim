local utils = require("pymple.utils")
local log = require("pymple.log")
local update_imports_jobs = require("pymple.update_imports.jobs")
local jobs = require("pymple.jobs")
local async = require("plenary.async")

local M = {}

---@param source string: The import path to the source file/dir
---@param destination string: The import path to the destination file/dir
---@param filetypes string[]: The filetypes to update imports for
---@return ReplaceJob | nil
local function make_split_imports_job(source, destination, filetypes)
  local split = true
  local gg_args = update_imports_jobs.make_gg_args(source, filetypes, split)
  log.debug("split gg args: " .. gg_args)
  local gg_results = jobs.gg(gg_args)
  if #gg_results == 0 then
    return nil
  end

  local sed_patterns =
    update_imports_jobs.make_sed_patterns(source, destination, split)

  return update_imports_jobs.ReplaceJob.new(sed_patterns, gg_results)
end

M.make_split_imports_job = make_split_imports_job

---@param source string: The import path to the source file/dir
---@param destination string: The import path to the destination file/dir
---@param filetypes string[]: The filetypes to update imports for
---@return ReplaceJob | nil
local function make_monolithic_imports_job(source, destination, filetypes)
  local gg_args = update_imports_jobs.make_gg_args(source, filetypes, false)
  log.debug("monolithic gg args: " .. gg_args)
  local gg_results = jobs.gg(gg_args)
  if #gg_results == 0 then
    return nil
  end

  local sed_patterns =
    update_imports_jobs.make_sed_patterns(source, destination, false)

  return update_imports_jobs.ReplaceJob.new(sed_patterns, gg_results)
end

M.make_monolithic_imports_job = make_monolithic_imports_job

---@param source string: The path to the source file/dir
---@param destination string: The path to the destination file/dir
---@param filetypes string[]: The filetypes to update imports for
---@param python_root string: The root of the python project
---@return ReplaceJob[]
function M.prepare_jobs(source, destination, filetypes, python_root)
  local s, d = unpack(
    utils.map(
      utils.to_python_reference_path,
      utils.make_files_relative({ source, destination }, python_root),
      {}
    )
  )
  --- @type ReplaceJob[]
  local replace_jobs = {}
  if utils.is_python_file(source) and utils.is_python_file(destination) then
    log.debug("Operating on a file")
    local s_job = make_split_imports_job(s, d, filetypes)
    local m_job = make_monolithic_imports_job(s, d, filetypes)
    if s_job then
      table.insert(replace_jobs, s_job)
    end
    if m_job then
      table.insert(replace_jobs, m_job)
    end
  elseif utils.recursive_dir_contains_python_files(destination) then
    log.debug("Operating on a directory")
    local m_job = make_monolithic_imports_job(s, d, filetypes)
    if m_job then
      table.insert(replace_jobs, m_job)
    end
  end
  return replace_jobs
end

---Run the replace jobs on the files
---@param r_jobs ReplaceJob[]: The replace jobs to run
function M.run_jobs(r_jobs)
  for _, j in ipairs(r_jobs) do
    j:run_on_files()
  end
  utils.async_refresh_buffers(utils.DEFAULT_HANG_TIME)
end

---Run the replace jobs in memory (dry run)
---@param r_jobs ReplaceJob[]: The replace jobs to run
---@return ReplaceJobResult[]
function M.dry_run_jobs(r_jobs)
  local results = {}
  for _, j in ipairs(r_jobs) do
    for _, result in ipairs(j:run_on_lines()) do
      table.insert(results, result)
    end
  end
  return results
end

function M.async_dry_run_jobs(r_jobs, channel)
  for _, j in ipairs(r_jobs) do
    async.run(function()
      j:async_run_on_lines(channel)
    end)
  end
end

return M
