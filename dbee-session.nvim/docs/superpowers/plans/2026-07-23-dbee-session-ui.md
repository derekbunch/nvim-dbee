# Dbee Session UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone, SQL-buffer-centered UI that consumes nvim-dbee's public core API without initializing its UI.

**Architecture:** `dbee_session` owns an explicit session object per tabpage. It invokes only `dbee.api.core`, creates scratch schema/result buffers and their adjacent splits, and tracks every owned window so close restores the source SQL window. A tiny adapter wraps Dbee's public API and event listener boundary, making headless tests independent of the Go backend.

**Tech Stack:** LuaJIT, Neovim 0.10+, nvim-dbee public Lua API, native headless Neovim tests.

---

### Task 1: Create a testable Dbee adapter

**Files:**
- Create: `lua/dbee_session/dbee.lua`
- Create: `tests/dbee_spec.lua`
- Create: `tests/run.lua`
- Create: `tests/minimal_init.lua`
- Create: `tests/harness.lua`

- [ ] **Step 1: Write the failing adapter test**

```lua
local dbee = require("dbee_session.dbee")

it("uses only the public core API", function()
  local calls = {}
  package.loaded.dbee = {
    setup = function() end,
    api = { core = {
      get_current_connection = function() return { id = "primary" } end,
      connection_execute = function(_, query)
        calls.query = query
        return { id = "call-1" }
      end,
    } },
  }

  assert.are.same("primary", dbee.current_connection().id)
  assert.are.same("call-1", dbee.execute("primary", "select 1").id)
  assert.are.same("select 1", calls.query)
end)
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `nvim --headless -u tests/minimal_init.lua -c "lua require('tests.run')" -c qa`

Expected: failure because `dbee_session.dbee` does not exist.

- [ ] **Step 3: Implement the adapter**

```lua
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
```

- [ ] **Step 4: Run the adapter test and verify it passes**

Run: `nvim --headless -u tests/minimal_init.lua -c "lua require('tests.run')" -c qa`

Expected: adapter test passes.

- [ ] **Step 5: Commit**

```bash
git add lua/dbee_session/dbee.lua tests
git commit -m "feat: add public Dbee core adapter"
```

### Task 2: Build owned session windows

**Files:**
- Create: `lua/dbee_session/session.lua`
- Create: `tests/session_spec.lua`

- [ ] **Step 1: Write the failing session-layout tests**

Test these contracts:

```lua
it("keeps the SQL source buffer in its original window", function()
  vim.bo.filetype = "sql"
  local source = vim.api.nvim_get_current_buf()
  local session = require("dbee_session.session").open(fake_dbee)
  assert.are.same(source, vim.api.nvim_win_get_buf(session.source_win))
end)

it("closes only session-owned windows", function()
  local session = require("dbee_session.session").open(fake_dbee)
  session:close()
  assert.is_true(vim.api.nvim_win_is_valid(session.source_win))
  assert.is_false(vim.api.nvim_win_is_valid(session.schema_win))
  assert.is_false(vim.api.nvim_win_is_valid(session.result_win))
end)
```

- [ ] **Step 2: Run the tests and verify failure**

Run: `nvim --headless -u tests/minimal_init.lua -c "lua require('tests.run')" -c qa`

Expected: failure because `session.open` does not exist.

- [ ] **Step 3: Implement the minimal session object**

Create unlisted scratch buffers with `buftype=nofile`, `bufhidden=wipe`, `swapfile=false`, and `modifiable=false`. Create a left schema split and a lower result split by opening two new windows from the source tabpage. Record `source_win`, `source_buf`, `schema_win`, `schema_buf`, `result_win`, and `result_buf`. `close()` only closes valid owned windows, then focuses `source_win` when valid.

- [ ] **Step 4: Run tests and verify pass**

Run: `nvim --headless -u tests/minimal_init.lua -c "lua require('tests.run')" -c qa`

Expected: both source-preservation and owned-window-close tests pass.

- [ ] **Step 5: Commit**

```bash
git add lua/dbee_session/session.lua tests/session_spec.lua
git commit -m "feat: add SQL buffer session layout"
```

### Task 3: Execute SQL and render results

**Files:**
- Create: `lua/dbee_session/query.lua`
- Modify: `lua/dbee_session/session.lua`
- Create: `tests/query_spec.lua`

- [ ] **Step 1: Write failing query-selection tests**

```lua
it("prefers a visual selection over the surrounding SQL buffer", function()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "select 1", "select 2" })
  local query = require("dbee_session.query").from_buffer(0, { "select 2" })
  assert.are.same("select 2", query)
