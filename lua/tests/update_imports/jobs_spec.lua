local jobs = require("pymple.update_imports.jobs")

describe("build_filetypes_args", function()
  it("std", function()
    local filetypes = { "python", "lua" }
    local result = jobs.build_filetypes_args(filetypes)
    assert.are.same({ "-t", "python", "-t", "lua" }, result)
  end)
end)

describe("make_gg_args", function()
  it("split", function()
    local result = jobs.make_gg_args("foo.bar.baz", { "python", "md" }, true)
    assert.are.same(
      "--json -U -t python -t md 'from\\s+foo\\.bar\\s+import\\s+(?:\\([\\sa-zA-Z0-9_,]*baz[\\sa-zA-Z0-9_,]*\\)\\s*|[\\w,]*baz[\\w,]*)' .",
      result
    )
  end)

  it("std", function()
    local result = jobs.make_gg_args("foo.bar.baz", { "python", "md" }, false)
    assert.are.same(
      "--json -t python -t md '[^\\.]\\bfoo\\.bar\\.baz\\b' .",
      result
    )
  end)
end)

describe("make_sed_patterns", function()
  it("std", function()
    local result = jobs.make_sed_patterns("foo.bar.baz", "oof.rab.zab", false)
    assert.are.same({ "s/foo\\.bar\\.baz/oof\\.rab\\.zab/" }, result)
  end)

  it("split", function()
    local result = jobs.make_sed_patterns("foo.bar.baz", "oof.rab.zab", true)
    assert.are.same({ "s/foo\\.bar/oof\\.rab/", "s/baz/zab/" }, result)
  end)
end)

describe("replace_job", function()
  it("new_std", function()
    local sed_patterns = { "s/foo/bar/" }
    local gg_results = {
      {
        path = "foo/bar/baz.py",
        results = {
          {
            line_number = 1,
            line = "foo",
            line_start = 1,
            line_end = 1,
            matches = {
              { m_start = 0, m_end = 2 },
            },
          },
        },
      },
    }
    local rjob = jobs.ReplaceJob.new(sed_patterns, gg_results)
    assert.are.same(sed_patterns, rjob.sed_patterns)
    assert.are.same(gg_results, rjob.targets)
  end)

  it("new_missing_targets", function()
    local sed_patterns = { "s/foo/bar/" }
    local rjob = jobs.ReplaceJob.new(sed_patterns, {})
    assert.are.same(sed_patterns, rjob.sed_patterns)
    assert.are.same({}, rjob.targets)
  end)

  it("new_missing_patterns", function()
    local gg_results = {
      {
        path = "foo/bar/baz.py",
        results = {
          {
            line_number = 1,
            line = "foo",
            line_start = 1,
            line_end = 1,
            matches = {
              { m_start = 0, m_end = 2 },
            },
          },
        },
      },
    }
    local rjob = jobs.ReplaceJob.new(nil, gg_results)
    assert.are.same({}, rjob.sed_patterns)
    assert.are.same(gg_results, rjob.targets)
  end)

  it("new_missing_all", function()
    local rjob = jobs.ReplaceJob.new()
    assert.are.same({}, rjob.sed_patterns)
    assert.are.same({}, rjob.targets)
  end)

  it("add_target", function()
    local rjob = jobs.ReplaceJob.new()
    local gg_results = {
      {
        path = "foo/bar/baz.py",
        results = {
          {
            line_number = 1,
            line = "foo",
            line_start = 1,
            line_end = 1,
            matches = {
              { m_start = 0, m_end = 2 },
            },
          },
        },
      },
    }
    rjob:add_target(gg_results)
    assert.are.same({ gg_results }, rjob.targets)
  end)

  it("add_pattern", function()
    local rjob = jobs.ReplaceJob.new()
    rjob:add_pattern("s/foo/bar/")
    assert.are.same({ "s/foo/bar/" }, rjob.sed_patterns)
  end)

  it("run_on_files", function()
    -- setup
    local fixture_file_path = "lua/tests/update_imports/fixtures/file.txt"
    io.popen("echo 'foo bar baz' > " .. fixture_file_path)
    local sed_patterns = { "s/foo/bar/" }
    local gg_results = {
      {
        path = fixture_file_path,
        results = {
          {
            line_number = 1,
            line = "foo bar baz\n",
            line_start = 1,
            line_end = 1,
            matches = {
              { m_start = 0, m_end = 3 },
            },
          },
        },
      },
    }
    local rjob = jobs.ReplaceJob.new(sed_patterns, gg_results)
    rjob:run_on_files()
    local handle = assert(io.popen("cat " .. fixture_file_path))
    local result = assert(handle:read("*a"))
    handle:close()
    assert.are.same("bar bar baz\n", result)
  end)

  it("run_on_lines_std", function()
    local sed_patterns = { "s/bar/rab/" }
    local gg_results = {
      {
        path = "some_file.txt",
        results = {
          {
            line_number = 1,
            line = "foo bar baz\n",
            line_start = 1,
            line_end = 1,
            matches = {
              { m_start = 4, m_end = 6 },
            },
          },
        },
      },
    }
    local rjob = jobs.ReplaceJob.new(sed_patterns, gg_results)
    local results = rjob:run_on_lines()
    assert.are.same({
      {
        file_path = "some_file.txt",
        line_before = "foo bar baz\n",
        line_after = "foo rab baz\n",
        line_num = 1,
      },
    }, results)
  end)

  it("run_on_lines_multiple_patterns", function()
    local sed_patterns = { "s/bar/rab/", "s/foo/oof/" }
    local gg_results = {
      {
        path = "some_file.txt",
        results = {
          {
            line_number = 1,
            line = "foo bar baz\n",
            line_start = 1,
            line_end = 1,
            matches = {
              { m_start = 4, m_end = 6 },
              { m_start = 7, m_end = 9 },
            },
          },
        },
      },
    }
    local rjob = jobs.ReplaceJob.new(sed_patterns, gg_results)
    local results = rjob:run_on_lines()
    assert.are.same({
      {
        file_path = "some_file.txt",
        line_before = "foo bar baz\n",
        line_after = "oof rab baz\n",
        line_num = 1,
      },
    }, results)
  end)

  it("run_on_lines_multiple_lines", function()
    local sed_patterns = { "s/bar/rab/" }
    local gg_results = {
      {
        path = "some_file.txt",
        results = {
          {
            line_number = 1,
            line = "foo bar baz\n",
            line_start = 1,
            line_end = 1,
            matches = {
              { m_start = 4, m_end = 6 },
            },
          },
          {
            line_number = 2,
            line = "oof bar zab\n",
            line_start = 1,
            line_end = 1,
            matches = {
              { m_start = 4, m_end = 6 },
            },
          },
        },
      },
    }
    local rjob = jobs.ReplaceJob.new(sed_patterns, gg_results)
    local results = rjob:run_on_lines()
    assert.are.same({
      {
        file_path = "some_file.txt",
        line_before = "foo bar baz\n",
        line_after = "foo rab baz\n",
        line_num = 1,
      },
      {
        file_path = "some_file.txt",
        line_before = "oof bar zab\n",
        line_after = "oof rab zab\n",
        line_num = 2,
      },
    }, results)
  end)
end)
