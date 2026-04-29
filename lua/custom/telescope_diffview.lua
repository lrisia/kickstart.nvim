-- When telescope opens a file while diffview is showing, close diffview first
-- so the picked file lands fullscreen in the original tab — not crammed into
-- one of diffview's panes alongside leftover diff buffers.
--
-- Implementation: override the prompt buffer's local `<CR>` mapping inside
-- every TelescopePrompt buffer. We use a deferred `vim.schedule` so we set
-- our mapping AFTER telescope has set its own — buffer-local mappings are
-- last-write-wins, and that ordering guarantees ours runs.
--
-- Why not `actions.select_default:replace`? In practice the action-replacement
-- plumbing inside telescope was unreliable in this config (the picker still
-- ended up cramming the file alongside the diff panes). Owning the keymap
-- directly is more deterministic.

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('TelescopeDiffviewReplace', { clear = true }),
  pattern = 'TelescopePrompt',
  callback = function(ev)
    local bufnr = ev.buf
    -- Defer until after telescope has finished wiring up its own mappings on
    -- this prompt buffer; otherwise telescope's later write would clobber ours.
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(bufnr) then return end

      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      local function tab_has_diffview()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local b = vim.api.nvim_win_get_buf(win)
          local n = vim.api.nvim_buf_get_name(b)
          if n:match '^diffview://' or n:match '^git:' then return true end
          local ft = vim.bo[b].filetype
          if ft and ft:match '^Diffview' then return true end
        end
        return false
      end

      local function diffview_aware_select()
        local entry = action_state.get_selected_entry()
        local path = entry and (entry.path or entry.filename)

        -- Non-file pickers and the no-diffview case → telescope's default.
        if not (path and tab_has_diffview()) then
          actions.select_default(bufnr)
          return
        end

        -- Close picker, close diffview tab, then open the picked file in the
        -- now-clean original tab. Schedule the edit so DiffviewClose has time
        -- to fully restore the original tab's window layout.
        pcall(actions.close, bufnr)
        pcall(vim.cmd, 'DiffviewClose')
        vim.g.neotree_last_source = 'filesystem'
        vim.schedule(function() pcall(vim.cmd, 'edit ' .. vim.fn.fnameescape(path)) end)
      end

      vim.keymap.set('i', '<CR>', diffview_aware_select, { buffer = bufnr, silent = true })
      vim.keymap.set('n', '<CR>', diffview_aware_select, { buffer = bufnr, silent = true })
    end)
  end,
})
