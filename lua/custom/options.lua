-- vim option overrides that don't fit cleanly into a plugin spec or keymap
-- file. Kept separate so kickstart's `init.lua` stays clean for upstream
-- pulls.

-- Hide the tabline. Vim's default tabline format renders buffer names raw,
-- which surfaces ugly URI-style strings like `diffview:///panels/0/...` when
-- diffview opens its tab. Until/unless we install bufferline.nvim (which
-- replaces tabline rendering entirely), it's nicer to just not show it.
vim.opt.showtabline = 0

-- Disable netrw entirely. neo-tree hijacks netrw via `hijack_netrw_behavior`
-- so we don't want netrw loaded at all — saves a bit of startup time and
-- avoids the chance of a stray `:Explore` opening netrw instead of neo-tree.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Default border for floating windows (LSP hover, signature help, diagnostic
-- floats, :Lazy, :Mason, etc). Plugins that explicitly set their own border
-- still win; this only fills in the default.
vim.o.winborder = 'rounded'
