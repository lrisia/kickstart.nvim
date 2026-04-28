-- Side-by-side git review via diffview.nvim
-- Triggered manually with <leader>g{d,h,H} or by entering neo-tree's Git tab
-- (see kickstart/plugins/neo-tree.lua for the redirect autocmd).
return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory', 'DiffviewToggleFiles', 'DiffviewFocusFiles' },
  keys = {
    { '<leader>gd', '<cmd>DiffviewOpen<CR>', desc = '[G]it [D]iff (working tree vs HEAD)' },
    { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = '[G]it [H]istory (current file)' },
    { '<leader>gH', '<cmd>DiffviewFileHistory<CR>', desc = '[G]it [H]istory (whole repo)' },
  },
  config = function() require('diffview').setup() end,
}
