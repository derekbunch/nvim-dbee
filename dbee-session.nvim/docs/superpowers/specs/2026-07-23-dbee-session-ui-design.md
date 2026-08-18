# Dbee Session UI Design

## Goal

Provide an opt-in SQL-buffer-centered Neovim UI for nvim-dbee without invoking nvim-dbee's drawer, editor, result, or call-log UI.

## Package

Create `dbee-session.nvim` as an independent Lua plugin that declares `kndndrj/nvim-dbee` as a dependency. It is configured instead of calling `require("dbee").setup()` directly, so it owns the single upstream setup call.

## Integration boundary

The plugin calls only nvim-dbee's public core API:

- `require("dbee").api.core.get_current_connection()`
- `connection_execute(connection_id, query)`
- `call_display_result(call_id, buffer, from, to)`
- `connection_get_structure(connection_id)`
- `register_event_listener("call_state_changed", listener)`

It never calls `dbee.open`, `dbee.execute`, or `api.ui.*`, so nvim-dbee's built-in UI is never initialized.

## Session model

`:DbeeSessionOpen` starts a session in the current SQL buffer. The editor remains the primary window. The plugin adds an owned schema split at the left and a result split below. `:DbeeSessionClose` closes only those owned windows and restores focus to the SQL buffer.

`:DbeeSessionExecute` executes the visual selection when present, otherwise the full SQL buffer. It writes the finished call into the session result buffer through `call_display_result`.

## Scope

The first version includes connection state, schema refresh, query execution, results, lifecycle, and default commands. It deliberately omits a replacement connection editor, call log, floating UI, statement text objects, and persistent layout state.

## Error handling

Commands reject non-SQL source buffers, missing current connections, and stale sessions with actionable notifications. Failed calls render the backend error in the result buffer.

## Verification

Headless Neovim tests exercise layout ownership, source-buffer preservation, execution selection precedence, and result rendering using a fake public Dbee core API. A smoke test loads the plugin alongside the local nvim-dbee checkout and verifies that opening a session does not initialize Dbee's UI.
