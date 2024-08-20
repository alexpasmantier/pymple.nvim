local Job = require("plenary.job")
local log = require("pymple.log")
local utils = require("pymple.utils")

local M = {}

function M.find_import_candidates(gg_args, sys_paths)
  local candidates = {}
  for _, sys_path in ipairs(sys_paths) do
    local gg_command = "gg " .. gg_args .. sys_path
    log.debug("GG command: " .. gg_command)
    local job = Job:new({
      command = utils.SHELL,
      args = { "-c", gg_command },
      on_exit = function(job, _)
        local results = job:result()
        if #results ~= 0 then
          for _, result in ipairs(results) do
            local path = utils.make_relative_to(result, sys_path)
            table.insert(candidates, path)
          end
        end
      end,
    })
    job:sync()
  end
  return candidates
end

return M
