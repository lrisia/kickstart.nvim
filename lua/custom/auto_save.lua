-- Auto-save: writes the current buffer after a quiet period.
-- Triggers on InsertLeave / TextChanged, debounced per-buffer.

local group = vim.api.nvim_create_augroup('autosave', { clear = true })
local timers = {}
local debounce_ms = 1000

local function clear_timer(buf)
  local t = timers[buf]
  if not t then return end
  timers[buf] = nil
  if not t:is_closing() then
    t:stop()
    t:close()
  end
end

local function save_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return false end
  if not (vim.bo[buf].modified
    and not vim.bo[buf].readonly
    and vim.api.nvim_buf_get_name(buf) ~= ''
    and vim.bo[buf].buftype == '')
  then
    return false
  end
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('silent! write')
  end)
  -- `silent! write` swallows errors; the modified flag tells us if it stuck.
  return not vim.bo[buf].modified
end

vim.api.nvim_create_autocmd({ 'InsertLeave', 'TextChanged' }, {
  desc = 'Auto save on changes (debounced)',
  group = group,
  callback = function(args)
    local buf = args.buf
    clear_timer(buf)

    -- Capture this timer in the closure so a later autocmd that replaces
    -- timers[buf] doesn't cause us to close the wrong handle.
    local t = assert(vim.uv.new_timer())
    timers[buf] = t
    t:start(debounce_ms, 0, vim.schedule_wrap(function()
      if save_buffer(buf) then
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t')
        vim.notify(string.format('[autosave] %s', name), vim.log.levels.INFO)
      end
      if timers[buf] == t then
        timers[buf] = nil
      end
      if not t:is_closing() then
        t:close()
      end
    end))
  end,
})

vim.api.nvim_create_autocmd({ 'BufWipeout', 'BufDelete' }, {
  desc = 'Cancel pending autosave when buffer is destroyed',
  group = group,
  callback = function(args)
    clear_timer(args.buf)
  end,
})
