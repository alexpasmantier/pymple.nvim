---@tag pymple.jobs
---@brief [[
--- Pymple's jobs module exposes functions that run jobs in the background.
--- These will typically be used for tasks like searching for import candidates
--- or updating imports in the workspace using `gg` and `sed`.
---@brief ]]

---@class Jobs
---@field global_sed fun(gg_job_results: GGJsonResult[], sed_args: string): nil
---@field ranged_sed fun(gg_job_results: GGJsonResult[], sed_args: string): nil
---@field gg fun(args: string[]): GGJsonResult[]
---@field find_import_candidates_in_workspace fun(args: string[]): string[]
---@field find_import_candidates_in_venv fun(args: string[], site_packages_location: string): string[]
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

--- Runs a sed command
---@param pattern string: The pattern to pass to sed
---@param file_path string: The path to the file to run the sed command on
function M.sed(pattern, file_path)
  Job:new({
    command = "zsh",
    args = {
      "-c",
      "sed -i '' " .. pattern .. " " .. file_path,
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

---------------------------------------------------

-- to be formatted using the full import path to the renamed file/dir
local SPLIT_IMPORT_REGEX =
  [[from\s+%s\s+import\s+\(?\n?[\sa-zA-Z0-9_,\n]+\)?\s*$]]

---@param filetypes string[]
---@return string[]
local function build_filetypes_args(filetypes)
  local args = {}
  for _, filetype in ipairs(filetypes) do
    table.insert(args, "-t")
    table.insert(args, filetype)
  end
  return args
end

M.build_filetypes_args = build_filetypes_args

---@param import_path string: The import path to replace
---@param filetypes string[]: The filetypes to search for
---@param split boolean: Whether to look for split import or not (default: false)
---@return string
local make_gg_args = function(import_path, filetypes, split)
  if split then
    local head, _ = utils.split_import_path(import_path)
    return table.concat({
      "--json",
      "-U",
      table.concat(build_filetypes_args(filetypes), " "),
      string.format(
        "'%s'",
        SPLIT_IMPORT_REGEX:format(utils.escape_import_path(head))
      ),
      ".",
    }, " ")
  else
    -- search for the full import path (possibly prefixing something else)
    return table.concat({
      "--json",
      table.concat(build_filetypes_args(filetypes), " "),
      string.format("'%s[\\.\\s]'", utils.escape_import_path(import_path)),
      ".",
    }, " ")
  end
end

---@param source_import_path string: The import path to replace
---@param destination_import_path string: The import path to replace with
---@param split boolean: Whether to look for split import or not (default: false)
---@return string[]
local make_sed_patterns = function(
  source_import_path,
  destination_import_path,
  split
)
  if not split then
    return {
      string.format(
        "s/%s\\([\\. ]\\)/%s\\1/",
        utils.escape_import_path(source_import_path),
        utils.escape_import_path(destination_import_path)
      ),
    }
  end
  local s_head, s_tail =
    utils.split_import_on_last_separator(source_import_path)
  local d_head, d_tail =
    utils.split_import_on_last_separator(destination_import_path)
  local sed_args_base = "s/"
    .. utils.escape_import_path(s_head)
    .. "/"
    .. utils.escape_import_path(d_head)
    .. "/"
  local sed_args_module = "s/"
    .. utils.escape_import_path(s_tail)
    .. "/"
    .. utils.escape_import_path(d_tail)
    .. "/"
  return { sed_args_base, sed_args_module }
end

---@class ReplaceJob
---@field file_path string
---@field sed_pattern string
local ReplaceJob = {}

ReplaceJob.__index = ReplaceJob

---Creates a new ReplaceJob
---@param file_path string: The path to the file to run the sed command on
---@param sed_pattern string: The pattern to pass to sed
function ReplaceJob.new(file_path, sed_pattern)
  local self = setmetatable({}, ReplaceJob)
  self.file_path = file_path
  self.sed_pattern = sed_pattern
  return self
end

function ReplaceJob()
  M.sed(self.sed_pattern, self.file_path)
end

function ReplaceJob:run()
  M.sed(self.sed_pattern, self.file_path)
end

return M
