local M = {}

function M.setup(_) end

return setmetatable(M, {
  __index = function(_, k)
    return require("pymple.api")[k]
  end,
})
