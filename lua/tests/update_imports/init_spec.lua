local update_imports = require("pymple.update_imports")

local FIXTURES_PATH = "lua/tests/update_imports/fixtures"

describe("udpate_imports", function()
  it("std_dir", function()
    local source = FIXTURES_PATH .. "/python_project/foo/baz"
    local destination = FIXTURES_PATH .. "/python_project/foo/zab"
    local filetypes = { "py" }
    local python_root = FIXTURES_PATH .. "/python_project"
    local dry_run = true
    local results = update_imports.prepare_jobs(
      source,
      destination,
      filetypes,
      python_root,
      dry_run
    )
    assert.not_nil(results)
    assert.equals(7, #results)

    assert.equals(
      vim.fn.fnamemodify(results[1].file_path, ":."),
      "lua/tests/update_imports/fixtures/python_project/foo/bar.py"
    )

    assert.equals(
      "from foo.baz.quux import some_variable\n",
      results[1].line_before
    )
    assert.equals(
      "from foo.zab.quux import some_variable\n",
      results[1].line_after
    )
    assert.equals("import foo.baz.quux\n", results[2].line_before)
    assert.equals("import foo.zab.quux\n", results[2].line_after)
    assert.equals("import foo.baz.quux.something\n", results[3].line_before)
    assert.equals("import foo.zab.quux.something\n", results[3].line_after)
    assert.equals("import foo.baz.quux_wrong\n", results[4].line_before)
    assert.equals("import foo.zab.quux_wrong\n", results[4].line_after)
    assert.equals("from foo.baz import quux\n", results[5].line_before)
    assert.equals("from foo.zab import quux\n", results[5].line_after)
    assert.equals("from foo.baz import (\n", results[6].line_before)
    assert.equals("from foo.zab import (\n", results[6].line_after)
    assert.equals("from foo.baz import (\n", results[7].line_before)
    assert.equals("from foo.zab import (\n", results[7].line_after)
  end)

  it("std_file", function()
    local source = FIXTURES_PATH .. "/python_project/foo/baz/quux.py"
    local destination = FIXTURES_PATH .. "/python_project/foo/baz/xuuq.py"
    local filetypes = { "py" }
    local python_root = FIXTURES_PATH .. "/python_project"
    local dry_run = true
    local results = update_imports.prepare_jobs(
      source,
      destination,
      filetypes,
      python_root,
      dry_run
    )
    assert.not_nil(results)
    assert.equals(5, #results)

    assert.equals(
      vim.fn.fnamemodify(results[1].file_path, ":."),
      "lua/tests/update_imports/fixtures/python_project/foo/bar.py"
    )

    assert.equals("from foo.baz import quux\n", results[1].line_before)
    assert.equals("from foo.baz import xuuq\n", results[1].line_after)
    assert.equals(
      "from foo.baz import (\n    something,\n    quux,\n    something_else,\n)\n",
      results[2].line_before
    )
    assert.equals(
      "from foo.baz import (\n    something,\n    xuuq,\n    something_else,\n)\n",
      results[2].line_after
    )
    assert.equals(
      "from foo.baz.quux import some_variable\n",
      results[3].line_before
    )
    assert.equals(
      "from foo.baz.xuuq import some_variable\n",
      results[3].line_after
    )
    assert.equals("import foo.baz.quux\n", results[4].line_before)
    assert.equals("import foo.baz.xuuq\n", results[4].line_after)
    assert.equals("import foo.baz.quux.something\n", results[5].line_before)
    assert.equals("import foo.baz.xuuq.something\n", results[5].line_after)
  end)
end)
