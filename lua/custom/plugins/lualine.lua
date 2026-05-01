-- lualine replaces kickstart's mini.statusline with a more polished bottom
-- bar that surfaces git/diagnostics/lsp info alongside mode and position.
--
-- The `:LualineStyle <rounded|slant|plain|subtle>` user command swaps
-- separator presets at runtime so the look can be A/B-tested without a
-- restart. Tab-complete is wired up.

return {
  'nvim-lualine/lualine.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    -- Powerline glyphs encoded as UTF-8 byte escapes so the literal chars
    -- survive transit through tools that strip Private Use Area codepoints.
    --   \xee\x82\xb0 = U+E0B0 (slant right)         \xee\x82\xb2 = U+E0B2 (slant left)
    --   \xee\x82\xb1 = U+E0B1 (slant right line)    \xee\x82\xb3 = U+E0B3 (slant left line)
    --   \xee\x82\xb4 = U+E0B4 (rounded right thick) \xee\x82\xb6 = U+E0B6 (rounded left thick)
    --   \xee\x82\xb5 = U+E0B5 (rounded right thin)  \xee\x82\xb7 = U+E0B7 (rounded left thin)
    local separators = {
      rounded = {
        section = { left = '', right = '' },
        component = { left = '|', right = '|' },
      },
      slant = {
        section = { left = '', right = '' },
        component = { left = '|', right = '|' },
      },
      plain = {
        section = { left = '', right = '' },
        component = { left = '', right = '' },
      },
      subtle = {
        section = { left = '', right = '' },
        component = { left = '│', right = '│' },
      },
    }

    -- Make the middle (c) section transparent across all modes. Two layers
    -- need clearing: the per-mode lualine_c_* groups (the section itself)
    -- and the underlying StatusLine group (which fills the gap between c
    -- and x). `vim.cmd 'hi'` only changes bg, preserving fg — unlike
    -- nvim_set_hl which would replace the whole highlight.
    local function transparent_middle()
      local modes = { 'normal', 'insert', 'visual', 'replace', 'command', 'inactive', 'terminal' }
      for _, mode in ipairs(modes) do
        vim.cmd('hi lualine_c_' .. mode .. ' guibg=NONE')
      end
      vim.cmd 'hi StatusLine guibg=NONE'
      vim.cmd 'hi StatusLineNC guibg=NONE'
    end

    local function build_opts(style)
      local sep = separators[style]
      return {
        options = {
          theme = 'auto',
          globalstatus = true,
          section_separators = sep.section,
          component_separators = sep.component,
          disabled_filetypes = { statusline = { 'neo-tree', 'aerial' } },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff' },
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = { 'diagnostics', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
      }
    end

    require('lualine').setup(build_opts 'slant')
    transparent_middle()

    -- Re-apply transparency whenever the colorscheme changes (or lualine
    -- re-runs setup) — those events overwrite the lualine_c_* highlights.
    vim.api.nvim_create_autocmd('ColorScheme', {
      callback = transparent_middle,
    })

    vim.api.nvim_create_user_command('LualineStyle', function(args)
      local style = args.args
      if not separators[style] then
        vim.notify('Pick one: rounded | slant | plain | subtle', vim.log.levels.WARN)
        return
      end
      require('lualine').setup(build_opts(style))
      transparent_middle()
      vim.cmd 'redrawstatus!'
      local s = separators[style]
      vim.notify(
        string.format(
          'Lualine: %s\nsection: [%s] [%s]\ncomponent: [%s] [%s]',
          style,
          s.section.left,
          s.section.right,
          s.component.left,
          s.component.right
        )
      )
    end, {
      nargs = 1,
      complete = function()
        return { 'rounded', 'slant', 'plain', 'subtle' }
      end,
    })
  end,
}
