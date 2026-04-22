-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

---@module 'lazy'
---@type LazySpec
return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  ---@module 'neo-tree'
  ---@type neotree.Config
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
      hijack_netrw_behavior = 'open_current',
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = true,
      },
    },
  },
  config = function(_, opts)
    require('neo-tree').setup(opts)

    -- make neo-tree background transparent
    local function set_transparent()
      vim.api.nvim_set_hl(0, 'NeoTreeNormal', { bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'NeoTreeNormalNC', { bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'NeoTreeEndOfBuffer', { bg = 'NONE' })
    end

    set_transparent()

    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = '*',
      callback = set_transparent,
    })
  end,
}
