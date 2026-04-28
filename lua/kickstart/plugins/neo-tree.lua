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
        -- Case 1: inside a diffview tab → close diffview
        local ok_dv, dv_lib = pcall(require, 'diffview.lib')
        if ok_dv and dv_lib.get_current_view() then
          vim.cmd 'DiffviewClose'
          return
        end
        -- Case 2: neo-tree visible → close it
        local manager = require 'neo-tree.sources.manager'
        local renderer = require 'neo-tree.ui.renderer'
        for _, src in ipairs { 'filesystem', 'git_status' } do
          local state = manager.get_state(src)
          if state and renderer.window_exists(state) then
            require('neo-tree.command').execute { action = 'close' }
            return
          end
        end
        -- Case 3: nothing open → reveal neo-tree with last source
        local last = vim.g.neotree_last_source or 'filesystem'
        if last == 'filesystem' then
          vim.cmd 'Neotree reveal source=filesystem'
        else
          vim.cmd('Neotree focus source=' .. last)
        end
      end,
      desc = 'NeoTree / Diffview toggle',
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
        -- Bypass loading git_status: jump straight to diffview
        ['>'] = function()
          vim.schedule(function()
            pcall(require('neo-tree.command').execute, { action = 'close' })
            vim.cmd 'DiffviewOpen'
          end)
        end,
        ['<'] = function()
          vim.schedule(function()
            pcall(require('neo-tree.command').execute, { action = 'close' })
            vim.cmd 'DiffviewOpen'
          end)
        end,
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

    -- Redirect: entering neo-tree's git_status (via Git tab click or `>`) → close
    -- neo-tree and open diffview instead. Reset last_source to filesystem so the
    -- next `\` opens Files, not the redirect again.
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('NeotreeGitToDiffview', { clear = true }),
      callback = function(ev)
        if vim.bo[ev.buf].filetype ~= 'neo-tree' then return end
        local name = vim.api.nvim_buf_get_name(ev.buf)
        if not name:match 'neo%-tree%s+git_status%s+%[' then return end
        vim.schedule(function()
          pcall(require('neo-tree.command').execute, { action = 'close' })
          vim.g.neotree_last_source = 'filesystem'
          vim.cmd 'DiffviewOpen'
        end)
      end,
    })

    -- Auto-open neo-tree fullscreen when the user lands on an empty unnamed
    -- buffer with no real file buffers anywhere (bare `nvim`, after closing
    -- the last buffer, after exiting diffview, etc.). hijack_netrw_behavior
    -- = 'open_current' makes it take over the current window = fullscreen.
    local function is_empty_buffer(buf)
      if vim.api.nvim_buf_get_name(buf) ~= '' then return false end
      if vim.bo[buf].buftype ~= '' then return false end
      if vim.api.nvim_buf_line_count(buf) > 1 then return false end
      return (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or '') == ''
    end
    local function has_any_real_buffer()
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if
          vim.api.nvim_buf_is_loaded(b)
          and vim.bo[b].buflisted
          and vim.bo[b].buftype == ''
          and vim.api.nvim_buf_get_name(b) ~= ''
        then
          return true
        end
      end
      return false
    end
    vim.api.nvim_create_autocmd({ 'VimEnter', 'BufEnter' }, {
      group = vim.api.nvim_create_augroup('NeotreeAutoOpenWhenEmpty', { clear = true }),
      callback = function(ev)
        if not is_empty_buffer(ev.buf) then return end
        if has_any_real_buffer() then return end
        vim.schedule(function()
          if is_empty_buffer(vim.api.nvim_get_current_buf()) and not has_any_real_buffer() then
            vim.cmd 'Neotree reveal source=filesystem'
          end
        end)
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
