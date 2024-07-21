local utils = require("pymple.utils")

local function handle_error(err)
  -- Extract the actual error message without traceback
  local error_message = err:match(":%d+: (.+)")
  vim.api.nvim_echo({ { error_message or err, "ErrorMsg" } }, true, {})
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
  },
}

for _, binary in ipairs(required_binaries) do
  if not utils.check_binary_installed(binary.binary) then
    handle_error(
      "[pymple.nvim]: Binary "
        .. binary.name
        .. " is not installed. Please install it to use pymple.nvim.\nFor more information, see "
        .. binary.help
    )
  end
end
