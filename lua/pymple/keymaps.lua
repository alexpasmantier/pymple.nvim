local config = require("pymple.config")

local M = {}

---Setup pymple keymaps
M.setup = function()
  for k, v in pairs(config.user_config.keymaps) do
    vim.api.nvim_set_keymap(
      "n",
      v.keys,
      "<cmd>lua require('pymple.api')." .. k .. "()<CR>",
      {
        desc = v.desc,
        noremap = true,
        silent = true,
      }
    )
  end
end

return M
