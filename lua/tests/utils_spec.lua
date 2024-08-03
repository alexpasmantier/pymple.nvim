local utils = require("pymple.utils")
local FIXTURES_PATH = "lua/tests/fixtures/utils"
local cwd = vim.fn.getcwd()
local mock = require("luassert.mock")

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
    utils.add_import_to_buffer("foo.bar", "baz", buf)
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
    utils.add_import_to_buffer("foo.bar", "baz", buf)
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
    utils.add_import_to_buffer("foo.bar", "baz", buf)
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
    local result = utils.get_virtual_environment()
    assert.equals("/foo/bar", result)
    mock.revert(os)
  end)

  it(".venv exists", function()
    local working_dir = cwd
      .. "/"
      .. FIXTURES_PATH
      .. "/virtual_environments/present"
    local result = utils.get_virtual_environment(working_dir)
    assert.equals(working_dir .. "/.venv", result)
    mock.revert(vim.fn)
  end)

  it("no venv", function()
    local working_dir = cwd
      .. FIXTURES_PATH
      .. "/virtual_environments/not_present"
    local result = utils.get_virtual_environment(working_dir)
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