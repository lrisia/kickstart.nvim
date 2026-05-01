-- nvim-colorizer renders color literals (hex, rgb, hsl, tailwind classes) as
-- a small colored swatch next to the text — useful when editing CSS, Tailwind
-- in TS/JSX, or any file referencing color values.
--
-- `mode = 'virtualtext'` adds a `■` block after the literal instead of dyeing
-- the text/background, so it doesn't interfere with the surrounding syntax
-- highlighting.

return {
  'NvChad/nvim-colorizer.lua',
  event = { 'BufReadPost', 'BufNewFile' },
  opts = {
    user_default_options = {
      tailwind = true,
      RGB = true,
      RRGGBB = true,
      RRGGBBAA = true,
      names = false,
      mode = 'virtualtext',
    },
    filetypes = {
      '*',
      css = { css = true, css_fn = true },
      html = { names = true },
    },
  },
}
