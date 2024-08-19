local utils = require("pymple.utils")
local health = require("pymple.health")

for _, binaries in ipairs(health.required_binaries) do
  for _, p in ipairs(binaries.package) do
    local installed, version = health.check_binary_installed(p)

    if not installed then
      utils.print_err(
        "Binary "
          .. p.name
          .. " is not installed. Please install it manually to use pymple.nvim "
          .. "or run `:PympleBuild`. For more information, see "
          .. p.url
      )
    end

    if
      installed
      and version
      and version ~= "(unknown version)"
      and (p.min_version or p.max_version)
      and not health.version_satisfies_constraint(
        version,
        p.min_version,
        p.max_version
      )
    then
      utils.print_err(
        string.format(
          "Binary %s (%s) is installed, but the version is either too old or too recent (min: %s, max: %s). Please update it to use pymple.nvim. For more information, see %s",
          p.name,
          version,
          p.min_version,
          p.max_version,
          p.url
        )
      )
    end
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
