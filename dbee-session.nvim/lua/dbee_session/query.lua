local M = {}

local function join_nonempty(lines)
  local text = table.concat(lines or {}, "\n")
  if text:match("^%s*$") then
    return nil
  end

  return text
end

function M.from_buffer(bufnr, selected_lines)
  return join_nonempty(selected_lines) or join_nonempty(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) or ""
end

return M
