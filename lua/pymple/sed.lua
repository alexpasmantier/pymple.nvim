M = {}

local Job = require("plenary.job")

---@param rg_job_results table: The results of the rg job
---@param sed_args table: The arguments to pass to sed
function M.global_sed(rg_job_results, sed_args)
  local file_paths = {}
  for _, line in ipairs(rg_job_results) do
    local t = vim.json.decode(line)
    if t.type == "match" then
      table.insert(file_paths, t.data.path.text)
    end
  end
  if #file_paths == 0 then
    return
  end
  Job:new({
    command = "zsh",
    args = {
      "-c",
      "sed -i '' " .. table.concat(sed_args, " ") .. " " .. table.concat(file_paths, " "),
    },
  }):start()
end

local MATCH = "match"

---@param rg_job_results table: The results of the rg job
---@param sed_args table: The arguments to pass to sed
function M.ranged_sed(rg_job_results, sed_args)
  local matches = {}
  for _, line in ipairs(rg_job_results) do
    local t = vim.json.decode(line)
    if t.type == MATCH then
      local additional_line_count = select(2, t.data.lines.text:gsub("\n", "")) - 1
      table.insert(
        matches,
        { path = t.data.path.text, lines = { t.data.line_number, t.data.line_number + additional_line_count } }
      )
    end
  end
  if #matches == 0 then
    return
  end
  for _, match in ipairs(matches) do
    Job
      :new({
        command = "zsh",
        args = {
          "-c",
          "sed -i '' "
            .. string.format(table.concat(sed_args, " "), match.lines[1], match.lines[2])
            .. " "
            .. match.path,
        },
      })
      :start()
  end
end

return M
