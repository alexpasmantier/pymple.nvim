local resolve_imports = require("pymple.resolve_imports")

describe("add_symbol_regexes", function()
  it("std", function()
    local args = {}
    local symbol = "foo"
    local regexes = { "a %sb", "b %sa" }
    local result = resolve_imports.add_symbol_regexes(args, symbol, regexes)
    assert.are.same({
      "-e",
      "a foob",
      "-e",
      "b fooa",
    }, result)
  end)
end)
