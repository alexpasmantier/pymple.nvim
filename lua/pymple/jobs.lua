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
local fs = require("pymple.fs")

local os_name = vim.loop.os_uname().sysname

local sed_binary = "sed"
local sed_inplace_args = "-i"
if os_name == "Darwin" then
  sed_binary = "gsed"
end

M.SED_BINARY = sed_binary
M.SED_INPLACE_ARGS = sed_inplace_args

---@class GGJsonMatch
---@field m_start number
---@field m_end number

---@class GGJsonSearchResult
---@field line_number number
---@field line string
---@field line_start number
---@field line_end number
---@field matches GGJsonMatch[]

---@class GGJsonResult
---@field path string
---@field results GGJsonSearchResult[]

--- Runs a sed command
---@param pattern string: The pattern to pass to sed
---@param file_path string: The path to the file to run the sed command on
---@param range number[]: The range of lines to run the sed command on
---@return Job: The job that was started
function M.sed(pattern, file_path, range)
  local sed_command = string.format(
    '%s %s "%s,%s%s" %s',
    sed_binary,
    sed_inplace_args,
    range[1],
    range[2],
    pattern,
    file_path
  )
  local job = Job:new({ command = utils.SHELL, args = { "-c", sed_command } })

  log.debug(
    "Open file descriptors: "
      .. fs.get_open_file_descriptors()
      .. "/"
      .. fs.max_open_file_descriptors
  )
  -- while fs.get_open_file_descriptors() >= fs.max_open_file_descriptors do
  --   -- if we're close to the limit, wait a bit
  --   vim.wait(100)
  -- end
  job:start()
  return job
end

function M.multi_sed(patterns, file_path, range)
  local ranged_patterns = {}
  for _, pattern in ipairs(patterns) do
    table.insert(
      ranged_patterns,
      string.format("%s,%s" .. pattern, range[1], range[2])
    )
  end
  local sed_command = string.format(
    sed_binary .. " " .. sed_inplace_args .. ' "%s" %s',
    table.concat(ranged_patterns, "; "),
    file_path
  )
  log.debug("Running sed command: " .. sed_command)
  local job = Job:new({ command = utils.SHELL, args = { "-c", sed_command } })
  job:sync()
end

local MAX_GG_RESULTS = 5000

--- Runs a gg job and returns the results
---@param args string: Arguments to pass to the `gg` command
---@return GGJsonResult[]: The results of the gg job
function M.gg(args)
  local subcommand = string.format("gg -C -M %s ", MAX_GG_RESULTS) .. args
  log.debug("Starting gg job: " .. subcommand)
  local job = Job:new({
    command = utils.SHELL,
    args = { "-c", subcommand },
  })
  job:sync()
  local gg_results = {}
  for _, file_result in ipairs(job:result()) do
    local t = vim.json.decode(file_result)
    -- this is unfortunate but `end` is a reserved keyword in Lua
    for _, sr in ipairs(t.results) do
      for _, m in ipairs(sr.matches) do
        m.m_start = m["start"]
        m.m_end = m["end"]
        m["start"] = nil
        m["end"] = nil
      end
    end
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
  local gg_command = "gg " .. table.concat(args, " ")
  log.debug("GG command: " .. gg_command)
  local job = Job:new({
    command = utils.SHELL,
    args = { "-c", gg_command },
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
