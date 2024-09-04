describe("version_satisfies_constraint", function()
  it("both min and max boundaries", function()
    local health = require("pymple.health")
    assert.is_true(
      health.version_satisfies_constraint("1.0.0", "0.0.0", "2.0.0")
    )
    assert.is_true(
      health.version_satisfies_constraint("0.2.0", "0.1.0", "2.0.0")
    )
    assert.is_true(
      health.version_satisfies_constraint("1.2.3", "1.2.1", "1.3.0")
    )
    assert.is_true(
      health.version_satisfies_constraint("1.1.1", "0.2.3", "3.1.3")
    )
  end)
  it("only min boundary", function()
    local health = require("pymple.health")
    assert.is_true(health.version_satisfies_constraint("1.0.0", "0.0.0", nil))
    assert.is_true(health.version_satisfies_constraint("0.2.0", "0.1.0", nil))
    assert.is_true(health.version_satisfies_constraint("1.2.3", "1.2.1", nil))
  end)
  it("only max boundary", function()
    local health = require("pymple.health")
    assert.is_true(health.version_satisfies_constraint("1.0.0", nil, "2.0.0"))
    assert.is_true(health.version_satisfies_constraint("0.2.0", nil, "2.0.0"))
    assert.is_true(health.version_satisfies_constraint("1.2.3", nil, "1.3.0"))
  end)
  it("different formats", function()
    assert.is_true(
      require("pymple.health").version_satisfies_constraint("1.0.0", "1", "2")
    )
    assert.is_true(
      require("pymple.health").version_satisfies_constraint(
        "1.0.0",
        "1.0",
        "2.0"
      )
    )
    assert.is_true(
      require("pymple.health").version_satisfies_constraint(
        "1.0.0",
        "0.0",
        "2.0.0"
      )
    )
  end)
end)
