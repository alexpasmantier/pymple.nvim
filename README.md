# 🔴 pymple.nvim
Pymple adds missing common Python IDE features for Neovim when dealing with imports: 
- 🦀 **automatic import updates on module/package rename**
- 🦀 **code-action-like import resolution**

## tl;dr
👉 **Automatic import updates on file/dir move/rename that currently supports `neo-tree`, `nvim-tree` and `oil.nvim`.**

### with `oil.nvim`
https://github.com/user-attachments/assets/dc294f74-c1f2-48e2-8e7f-68399b5a391b

### with `neo-tree.nvim`
https://github.com/user-attachments/assets/d10c97dc-a2cd-4a0c-8c4f-d34456362e8b


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

The following features are currently available:
- Automatic refactoring of workspace imports on python file/dir move/rename.
  - ✅ confirmation prompt
  - ✅ preview window
  - ✅ optionally ignore individual changes
  - currently supports:
    - ✅ `neo-tree`
    - ✅ `nvim-tree`
    - ✅ `oil.nvim`
- Automatic missing import resolution for symbol under cursor:
  - ✅ searches in current workspace
  - ✅ searches in virtual environments
  - ✅ searches in the python stdlib
- ✅ Automatic project root discovery for python projects
- ✅ Automatic virtual environment discovery



## 🚀 Usage
### 🦀 Import updates on file move/rename
If you're using a file explorer such as `neo-tree`, `nvim-tree` or `oil.nvim`, pymple will automatically detect it and setup the appropriate hooks.  

When you rename or move a file or directory, you'll be prompted with a confirmation window and be able to preview the pending changes while discarding the ones you don't want.

While inside the preview window, the current mappings are defined by default:

| keybinding      | action                                  |
|-----------------|-----------------------------------------|
| `<CR>`          |      Confirm and update the imports     |
| `<C-k>`         |       Move to the previous change       |
| `<C-j>`         |         Move to the next change         |
| `<C-i>` or `dd` |              Discard change             |
| `<C-c>` or `q`  | Cancel refactoring and close the window |

https://github.com/user-attachments/assets/d10c97dc-a2cd-4a0c-8c4f-d34456362e8b

If you're not using a file explorer, the current alternative would be to manually call `:PympleUpdateImports <source> <destination>` after the file rename operation which will bring up the confirmation window mentioned above.

### 🦀 Import resolution
By default, pymple will setup a keymap for this (`<leader>li`) which you can change in the configuration:
```lua
  -- automatically register the following keymaps on plugin setup
  keymaps = {
    -- Resolves import for symbol under cursor.
    -- This will automatically find and add the corresponding import to
    -- the top of the file (below any existing doctsring)
    resolve_import_under_cursor = {
      desc = "Resolve import under cursor",
      keys = "<leader>li"  -- feel free to change this to whatever you like
    }
  },
```

When inside a python buffer, with the cursor on any importable symbol, pressing the above keymap will perform the following action:
- **if the symbol resolves to a unique import candidate:** add that import to the top of the file (after eventual docstrings) and automatically save the file to run any import sorting/formatting autocommands;
- **if there are multiple candidates:** prompt the user to select the right one and perform step above;
- **if there are no candidates matching the symbol:** Print a warning message to notify the user.


https://github.com/user-attachments/assets/b1dd773e-bf1c-4d4c-9546-1b5e27d726b7


## ⚙️ Configuration
Here is the default configuration:

```lua
default_config = {
{
  -- options for the update imports feature
  update_imports = {
    -- the filetypes on which to run the update imports command
    -- NOTE: this should at least include "python" for the plugin to
    -- actually do anything useful
    filetypes = { "python", "markdown" }
  },
  -- options for the add import for symbol under cursor feature
  add_import_to_buf = {
    -- whether to autosave the buffer after adding the import (which will
    -- automatically format/sort the imports if you have on-save autocommands)
    autosave = true
  },
  -- automatically register the following keymaps on plugin setup
  keymaps = {
    -- Resolves import for symbol under cursor.
    -- This will automatically find and add the corresponding import to
    -- the top of the file (below any existing doctsring)
    resolve_import_under_cursor = {
      desc = "Resolve import under cursor",
      keys = "<leader>li"  -- feel free to change this to whatever you like
    }
  },
  -- logging options
  logging = {
    -- whether to log to the neovim console (only use this for debugging
    -- as it might quickly ruin your neovim experience)
    console = {
      enabled = false
    },
    -- whether or not to log to a file (default location is nvim's
    -- stdpath("data")/pymple.vlog which will typically be at
    -- `~/.local/share/nvim/pymple.vlog` on unix systems)
    file = {
      enabled = true,
      -- the maximum number of lines to keep in the log file (pymple will
      -- automatically manage this for you so you don't have to worry about
      -- the log file getting too big)
      max_lines = 1000,
      path = "/Users/alex/.local/share/nvim/pymple.vlog"
    },
    -- the log level to use
    -- (one of "trace", "debug", "info", "warn", "error", "fatal")
    level = "info"
  },
  -- python options
  python = {
    -- the names of root markers to look out for when discovering a project
    root_markers = { "pyproject.toml", "setup.py", ".git", "manage.py" },
    -- the names of virtual environment folders to look out for when
    -- discovering a project
    virtual_env_names = { ".venv" }
  }
}
```


## 🆘 Help
If something's not working as expected, start by running `checkhealth` inside of neovim to check all your requirements are setup correctly:
```vim
:checkhealth pymple
```
<img width="1088" alt="Screenshot 2024-08-17 at 20 09 30" src="https://github.com/user-attachments/assets/99015738-46f4-4b8d-afef-fc710b63ee8d">

The helpfiles might be of help too:
```lua
:help pymple.txt
```
<img width="713" alt="Screenshot 2024-08-21 at 21 24 44" src="https://github.com/user-attachments/assets/186d1e3a-1ed0-42d2-af95-d93e82f4bc78">

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

You can then open a buffer with the associated logs by running the following command:
```vim
:PympleLogs
```

*NOTE*: if you have trouble filtering through the logs, or if you just like colors, maybe [this](https://github.com/alexpasmantier/tree-sitter-vlog) might interest you.






If that doesn't help, feel free to open an issue.
