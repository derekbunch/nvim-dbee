local adapter = require("dbee_session.dbee")
local Session = require("dbee_session.session")

local M = {}
local config = {
  dbee = {},
  schema_width = 36,
  result_height = 14,
}
local sessions = {}
local setup_done = false

local function current_tab()
  return vim.api.nvim_get_current_tabpage()
end

local function current_session()
  local session = sessions[current_tab()]
  if session and not session.closed then
    return session
  end

  return nil
end

local function ensure_setup()
  if not setup_done then
    adapter.setup(config.dbee)
    setup_done = true
  end
end

function M.setup(options)
  config = vim.tbl_deep_extend("force", config, options or {})
  ensure_setup()
end

function M.open()
  if vim.bo.filetype ~= "sql" then
    error("DbeeSessionOpen must be called from a SQL buffer")
  end

  ensure_setup()
  if current_session() then
    return current_session()
  end

  local session = Session.open(adapter, config)
  sessions[current_tab()] = session
  return session
end

function M.close()
  local session = current_session()
  if not session then
    return
  end

  session:close()
  sessions[current_tab()] = nil
end

function M.toggle()
  return current_session() and M.close() or M.open()
end

function M.execute(selected_lines)
  local session = current_session()
  if not session then
    error("no Dbee session is open in this tabpage")
  end

  return session:execute(selected_lines)
end

function M.refresh_schema()
  local session = current_session()
  if not session then
    error("no Dbee session is open in this tabpage")
  end

  return session:refresh_schema()
end

function M.is_open()
  return current_session() ~= nil
end

return M
