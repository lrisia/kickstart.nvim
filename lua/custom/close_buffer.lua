-- Buffer-close helpers used by the <leader>b{d,D,A} keymaps in keymaps.lua.
--
-- Plain `:bd` closes the *window* showing the buffer, which is rarely what we
-- want — we switch to the alternate buffer first, then delete the original,
-- so splits/sidebars stay put. The bulk variants iterate listed buffers and
-- skip ones that fail to delete (e.g. modified without `force`) on purpose,
-- so unsaved work isn't silently dropped.

local M = {}

-- Close the current buffer while keeping the window/split open. Falls back to
-- a fresh empty buffer when there's no usable alternate.
function M.current()
  local cur = vim.api.nvim_get_current_buf()
  local alt = vim.fn.bufnr '#'
  if alt ~= -1 and alt ~= cur and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buflisted then
    vim.cmd('buffer ' .. alt)
  else
    vim.cmd 'enew'
  end
  if vim.api.nvim_buf_is_valid(cur) then
    pcall(vim.api.nvim_buf_delete, cur, { force = false })
  end
end

function M.others()
  local cur = vim.api.nvim_get_current_buf()
  local count = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= cur and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      if pcall(vim.api.nvim_buf_delete, buf, { force = false }) then count = count + 1 end
    end
  end
  vim.notify('Closed ' .. count .. ' buffer(s)')
end

function M.all()
  local count = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      if pcall(vim.api.nvim_buf_delete, buf, { force = false }) then count = count + 1 end
    end
  end
  vim.notify('Closed ' .. count .. ' buffer(s)')
end

return M
