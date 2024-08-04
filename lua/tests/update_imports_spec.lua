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
    local mocked_sjob = mock(function() end, true)
    mocked_sjob.returns("some_result")
    local mocked_rjob = mock(function() end, true)
    update_imports.update_imports_split(
      source,
      destination,
      filetypes,
      mocked_sjob,
      mocked_rjob
    )
    assert.spy(mocked_sjob).was_called_with({
      "--json",
      "-U",
      "-t python -t lua",
      "'from\\s+foo\\.bar\\s+import\\s+\\(?\\n?[\\sa-zA-Z0-9_,\\n]+\\)?\\s*$'",
      ".",
    })
    assert
      .spy(mocked_rjob)
      .was_called_with("some_result", "'%s,%ss/foo\\.bar/oof\\.rab/'")
    assert.spy(mocked_rjob).was_called_with("some_result", "'%s,%ss/baz/zab/'")
    mock.revert(mocked_sjob)
    mock.revert(mocked_rjob)
  end)
end)

describe("update_imports_monolithic", function()
  it("std", function()
    local source = "foo/bar/baz"
    local destination = "oof/rab/zab"
    local filetypes = { "python", "lua" }
    local mocked_sjob = mock(function() end, true)
    mocked_sjob.returns("some_result")
    local mocked_rjob = mock(function() end, true)
    update_imports.update_imports_monolithic(
      source,
      destination,
      filetypes,
      mocked_sjob,
      mocked_rjob
    )
    assert.spy(mocked_sjob).was_called_with({
      "--json",
      "-t python -t lua",
      "'foo\\.bar\\.baz[\\.\\s]'",
      ".",
    })
    assert
      .spy(mocked_rjob)
      .was_called_with("some_result", "'s/foo\\.bar\\.baz\\([\\. ]\\)/oof\\.rab\\.zab\\1/'")

    mock.revert(mocked_sjob)
    mock.revert(mocked_rjob)
  end)
end)
