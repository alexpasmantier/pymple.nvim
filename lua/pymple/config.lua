M = {}

---@type table<string, string>
M.HL_GROUPS = {
  Error = "ErrorMsg",
  Warning = "WarningMsg",
  More = "MoreMsg",
  Mode = "ModeMsg",
}

---@alias Keymaps { resolve_import_under_cursor: {keys: string, desc: string} }

---@type Keymaps
local default_keymaps = {
  resolve_import = { keys = "<leader>li", desc = "Resolve import under cursor" },
}

---@alias UserCommandOptions {update_imports: boolean, resolve_imports: boolean}

---@type UserCommandOptions
local default_user_command_options = {
  update_imports = true,
  resolve_imports = true,
}

---@alias Config { keymaps: Keymaps, create_user_commands: UserCommandOptions }

---@type Config
M.default_config = {
  keymaps = default_keymaps,
  create_user_commands = default_user_command_options,
}

return M
