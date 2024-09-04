local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info
local utils = require("pymple.utils")

local M = {}
-- local is_win = vim.api.nvim_call_function("has", { "win32" }) == 1

---@class RequiredBinary
---@field name string
---@field url string
---@field optional boolean
---@field binaries string[]
---@field min_version string | nil
---@field max_version string | nil

---@type RequiredBinary[]
local required_binaries = {
  {
    name = "gg",
    url = "[alexpasmantier/grip-grab](https://github.com/alexpasmantier/grip-grab)",
    optional = false,
    binaries = { "gg" },
    min_version = "0.2.23",
  },
  {
    name = "sed",
    url = "[https://www.gnu.org/software/sed](https://www.gnu.org/software/sed/manual/sed.html)",
    optional = false,
    binaries = { linux = "sed", darwin = "gsed" },
  },
}

M.required_binaries = required_binaries

local required_plugins = {
  { lib = "plenary", optional = false },
  -- nui doesn't have any top level init.lua
  { lib = "nui.object", optional = false },
  { lib = "nvim-web-devicons", optional = true },
  { lib = "dressing", optional = true },
  { lib = "telescope", optional = true },
}

M.required_plugins = required_plugins

local check_binary_installed = function(p)
  local binaries = p.binaries
  local os_name = string.lower(vim.loop.os_uname().sysname)
  if binaries[os_name] then
    binaries = { binaries[os_name] }
  end
  for _, binary in pairs(binaries) do
    local found = vim.fn.executable(binary) == 1
    -- if not found and is_win then
    --   binary = binary .. ".exe"
    --   found = vim.fn.executable(binary) == 1
    -- end
    if found then
      local handle = io.popen(binary .. " --version")
      local binary_version_output = handle:read("*a")
      local binary_version = binary_version_output:match("%d+%.?%d*%.?%d*")
      handle:close()
      return true, binary_version
    end
  end
  return false
end

M.check_binary_installed = check_binary_installed

local function lualib_installed(lib_name)
  local res, _ = pcall(require, lib_name)
  return res
end

local function compare_versions(version1, version2)
  local version1_parts = utils.split_string(version1, ".")
  local version2_parts = utils.split_string(version2, ".")
  for i, part in ipairs(version1_parts) do
    local part_num = tonumber(part)
    local other_part = tonumber(version2_parts[i]) or 0
    if part_num > other_part then
      return 1
    elseif part_num < other_part then
      return -1
    end
  end
  return 0
end

---@param version string
---@param min_version string
---@param max_version string
local function version_satisfies_constraint(version, min_version, max_version)
  if not min_version and not max_version then
    return true
  else
    min_version = min_version or "0"
    max_version = max_version or "9999"
    return compare_versions(version, min_version) >= 0
      and compare_versions(version, max_version) <= 0
  end
end

M.version_satisfies_constraint = version_satisfies_constraint

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

  for _, req_bin in pairs(required_binaries) do
    local installed, version = check_binary_installed(req_bin)
    if not installed then
      local err_msg = ("%s: not found."):format(req_bin.name)
      if req_bin.optional then
        warn(
          ("%s %s"):format(
            err_msg,
            ("Install %s for extended capabilities"):format(req_bin.url)
          )
        )
      else
        error(
          ("%s %s"):format(
            err_msg,
            ("pymple.nvim will not work without %s installed."):format(
              req_bin.url
            )
          )
        )
      end
    else
      version = version or "(unknown version)"
      if
        (req_bin.min_version or req_bin.max_version)
        and version ~= "(unknown version)"
        and not version_satisfies_constraint(
          version,
          req_bin.min_version,
          req_bin.max_version
        )
      then
        error(
          ("%s: installed version %s is too old."):format(req_bin.name, version)
        )
      else
        ok(("%s: found %s"):format(req_bin.name, version))
      end
    end
  end
end

return M
