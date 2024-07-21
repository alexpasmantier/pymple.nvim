M = {}

local Job = require("plenary.job")
local utils = require("pymple.utils")
local config = require("pymple.config")

---@alias gg_json_search_result {line_number: number, line: string}
---@alias gg_json_search_results gg_json_search_result[]
---@alias gg_json_result {path: string, results: gg_json_search_results}
---@alias gg_json_results gg_json_result[]

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
  Job:new({
    command = "zsh",
    args = {
      "-c",
      "sed -i '' " .. table.concat(sed_args, " ") .. " " .. table.concat(
        file_paths,
        " "
      ),
    },
  }):start()
end

---@param gg_job_results gg_json_results: The results of the gg job
---@param sed_args table: The arguments to pass to sed
local function ranged_sed(gg_job_results, sed_args)
  local matches = {}
  for _, file_result in ipairs(gg_job_results) do
    for _, search_result in ipairs(file_result.results) do
      -- gsub returns the number of replaced occurences as a second element
      local additional_line_count = select(2, search_result.line:gsub("\n", ""))
        - 1
      table.insert(matches, {
        path = file_result.path,
        lines = {
          search_result.line_number,
          search_result.line_number + additional_line_count,
        },
      })
    end
  end
  if #matches == 0 then
    return
  end
  for _, match in ipairs(matches) do
    Job:new({
      command = utils.SHELL,
      args = {
        "-c",
        "sed -i '' " .. string.format(
          table.concat(sed_args, " "),
          match.lines[1],
          match.lines[2]
        ) .. " " .. match.path,
      },
    }):start()
  end
end

---@param gg_args table: The arguments to pass to gg
---@param sed_args table: The arguments to pass to sed
---@param range boolean: Whether or not to call sed with a range specifier
function M.gg_into_sed(gg_args, sed_args, range)
  Job:new({
    command = utils.SHELL,
    args = { "-c", "gg " .. table.concat(gg_args, " ") },
    on_exit = function(job, _)
      local gg_results = {}
      for _, file_result in ipairs(job:result()) do
        local t = vim.json.decode(file_result)
        table.insert(gg_results, t)
      end
      if range then
        ranged_sed(gg_results, sed_args)
      else
        global_sed(gg_results, sed_args)
      end
    end,
  }):start()
end

---Searches for a definition of a given symbol and automatically adds the import
---to the top of the current buffer
---@param symbol string: the symbol for which to resolve an import
---@param opts {command_args: string[]}
function M.resolve_import(symbol, opts)
  Job
    :new({
      command = utils.SHELL,
      args = { "-c", "gg " .. table.concat(opts.command_args, " ") },
      on_exit = function(job, _)
        local results = job:result()
        if #results == 0 then
          vim.schedule(function()
            vim.api.nvim_echo({
              {
                "No results found in current workdir",
                config.HL_GROUPS.Error,
              },
            }, false, {})
          end)
          return
        elseif #results == 1 then
          vim.schedule(function()
            local path = string.gsub(results[1], "^%./", "")
            local import_path = utils.to_import_path(path)
            utils.add_import_to_current_buf(
              utils.to_import_path(import_path),
              symbol
            )
          end)
          return
        end
        local potential_imports = {}
        for _, line in ipairs(results) do
          local path = string.gsub(line, "^%./", "")
          local import_path = utils.to_import_path(path)
          table.insert(potential_imports, import_path)
        end
        -- sort imports by length
        table.sort(potential_imports, function(a, b)
          return #a < #b
        end)

        local message = {}
        for i, import_path in ipairs(potential_imports) do
          table.insert(message, string.format("%s: ", i) .. import_path)
        end
        vim.schedule(function()
          local user_input =
            vim.fn.input(table.concat(message, "\n") .. "\nSelect an import: ")
          local chosen_import = potential_imports[tonumber(user_input)]
          if chosen_import then
            utils.add_import_to_current_buf(chosen_import, symbol)
          else
            vim.api.nvim_echo(
              { { "Invalid selection", config.HL_GROUPS.Error } },
              false,
              {}
            )
          end
        end)
      end,
    })
    :start()
end

return M
