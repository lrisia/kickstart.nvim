-- Inline git diff with auto-toggle overlay based on neo-tree git_status
-- Part of mini.nvim — depends on mini.nvim being loaded first

return {
  'nvim-mini/mini.nvim',
  optional = true,
  config = function()
    require('mini.diff').setup()

    local group = vim.api.nvim_create_augroup('MiniDiffNeoTreeIntegration', { clear = true })
    local in_git_status_mode = false

    local function set_overlay_all(enable)
      local mini_diff = require('mini.diff')
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' then
          local buf_data = mini_diff.get_buf_data(buf)
          if buf_data then
            local is_on = buf_data.overlay
            if (enable and not is_on) or (not enable and is_on) then
              pcall(mini_diff.toggle_overlay, buf)
            end
          end
        end
      end
    end

    -- Source detection by scanning windows for an actual neo-tree buffer.
    -- More reliable than state.winid (which gets stale when neo-tree's window
    -- gets a non-neotree buffer, e.g. via hijack_netrw_behavior='open_current').
    local function get_visible_neotree_source()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == 'neo-tree' then
          local name = vim.api.nvim_buf_get_name(buf)
          local src = name:match 'neo%-tree%s+([%w_]+)'
          if src then return src end
        end
      end
      return nil
    end

    local function enable_overlay(buf, retries)
      if not vim.api.nvim_buf_is_valid(buf) then return end
      if not in_git_status_mode then return end
      if vim.bo[buf].buftype ~= '' then return end
      local mini_diff = require('mini.diff')
      local buf_data = mini_diff.get_buf_data(buf)
      if buf_data then
        if not buf_data.overlay then pcall(mini_diff.toggle_overlay, buf) end
        return
      end
      if retries > 0 then vim.defer_fn(function() enable_overlay(buf, retries - 1) end, 100) end
    end

    local function sync_state()
      local visible = get_visible_neotree_source()
      if visible == 'git_status' and not in_git_status_mode then
        in_git_status_mode = true
        set_overlay_all(true)
      elseif visible == 'filesystem' and in_git_status_mode then
        in_git_status_mode = false
        set_overlay_all(false)
      end
      -- visible == nil → neo-tree closed; preserve mode and ensure current buffer matches
      if in_git_status_mode then enable_overlay(vim.api.nvim_get_current_buf(), 0) end
    end

    vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufEnter', 'WinClosed', 'WinEnter' }, {
      group = group,
      callback = function(args)
        vim.schedule(sync_state)
        if args.event ~= 'BufEnter' and args.event ~= 'BufWinEnter' then return end
        if vim.bo[args.buf].buftype ~= '' or vim.bo[args.buf].filetype == 'neo-tree' then return end
        -- mini.diff may attach AFTER our BufEnter; retry until data is ready
        vim.defer_fn(function() enable_overlay(args.buf, 5) end, 50)
      end,
    })

    -- Telescope picked a file → user is done with git review, force-disable overlays
    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'TelescopeFileOpened',
      callback = function()
        if in_git_status_mode then
          in_git_status_mode = false
          set_overlay_all(false)
        end
      end,
    })

    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'MiniDiffUpdated',
      callback = function(args)
        if not in_git_status_mode then return end
        local mini_diff = require('mini.diff')
        local buf_data = mini_diff.get_buf_data(args.buf)
        if buf_data and not buf_data.overlay then
          pcall(mini_diff.toggle_overlay, args.buf)
        end
      end,
    })

    vim.keymap.set('n', '<leader>go', function()
      local mini_diff = require('mini.diff')
      local buf = vim.api.nvim_get_current_buf()
      local buf_data = mini_diff.get_buf_data(buf)
      if not buf_data then
        vim.notify('mini.diff: buffer ยังไม่พร้อม', vim.log.levels.WARN)
        return
      end
      -- Disabling: exit auto-mode FIRST so MiniDiffUpdated won't snap it back on
      if buf_data.overlay then in_git_status_mode = false end
      mini_diff.toggle_overlay(buf)
    end, { desc = '[G]it [O]verlay toggle' })
  end,
}
