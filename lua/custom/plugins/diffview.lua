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
  config = function()
    -- Mouse-wheel handler that syncs every diff pane in the current tab when
    -- the wheel is rolled over any of them — independent of where the cursor
    -- actually sits. Outside diffview tabs (no diff windows), it degrades to
    -- default behavior (scroll just the window under the mouse).
    --
    -- This exists because vim's built-in `scrollbind` only fires when the
    -- *active* window is the one being scrolled. The workflow here parks the
    -- cursor on the file panel sidebar (Tab to switch files), so wheel-
    -- scrolling a diff pane otherwise wouldn't propagate to its sibling.
    local function wheel(direction)
      return function()
        local mouse_win = vim.fn.getmousepos().winid
        if mouse_win == 0 then return end

        local diff_wins, mouse_on_diff = {}, false
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.wo[w].diff then
            table.insert(diff_wins, w)
            if w == mouse_win then mouse_on_diff = true end
          end
        end

        local key = vim.api.nvim_replace_termcodes(direction == 'down' and '3<C-e>' or '3<C-y>', true, false, true)
        local targets = (mouse_on_diff and #diff_wins > 1) and diff_wins or { mouse_win }
        for _, w in ipairs(targets) do
          vim.api.nvim_win_call(w, function() vim.cmd('normal! ' .. key) end)
        end
      end
    end

    vim.keymap.set({ 'n', 'v' }, '<ScrollWheelDown>', wheel 'down', { desc = 'Wheel down (sync diff panes)' })
    vim.keymap.set({ 'n', 'v' }, '<ScrollWheelUp>', wheel 'up', { desc = 'Wheel up (sync diff panes)' })

    require('diffview').setup {
      -- Sync scroll + cursor between the old/new diff panes when keyboard-
      -- driven (j/k, <C-d>, etc.) — scrollbind alone covers that case once
      -- the active window is one of the panes. The wheel-handler above
      -- covers the cursor-on-sidebar case.
      hooks = {
        diff_buf_win_enter = function()
          vim.opt_local.scrollbind = true
          vim.opt_local.cursorbind = true
        end,
      },
    }
  end,
}
