local M = {}

local function core()
  return require("dbee").api.core
end

function M.setup(config)
  local ok, err = pcall(require("dbee").setup, config)
  if not ok and not tostring(err):find("setup() can only be called once", 1, true) then
    error(err)
  end
end

function M.current_connection()
  return core().get_current_connection()
end

function M.execute(connection_id, query)
  return core().connection_execute(connection_id, query)
end

function M.display_result(call_id, bufnr)
  return core().call_display_result(call_id, bufnr, 0, -1)
end

function M.structure(connection_id)
  return core().connection_get_structure(connection_id)
end

function M.on_call_state_changed(listener)
  core().register_event_listener("call_state_changed", listener)
end

return M
