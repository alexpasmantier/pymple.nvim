local utils = require("pymple.utils")
local FIXTURES_PATH = "lua/tests/fixtures/utils"
local cwd = vim.fn.getcwd()
local mock = require("luassert.mock")

describe("find_project_root", function()
  it("pythonpath", function()
    mock(os, "getenv", function()
      return "/some/path"
    end)
    local result = utils.find_project_root(nil, {})
    assert.equals("/some/path", result)
    mock.revert(os)
  end)

  it("no pythonpath and src", function()
    local result = utils.find_project_root(
      FIXTURES_PATH .. "/project_with_src/src",
      { "pyproject.toml" }
    )
    assert.equals(FIXTURES_PATH .. "/project_with_src/src", result)
  end)

  it("no pythonpath and no src", function()
    local result = utils.find_project_root(
      FIXTURES_PATH .. "/project/module/__init__.py",
      { "pyproject.toml" }
    )
    assert.equals(FIXTURES_PATH .. "/project", result)
  end)

  it("no root", function()
    local result = utils.find_project_root(
      FIXTURES_PATH .. "/project_no_root/a/b/c.py",
      { "pyproject.toml" }
    )
    assert.equals(nil, result)
  end)
end)

describe("to_import_path", function()
  it("std", function()
    local result = utils.to_import_path("foo/bar/baz.py")
    assert.equals("foo.bar.baz", result)
  end)
end)

describe("split_import_on_last_separator", function()
  it("std", function()
    local base_path, module_name =
      utils.split_import_on_last_separator("foo.bar.baz")
    assert.equals("foo.bar", base_path)
    assert.equals("baz", module_name)
  end)

  it("no separator", function()
    local base_path, module_name = utils.split_import_on_last_separator("foo")
    assert.equals("", base_path)
    assert.equals("foo", module_name)
  end)
end)

describe("escape_import_path", function()
  it("std", function()
    local result = utils.escape_import_path("foo.bar.baz")
    assert.equals("foo\\.bar\\.baz", result)
  end)
end)

describe("is_python_file", function()
  it("std", function()
    local result = utils.is_python_file("foo/bar/baz.py")
    assert.is_true(result)
  end)

  it("not python", function()
    local result = utils.is_python_file("foo/bar/baz.lua")
    assert.is_false(result)
  end)

  it("no extension", function()
    local result = utils.is_python_file("foo/bar/baz")
    assert.is_false(result)
  end)
end)

describe("recursive_dir_contains_python_files", function()
  it("std", function()
    local result = utils.recursive_dir_contains_python_files(
      FIXTURES_PATH .. "/contains_python_files"
    )
    assert.is_true(result)
  end)

  it("no python files", function()
    local result = utils.recursive_dir_contains_python_files(
      FIXTURES_PATH .. "/no_python_files"
    )
    assert.is_false(result)
  end)
end)

describe("find_docstring_end_line_number_in_lines", function()
  it("no docstring", function()
    local lines = vim.fn.readfile(
      cwd .. "/" .. FIXTURES_PATH .. "/docstrings/no_docstring.py"
    )
    local result = utils.find_docstring_end_line_number_in_lines(lines)
    assert.equals(0, result)
  end)

  it("single line docstring", function()
    local lines = vim.fn.readfile(
      cwd .. "/" .. FIXTURES_PATH .. "/docstrings/single_line_docstring.py"
    )
    local result = utils.find_docstring_end_line_number_in_lines(lines)
    assert.equals(1, result)
  end)

  it("multiline docstring", function()
    local lines = vim.fn.readfile(
      cwd .. "/" .. FIXTURES_PATH .. "/docstrings/multiline_docstring.py"
    )
    local result = utils.find_docstring_end_line_number_in_lines(lines)
    assert.equals(4, result)
  end)

  it("misc 1", function()
    local lines =
      vim.fn.readfile(cwd .. "/" .. FIXTURES_PATH .. "/docstrings/misc_1.py")
    local result = utils.find_docstring_end_line_number_in_lines(lines)
    assert.equals(2, result)
  end)

  it("misc 2", function()
    local lines =
      vim.fn.readfile(cwd .. "/" .. FIXTURES_PATH .. "/docstrings/misc_2.py")
    local result = utils.find_docstring_end_line_number_in_lines(lines)
    assert.equals(2, result)
  end)

  it("misc 3", function()
    local lines =
      vim.fn.readfile(cwd .. "/" .. FIXTURES_PATH .. "/docstrings/misc_3.py")
    local result = utils.find_docstring_end_line_number_in_lines(lines)
    assert.equals(4, result)
  end)
end)

describe("find_docstring_end_line_number", function()
  it("std", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      vim.fn.readfile(
        cwd .. "/" .. FIXTURES_PATH .. "/docstrings/multiline_docstring.py"
      )
    )
    local result = utils.find_docstring_end_line_number(buf)
    assert.equals(4, result)
  end)
end)

describe("add_import_to_current_buf", function()
  it("no docstring", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      vim.fn.readfile(
        cwd .. "/" .. FIXTURES_PATH .. "/docstrings/no_docstring.py"
      )
    )
    utils.add_import_to_buffer("from foo.bar import baz", buf, false)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    -- lua table indexing is 1-based
    assert.equals("from foo.bar import baz", lines[1])
  end)

  it("single line docstring", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      vim.fn.readfile(
        cwd .. "/" .. FIXTURES_PATH .. "/docstrings/single_line_docstring.py"
      )
    )
    utils.add_import_to_buffer("from foo.bar import baz", buf, false)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    -- lua table indexing is 1-based
    assert.equals("from foo.bar import baz", lines[3])
  end)

  it("multiline docstring", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      vim.fn.readfile(
        cwd .. "/" .. FIXTURES_PATH .. "/docstrings/multiline_docstring.py"
      )
    )
    utils.add_import_to_buffer("from foo.bar import baz", buf, false)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    -- lua table indexing is 1-based
    assert.equals("from foo.bar import baz", lines[6])
  end)
