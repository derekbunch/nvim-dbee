local query = require("dbee_session.query")
local M = {}
local Session = {}
Session.__index = Session

local function set_lines(bufnr, lines)
  local modifiable = vim.bo[bufnr].modifiable
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = modifiable
end

local function scratch_buffer(filetype)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = filetype
  vim.bo[bufnr].modifiable = false
  return bufnr
end

local function structure_lines(structures, depth, lines)
  for _, structure in ipairs(structures or {}) do
    local name = structure.schema ~= "" and (structure.schema .. "." .. structure.name) or structure.name
    table.insert(lines, string.rep("  ", depth) .. name)
    structure_lines(structure.children, depth + 1, lines)
  end
end

local function split(source_win, command, bufnr)
  vim.api.nvim_set_current_win(source_win)
  vim.cmd(command)
  local winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(winid, bufnr)
  return winid
end

function Session:refresh_schema()
  local connection = self.dbee.current_connection()
  if not connection then
    set_lines(self.schema_buf, { "No active Dbee connection" })
    return nil
  end

  local ok, structures = pcall(self.dbee.structure, connection.id)
  if not ok then
    set_lines(self.schema_buf, { "Unable to load schema", tostring(structures) })
    return nil
  end

  local lines = {}
  structure_lines(structures, 0, lines)
  set_lines(self.schema_buf, #lines > 0 and lines or { "No schema available" })
  return connection
end

function Session:write_result(lines)
  set_lines(self.result_buf, lines)
end

function Session:on_call_state_changed(data)
  local call = data.call
  if not self.active_call_id or call.id ~= self.active_call_id then
    return
  end

  if call.state == "retrieving" then
    local ok, err = pcall(self.dbee.display_result, call.id, self.result_buf)
    if not ok then
      self:write_result({ "Unable to display result", tostring(err) })
    end
  elseif call.state == "executing_failed" or call.state == "retrieving_failed" or call.state == "canceled" then
    self:write_result({ "Query failed", call.error or call.state })
  end
end

function Session:execute(selected_lines)
  local connection = self.dbee.current_connection()
  if not connection then
    self:write_result({ "No active Dbee connection" })
    return nil
  end

  local text = query.from_buffer(self.source_buf, selected_lines)
  if text == "" then
    self:write_result({ "No SQL to execute" })
    return nil
  end

  local ok, call = pcall(self.dbee.execute, connection.id, text)
  if not ok then
    self:write_result({ "Unable to execute query", tostring(call) })
    return nil
  end

  self.active_call_id = call.id
  self:write_result({ "Executing..." })
  return call
end

function Session:close()
  self.closed = true
  for _, winid in ipairs({ self.schema_win, self.result_win }) do
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_close(winid, true)
    end
  end

  if vim.api.nvim_win_is_valid(self.source_win) then
    vim.api.nvim_set_current_win(self.source_win)
  end
end

function M.open(dbee, config)
  config = config or {}
  local source_win = vim.api.nvim_get_current_win()
  local session = setmetatable({
    dbee = dbee,
    source_win = source_win,
    source_buf = vim.api.nvim_win_get_buf(source_win),
    schema_buf = scratch_buffer("dbee-session-schema"),
    result_buf = scratch_buffer("dbee-session-result"),
  }, Session)
  local schema_width = config.schema_width or 36
  local result_height = config.result_height or 14

  session.schema_win = split(source_win, "topleft vertical " .. schema_width .. "new", session.schema_buf)
  session.result_win = split(source_win, "belowright " .. result_height .. "new", session.result_buf)
  vim.api.nvim_set_current_win(source_win)
  session:refresh_schema()
  dbee.on_call_state_changed(function(data)
    if not session.closed then
      session:on_call_state_changed(data)
    end
  end)

  return session
end

return M
