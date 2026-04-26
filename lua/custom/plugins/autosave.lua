-- Custom autosave plugin
-- Saves the current buffer automatically on InsertLeave and TextChanged

return {
  'autosave.nvim',
  dir = vim.fn.stdpath('config') .. '/lua/custom/plugins',
  name = 'autosave',
  lazy = false,
  config = function()
    local group = vim.api.nvim_create_augroup('autosave', { clear = true })
    local timer = nil
    local debounce_ms = 1000

    local function save_buffer(buf)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      if vim.bo[buf].modified
        and not vim.bo[buf].readonly
        and vim.api.nvim_buf_get_name(buf) ~= ''
        and vim.bo[buf].buftype == ''
      then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd('silent! write')
        end)
      end
    end

    vim.api.nvim_create_autocmd({ 'InsertLeave', 'TextChanged' }, {
      desc = 'Auto save on changes (debounced)',
      group = group,
      callback = function(args)
        local buf = args.buf
        if timer then
          timer:stop()
          timer:close()
          timer = nil
        end
        timer = vim.uv.new_timer()
        timer:start(debounce_ms, 0, vim.schedule_wrap(function()
          save_buffer(buf)
          if timer then
            timer:close()
            timer = nil
          end
        end))
      end,
    })
  end,
}
