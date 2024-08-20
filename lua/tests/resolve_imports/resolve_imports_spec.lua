local resolve_imports = require("pymple.resolve_imports")
describe("build_symbol_regexes", function()
  it("std", function()
    local symbol = "foo"
    local regexes = { "a %sb", "b %sa" }
    local result = resolve_imports.build_symbol_regexes(symbol, regexes)
    assert.are.same("-e a foob -e b fooa ", result)
  end)
end)
