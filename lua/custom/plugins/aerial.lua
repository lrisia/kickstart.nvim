-- Aerial is outliner on side bar using LSP
-- https://github.com/stevearc/aerial.nvim

return {
  'stevearc/aerial.nvim',
  opts = {
    close_on_select = true,
  },
  -- Optional dependencies
  dependencies = {
     "nvim-treesitter/nvim-treesitter",
     "nvim-tree/nvim-web-devicons"
  },
  keys = {
    { '<leader>o', '<cmd>AerialToggle<CR>', desc = '[O]utline toggle (Aerial)' },
    { '{', '<cmd>AerialPrev<CR>', desc = 'Aerial prev symbol' },
    { '}', '<cmd>AerialNext<CR>', desc = 'Aerial next symbol' },
  },
}
