-- Telescope customizations layered on top of the upstream kickstart spec.
--
-- We don't touch `init.lua` so a `git pull` from kickstart stays clean.
-- Kickstart's telescope spec uses `config = function()` with a hardcoded
-- `setup{}`, so `opts`-merging won't work — instead we hook `User VeryLazy`
-- (which fires after VimEnter, after kickstart's config has already set the
-- baseline keymap) and override `<leader><leader>` with a wrapped version
-- that adds `dd` to delete a buffer inside the picker.
--
-- lazy.nvim merges this spec with the upstream one in `init.lua` (matched by
-- the plugin URL). Only specify what we want to add or override here.

return {
  'nvim-telescope/telescope.nvim',
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      once = true,
      callback = function()
        local builtin = require 'telescope.builtin'
        local actions = require 'telescope.actions'

        -- Re-run setup to override kickstart's hardcoded borderchars with
        -- rounded corners. Telescope's setup deep-merges defaults, so only
        -- this key changes — everything else from kickstart stays intact.
        require('telescope').setup {
          defaults = {
            borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
          },
        }

        vim.keymap.set('n', '<leader><leader>', function()
          builtin.buffers {
            attach_mappings = function(_, map)
              map('n', 'dd', actions.delete_buffer, { desc = 'Delete buffer' })
              return true
            end,
          }
        end, { desc = '[ ] Find existing buffers' })
      end,
    })
  end,
}
