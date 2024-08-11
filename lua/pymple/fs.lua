local Job = require("plenary.job")
local utils = require("pymple.utils")
local log = require("pymple.log")

local M = {}

local function get_max_open_file_descriptors()
  local handle = io.popen("ulimit -n")
  local result = handle:read("*a")
  handle:close()
  return tonumber(result)
end

local max_open_file_descriptors = get_max_open_file_descriptors()
M.max_open_file_descriptors = max_open_file_descriptors

local function get_open_file_descriptors()
  local current_pid = vim.fn.getpid()
  local handle = io.popen("lsof -p " .. current_pid .. " | wc -l")
  local result = assert(handle:read("*a"))
  handle:close()
  return tonumber(result)
end

M.get_open_file_descriptors = get_open_file_descriptors

return M
