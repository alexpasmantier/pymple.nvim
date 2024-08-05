local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_set = require("telescope.actions.set")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local cwd = vim.fn.getcwd()
local Path = require("plenary.path")
local utils = require("pymple.utils")

local M = {}

---@class FlattenedResult
---@field path string
---@field line_number number
---@field line string
---@field line_start number
---@field line_end number

---@param gg_results GGJsonResult[]
---@return FlattenedResult[]
local flatten_gg_results = function(gg_results)
  local results = {}
  for _, result in ipairs(gg_results) do
    for _, line in ipairs(result.results) do
      table.insert(results, {
        path = result.path,
        line_number = line.line_number,
        line = line.line,
        line_start = line.line_start,
        line_end = line.line_end,
      })
    end
  end
  return results
end

---@param flattened_result FlattenedResult
---@return GGJsonResult
local flattened_result_to_gg_result = function(flattened_result)
  return {
    path = flattened_result.path,
    results = {
      {
        line_number = flattened_result.line_number,
        line = flattened_result.line,
        line_start = flattened_result.line_start,
        line_end = flattened_result.line_end,
      },
    },
  }
end

---@param gg_results GGJsonResult[]
---@param rjobs function[]
function M.preview_files(gg_results, rjobs)
  -- local relative_files = utils.make_files_relative(changed_files)
  local flat_results = flatten_gg_results(gg_results)
  local preview = pickers
    .new({}, {
      prompt_title = "Preview Impacted File",
      finder = finders.new_table({
        results = flat_results,
        entry_maker = function(line)
          return make_entry.set_default_entry_mt({
            display = line.path .. ":" .. line.line_number,
            filename = line.path,
            ordinal = line.path,
          }, {})
        end,
      }),
      previewer = previewers.cat.new({}),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        -- FIXME: this still doesn't work
        action_set.select:replace(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local selected_entries = picker:get_multi_selection()
          local selected_gg_results =
            utils.map(flattened_result_to_gg_result, selected_entries)
          actions.close(prompt_bufnr)
          for _, rjob in ipairs(rjobs) do
            rjob(selected_gg_results)
          end
        end)
        -- map("i", "<CR>", function(bufnr)
        --   local picker = action_state.get_current_picker(bufnr)
        --   local selected_entries = picker:get_multi_selection()
        --   actions.close(bufnr)
        --
        --   local selected_gg_results =
        --     utils.map(flattened_result_to_gg_result, selected_entries)
        --   for _, rjob in ipairs(rjobs) do
        --     rjob(selected_gg_results)
        --   end
        -- end)
        return true
      end,
    })
    :find()
  return preview
end

return M
