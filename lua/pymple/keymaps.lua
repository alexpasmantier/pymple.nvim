local M = {}

---Setup pymple keymaps
---@param keymaps Keymaps
M.setup_keymaps = function(keymaps)
  for k, v in pairs(keymaps) do
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
