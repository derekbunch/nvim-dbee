local function reset_layout()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if winid ~= vim.api.nvim_get_current_win() then
      vim.api.nvim_win_close(winid, true)
    end
  end

  vim.cmd("enew!")
  vim.bo.filetype = "sql"
end

describe("query execution", function()
  before_each(reset_layout)

  it("prefers supplied visual lines", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "select 1", "select 2" })
    local query = require("dbee_session.query")

    assert.equals("select 2", query.from_buffer(0, { "select 2" }))
    assert.equals("select 1\nselect 2", query.from_buffer(0))
  end)

  it("renders the active call when results are retrievable", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "select 1" })
    local listener
    local executed
    local fake = {
      current_connection = function()
        return { id = "primary" }
      end,
      structure = function()
        return {}
      end,
      execute = function(connection_id, query)
        executed = { connection_id, query }
        return { id = "call-1", state = "executing" }
      end,
      display_result = function(call_id, bufnr)
        local modifiable = vim.bo[bufnr].modifiable
        vim.bo[bufnr].modifiable = true
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "result for " .. call_id })
        vim.bo[bufnr].modifiable = modifiable
      end,
      on_call_state_changed = function(callback)
        listener = callback
      end,
    }
    local session = require("dbee_session.session").open(fake)

    session:execute()
    assert.same({ "primary", "select 1" }, executed)
    assert.same({ "Executing..." }, vim.api.nvim_buf_get_lines(session.result_buf, 0, -1, false))

    listener({ call = { id = "other", state = "retrieving" } })
    assert.same({ "Executing..." }, vim.api.nvim_buf_get_lines(session.result_buf, 0, -1, false))

    listener({ call = { id = "call-1", state = "retrieving" } })
    assert.same({ "result for call-1" }, vim.api.nvim_buf_get_lines(session.result_buf, 0, -1, false))
    session:close()
  end)

  it("displays failed call errors", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "bad query" })
    local listener
    local fake = {
      current_connection = function()
        return { id = "primary" }
      end,
      structure = function()
        return {}
      end,
      execute = function()
        return { id = "call-2", state = "executing" }
      end,
      on_call_state_changed = function(callback)
        listener = callback
      end,
    }
    local session = require("dbee_session.session").open(fake)

    session:execute()
    listener({ call = { id = "call-2", state = "executing_failed", error = "syntax error" } })

    assert.same({ "Query failed", "syntax error" }, vim.api.nvim_buf_get_lines(session.result_buf, 0, -1, false))
    session:close()
  end)
end)
