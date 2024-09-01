describe("gg", function()
  local jobs = require("pymple.jobs")
  local FIXTURES_PATH = "lua/tests/fixtures/jobs"
  local cwd = vim.fn.getcwd()

  it("std", function()
    local args =
      table.concat({ "--json", "-A", "foo", FIXTURES_PATH .. "/gg" }, " ")
    local gg_results = jobs.gg(args)
    local expected = {
      {
        path = cwd .. "/" .. FIXTURES_PATH .. "/gg/folder_1/file.py",
        results = {
          {
            line_number = 1,
            line = 'print("foo")\n',
            line_start = 1,
            line_end = 1,
            matches = { { m_start = 7, m_end = 10 } },
          },
        },
      },
      {
        path = cwd .. "/" .. FIXTURES_PATH .. "/gg/folder_1/file.txt",
        results = {
          {
            line_number = 1,
            line = "foo bar baz\n",
            line_start = 1,
            line_end = 1,
            matches = { { m_start = 0, m_end = 3 } },
          },
        },
      },
    }
    table.sort(gg_results, function(a, b)
      return a.path < b.path
    end)

    assert.are.same(expected, gg_results)
  end)

  it("only python files", function()
    local args = table.concat(
      { "--json", "-A", "-t python", "foo", FIXTURES_PATH .. "/gg" },
      " "
    )
    local gg_results = jobs.gg(args)
    local expected = {
      {
        path = cwd .. "/" .. FIXTURES_PATH .. "/gg/folder_1/file.py",
        results = {
          {
            line_number = 1,
            line = 'print("foo")\n',
            line_start = 1,
            line_end = 1,
            matches = { { m_start = 7, m_end = 10 } },
          },
        },
      },
    }

    assert.are.same(expected, gg_results)
  end)
end)