end)

it("uses the full buffer when no selection is supplied", function()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "select 1", "from dual" })
  assert.are.same("select 1\nfrom dual", require("dbee_session.query").from_buffer(0))
end)
```

- [ ] **Step 2: Run tests and verify failure**

Run: `nvim --headless -u tests/minimal_init.lua -c "lua require('tests.run')" -c qa`

Expected: failure because `dbee_session.query` does not exist.

- [ ] **Step 3: Implement selection and asynchronous rendering**

`query.from_buffer(bufnr, selected_lines)` returns the nonempty visual selection when supplied, otherwise concatenates all source lines. `session:execute(selected_lines)` obtains the current connection, reports a clear error when none exists, executes through the adapter, writes `Executing…` to the result buffer, and renders the final table on `call_state_changed` when the event's call id matches the active call and state is complete. Failed calls replace the result buffer with the reported error.

- [ ] **Step 4: Run tests and verify pass**

Run: `nvim --headless -u tests/minimal_init.lua -c "lua require('tests.run')" -c qa`

Expected: query selection and result event tests pass.

- [ ] **Step 5: Commit**

```bash
git add lua/dbee_session/query.lua lua/dbee_session/session.lua tests/query_spec.lua
git commit -m "feat: execute session queries and render results"
```

### Task 4: Expose plugin API, commands, and docs

**Files:**
- Create: `lua/dbee_session/init.lua`
- Create: `plugin/dbee_session.lua`
- Create: `README.md`
- Modify: `tests/session_spec.lua`

- [ ] **Step 1: Write failing command tests**

```lua
it("opens and closes a session through commands", function()
  vim.bo.filetype = "sql"
  vim.cmd("DbeeSessionOpen")
  assert.is_true(require("dbee_session").is_open())
  vim.cmd("DbeeSessionClose")
  assert.is_false(require("dbee_session").is_open())
end)
```

- [ ] **Step 2: Run test and verify failure**

Run: `nvim --headless -u tests/minimal_init.lua -c "lua require('tests.run')" -c qa`

Expected: `E492: Not an editor command: DbeeSessionOpen`.

- [ ] **Step 3: Implement public API and commands**

Expose `setup`, `open`, `close`, `toggle`, `execute`, `refresh_schema`, and `is_open`. Register `:DbeeSessionOpen`, `:DbeeSessionClose`, `:DbeeSessionToggle`, `:DbeeSessionExecute`, and `:DbeeSessionRefreshSchema`. `open` must reject non-SQL buffers. Read visual lines before leaving visual mode. `setup` must initialize the Dbee adapter but must never invoke Dbee's open, execute, or UI API.

- [ ] **Step 4: Run tests and verify pass**

Run: `nvim --headless -u tests/minimal_init.lua -c "lua require('tests.run')" -c qa`

Expected: command tests pass.

- [ ] **Step 5: Smoke-test alongside local nvim-dbee**

Run: `nvim --headless -u tests/smoke_init.lua -c "enew | set ft=sql | DbeeSessionOpen | lua assert(not require('dbee').api.current_config().window_layout:is_open())" -c qa`

Expected: zero exit status. The Dbee core loads, while Dbee's built-in layout remains closed.

- [ ] **Step 6: Document lazy.nvim installation**

Document this configuration:

```lua
{
  "derekbunch/dbee-session.nvim",
  dependencies = {
    "kndndrj/nvim-dbee",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    dbee = {
      sources = { require("dbee.sources").MemorySource:new() },
    },
  },
}
```

Explain the commands, default keymap recommendation, core-only guarantee, and current scope boundaries.

- [ ] **Step 7: Commit**

```bash
git add lua/dbee_session/init.lua plugin/dbee_session.lua README.md tests
git commit -m "feat: release Dbee session UI"
```
