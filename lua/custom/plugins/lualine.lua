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
        section = { left = '\xee\x82\xb4', right = '\xee\x82\xb6' },
        component = { left = '|', right = '|' },
      },
      slant = {
        section = { left = '\xee\x82\xb0', right = '\xee\x82\xb2' },
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
      local sections = { 'c', 'x' }
      local severities = { 'error', 'warn', 'info', 'hint' }
      for _, sec in ipairs(sections) do
        for _, mode in ipairs(modes) do
          vim.cmd('hi lualine_' .. sec .. '_' .. mode .. ' guibg=NONE')
          -- diagnostics component creates per-severity groups that override
          -- the section bg — clear those too.
          for _, sev in ipairs(severities) do
            vim.cmd('hi lualine_' .. sec .. '_diagnostics_' .. sev .. '_' .. mode .. ' guibg=NONE')
          end
        end
      end
      vim.cmd 'hi StatusLine guibg=NONE'
      vim.cmd 'hi StatusLineNC guibg=NONE'
    end

    -- Names of LSP clients attached to the current buffer, prefixed by a
    -- gear icon. In-memory lookup, safe to call on every refresh.
    local function lsp_name()
      local clients = vim.lsp.get_clients { bufnr = 0 }
      if #clients == 0 then
        return ''
      end
      local names = {}
      for _, c in ipairs(clients) do
        table.insert(names, c.name)
      end
      return '\xef\x82\x85  ' .. table.concat(names, ', ')
    end

    -- Active Python virtualenv name. Reads $VIRTUAL_ENV — pure env var
    -- lookup, no filesystem I/O, no caching needed.
    local function python_venv()
      if vim.bo.filetype ~= 'python' then
        return ''
      end
      local venv = os.getenv 'VIRTUAL_ENV'
      if not venv then
        return ''
      end
      return '  ' .. vim.fn.fnamemodify(venv, ':t')
    end

    local function build_opts(style)
      local sep = separators[style]
      return {
        options = {
          theme = 'auto',
          globalstatus = true,
          section_separators = sep.section,
          component_separators = sep.component,
          disabled_filetypes = { statusline = { 'neo-tree' } },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff' },
          lualine_c = {
            { 'filetype', icon_only = true, padding = { left = 1, right = 0 }, separator = '', color = { bg = 'NONE' } },
            { 'filename', path = 1, padding = { left = 0, right = 1 } },
          },
          lualine_x = {
            {
              'diagnostics',
              symbols = {
                error = '\xee\xaa\x87 ', -- U+EA87 codicon-error
                warn = '\xee\xa9\xac ', -- U+EA6C codicon-warning
                info = '\xee\xa9\xb4 ', -- U+EA74 codicon-info
                hint = '\xee\xa9\xa1 ', -- U+EA61 codicon-lightbulb
              },
            },
            lsp_name,
            python_venv,
          },
          lualine_y = {},
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
