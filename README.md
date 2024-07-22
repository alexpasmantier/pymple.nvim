# 🖍️ pymple.nvim
All your missing Python IDE features for Neovim.

## ⚡️ Requirements
- the [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) lua package
- the [grip-grab](https://github.com/alexpasmantier/grip-grab) rust search utility (>= 0.2.5)
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
- [x] Automatically refactor workspace imports on file move/rename
- [x] Code action-like bindable user command to automatically add missing import for symbol under cursor

## ⚙️ Configuration
The configuration is currently quite limited, but you can change the following options:
```lua
config = {
  -- automatically register the following keymaps on plugin setup
  keymaps = {
    resolve_import = {  -- resolve import under cursor when pressing <leader>li
      keys = "<leader>li",  -- feel free to change this to whatever you like
      desc = "Resolve import under cursor" 
    },
  },
  -- automatically create the following user commands on plugin setup
  create_user_commands = {
    update_imports = true,  -- update all workspace imports after moving/renaming a file
                            -- this takes two arguments (old_path, new_path)
                            -- and can be called as ":UpdatePythonImports old_path new_path"
    resolve_imports = true, -- resolve import for symbol under cursor and add it to the top
                            -- of the current buffer. 
                            -- This will usually be hooked up by pymple on setup to your file 
                            -- explorer's events and get triggered automatically when you move
                            -- or rename a file or a folder.
  },
}
```

## 🚀 Usage
TODO

## 🆘 Help
If something's not working as expected, please start by running `checkhealth` inside neovim:
```vim
:checkhealth pymple
```


If that doesn't help, feel free to open an issue.
