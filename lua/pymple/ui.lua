local M = {}

local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event

function M.get_confirmation_dialog(number_of_files, on_close, on_submit)
  on_close = on_close or function() end
  on_submit = on_submit or function() end
  local menu = Menu({
    relative = "editor",
    position = "50%",
    size = {
      width = 40,
      height = 3,
    },
    border = {
      style = "rounded",
      text = {
        top = string.format("Update imports in %s files?", number_of_files),
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    lines = {
      Menu.item("Yes"),
      Menu.item("No"),
      Menu.item("Preview changes"),
    },
    max_width = 30,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "q", "<C-c>" },
      submit = { "<CR>", "<Space>" },
    },
    on_close = function()
      on_close()
    end,
    on_submit = function(item)
      on_submit(item)
    end,
  })
  return menu
end

-- local menu = get_confirmation_dialog(10)
-- -- mount the component
-- menu:mount()

return M
