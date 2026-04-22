-- ~/.config/nvim/lua/keymaps.lua

-- MacOS native copy / undo / redo
vim.keymap.set({ 'n', 'i', 'v' }, '<D-c>', 'y', { desc = 'Copy with MacOs native key' })
vim.keymap.set({ 'n', 'i', 'v' }, '<D-แ>', 'y', { desc = 'Copy with MacOs native key (Thai char)' })
vim.keymap.set('n', '<D-z>', '<Undo>', { desc = 'Undo with MacOS native key' })
vim.keymap.set('n', '<D-ผ>', '<Undo>', { desc = 'Undo with MacOS native key (Thai char)' })
vim.keymap.set('n', '<D-Z>', '<C-r>', { desc = 'Redo with MacOS native key' })
vim.keymap.set('n', '<D-(>', '<C-r>', { desc = 'Redo with MacOS native key (Thai char)' })
vim.keymap.set({ 'n', 'i' }, '<D-A>', 'ggVG', { desc = 'Select all with MacOs native key' })
vim.keymap.set({ 'n', 'i' }, '<D-ฤ>', 'ggVG', { desc = 'Select all with MacOs native key (Thai char)' })

-- Override default 'd' key behavior
vim.keymap.set({ 'n', 'v' }, 'd', '"_d', { desc = 'Delete without yanking' })
vim.keymap.set('n', 'dd', '"_dd', { desc = 'Delete line without yanking' })
vim.keymap.set({ 'n', 'v' }, 'D', '"_D', { desc = 'Delete to end without yanking' })
vim.keymap.set({ 'n', 'v' }, 'x', '"_x', { desc = 'Delete char without yanking' })
-- Use '<leader>' as a prefix instead to use old behavior
vim.keymap.set({ 'n', 'v' }, '<leader>d', 'd', { desc = 'Cut (delete + yank)' })
vim.keymap.set('n', '<leader>dd', 'dd', { desc = 'Cut line' })
vim.keymap.set({ 'n', 'v' }, '<leader>D', 'D', { desc = 'Cut to end of line' })

-- Add quit key
local quit_modal = function()
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    '',
    '  Press q again to quit',
    '  Any other key to cancel',
    '',
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  local width = 32
  local height = #lines
  local ui = vim.api.nvim_list_uis()[1]
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Quit? ',
    title_pos = 'center',
  })

  vim.schedule(function()
    local ok, char = pcall(vim.fn.getcharstr)
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    if ok and (char == 'q' or char == 'Q' or char == 'ๆ') then vim.cmd 'qa' end
  end)
end

vim.keymap.set('n', '<leader>q', quit_modal, { desc = 'Quit nvim' })
vim.keymap.set('n', '<leader>ๆ', quit_modal, { desc = 'Quit nvim (Thai char)' })
