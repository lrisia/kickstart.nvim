-- Top-right toast: "Quit? press q" with 1-second total lifespan and fade-out.
-- Press q while it's visible (or fading) to confirm; any other key cancels.
-- Bound to <leader>q in custom/keymaps.lua.
local M = {}

local CONFIRM_KEYS = { q = true, Q = true, ['ๆ'] = true }
local VISIBLE_MS = 700
local FADE_MS = 300
local FADE_STEPS = 12
local active = false

function M.modal()
  -- Guard against re-entry while a toast is already up.
  if active then return end
  active = true

  local text = '  󰗼  Quit? press q  '
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local ui = vim.api.nvim_list_uis()[1]
  local width = vim.fn.strdisplaywidth(text)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = width,
    height = 1,
    row = 1,
    col = math.max(0, ui.width - width - 4),
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    noautocmd = true,
  })

  vim.api.nvim_set_option_value(
    'winhighlight',
    'NormalFloat:NormalFloat,FloatBorder:DiagnosticHint',
    { win = win }
  )
  vim.api.nvim_set_option_value('winblend', 0, { win = win })

  local done = false
  local ns_id
  local fade_timer
  local function close(quit)
    if done then return end
    done = true
    active = false
    if fade_timer then
      pcall(function() fade_timer:stop() end)
      pcall(function() fade_timer:close() end)
    end
    if ns_id then pcall(vim.on_key, nil, ns_id) end
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    if quit then vim.cmd 'qa' end
  end

  -- Listen for the next keypress without stealing focus.
  ns_id = vim.on_key(function(_, typed)
    if done then return end
    vim.schedule(function()
      if done then return end
      close(CONFIRM_KEYS[typed] == true)
    end)
  end)

  -- After the visible window, fade winblend 0 → 100 in small steps then close.
  vim.defer_fn(function()
    if done then return end
    local step_ms = math.max(1, math.floor(FADE_MS / FADE_STEPS))
    local step = 0
    fade_timer = vim.uv.new_timer()
    fade_timer:start(
      0,
      step_ms,
      vim.schedule_wrap(function()
        if done then return end
        step = step + 1
        local blend = math.min(100, math.floor(step * 100 / FADE_STEPS))
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_option_value('winblend', blend, { win = win })
        end
        if step >= FADE_STEPS then close(false) end
      end)
    )
  end, VISIBLE_MS)
end

return M
