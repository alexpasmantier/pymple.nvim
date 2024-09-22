local Job = require("plenary.job")
local log = require("pymple.log")
local utils = require("pymple.utils")

local M = {}

local function is_outcode_success(outcode)
  return outcode == 0 or outcode == -0
end

local JOB_TIMEOUT = 15000

local function is_cargo_installed()
  local job = Job:new({
    command = "cargo",
    args = { "--version" },
  })
  job:sync()
  return is_outcode_success(job.code)
end

local function install_cargo()
  local job = Job:new({
    command = "curl",
    args = { "-sSf", "https://sh.rustup.rs", "|", "sh", "-s", "--", "-y" },
  })
  job:sync(JOB_TIMEOUT)
  return is_outcode_success(job.code)
end

local function install_gg()
  local job = Job:new({
    command = "cargo",
    args = { "install", "grip-grab" },
  })
  -- this might take a while
  job:sync(2 * JOB_TIMEOUT)
  return is_outcode_success(job.code)
end

local function install_sed(os_name)
  local out, code = nil, nil
  if os_name == "Darwin" then
    log.debug("MacOS detected, installing gsed...")
    local job = Job:new({
      command = "brew",
      args = { "install", "gnu-sed" },
    })
    out, code = job:sync(JOB_TIMEOUT)
  elseif os_name == "Linux" then
    log.debug("MacOS detected, installing sed...")
    -- make this depend on the package manager
    local job = Job:new({
      command = "sudo",
      args = { "apt-get", "install", "sed" },
    })
    out, code = job:sync(JOB_TIMEOUT)
  end
  if is_outcode_success(code) then
    return true
  else
    log.warning(out)
    return false
  end
end

local function install_fd(os_name)
  local out, code = nil, nil
  if os_name == "Darwin" then
    log.debug("MacOS detected, installing fd...")
    local job = Job:new({
      command = "brew",
      args = { "install", "fd" },
    })
    out, code = job:sync(JOB_TIMEOUT)
  elseif os_name == "Linux" then
    log.debug("Linux detected, installing sed...")
    -- make this depend on the package manager
    local job = Job:new({
      command = "sudo",
      args = { "apt-get", "install", "fd-find" },
    })
    out, code = job:sync(JOB_TIMEOUT)
  end
  if is_outcode_success(code) then
    return true
  else
    log.warning(out)
    return false
  end
end

function M.build()
  -- check if cargo is installed
  if not is_cargo_installed() then
    -- install cargo
    utils.print_info("Installing cargo...")
    if install_cargo() then
      utils.print_info("Cargo installed successfully")
    else
      local message =
        "Failed to install cargo. Try installing it manually: https://doc.rust-lang.org/cargo/getting-started/installation.html"
      utils.print_err(message)
      return
    end
  end
  -- install gg's last version
  utils.print_info("Installing gg...")
  if install_gg() then
    utils.print_info("gg installed successfully")
  else
    local message =
      "Failed to install gg. Try installing it manually: https://crates.io/crates/grip-grab"
    utils.print_err(message)
    return
  end

  -- install sed or gsed depending on OS
  utils.print_info("Installing sed/gsed...")
  if install_sed(utils.OS_NAME) then
    utils.print_info("sed installed successfully")
  else
    local message = "Failed to install sed. Try installing it manually."
    utils.print_err(message)
    return
  end

  -- install fd depending on OS
  utils.print_info("Installing sed/gsed...")
  if install_fd(utils.OS_NAME) then
    utils.print_info("fd installed successfully")
  else
    local message = "Failed to install fd. Try installing it manually."
    utils.print_err(message)
    return
  end
end

return M