end)

describe("get_virtual_environment", function()
  it("VIRTUAL_ENV set", function()
    mock(os, "getenv", function()
      return "/foo/bar"
    end)
    local result = utils.get_virtual_environment(cwd, {})
    assert.equals("/foo/bar", result)
    mock.revert(os)
  end)

  it(".venv exists", function()
    local working_dir = cwd
      .. "/"
      .. FIXTURES_PATH
      .. "/virtual_environments/present"
    local result = utils.get_virtual_environment(working_dir, { ".venv" })
    assert.equals(working_dir .. "/.venv", result)
  end)

  it("no venv", function()
    local working_dir = cwd
      .. FIXTURES_PATH
      .. "/virtual_environments/not_present"
    local result = utils.get_virtual_environment(working_dir, { ".venv" })
    assert.equals(nil, result)
  end)
end)

describe("table_contains", function()
  it("std", function()
    local result = utils.table_contains({ "foo", "bar", "baz" }, "bar")
    assert.is_true(result)
  end)

  it("not present", function()
    local result = utils.table_contains({ "foo", "bar", "baz" }, "qux")
    assert.is_false(result)
  end)
end)

describe("longest_string_in_list", function()
  it("std", function()
    local result = utils.longest_string_in_list({ "fooo", "fo", "foo" })
    assert.equals("fooo", result)
  end)

  it("empty list", function()
    local result = utils.longest_string_in_list({})
    assert.equals(nil, result)
  end)
end)

describe("deduplicate_list", function()
  it("std", function()
    local result = utils.deduplicate_list({ "foo", "bar", "foo", "baz" })
    assert.same({ "foo", "bar", "baz" }, result)
  end)

  it("empty list", function()
    local result = utils.deduplicate_list({})
    assert.same({}, result)
  end)
end)

describe("make_relative_to", function()
  it("std", function()
    local result = utils.make_relative_to("/foo/bar/baz", "/foo")
    assert.equals("bar/baz", result)
  end)
end)

describe("make_files_relative", function()
  it("std", function()
    local result =
      utils.make_files_relative({ "/foo/bar/baz", "/foo/bar" }, "/foo")
    assert.same({ "bar/baz", "bar" }, result)
  end)
end)

describe("map", function()
  it("std", function()
    local result = utils.map(function(x)
      return x * 2
    end, { 1, 2, 3 })
    assert.same({ 2, 4, 6 }, result)
  end)

  it("empty list", function()
    local result = utils.map(function(x)
      return x * 2
    end, {})
    assert.same({}, result)
  end)

  it("extra_args", function()
    local fn = function(x, n, m)
      return x + n + m
    end
    local result = utils.map(fn, { 1, 2, 3 }, { 10, 20 })
    assert.same({ 31, 32, 33 }, result)
  end)
end)

describe("split_string", function()
  it("space", function()
    local result = utils.split_string("foo bar baz", " ")
    assert.same({ "foo", "bar", "baz" }, result)
  end)

  it("dot", function()
    local result = utils.split_string("foo.bar.baz", ".")
    assert.same({ "foo", "bar", "baz" }, result)
  end)

  it("no separator in string", function()
    local result = utils.split_string("foo", ".")
    assert.same({ "foo" }, result)
  end)

  it("split on empty string", function()
    local result = utils.split_string("foo", "")
    assert.same({ "foo" }, result)
  end)
end)

describe("any", function()
  it("true", function()
    local result = utils.any({ true, false, true })
    assert.is_true(result)
  end)
  it("false", function()
    local result = utils.any({ false, false, false })
    assert.is_false(result)
  end)
  it("empty", function()
    local result = utils.any({})
    assert.is_false(result)
  end)
end)

describe("all", function()
  it("true", function()
    local result = utils.all({ true, true, true })
    assert.is_true(result)
  end)
  it("false", function()
    local result = utils.all({ true, false, true })
    assert.is_false(result)
  end)
  it("empty", function()
    local result = utils.all({})
    assert.is_true(result)
  end)
end)

describe("shorten_path", function()
  it("short path", function()
    local result = utils.shorten_path("/foo/bar/baz", 20)
    assert.equals("/foo/bar/baz", result)
  end)

  it("long path", function()
    local result = utils.shorten_path("/foo/bar/baz/qux/quux", 14)
    assert.equals("/f/b/b/q/quux", result)
  end)

  it("long path with no limit", function()
    local result = utils.shorten_path("/foo/bar/baz/qux/quux", 0)
    assert.equals("/foo/bar/baz/qux/quux", result)
  end)

  it("path with single element", function()
    local result = utils.shorten_path("/foo", 10)
    assert.equals("/foo", result)
  end)

  it("empty path", function()
    local result = utils.shorten_path("", 10)
    assert.equals("", result)
  end)
end)

describe("get_python_sys_paths", function()
  it("std", function()
    local e = function(_)
      return "['', '/Users/someone/.pyenv/versions/3.11.2/lib/python311.zip', '/Users/someone/.pyenv/versions/3.11.2/lib/python3.11', '/Users/someone/.pyenv/versions/3.11.2/lib/python3.11/lib-dynload', '/Users/someone/.pyenv/versions/3.11.2/lib/python3.11/site-packages']"
    end
    local result = utils.get_python_sys_paths(e)
    assert.same({
      "/Users/someone/.pyenv/versions/3.11.2/lib/python3.11",
      "/Users/someone/.pyenv/versions/3.11.2/lib/python3.11/site-packages",
    }, result)
  end)
end)
