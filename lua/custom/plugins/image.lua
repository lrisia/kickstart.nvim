-- Render image files (PNG/JPG/GIF/WebP/AVIF) inline in nvim buffers using
-- Ghostty's Kitty graphics protocol support. Opening any image file via
-- :edit or neo-tree shows the picture instead of binary garbage.
return {
  '3rd/image.nvim',
  -- Default `magick_rock` processor needs luarocks; we skip that complexity
  -- and use the ImageMagick CLI directly (installed via brew).
  opts = {
    backend = 'kitty',
    processor = 'magick_cli',
    integrations = {
      -- We only want buffer-level image preview for now. Markdown inline
      -- rendering is a separate concern — leave it off so this plugin
      -- doesn't activate every time we edit a .md file.
      markdown = { enabled = false },
      neorg = { enabled = false },
    },
    -- Cap how big a single image renders so a huge PNG doesn't take over
    -- the screen. 80% of window height is a reasonable ceiling.
    max_height_window_percentage = 80,
    -- Hide images when another window covers them (e.g. opening a split
    -- on top of an image preview).
    window_overlap_clear_enabled = true,
  },
}
