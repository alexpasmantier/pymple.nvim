local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local cwd = vim.fn.getcwd()
local Path = require("plenary.path")
local utils = require("pymple.utils")

local M = {}

function M.preview_files(changed_files, gg_results, rjobs)
  local relative_files = utils.make_files_relative(changed_files)
  local preview = pickers
    .new({}, {
      prompt_title = "Preview Impacted File",
      finder = finders.new_table({
        results = relative_files,
        entry_maker = function(line)
          return make_entry.set_default_entry_mt({
            ordinal = line,
            display = line,
            filename = line,
          }, {})
        end,
      }),
      previewer = previewers.cat.new({}),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        local picker = action_state.get_current_picker(prompt_bufnr)
        map("i", "<CR>", function()
          actions.close(prompt_bufnr)
          actions.select_default:replace(function()
            local selected_entries = {}
            for _, entry in ipairs(picker:get_multi_selection()) do
              table.insert(selected_entries, entry)
            end
            if #selected_entries == 0 then
              return
            end
            local selected_gg_results = {}
            -- FIXME: this doesn't seem to be doing anything
            P(selected_entries)
            for _, result in ipairs(gg_results) do
              if vim.tbl_contains(selected_entries, result.path) then
                table.insert(selected_gg_results, result)
              end
            end
            for _, rjob in ipairs(rjobs) do
              rjob(selected_gg_results)
            end
          end)
          return true
        end)
        return true
      end,
    })
    :find()
  return preview
end

return M
