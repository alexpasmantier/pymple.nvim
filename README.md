# 🖍️ pymple.nvim
All your missing Python IDE features for Neovim.

## ⚡️ Requirements
- the [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) lua package
- the [grip-grab](https://github.com/alexpasmantier/grip-grab) search utility (>= 0.2.5)
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
TODO

## 🚀 Usage
TODO
