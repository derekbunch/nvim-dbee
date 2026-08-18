# Save for later

## DAP-style SQL session UI

Make nvim-dbee opt-in from the current SQL buffer, modeled after `nvim-dap-ui` rather than a whole-editor takeover:

- Start a Dbee session from the current SQL buffer.
- Preserve that buffer in the current tabpage as the primary editor.
- Add Dbee-owned supporting panes around it: connection selector, schema explorer, query history, and result view.
- Execute the selection or buffer against the session connection.
- Close only Dbee-owned windows when the session closes and return focus to the SQL buffer.
