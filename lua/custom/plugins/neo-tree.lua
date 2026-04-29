-- Neo-tree customizations layered on top of the upstream kickstart spec.
--
-- Adds:
--   - smart `\` toggle: closes diffview if open, otherwise toggles neo-tree
--     and remembers the last source so re-opening lands you back where you were
--   - source selector winbar with Files / Git tabs
--   - filesystem niceties (hijack netrw, follow current file, libuv watcher,
--     show hidden files)
--   - close-on-open: opening a file closes the tree
--   - transparent backgrounds + theme-aware tab colors that re-apply on
--     every ColorScheme change
--   - auto-open neo-tree (fullscreen) when nvim lands on an empty unnamed
--     buffer, so the user never sees `[No Name]`
--   - redirect: entering the git_status source bounces over to diffview
--
-- lazy.nvim merges this spec with the upstream one in
-- `lua/kickstart/plugins/neo-tree.lua` (matched by the plugin URL). Only
-- specify what we want to add or override here.

-- ---------------------------------------------------------------------------
-- Module-level helpers and toggle.
--
-- Defined outside `config = function()` so they can also be referenced from
-- `opts.window.mappings`, which is built before `config` runs. This is how
-- we override neo-tree's buffer-local `\ → close_window` mapping with our
-- own smart toggle (which has the bare-nvim flash guard).
-- ---------------------------------------------------------------------------

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

-- Open the tree. Picks layout based on whether the *current window* shows a
-- real file: empty / `[No Name]` window → fullscreen takeover so the user
-- never has to look at `[No Name]`; a real file → sidebar so the file stays
-- visible.
--
-- We check the current window rather than `has_any_real_buffer()` because
-- after `DiffviewClose` the file buffers diffview loaded are still listed
-- even though the user is back on `[No Name]` — the global check would say
-- "real buffers exist" and we'd wrongly pick sidebar mode for an empty pane.
--
-- The defensive `close` first is to handle sequences like `>` (cycle to
-- git_status → diffview redirect) → `\` (close diffview → open tree) where
-- a previous neo-tree window can still be lingering. Without it we end up
-- with two trees side-by-side.
local function current_window_shows_real_file()
  local buf = vim.api.nvim_get_current_buf()
  return vim.bo[buf].buflisted
    and vim.bo[buf].buftype == ''
    and vim.api.nvim_buf_get_name(buf) ~= ''
end

local function open_tree()
  pcall(function() require('neo-tree.command').execute { action = 'close' } end)

  local last = vim.g.neotree_last_source or 'filesystem'
  if not current_window_shows_real_file() then
    vim.cmd 'Neotree position=current source=filesystem reveal'
  elseif last == 'filesystem' then
    vim.cmd 'Neotree reveal source=filesystem'
  else
    vim.cmd('Neotree focus source=' .. last)
  end
end

local function maybe_auto_open()
  if is_empty_buffer(vim.api.nvim_get_current_buf()) and not has_any_real_buffer() then
    open_tree()
  end
end

-- Smart `\` toggle. Used for both the global keymap and as the buffer-local
-- `\` mapping inside neo-tree windows (see opts.window.mappings below) so
-- the bare-nvim flash guard works no matter where the keypress comes from.
local function smart_toggle()
  -- Case 1: inside a diffview tab → close diffview, reopen tree.
  -- Defer open_tree to the next tick so DiffviewClose's async cleanup
  -- (tab-close, buffer wipeout) finishes before we try to draw the tree.
  local ok_dv, dv_lib = pcall(require, 'diffview.lib')
  if ok_dv and dv_lib.get_current_view() then
    vim.cmd 'DiffviewClose'
    vim.schedule(open_tree)
    return
  end
  -- Case 2: neo-tree visible → close it. Skip if there's no real buffer to
  -- fall back on — closing would land on `[No Name]` and the auto-open
  -- autocmd would just bounce the tree right back, causing a flash.
  local manager = require 'neo-tree.sources.manager'
  local renderer = require 'neo-tree.ui.renderer'
  for _, src in ipairs { 'filesystem', 'git_status' } do
    local state = manager.get_state(src)
    if state and renderer.window_exists(state) then
      if not has_any_real_buffer() then return end
      require('neo-tree.command').execute { action = 'close' }
      return
    end
  end
  -- Case 3: nothing open → reveal neo-tree
  open_tree()
end

---@module 'lazy'
---@type LazySpec
return {
  'nvim-neo-tree/neo-tree.nvim',
  ---@module 'neo-tree'
  ---@type neotree.Config
  opts = {
    window = {
      mappings = {
        -- Route buffer-local `\` through smart_toggle instead of neo-tree's
        -- built-in `close_window` so the flash guard runs.
        ['\\'] = smart_toggle,
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
      -- Override upstream's `filesystem.window.mappings.\\ = close_window`
      -- (set in lua/kickstart/plugins/neo-tree.lua). Source-specific mappings
      -- win over the global `window.mappings` above, so we have to override
      -- here too to keep the smart toggle in effect for the filesystem source.
      window = {
        mappings = {
          ['\\'] = smart_toggle,
        },
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

    -- Global `\` keymap. Overrides upstream's plain `:Neotree reveal` mapping.
    -- Set inside config so this override is guaranteed to win regardless of
    -- how lazy.nvim merges the `keys` lists from the two specs.
    vim.keymap.set('n', '\\', smart_toggle, { desc = 'NeoTree / Diffview toggle', silent = true })

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

    -- Auto-open the tree (fullscreen) when the user lands on an empty unnamed
    -- buffer with no real file buffers anywhere — bare `nvim`, after closing
    -- the last buffer, etc. The user explicitly never wants to see `[No Name]`.
    --
    -- One-shot check for the bare-nvim startup case: lazy=false plugins load
    -- *during* VimEnter, so a VimEnter autocmd registered here would miss the
    -- event entirely. Run the check directly on the next tick instead.
    vim.schedule(maybe_auto_open)

    -- BufEnter handles the runtime case: e.g. after `:bd` of the last real
    -- buffer the user lands on `[No Name]` and we want the tree to fill in.
    -- The smart `\` toggle is responsible for not creating a flash by refusing
    -- to close when there's nothing to fall back to.
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('NeotreeAutoOpenWhenEmpty', { clear = true }),
      callback = function(ev)
        if not is_empty_buffer(ev.buf) then return end
        if has_any_real_buffer() then return end
        vim.schedule(maybe_auto_open)
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
