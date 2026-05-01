-- Override blink.cmp's default kind icons with Codicons. Maple Mono NF
-- renders Codicon glyphs cleanly (proven by the lualine diagnostic + LSP
-- name icons), so we stick with that family for visual consistency across
-- the menu, statusline, and diagnostic gutter.
--
-- Using `vim.fn.nr2char` keeps the table readable — the codepoint number
-- stays inline with each kind name rather than buried in a byte escape.

return {
  'saghen/blink.cmp',
  opts = function(_, opts)
    local function icon(cp)
      return vim.fn.nr2char(cp)
    end

    opts.appearance = opts.appearance or {}
    opts.appearance.kind_icons = {
      Text = icon(0xea93),
      Method = icon(0xea8c),
      Function = icon(0xea8c),
      Constructor = icon(0xea8c),
      Field = icon(0xeb5f),
      Variable = icon(0xea88),
      Property = icon(0xeb65),
      Class = icon(0xeb5b),
      Interface = icon(0xeb61),
      Struct = icon(0xea91),
      Module = icon(0xea8b),
      Unit = icon(0xea96),
      Value = icon(0xea95),
      Enum = icon(0xea95),
      EnumMember = icon(0xeb5e),
      Keyword = icon(0xeb62),
      Constant = icon(0xeb5d),
      Snippet = icon(0xeb66),
      Color = icon(0xeb5c),
      File = icon(0xeb60),
      Reference = icon(0xea94),
      Folder = icon(0xea83),
      Event = icon(0xea86),
      Operator = icon(0xeb64),
      TypeParameter = icon(0xea92),
    }

    return opts
  end,
}
