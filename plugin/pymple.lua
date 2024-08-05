local utils = require("pymple.utils")

local function handle_error(err)
  -- Extract the actual error message without the traceback
  local error_message = err:match(":%d+: (.+)")
  utils.print_err(error_message)
end

local required_binaries = {
  {
    name = "sed",
    binary = "sed",
    help = "https://www.gnu.org/software/sed/manual/sed.html",
  },
  {
    name = "gg",
    binary = "gg",
    help = "https://github.com/alexpasmantier/grip-grab",
    min_version = "0.2.20",
  },
}

for _, binary in ipairs(required_binaries) do
  local installed, version = utils.check_binary_installed(binary.binary)

  if not installed then
    utils.print_err(
      "Binary "
        .. binary.name
        .. " is not installed. Please install it to use pymple.nvim. For more information, see "
        .. binary.help
    )
  end

  -- TODO: finish this
  if installed and version then
    print("Found " .. binary.name .. " version: " .. version)
  end
end

local required_plugins = {
  {
    name = "nvim-treesitter",
    help = "https://github.com/nvim-treesitter/nvim-treesitter",
  },
  {
    name = "telescope",
    help = "https://github.com/nvim-telescope/telescope.nvim",
  },
  {
    name = "plenary",
    help = "https://github.com/nvim-lua/plenary.nvim",
  },
}

for _, plugin in ipairs(required_plugins) do
  if not utils.check_plugin_installed(plugin.name) then
    utils.print_err(
      "Plugin "
        .. plugin.name
        .. " is not installed. Please install it to use pymple.nvim. For more information, see "
        .. plugin.help
    )
  end
end
