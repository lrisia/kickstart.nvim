-- Switch the project-wide icon provider from nvim-web-devicons to mini.icons
-- without touching the upstream kickstart mini.nvim spec. We hook on
-- `User VeryLazy` so this runs after kickstart's `require('mini.ai').setup()`
-- etc. have already loaded the mini.* modules, then mock nvim-web-devicons
-- so neo-tree / telescope / lualine pick up mini.icons transparently.
return {
  'nvim-mini/mini.nvim',
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      once = true,
      callback = function()
        require('mini.icons').setup()
        MiniIcons.mock_nvim_web_devicons()
      end,
    })
  end,
}
