# 🖍️ pymple.nvim
All your missing Python IDE features for Neovim (WIP 🤓).

## ⚡️ Requirements
- the [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) lua package
- the [grip-grab](https://github.com/alexpasmantier/grip-grab) rust search utility (>= 0.2.19)
- a working version of [sed](https://www.gnu.org/software/sed/)

## 📦 Installation
### Using Lazy
```lua
return {
  {
    "alexpasmantier/pymple.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("pymple").setup()
    end,
  },
}
```
### Using Packer
```lua
use {
  "alexpasmantier/pymple.nvim",
  requires = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("pymple").setup()
  end,
}
```

## ✨ Current features
This plugin attempts to provide missing utilities when working with Python
inside Neovim.

The following features are currently available:
- ✅ Automatically refactoring of workspace imports on python file/dir move/rename
- ✅ Automatically add missing import for symbol under cursor with a keymap (searches in workspace and installed packages)
- 👷 shortcuts to create usual python files (`tests`, `__init__`, etc.) from your favorite file explorer
- 👷 automatic and configurable creation of test files that mirror your project
  structure


## ⚙️ Configuration
Configuring the plugin is pretty straightforward at the moment.
You can decide whether to create user commands or not, how to setup different keymaps,
which filetypes to update imports for, and whether or not to activate logging.

The default configuration is as follows:

```lua
config = {
  -- automatically register the following keymaps on plugin setup
  keymaps = {
    -- Resolves import for symbol under cursor.
    -- This will automatically find and add the corresponding import to
    -- the top of the file (below any existing doctsring)
    add_import_for_symbol_under_cursor = {
      keys = "<leader>li", -- feel free to change this to whatever you like
      desc = "Resolve import under cursor", -- description for the keymap
    },
  },
  -- automatically create the following user commands on plugin setup
  create_user_commands = {
    -- Update all workspace imports after moving/renaming a file.
    -- This takes two arguments (old_path, new_path)
    -- and can be called as ":UpdatePythonImports old_path new_path"
    update_imports = true,
    -- Resolve import for symbol under cursor and add it to the top
    -- of the current buffer.
    -- This will usually be hooked up by pymple on setup to your file
    -- explorer's events and get triggered automatically when you move
    -- or rename a file or a folder.
    add_import_for_symbol_under_cursor = true,
  },
  -- options for the update imports feature
  update_imports = {
    -- the filetypes on which to run the update imports command
    -- NOTE: this should at least include "python" for the plugin to
    -- actually do anything useful
    filetypes = { "python", "markdown" },
  },
  -- logging options
  logging = {
    -- whether to enable logging
    enabled = false,
    -- whether to log to a file (default location is nvim's
    -- stdpath("data")/pymple.vlog which is usually
    -- `~/.local/share/nvim/pymple.vlog` on unix systems)
    use_file = false,
    -- whether to log to the neovim console (only use this for debugging
    -- as it might quickly ruin your neovim experience)
    use_console = false,
    -- the log level to use
    -- (one of "trace", "debug", "info", "warn", "error", "fatal")
    level = "debug",
  },
  -- python options
  python = {
  -- the names of virtual environment folders to look out for
  virtual_env_names = { ".venv" },
  },
}
```


## 🚀 Usage
TODO

## 🆘 Help
If something's not working as expected, please start by running `checkhealth` inside of neovim:
```vim
:checkhealth pymple
```
<img width="846" alt="Screenshot 2024-07-22 at 13 20 27" src="https://github.com/user-attachments/assets/e9c32971-d679-437d-9d08-114b349569ff">


If that doesn't help, try activating logging and checking the logs for any errors:
```lua
require("pymple").setup({
  logging = {
    enabled = true,
    use_file = true,
    level = "debug",
  },
})
```
If you're running a regular unix system, you'll most likely find the logs in `~/.local/share/nvim/pymple.vlog`.

*NOTE*: if you have trouble filtering through the logs, or if you just like colors, maybe [this](https://github.com/alexpasmantier/tree-sitter-vlog) might interest you.






If that doesn't help, feel free to open an issue.
