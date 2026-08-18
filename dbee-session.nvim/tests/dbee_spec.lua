describe("Dbee adapter", function()
  before_each(function()
    package.loaded["dbee_session.dbee"] = nil
  end)

  it("uses public core methods", function()
    local calls = {}
    package.loaded.dbee = {
      api = {
        core = {
          get_current_connection = function()
            return { id = "primary" }
          end,
          connection_execute = function(connection_id, query)
            calls.connection_id = connection_id
            calls.query = query
            return { id = "call-1" }
          end,
        },
      },
      setup = function(config)
        calls.config = config
      end,
    }

    local dbee = require("dbee_session.dbee")
    dbee.setup({ sources = {} })

    assert.equals("primary", dbee.current_connection().id)
    assert.equals("call-1", dbee.execute("primary", "select 1").id)
    assert.equals("primary", calls.connection_id)
    assert.equals("select 1", calls.query)
    assert.same({ sources = {} }, calls.config)
  end)
end)
