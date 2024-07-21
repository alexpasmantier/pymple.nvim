vim.api.nvim_create_user_command("UpdatePythonImports", function(opts)
  require("pymple.api").update_imports(opts.fargs[1], opts.fargs[2])
end, {
  nargs = 2,
  desc = "Update all imports in workspace after renaming `source` to `destination`",
})

vim.api.nvim_create_user_command("ResolvePythonImportUnderCursor", function(_)
  require("pymple.api").resolve_import()
end, {
  nargs = 0,
  desc = "Resolves import for symbol under cursor",
})
