---@tag pymple.config
---@brief [[
--- The default configuration is as follows:
---
--- <pre>
--- ```lua
--- default_config = {
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
---   -- options for the update imports feature
---   update_imports = {
---     -- the filetypes on which to run the update imports command
---     -- NOTE: this should at least include "python" for the plugin to
---     -- actually do anything useful
---     filetypes = { "python", "markdown" },
---   },
---   -- options for the add import to buffer feature
---   add_import_to_buf = {
---     -- whether to autosave the buffer after adding the import (which will
---     -- automatically format/sort the imports if you have on-save autocommands)
---     autosave = true,
---   },
---   -- logging options
---   logging = {
---     -- whether or not to log to a file (default location is nvim's
---     -- stdpath("data")/pymple.vlog which will typically be at
---     -- `~/.local/share/nvim/pymple.vlog` on unix systems)
---     file = {
---       enabled = true,
---       path = vim.fn.stdpath("data") .. "/pymple.vlog",
---       -- the maximum number of lines to keep in the log file (pymple will
---       -- automatically manage this for you so you don't have to worry about
---       -- the log file getting too big)
---       max_lines = 1000,
---     },
---     -- whether to log to the neovim console (only use this for debugging
---     -- as it might quickly ruin your neovim experience)
---     console = {
---       enabled = false,
---     },
---     -- the log level to use
---     -- (one of "trace", "debug", "info", "warn", "error", "fatal")
---     level = "debug",
---   },
---   -- python options
---   python = {
---     -- the names of virtual environment folders to look out for when
---     -- discovering a project
---     virtual_env_names = { "venv", ".venv", "env", ".env", "virtualenv", ".virtualenv" },
---     -- the names of root markers to look out for when discovering a project
---     root_markers = { "pyproject.toml", "setup.py", ".git", "manage.py" },
---   },
--- }
--- ```
--- </pre>
---@brief ]]

local utils = require("pymple.utils")

---@class config
---@field user_config Config
---@field HL_GROUPS HlGroups
---@field default_config Config
---@field validate_configuration fun(): boolean
---@field set_user_config fun(opts: Config): Config
M = {}

---@class HlGroups
---@field Error string
---@field Warning string
---@field More string
---@field Mode string

---@type HlGroups
M.HL_GROUPS = {
  Error = "ErrorMsg",
  Warning = "WarningMsg",
  More = "MoreMsg",
  Mode = "ModeMsg",
}

---@class Keymaps
---@field add_import_for_symbol_under_cursor {keys: string, desc: string}

---@type Keymaps
local default_keymaps = {
  add_import_for_symbol_under_cursor = {
    keys = "<leader>li",
    desc = "Resolve import under cursor",
  },
}

---@class UpdateImportsOptions
---@field filetypes string[]

---@type UpdateImportsOptions
local default_update_imports_options = {
  filetypes = { "python", "markdown" },
}

---@class AddImportToBufOptions
---@field autosave boolean

---@type AddImportToBufOptions
local default_add_import_to_buf_options = {
  autosave = true,
}

---@class LoggingOptions
---@field file {enabled: boolean, path: string, max_lines: number}
---@field console {enabled: boolean}
---@field level "trace"|"debug"|"info"|"warn"|"error"|"fatal"

---@type LoggingOptions
local default_logging_options = {
  file = {
    enabled = true,
    path = vim.fn.stdpath("data") .. "/pymple.vlog",
    max_lines = 1000,
  },
  console = {
    enabled = false,
  },
  level = "info",
}

---@class PythonOptions
---@field virtual_env_names string[]
---@field root_markers string[]

---@type PythonOptions
local default_python_options = {
  virtual_env_names = { ".venv" },
  root_markers = { "pyproject.toml", "setup.py", ".git", "manage.py" },
}

---@class Config
---@field keymaps Keymaps
---@field update_imports UpdateImportsOptions
---@field add_import_to_buf AddImportToBufOptions
---@field logging LoggingOptions
---@field python PythonOptions

---@type Config
local default_config = {
  keymaps = default_keymaps,
  update_imports = default_update_imports_options,
  add_import_to_buf = default_add_import_to_buf_options,
  logging = default_logging_options,
  python = default_python_options,
}

---@type Config
M.default_config = default_config

---@param opts Config
function M:set_user_config(opts)
  self.user_config = vim.tbl_deep_extend("force", self.default_config, opts)
end

---@return boolean
function M:validate_configuration()
  if
    not vim.tbl_contains(self.user_config.update_imports.filetypes, "python")
  then
    utils.print_err(
      "Your configuration is invalid: `update_imports.filetypes` must at least contain the value `python`."
    )
    return false
  end
  return true
end

return M
