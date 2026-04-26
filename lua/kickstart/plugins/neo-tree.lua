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
    {
      '\\',
      function()
        local manager = require 'neo-tree.sources.manager'
        local renderer = require 'neo-tree.ui.renderer'
        for _, src in ipairs { 'filesystem', 'git_status' } do
          local state = manager.get_state(src)
          if state and renderer.window_exists(state) then
            require('neo-tree.command').execute { action = 'close' }
            return
          end
        end
        local last = vim.g.neotree_last_source or 'filesystem'
        if last == 'filesystem' then
          vim.cmd 'Neotree reveal source=filesystem'
        else
          vim.cmd('Neotree focus source=' .. last)
        end
      end,
      desc = 'NeoTree toggle',
      silent = true,
    },
  },
  ---@module 'neo-tree'
  ---@type neotree.Config
  opts = {
    window = {
      mappings = {
        ['\\'] = 'close_window',
        ['<space>'] = 'none',
      },
    },
    filesystem = {
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
    sources = { 'filesystem', 'git_status' },
    source_selector = {
      truncation_character = '...',
      winbar = true,
      statusline = false,
      content_layout = 'center',
      tabs_layout = 'equal',
      padding = { left = 1, right = 1 },
      separator = { left = '', right = '  ' },
      show_separator_on_edge = false,
      sources = {
        { source = 'filesystem', display_name = '\u{f024b} Files' },
        { source = 'git_status', display_name = '\u{f02a2} Git' },
      },
    },
    event_handlers = {
      {
        event = 'file_opened',
        handler = function(file_path) require('neo-tree.command').execute { action = 'close' } end,
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

    -- tab colors pulled from the current colorscheme (theme-agnostic)
    local function apply_neotree_tabs()
      local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
      local comment = vim.api.nvim_get_hl(0, { name = 'Comment', link = false })

      local fg_main = normal.fg
      local fg_dim = comment.fg

      vim.api.nvim_set_hl(0, 'WinBar', { bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'WinBarNC', { bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'NeoTreeTabActive', { fg = fg_main, bg = 'NONE', bold = true })
      vim.api.nvim_set_hl(0, 'NeoTreeTabSeparatorActive', { fg = fg_main, bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'NeoTreeTabInactive', { fg = fg_dim, bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'NeoTreeTabSeparatorInactive', { fg = fg_dim, bg = 'NONE' })
    end

    apply_neotree_tabs()

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'neo-tree',
      callback = function(ev)
        local function update()
          local name = vim.api.nvim_buf_get_name(ev.buf)
          local src = name:match 'neo%-tree%s+([%w_]+)%s+%['
          if src then
            vim.g.neotree_last_source = src
          end
        end
        update()
        vim.api.nvim_create_autocmd('BufEnter', {
          buffer = ev.buf,
          callback = update,
        })
      end,
    })

    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = '*',
      callback = function()
        set_transparent()
        apply_neotree_tabs()
      end,
    })
  end,
}
