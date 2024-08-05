---@tag pymple.jobs
---@brief [[
--- Pymple's jobs module exposes functions that run jobs in the background.
--- These will typically be used for tasks like searching for import candidates
--- or updating imports in the workspace using `gg` and `sed`.
---@brief ]]
M = {}

local Job = require("plenary.job")
local utils = require("pymple.utils")
local log = require("pymple.log")

---@class GGJsonMatch
---@field start number
---@field end number

---@class GGJsonSearchResult
---@field line_number number
---@field line string
---@field line_start number
---@field line_end number
---@field matches GGJsonMatch[]

---@class GGJsonResult
---@field path string
---@field results GGJsonSearchResult[]

--- Runs a global sed command on the results of a gg job
---@param gg_job_results GGJsonResult[]: The results of the gg job
---@param sed_args string: The arguments to pass to sed
function M.global_sed(gg_job_results, sed_args)
  local file_paths = {}
  for _, result in ipairs(gg_job_results) do
    table.insert(file_paths, result.path)
  end
  file_paths = utils.deduplicate_list(file_paths)
  if #file_paths == 0 then
    return
  end
  local sed_command = "sed -i '' "
    .. sed_args
    .. " "
    .. table.concat(file_paths, " ")
  log.debug("Sed command: " .. sed_command)
  Job:new({
    command = "zsh",
    args = {
      "-c",
      sed_command,
    },
  }):start()
end

--- Runs a ranged sed command on the results of a gg job
---@param gg_job_results GGJsonResult[]: The results of the gg job
---@param sed_args string: The arguments to pass to sed
function M.ranged_sed(gg_job_results, sed_args)
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
    local sed_command = "sed -i ''"
      .. string.format(sed_args, match.lines[1], match.lines[2])
      .. " "
      .. match.path
    log.debug("Sed command: " .. sed_command)
    Job:new({
      command = utils.SHELL,
      args = { "-c", sed_command },
    }):start()
  end
end

--- Runs a gg job and returns the results
---@param args string[]: Arguments to pass to the `gg` command
---@return GGJsonResult[]: The results of the gg job
function M.gg(args)
  local subcommand = "gg -C " .. table.concat(args, " ")
  log.debug("Starting gg job: " .. subcommand)
  local job = Job:new({
    command = utils.SHELL,
    args = { "-c", subcommand },
  })
  job:sync()
  local gg_results = {}
  for _, file_result in ipairs(job:result()) do
    local t = vim.json.decode(file_result)
    table.insert(gg_results, t)
  end
  log.debug(#gg_results .. " results found")
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
          table.insert(candidates, result)
        end
      end
    end,
  })
  job:sync()
  return candidates
end

return M
