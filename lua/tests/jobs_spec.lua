local jobs = require("pymple.jobs")
local FIXTURES_PATH = "lua/tests/fixtures/jobs"
local cwd = vim.fn.getcwd()

describe("gg", function()
  it("std", function()
    local args = { "--json", "-A", "foo", FIXTURES_PATH .. "/gg" }
    local gg_results = jobs.gg(args)
    -- NOTE: this is super annoying to write, but gg results contain an `end` key which is a reserved keyword in Lua...
    local expected = vim.json.decode(
      '[{"path":"'
        .. cwd
        .. '/lua/tests/fixtures/jobs/gg/folder_1/file.py","results":[{"line_number":1,"line":"print(\\"foo\\")\\n","line_start":1,"line_end":1,"matches":[{"start":7,"end":10}]}]},'
        .. '{"path":"'
        .. cwd
        .. '/lua/tests/fixtures/jobs/gg/folder_1/file.txt","results":[{"line_number":1,"line":"foo bar baz\\n","line_start":1,"line_end":1,"matches":[{"start":0,"end":3}]}]}]'
    )

    assert.are.same(expected, gg_results)
  end)

  it("only python files", function()
    local args = { "--json", "-A", "-t python", "foo", FIXTURES_PATH .. "/gg" }
    local gg_results = jobs.gg(args)
    -- NOTE: this is super annoying to write, but gg results contain an `end` key which is a reserved keyword in Lua...
    local expected = vim.json.decode(
      '[{"path":"'
        .. cwd
        .. '/lua/tests/fixtures/jobs/gg/folder_1/file.py","results":[{"line_number":1,"line":"print(\\"foo\\")\\n","line_start":1,"line_end":1,"matches":[{"start":7,"end":10}]}]}]'
    )

    assert.are.same(expected, gg_results)
  end)
end)
