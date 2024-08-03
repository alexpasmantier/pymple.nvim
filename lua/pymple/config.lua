---@tag pymple.config
---@brief [[
--- Plugin configuration
--- Configuring the plugin is pretty straightforward at the moment.
--- You can decide whether to create user commands or not, how to setup different keymaps,
--- which filetypes to update imports for, and whether or not to activate logging.
---
--- The default configuration is as follows:
---
--- <pre>
--- ```lua
--- config = {
---   -- automatically register the following keymaps on plugin setup
---   keymaps = {
---     -- Resolves import for symbol under cursor.
---     -- This will automatically find and add the corresponding import to
---     -- the top of the file (below any existing doctsring)
---     add_import_for_symbol_under_cursor = {
---       keys = "<leader>li", -- feel free to change this to whatever you like
---       desc = "Resolve import under cursor", -- description for the keymap
---     },
---   },
---   -- automatically create the following user commands on plugin setup
---   create_user_commands = {
---     -- Update all workspace imports after moving/renaming a file.
---     -- This takes two arguments (old_path, new_path)
---     -- and can be called as ":UpdatePythonImports old_path new_path"
---     update_imports = true,
---     -- Resolve import for symbol under cursor and add it to the top
---     -- of the current buffer.
---     -- This will usually be hooked up by pymple on setup to your file
---     -- explorer's events and get triggered automatically when you move
---     -- or rename a file or a folder.
---     add_import_for_symbol_under_cursor = true,
---   },
---   -- options for the update imports feature
---   update_imports = {
---     -- the filetypes on which to run the update imports command
---     -- NOTE: this should at least include "python" for the plugin to
---     -- actually do anything useful
---     filetypes = { "python", "markdown" },
---   },
---   -- logging options
---   logging = {
---     -- whether to enable logging
---     enabled = false,
---     -- whether to log to a file (default location is nvim's
---     -- stdpath("data")/pymple.vlog which is usually
---     -- `~/.local/share/nvim/pymple.vlog` on unix systems)
---     use_file = false,
---     -- whether to log to the neovim console (only use this for debugging
---     -- as it might quickly ruin your neovim experience)
---     use_console = false,
---     -- the log level to use
---     -- (one of "trace", "debug", "info", "warn", "error", "fatal")
---     level = "debug",
---   },
---   -- python options
---   python = {
---   -- the names of virtual environment folders to look out for
---   virtual_env_names = { ".venv" },
---   },
--- }
--- ```
--- </pre>
---@brief ]]
M = {}

---@alias HlGroups { Error: string, Warning: string, More: string, Mode: string }

---@type HlGroups
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

---@alias LoggingOptions { enabled: boolean, use_file: boolean, use_console: boolean, level: "trace" | "debug" | "info" | "warn" | "error" | "fatal" }

---@type LoggingOptions
local default_logging_options = {
  enabled = false,
  use_file = false,
  use_console = false,
  level = "debug",
}

---@alias PythonOptions { virtual_env_names: string[] }

---@type PythonOptions
local default_python_options = {
  virtual_env_names = { ".venv" },
}

---@alias Config { keymaps: Keymaps, create_user_commands: UserCommandOptions, update_imports: UpdateImportsOptions, logging: LoggingOptions, python: PythonOptions}

local default_config = {
  keymaps = default_keymaps,
  create_user_commands = default_user_command_options,
  update_imports = default_update_imports_options,
  logging = default_logging_options,
  python = default_python_options,
}

---@type Config
M.default_config = default_config

---@param opts Config
function M.set_config(opts)
  M.config = vim.tbl_deep_extend("force", default_config, opts)
end

M.set_config(M.default_config)

return M
