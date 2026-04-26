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

    local function is_git_status_visible()
      local ok_mgr, manager = pcall(require, 'neo-tree.sources.manager')
      local ok_rdr, renderer = pcall(require, 'neo-tree.ui.renderer')
      if not (ok_mgr and ok_rdr) then return false end
      local state = manager.get_state('git_status')
      return state and renderer.window_exists(state) or false
    end

    vim.api.nvim_create_autocmd('BufEnter', {
      group = group,
      callback = function()
        if vim.bo.filetype ~= 'neo-tree' then return end
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname:match('git_status') then
          in_git_status_mode = true
          set_overlay_all(true)
          return
        end
        -- Defer disable: if neo-tree is closing or user ended up off git_status,
        -- a transient filesystem-buffer enter shouldn't kill overlays.
        vim.schedule(function()
          if vim.bo.filetype == 'neo-tree' and not is_git_status_visible() then
            in_git_status_mode = false
            set_overlay_all(false)
          end
        end)
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
      if mini_diff.get_buf_data(buf) then
        mini_diff.toggle_overlay(buf)
        local buf_data = mini_diff.get_buf_data(buf)
        if buf_data and not buf_data.overlay then
          in_git_status_mode = false
        end
      else
        vim.notify('mini.diff: buffer ยังไม่พร้อม', vim.log.levels.WARN)
      end
    end, { desc = '[G]it [O]verlay toggle' })
  end,
}