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
  add_import_for_symbol_under_cursor = {
    keys = "<leader>li",
    desc = "Resolve import under cursor",
  },
}

---@alias UserCommandOptions {update_imports: boolean, add_import_for_symbol_under_cursor: boolean}

---@type UserCommandOptions
local default_user_command_options = {
  update_imports = true,
  add_import_for_symbol_under_cursor = true,
}

---@alias UpdateImportsOptions { filetypes: string[]}

---@type UpdateImportsOptions
local default_update_imports_options = {
  filetypes = { "python", "markdown" },
}

---@alias Config { keymaps: Keymaps, create_user_commands: UserCommandOptions, update_imports: UpdateImportsOptions }

---@type Config
M.default_config = {
  keymaps = default_keymaps,
  create_user_commands = default_user_command_options,
  update_imports = default_update_imports_options,
}

return M
