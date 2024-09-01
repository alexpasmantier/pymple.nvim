local log = require("pymple.log")
local utils = require("pymple.utils")

local M = {}

function M.find_import_candidates(gg_args, sys_paths)
  local candidates = {}
  for _, sys_path in ipairs(sys_paths) do
    local gg_command = "gg " .. gg_args .. sys_path
    log.debug("GG command: " .. gg_command)

    local job = vim.system({ utils.SHELL, "-c", gg_command }):wait()
    local result_lines = vim.split(job.stdout, "\n")
    for i, line in ipairs(result_lines) do
      if line == "" then
        table.remove(result_lines, i)
      end
    end
    if #result_lines ~= 0 then
      for _, line in ipairs(result_lines) do
        local path = utils.make_relative_to(line, sys_path)
        table.insert(candidates, path)
      end
    end
  end
  return candidates
end

return M
