local function reset_layout()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if winid ~= vim.api.nvim_get_current_win() then
      vim.api.nvim_win_close(winid, true)
    end
  end

  vim.cmd("enew!")
  vim.bo.filetype = "sql"
end

local function fake_dbee()
  return {
    current_connection = function()
      return { id = "primary", name = "Primary" }
    end,
    structure = function()
      return {
        {
          name = "users",
          schema = "public",
          type = "table",
          children = {},
        },
      }
    end,
    on_call_state_changed = function() end,
  }
end

describe("session layout", function()
  before_each(reset_layout)

  it("preserves the SQL source buffer", function()
    local source_buf = vim.api.nvim_get_current_buf()
    local session = require("dbee_session.session").open(fake_dbee())

    assert.equals(source_buf, vim.api.nvim_win_get_buf(session.source_win))
    assert.equals(source_buf, vim.api.nvim_get_current_buf())
    assert.is_true(vim.api.nvim_win_is_valid(session.schema_win))
    assert.is_true(vim.api.nvim_win_is_valid(session.result_win))
    assert.same({ "public.users" }, vim.api.nvim_buf_get_lines(session.schema_buf, 0, -1, false))

    session:close()
  end)

  it("closes only its owned windows", function()
    local session = require("dbee_session.session").open(fake_dbee())
    local source_win = session.source_win
    local schema_win = session.schema_win
    local result_win = session.result_win

    session:close()

    assert.is_true(vim.api.nvim_win_is_valid(source_win))
    assert.is_false(vim.api.nvim_win_is_valid(schema_win))
    assert.is_false(vim.api.nvim_win_is_valid(result_win))
    assert.equals(source_win, vim.api.nvim_get_current_win())
  end)
end)
