-- largely inspired by tjdevries/vlog.nvim

local modes = {
  { name = "trace", hl = "Comment" },
  { name = "debug", hl = "Comment" },
  { name = "info", hl = "@string" },
  { name = "warn", hl = "WarningMsg" },
  { name = "error", hl = "ErrorMsg" },
  { name = "fatal", hl = "ErrorMsg" },
}
local FLOAT_PRECISION = 0.01
local PLUGIN_NAME = "pymple.nvim"

local log = {}
log.off_config = {
  use_console = false,
  use_file = false,
}
-- turns log.* into a no-op until instantiated (instead of an error)
setmetatable(log, {
  __index = function(_, k)
    return function(_) end
  end,
})

local unpack = unpack or table.unpack

---@param logfile string: The path to the logfile
---@param max_lines number: The maximum number of lines to keep in the logfile
local function maybe_trim_logfile(logfile, max_lines)
  -- check if the logfile exists
  if vim.fn.filereadable(logfile) == 0 then
    P("Logfile does not exist")
    return
  end
  local handle = assert(io.popen("wc -l " .. logfile))
  local num_lines = handle:read("*a")
  handle:close()

  num_lines = tonumber(string.match(num_lines, "%d+"))
  if num_lines > max_lines then
    local lines_to_delete = num_lines - max_lines
    os.execute(string.format("sed -i '1,%dd' %s", lines_to_delete, logfile))
  end
end

---@param config LoggingOptions: The configuration for the logger
log.new = function(config, standalone)
  local outfile = config.file.path
    or string.format(
      "%s/%s.vlog",
      vim.api.nvim_call_function("stdpath", { "data" }),
      PLUGIN_NAME
    )

  if config.file.enabled then
    maybe_trim_logfile(outfile, config.file.max_lines)
  end

  local obj
  if standalone then
    obj = log
  else
    obj = {}
  end

  local levels = {}
  for i, v in ipairs(modes) do
    levels[v.name] = i
  end

  local round = function(x, increment)
    increment = increment or 1
    x = x / increment
    return (x > 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)) * increment
  end

  local make_string = function(...)
    local t = {}
    for i = 1, select("#", ...) do
      local x = select(i, ...)

      if type(x) == "number" and FLOAT_PRECISION then
        x = tostring(round(x, FLOAT_PRECISION))
      elseif type(x) == "table" then
        x = vim.inspect(x)
      else
        x = tostring(x)
      end

      t[#t + 1] = x
    end
    return table.concat(t, " ")
  end

  local log_at_level = function(level, level_config, message_maker, ...)
    -- Return early if we're below the config.level
    if level < levels[config.level] then
      return
    end
    local nameupper = level_config.name:upper()

    local msg = message_maker(...)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    if config.console.enabled then
      local console_string = string.format(
        "[%-6s%s] %s: %s",
        nameupper,
        os.date("%H:%M:%S"),
        lineinfo,
        msg
      )

      if level_config.hl then
        vim.cmd(string.format("echohl %s", level_config.hl))
      end

      local split_console = vim.split(console_string, "\n")
      for _, v in ipairs(split_console) do
        vim.cmd(
          string.format([[echom "[%s] %s"]], PLUGIN_NAME, vim.fn.escape(v, '"'))
        )
      end

      if level_config.hl then
        vim.cmd("echohl NONE")
      end
    end

    -- Output to log file
    if config.file.enabled then
      local fp = io.open(outfile, "a")
      local str =
        string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, msg)
      fp:write(str)
      fp:close()
    end
  end

  for i, x in ipairs(modes) do
    obj[x.name] = function(...)
      return log_at_level(i, x, make_string, ...)
    end

    obj[("fmt_%s"):format(x.name)] = function()
      return log_at_level(i, x, function(...)
        local passed = { ... }
        local fmt = table.remove(passed, 1)
        local inspected = {}
        for _, v in ipairs(passed) do
          table.insert(inspected, vim.inspect(v))
        end
        return string.format(fmt, unpack(inspected))
      end)
    end
  end
end

-- }}}

return log
