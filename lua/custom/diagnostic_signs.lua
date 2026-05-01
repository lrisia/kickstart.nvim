-- Override the diagnostic gutter signs to use Codicon icons instead of the
-- default `E`/`W`/`I`/`H` letters. Kickstart calls `vim.diagnostic.config`
-- in init.lua but doesn't specify `signs.text` — calling config again here
-- with just that key deep-merges, leaving everything else (virtual_text,
-- severity_sort, float border, etc) intact.
--
-- Same icons as lualine's diagnostic count for visual consistency.

vim.diagnostic.config {
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '\xee\xaa\x87', -- U+EA87 codicon-error
      [vim.diagnostic.severity.WARN] = '\xee\xa9\xac', -- U+EA6C codicon-warning
      [vim.diagnostic.severity.INFO] = '\xee\xa9\xb4', -- U+EA74 codicon-info
      [vim.diagnostic.severity.HINT] = '\xee\xa9\xa1', -- U+EA61 codicon-lightbulb
    },
  },
}
