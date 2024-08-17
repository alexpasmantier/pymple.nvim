local jobs = require("pymple.jobs")
local utils = require("pymple.utils")
local async = require("plenary.async")
local log = require("pymple.log")

local M = {}

-- to be formatted using the full import path to the renamed file/dir
-- local SPLIT_IMPORT_REGEX =
--   [[from\s+%s\s+import\s+\(?\n?[\sa-zA-Z0-9_,\n]+\)?\s*$]]
local SPLIT_IMPORT_REGEX =
  [[from\s+%s\s+import\s+(?:\([\sa-zA-Z0-9_,]*%s[\sa-zA-Z0-9_,]*\)\s*|[\w,]*%s[\w,]*)]]

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
    local head, tail = utils.split_import_on_last_separator(import_path)
    return table.concat({
      "--json",
      "-U",
      table.concat(build_filetypes_args(filetypes), " "),
      string.format(
        "'%s'",
        SPLIT_IMPORT_REGEX:format(utils.escape_import_path(head), tail, tail)
      ),
      ".",
    }, " ")
  else
    -- search for the full import path (possibly prefixing something else)
    return table.concat({
      "--json",
      table.concat(build_filetypes_args(filetypes), " "),
      string.format("'[^\\.]\\b%s\\b'", utils.escape_import_path(import_path)),
      ".",
    }, " ")
  end
end

M.make_gg_args = make_gg_args

---@param source_import_path string: The import path to replace
---@param destination_import_path string: The import path to replace with
---@param split boolean: Whether to look for split import or not (default: false)
---@return string[]
local make_sed_patterns = function(
  source_import_path,
  destination_import_path,
  split
)
  if split then
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
  return {
    string.format(
      "s/%s/%s/",
      utils.escape_import_path(source_import_path),
      utils.escape_import_path(destination_import_path)
    ),
  }
end

M.make_sed_patterns = make_sed_patterns

---@class ReplaceJob
---@field sed_patterns string[]
---@field targets GGJsonResult[]
local ReplaceJob = {}

ReplaceJob.__index = ReplaceJob

---Creates a new ReplaceJob
---@param sed_patterns string[]: The patterns to pass to sed
---@param targets GGJsonResult[]: The targets to replace
---@return ReplaceJob
function ReplaceJob.new(sed_patterns, targets)
  local self = setmetatable({}, ReplaceJob)
  self.sed_patterns = sed_patterns or {}
  self.targets = targets or {}
  return self
end

---Adds a target to the ReplaceJob
---@param target GGJsonResult: The target to add to the job
function ReplaceJob:add_target(target)
  table.insert(self.targets, target)
end

---Adds a pattern to the ReplaceJob
---@param pattern string: The pattern to add to the job
function ReplaceJob:add_pattern(pattern)
  table.insert(self.sed_patterns, pattern)
end

---Runs the ReplaceJob on the target files
function ReplaceJob:run_on_files()
  -- local futures = {}
  for _, t in ipairs(self.targets) do
    for _, sr in ipairs(t.results) do
      async.run(function()
        jobs.multi_sed(
          self.sed_patterns,
          t.path,
          { sr.line_start, sr.line_end + 1 }
        )
      end)
    end
  end
end

---@class ReplaceJobResult
---@field file_path string
---@field line_before string
---@field line_after string
---@field line_num number

---Runs the ReplaceJob on individual lines and returns the modified lines
---@return ReplaceJobResult[]
function ReplaceJob:run_on_lines()
  local results = {}
  for _, t in ipairs(self.targets) do
    for _, sr in ipairs(t.results) do
      local line_before = sr.line
      local line_after = line_before
      for _, pattern in ipairs(self.sed_patterns) do
        local handle = assert(
          io.popen(
            "echo '"
              .. line_after
              .. string.format("' | %s '", jobs.SED_BINARY)
              .. pattern
              .. "'"
          )
        )
        -- sed adds a newline at the end of the line
        line_after = assert(handle:read("*a")):gsub("\n$", "")
        handle:close()
      end
      table.insert(results, {
        file_path = t.path,
        line_before = line_before,
        line_after = line_after,
        line_num = sr.line_number,
      })
    end
  end
  return results
end

function ReplaceJob:async_run_on_lines(channel)
  for _, t in ipairs(self.targets) do
    for _, sr in ipairs(t.results) do
      local line_before = sr.line
      local line_after = line_before
      for _, pattern in ipairs(self.sed_patterns) do
        local handle = assert(
          io.popen(
            'echo "'
              .. line_after
              .. string.format('" | %s "', jobs.SED_BINARY)
              .. pattern
              .. '"'
          )
        )
        -- sed adds a newline at the end of the line
        line_after = assert(handle:read("*a")):gsub("\n$", "")
        handle:close()
      end
      channel.send({
        file_path = t.path,
        line_before = line_before,
        line_after = line_after,
        line_num = sr.line_number,
      })
    end
  end
end

M.ReplaceJob = ReplaceJob

---@param path string
---@param ignored_paths {string: number[]}
local function is_path_ignored(path, ignored_paths)
  for p, _ in pairs(ignored_paths) do
    if path == p then
      return true
    end
  end
  return false
end

-- paths are of the form `path/to/file.py:line_number:`
---@param r_job ReplaceJob
---@param ignored_keys string[]
function M.filter_rjob_targets(r_job, ignored_keys)
  if #ignored_keys == 0 then
    return r_job
  end
  -- build up a hashmap of paths to line numbers
  local ignored_paths = {}
  for _, k in ipairs(ignored_keys) do
    local p, ln = unpack(vim.split(k, ":"))
    p = vim.fn.fnamemodify(p, ":p")
    if ignored_paths[p] == nil then
      ignored_paths[p] = {}
    end
    table.insert(ignored_paths[p], tonumber(ln))
  end

  local modified_targets = {}
  for _, target in ipairs(r_job.targets) do
    -- if the target's path is in the ignored paths
    if is_path_ignored(target.path, ignored_paths) then
      local new_target = { path = target.path, results = {} }
      -- only add lines if they are not ignored
      for _, result in ipairs(target.results) do
        if
          utils.all(utils.map(function(ln)
            return result.line_number ~= ln
          end, ignored_paths[target.path], {}))
        then
          table.insert(new_target.results, result)
        end
      end
      if #new_target.results > 0 then
        table.insert(modified_targets, new_target)
      end
    -- otherwise just add the target as-is
    else
      table.insert(modified_targets, target)
    end
  end
  local new_job = ReplaceJob.new(r_job.sed_patterns, modified_targets)
  return new_job
end

return M
