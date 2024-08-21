# 🖍️ pymple.nvim
This plugin adds missing Python IDE features for Neovim such as automatic import refactoring on module/package rename, import resolution code actions, venv selection etc.
## TL;DR
**Automatic refactoring of workspace imports on file move/rename**

https://github.com/user-attachments/assets/d10c97dc-a2cd-4a0c-8c4f-d34456362e8b

**Automatic resolution of workspace symbols**



https://github.com/user-attachments/assets/f98fe92f-8208-4a05-9063-5bb76256425b




## 📦 Installation
### Using Lazy
```lua
return {
  {
    "alexpasmantier/pymple.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      -- optional (nicer ui)
      "stevearc/dressing.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    build = ":PympleBuild",
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
    "MunifTanjim/nui.nvim",
    -- optional (nicer ui)
    "stevearc/dressing.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  run = ":PympleBuild",
  config = function()
    require("pymple").setup()
  end,
}
```

## ✨ Current features
This plugin attempts to provide missing utilities when working with Python
inside Neovim.

The following features are currently available:
- ✅ Automatic refactoring of workspace imports on python file/dir move/rename.
  - ✅ confirmation prompt
  - ✅ preview window
  - ✅ optionally ignore individual changes
  - ✅ currently supports `neo-tree` and `nvim-tree`
- ✅ Automatic missing import resolution for symbol under cursor:
  - ✅ searches in current workspace
  - ✅ searches in virtual environments
  - ✅ searches in the python stdlib
- ✅ Automatic project root discovery for python projects
- 👷 Automatic virtual environment discovery and activation for python projects (+ manual selection feature)
- 👷 Run tests for the current file
- 👷 Automatic and configurable creation of test files that mirror your project
  structure
- 👷 Additional functions to create usual python directory structures (auto `__init__`, etc.) from your favorite file explorer


## ⚙️ Configuration
Here is the default configuration:

```lua
default_config = {
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
  -- options for the update imports feature
  update_imports = {
    -- the filetypes on which to run the update imports command
    -- NOTE: this should at least include "python" for the plugin to
    -- actually do anything useful
    filetypes = { "python", "markdown" },
  },
  -- options for the add import to buffer feature
  add_import_to_buf = {
    -- whether to autosave the buffer after adding the import (which will
    -- automatically format/sort the imports if you have on-save autocommands)
    autosave = true,
  },
  -- logging options
  logging = {
    -- whether or not to log to a file (default location is nvim's
    -- stdpath("data")/pymple.vlog which will typically be at
    -- `~/.local/share/nvim/pymple.vlog` on unix systems)
    file = {
      enabled = true,
      path = vim.fn.stdpath("data") .. "/pymple.vlog",
      -- the maximum number of lines to keep in the log file (pymple will
      -- automatically manage this for you so you don't have to worry about
      -- the log file getting too big)
      max_lines = 1000,
    },
    -- whether to log to the neovim console (only use this for debugging
    -- as it might quickly ruin your neovim experience)
    console = {
      enabled = false,
    },
    -- the log level to use
    -- (one of "trace", "debug", "info", "warn", "error", "fatal")
    level = "debug",
  },
  -- python options
  python = {
    -- the names of virtual environment folders to look out for when
    -- discovering a project
    virtual_env_names = { "venv", ".venv", "env", ".env", "virtualenv", ".virtualenv" },
    -- the names of root markers to look out for when discovering a project
    root_markers = { "pyproject.toml", "setup.py", ".git", "manage.py" },
  },
}
```


## 🚀 Usage
Documentation is a work in progress and this section hasn't been written yet.

In the meantime, the pymple.nvim help files might be of help:
```
:help pymple.txt
```

## 🆘 Help
If something's not working as expected, please start by running `checkhealth` inside of neovim:
```vim
:checkhealth pymple
```
<img width="1088" alt="Screenshot 2024-08-17 at 20 09 30" src="https://github.com/user-attachments/assets/99015738-46f4-4b8d-afef-fc710b63ee8d">


If that doesn't help, try activating logging and checking the logs for any errors:
```lua
require("pymple").setup({
  logging = {
    file = {
      enabled = true,
      path = vim.fn.stdpath("data") .. "/pymple.vlog",
      max_lines = 1000, -- feel free to increase this number
    },
    -- this might help in some scenarios
    console = {
      enabled = false,
    },
    level = "debug",
  },
})
```
If you're running a regular unix system, you'll most likely find the logs in `~/.local/share/nvim/pymple.vlog` .

*NOTE*: if you have trouble filtering through the logs, or if you just like colors, maybe [this](https://github.com/alexpasmantier/tree-sitter-vlog) might interest you.






If that doesn't help, feel free to open an issue.
