---@tag pymple.jobs
---@brief [[
--- Pymple's jobs module exposes functions that run jobs in the background.
--- These will typically be used for tasks like searching for import candidates
--- or updating imports in the workspace using `gg` and `sed`.
---@brief ]]
M = {}

local Job = require("plenary.job")
local utils = require("pymple.utils")
local config = require("pymple.config")
local log = require("pymple.log")

---@class Job
---@field command string Command to run
---@field args? string[] List of arguments to pass
---@field cwd? string Working directory for job
---@field env? table<string, string>|string[] Environment looking like: { ['VAR'] = 'VALUE' } or { 'VAR=VALUE' }
---@field interactive? boolean
---@field detached? boolean Spawn the child in a detached state making it a process group leader
---@field skip_validation? boolean Skip validating the arguments
---@field enable_handlers? boolean If set to false, disables all callbacks associated with output (default: true)
---@field enabled_recording? boolean
---@field on_start? fun()
---@field on_stdout? fun(error: string, data: string, self?: Job)
---@field on_stderr? fun(error: string, data: string, self?: Job)
---@field on_exit? fun(self: Job, code: number, signal: number)
---@field maximum_results? number Stop processing results after this number
---@field writer? Job|table|string Job that writes to stdin of this job.

---@alias gg_json_matches {start: number, end: number}
---@alias gg_json_search_result {line_number: number, line: string, line_start: number, line_end: number, matches: gg_json_matches[]}
---@alias gg_json_search_results gg_json_search_result[]
---@alias gg_json_result {path: string, results: gg_json_search_results}
---@alias gg_json_results gg_json_result[]

--- Runs a global sed command on the results of a gg job
---@param gg_job_results gg_json_results: The results of the gg job
---@param sed_args table: The arguments to pass to sed
local function global_sed(gg_job_results, sed_args)
  local file_paths = {}
  for _, result in ipairs(gg_job_results) do
    table.insert(file_paths, result.path)
  end
  if #file_paths == 0 then
    return
  end
  local sed_args = table.concat(sed_args, " ")
    .. " "
    .. table.concat(file_paths, " ")
  log.debug("Sed args: " .. sed_args)
  Job:new({
    command = "zsh",
    args = {
      "-c",
      "sed -i '' " .. sed_args,
    },
  }):start()
end

--- Runs a ranged sed command on the results of a gg job
---@param gg_job_results gg_json_results: The results of the gg job
---@param sed_args table: The arguments to pass to sed
local function ranged_sed(gg_job_results, sed_args)
  local matches = {}
  for _, file_result in ipairs(gg_job_results) do
    for _, search_result in ipairs(file_result.results) do
      table.insert(matches, {
        path = file_result.path,
        lines = {
          search_result.line_start,
          search_result.line_end,
        },
      })
    end
  end
  if #matches == 0 then
    return
  end
  for _, match in ipairs(matches) do
    log.debug(
      "Match: "
        .. match.path
        .. " line start: "
        .. match.lines[1]
        .. " line end: "
        .. match.lines[2]
    )
    local sed_args =
      string.format(table.concat(sed_args, " "), match.lines[1], match.lines[2])
    log.debug("Sed args: " .. sed_args .. match.path)
    Job:new({
      command = utils.SHELL,
      args = {
        "-c",
        "sed -i '' " .. sed_args .. " " .. match.path,
      },
    }):start()
  end
end

--- Runs a gg job and pipes the results into a sed job
---@param gg_args table: The arguments to pass to gg
---@param sed_args table: The arguments to pass to sed
---@param range boolean: Whether or not to call sed with a range specifier
function M.gg_into_sed(gg_args, sed_args, range)
  log.debug("gg args: " .. table.concat(gg_args, " "))
  Job:new({
    command = utils.SHELL,
    args = { "-c", "gg " .. table.concat(gg_args, " ") },
    on_exit = function(job, _)
      local gg_results = {}
      for _, file_result in ipairs(job:result()) do
        local t = vim.json.decode(file_result)
        table.insert(gg_results, t)
      end
      log.debug(#gg_results .. " results found")
      if range then
        log.debug("Using ranged sed")
        ranged_sed(gg_results, sed_args)
      else
        log.debug("Using global sed")
        global_sed(gg_results, sed_args)
      end
    end,
  }):start()
end

--- Runs a gg job and returns the results
---@param args string[]: Arguments to pass to the `gg` command
---@return gg_json_results: The results of the gg job
function M.gg(args)
  local job = Job:new({
    command = utils.SHELL,
    args = { "-c", "gg -C " .. table.concat(args, " ") },
  })
  job:sync()
  local gg_results = {}
  for _, file_result in ipairs(job:result()) do
    local t = vim.json.decode(file_result)
    table.insert(gg_results, t)
  end
  return gg_results
end

---Finds import candidates in workspace
---@param args string[]: Arguments to pass to the `gg` command
---@return string[]: The import candidates
function M.find_import_candidates_in_workspace(args)
  local candidates = {}
  local job = Job:new({
    command = utils.SHELL,
    args = { "-c", "gg " .. table.concat(args, " ") },
    on_exit = function(job, _)
      local results = job:result()
      if #results ~= 0 then
        for _, result in ipairs(results) do
          table.insert(candidates, result)
        end
      end
    end,
  })
  job:sync()
  return candidates
end

---Finds import candidates in venv
---@param args string[]: Arguments to pass to the `gg` command
---@param site_packages_location string: The location of the site packages directory
---@return string[]: The import candidates
function M.find_import_candidates_in_venv(args, site_packages_location)
  local candidates = {}
  local prefix = site_packages_location .. "/"
  local job = Job:new({
    command = utils.SHELL,
    args = { "-c", "gg " .. table.concat(args, " ") },
    on_exit = function(job, _)
      local results = job:result()
      if #results ~= 0 then
        for _, result in ipairs(results) do
          local result = (result:sub(0, #prefix) == prefix)
              and result:sub(#prefix + 1)
            or result
          P(result)
          P(site_packages_location)
          table.insert(candidates, result)
        end
      end
    end,
  })
  job:sync()
  return candidates
end

return M
