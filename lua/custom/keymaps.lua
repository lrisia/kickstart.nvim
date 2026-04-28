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

-- Quit confirmation modal
local quick_quit = require 'custom.quick_quit'
vim.keymap.set('n', '<leader>q', quick_quit.modal, { desc = 'Quit nvim' })
vim.keymap.set('n', '<leader>ๆ', quick_quit.modal, { desc = 'Quit nvim (Thai char)' })
