local utils = require("pymple.utils")
local health = require("pymple.health")

PYMPLE_BINARIES = {}

for _, required_binary in ipairs(health.required_binaries) do
  local installed, version = health.check_binary_installed(required_binary)

  if not installed then
    utils.print_err(
      "Binary "
        .. required_binary.name
        .. " is not installed. Please install it manually to use pymple.nvim "
        .. "or run `:PympleBuild`. For more information, see "
        .. required_binary.url
    )
  else
    PYMPLE_BINARIES[required_binary.name] = version
  end

  if
    installed
    and version
    and version ~= "(unknown version)"
    and (required_binary.min_version or required_binary.max_version)
    and not health.version_satisfies_constraint(
      version,
      required_binary.min_version,
      required_binary.max_version
    )
  then
    utils.print_err(
      string.format(
        "Binary %s (%s) is installed, but the version is either too old or too recent (min: %s, max: %s). Please update it to use pymple.nvim. For more information, see %s",
        required_binary.name,
        version,
        required_binary.min_version,
        required_binary.max_version,
        required_binary.url
      )
    )
  end
end

local required_plugins = {
  {
    name = "plenary",
    importable_name = "plenary",
    url = "https://github.com/nvim-lua/plenary.nvim",
  },
  {
    name = "nui",
    importable_name = "nui.object",
    url = "https://github.com/MunifTanjim/nui.nvim",
  },
}

for _, plugin in ipairs(required_plugins) do
  if not utils.check_plugin_installed(plugin.importable_name) then
    utils.print_err(
      "Plugin "
        .. plugin.name
        .. " is not installed. Please install it to use pymple.nvim. For more information, see "
        .. plugin.url
    )
  end
end
