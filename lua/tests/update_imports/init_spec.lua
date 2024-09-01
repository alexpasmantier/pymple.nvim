local FIXTURES_PATH = "lua/tests/update_imports/fixtures"

describe("udpate_imports", function()
  local update_imports = require("pymple.update_imports")
  local ReplaceJob = require("pymple.update_imports.jobs").ReplaceJob

  it("make_split_imports_job", function()
    local source = "foo.bar"
    local destination = "oof.rab"
    local filetypes = { "py" }
    local r_job =
      update_imports.make_split_imports_job(source, destination, filetypes)
    assert.not_nil(r_job)
    assert.equals(2, #r_job.sed_patterns)
    assert.equals("s/foo/oof/", r_job.sed_patterns[1])
    assert.equals("s/bar/rab/", r_job.sed_patterns[2])
    assert.equals(1, #r_job.targets)
    assert.equals(
      vim.fn.fnamemodify(r_job.targets[1].path, ":."),
      "lua/tests/update_imports/fixtures/python_project/foo/baz/quux.py"
    )
  end)

  it("make_monolithic_imports_job", function()
    local source = "foo.bar"
    local destination = "oof.rab"
    local filetypes = { "py" }
    local r_job =
      update_imports.make_monolithic_imports_job(source, destination, filetypes)
    assert.not_nil(r_job)
    assert.equals(1, #r_job.sed_patterns)
    assert.equals("s/foo\\.bar/oof\\.rab/", r_job.sed_patterns[1])
    assert.equals(1, #r_job.targets)
    assert.equals(
      vim.fn.fnamemodify(r_job.targets[1].path, ":."),
      "lua/tests/update_imports/fixtures/python_project/foo/baz/quux.py"
    )
  end)

  it("prepare_jobs", function()
    local source = FIXTURES_PATH .. "/python_project/foo/bar.py"
    local destination = FIXTURES_PATH .. "/python_project/oof/rab.py"
    local filetypes = { "py" }
    local python_root = FIXTURES_PATH .. "/python_project"
    local r_jobs =
      update_imports.prepare_jobs(source, destination, filetypes, python_root)
    assert.not_nil(r_jobs)
    assert.equals(2, #r_jobs)
    assert.equals(2, #r_jobs[1].sed_patterns)
    assert.equals(1, #r_jobs[1].targets)
    assert.equals(1, #r_jobs[2].sed_patterns)
    assert.equals(1, #r_jobs[2].targets)
  end)

  it("dry_run_jobs", function()
    local rjobs = {
      ReplaceJob.new({
        "s/foo/oof/",
        "s/bar/rab/",
      }, {
        {
          path = FIXTURES_PATH .. "/python_project/foo/bar.py",
          results = {
            {
              line_number = 1,
              line = "from foo.bar import something\n",
              line_start = 1,
              line_end = 1,
              matches = {
                { m_start = 6, m_end = 13 },
              },
            },
            {
              line_number = 2,
              line = "from foo.bar import something_else\n",
              line_start = 2,
              line_end = 2,
              matches = {
                { m_start = 6, m_end = 13 },
              },
            },
          },
        },
      }),
      ReplaceJob.new({ "s/foo\\.bar/oof\\.rab/" }, {
        {
          path = FIXTURES_PATH .. "/python_project/foo/baz/quux.py",
          results = {
            {
              line_number = 1,
              line = "from foo.bar import something\n",
              line_start = 1,
              line_end = 1,
              matches = {
                { m_start = 6, m_end = 13 },
              },
            },
            {
              line_number = 2,
              line = "from foo.bar import something_else\n",
              line_start = 2,
              line_end = 2,
              matches = {
                { m_start = 6, m_end = 13 },
              },
            },
          },
        },
      }),
    }
    local results = update_imports.dry_run_jobs(rjobs)
    assert.not_nil(results)
    assert.equals(4, #results)
    -- first
    assert.equals(
      vim.fn.fnamemodify(results[1].file_path, ":."),
      "lua/tests/update_imports/fixtures/python_project/foo/bar.py"
    )
    assert.equals("from foo.bar import something\n", results[1].line_before)
    assert.equals("from oof.rab import something\n", results[1].line_after)
    -- second
    assert.equals(
      vim.fn.fnamemodify(results[2].file_path, ":."),
      "lua/tests/update_imports/fixtures/python_project/foo/bar.py"
    )
    assert.equals(
      "from foo.bar import something_else\n",
      results[2].line_before
    )
    assert.equals("from oof.rab import something_else\n", results[2].line_after)
    -- third
    assert.equals(
      vim.fn.fnamemodify(results[3].file_path, ":."),
      "lua/tests/update_imports/fixtures/python_project/foo/baz/quux.py"
    )
    assert.equals("from foo.bar import something\n", results[3].line_before)
    assert.equals("from oof.rab import something\n", results[3].line_after)
    -- fourth
    assert.equals(
      vim.fn.fnamemodify(results[4].file_path, ":."),
      "lua/tests/update_imports/fixtures/python_project/foo/baz/quux.py"
    )
    assert.equals(
      "from foo.bar import something_else\n",
      results[4].line_before
    )
    assert.equals("from oof.rab import something_else\n", results[4].line_after)
  end)
end)
