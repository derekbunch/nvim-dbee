local function reset_layout()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if winid ~= vim.api.nvim_get_current_win() then
      vim.api.nvim_win_close(winid, true)
    end
  end

  vim.cmd("enew!")
end

describe("Dbee session commands", function()
  before_each(function()
    reset_layout()
    package.loaded["dbee_session"] = nil
    package.loaded["dbee_session.init"] = nil
  end)

  it("opens and closes a SQL session", function()
    vim.bo.filetype = "sql"
    local setup_config
    package.loaded["dbee_session.dbee"] = {
      setup = function(config)
        setup_config = config
      end,
      current_connection = function()
        return { id = "primary" }
      end,
      structure = function()
        return {}
      end,
      on_call_state_changed = function() end,
    }

    local dbee_session = require("dbee_session")
    dbee_session.setup({ dbee = { sources = {} } })
    vim.cmd.runtime("plugin/dbee_session.lua")
    vim.cmd("DbeeSessionOpen")

    assert.is_true(dbee_session.is_open())
    assert.same({ sources = {} }, setup_config)

    vim.cmd("DbeeSessionClose")
    assert.is_false(dbee_session.is_open())
  end)

  it("rejects non-SQL source buffers", function()
    vim.bo.filetype = "lua"
    local ok, err = pcall(require("dbee_session").open)

    assert.is_false(ok)
    assert.is_truthy(tostring(err):find("SQL buffer", 1, true))
  end)
end)
