local M = {}

local resolve_imports = require("pymple.resolve_imports")
local update_imports = require("pymple.update_imports")

---Resolves import for symbol under cursor.
---This will automatically find and add the corresponding import to the top of
---the file (below any existing doctsring)
M.resolve_import = function()
  resolve_imports.resolve_python_import()
end

---Update all imports in workspace after renaming `source` to `destination`
---@param source string: The path to the source file/dir (before renaming/moving)
---@param destination string: The path to the destination file/dir (after renaming/moving)
M.update_imports = function(source, destination)
  P("update imports")
  update_imports.update_imports(source, destination)
end

return M
