local docgen = require("docgen")

local docs = {}

local OUTPUT_FILE = "./doc/pymple.txt"

docs.test = function()
  -- Filepaths that should generate docs
  local input_files = {
    "./lua/pymple/init.lua",
    "./lua/pymple/config.lua",
    "./lua/pymple/api.lua",
    "./lua/pymple/jobs.lua",
  }

  -- Maybe sort them that depends what you want and need
  -- table.sort(input_files, function(a, b)
  --   return #a < #b
  -- end)

  -- Output file
  local output_file_handle = io.open(OUTPUT_FILE, "w")

  output_file_handle:write("*pymple.nvim*    pymple.nvim Help File")

  for _, input_file in ipairs(input_files) do
    docgen.write(input_file, output_file_handle)
  end

  output_file_handle:write(" vim:tw=78:ts=8:ft=help:norl:\n")
  output_file_handle:close()
  vim.cmd([[checktime]])
end

docs.test()

return docs
