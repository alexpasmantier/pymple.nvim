local update_imports = require("pymple.update_imports")
local mock = require("luassert.mock")

describe("build_filetypes_args", function()
  it("std", function()
    local filetypes = { "python", "lua" }
    local result = update_imports.build_filetypes_args(filetypes)
    assert.are.same({ "-t", "python", "-t", "lua" }, result)
  end)
end)

describe("update_imports_split", function()
  it("std", function()
    local source = "foo/bar/baz"
    local destination = "oof/rab/zab"
    local filetypes = { "python", "lua" }
    local mocked_job = mock(function() end, true)
    update_imports.update_imports_split(
      source,
      destination,
      filetypes,
      mocked_job
    )
    assert.spy(mocked_job).was_called_with({
      "--json",
      "-U",
      "-t python -t lua",
      "'from\\s+foo\\.bar\\s+import\\s+\\(?\\n?[\\sa-zA-Z0-9_,\\n]+\\)?\\s*$'",
      ".",
    }, { "'%s,%ss/foo\\.bar/oof\\.rab/'" }, true)
    assert.spy(mocked_job).was_called_with({
      "--json",
      "-U",
      "-t python -t lua",
      "'from\\s+foo\\.bar\\s+import\\s+\\(?\\n?[\\sa-zA-Z0-9_,\\n]+\\)?\\s*$'",
      ".",
    }, { "'%s,%ss/baz/zab/'" }, true)
    mock.revert(mocked_job)
  end)
end)

describe("update_imports_monolithic", function()
  it("std", function()
    local source = "foo/bar/baz"
    local destination = "oof/rab/zab"
    local filetypes = { "python", "lua" }
    local mocked_job = mock(function() end, true)
    update_imports.update_imports_monolithic(
      source,
      destination,
      filetypes,
      mocked_job
    )
    assert.spy(mocked_job).was_called_with({
      "--json",
      "-t python -t lua",
      "'foo\\.bar\\.baz[\\.\\s]'",
      ".",
    }, { "'s/foo\\.bar\\.baz\\([\\. ]\\)/oof\\.rab\\.zab\\1/'" }, false)
    mock.revert(mocked_job)
  end)
end)
