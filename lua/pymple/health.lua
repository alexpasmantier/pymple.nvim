local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

local is_win = vim.api.nvim_call_function("has", { "win32" }) == 1

local optional_dependencies = {
  {
    functionality = "update_imports",
    package = {
      {
        name = "gg",
        url = "[alexpasmantier/grip-grab](https://github.com/alexpasmantier/grip-grab)",
        optional = false,
      },
    },
  },
  {
    functionality = "resolve_imports",
    package = {
      {
        name = "gg",
        url = "[alexpasmantier/grip-grab](https://github.com/alexpasmantier/grip-grab)",
        optional = false,
      },
    },
  },
  {
    functionality = "update_imports",
    package = {
      {
        name = "sed",
        url = "[https://www.gnu.org/software/sed](https://www.gnu.org/software/sed/manual/sed.html)",
        optional = false,
      },
    },
  },
}

local required_plugins = {
  { lib = "plenary", optional = false },
  { lib = "telescope", optional = false },
  { lib = "nvim-treesitter", optional = true },
  { lib = "neo-tree", optional = true },
}

local check_binary_installed = function(package)
  local binaries = package.binaries or { package.name }
  for _, binary in ipairs(binaries) do
    local found = vim.fn.executable(binary) == 1
    if not found and is_win then
      binary = binary .. ".exe"
      found = vim.fn.executable(binary) == 1
    end
    if found then
      local handle = io.popen(binary .. " --version")
      local binary_version = handle:read("*a")
      handle:close()
      return true, binary_version
    end
  end
end

local function lualib_installed(lib_name)
  local res, _ = pcall(require, lib_name)
  return res
end

local M = {}

M.check = function()
  -- Required lua libs
  start("Checking for required plugins")
  for _, plugin in ipairs(required_plugins) do
    if lualib_installed(plugin.lib) then
      ok(plugin.lib .. " installed.")
    else
      local lib_not_installed = plugin.lib .. " not found."
      if plugin.optional then
        warn(("%s %s"):format(lib_not_installed, plugin.info))
      else
        error(lib_not_installed)
      end
    end
  end

  -- external dependencies
  -- TODO: only perform checks if user has enabled dependency in their config
  start("Checking external dependencies")

  for _, opt_dep in pairs(optional_dependencies) do
    for _, package in ipairs(opt_dep.package) do
      local installed, version = check_binary_installed(package)
      if not installed then
        local err_msg = ("%s: not found."):format(package.name)
        if package.optional then
          warn(
            ("%s %s"):format(
              err_msg,
              ("Install %s for extended capabilities"):format(package.url)
            )
          )
        else
          error(
            ("%s %s"):format(
              err_msg,
              ("Functionality `%s` will not work without %s installed."):format(
                opt_dep.functionality,
                package.url
              )
            )
          )
        end
      else
        local eol = version:find("\n")
        local ver = eol and version:sub(0, eol - 1) or "(unknown version)"
        ok(("%s: found %s"):format(package.name, ver))
      end
    end
  end
end

return M
