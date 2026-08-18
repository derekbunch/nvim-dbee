if vim.g.loaded_dbee_session == 1 then
  return
end
vim.g.loaded_dbee_session = 1

local function selected_lines(opts)
  if opts.range == 0 then
    return nil
  end

  return vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
end

vim.api.nvim_create_user_command("DbeeSessionOpen", function()
  require("dbee_session").open()
end, {})

vim.api.nvim_create_user_command("DbeeSessionClose", function()
  require("dbee_session").close()
end, {})

vim.api.nvim_create_user_command("DbeeSessionToggle", function()
  require("dbee_session").toggle()
end, {})

vim.api.nvim_create_user_command("DbeeSessionExecute", function(opts)
  require("dbee_session").execute(selected_lines(opts))
end, { range = true })

vim.api.nvim_create_user_command("DbeeSessionRefreshSchema", function()
  require("dbee_session").refresh_schema()
end, {})
