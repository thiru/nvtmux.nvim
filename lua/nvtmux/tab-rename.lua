local Input = require('nui.input')
local event = require('nui.utils.autocmd').event
local _ = require('nvtmux.utils')

local M = {
  state = {
    nui_input = nil,
  }
}
M.rename_tab_popup_opts = {
  position = '50%',
  size = {
    width = 30,
  },
  border = {
    style = 'single',
    text = {
      top = 'Tab Name',
      top_align = 'center',
    },
  },
  win_options = {
    winhighlight = 'Normal:Normal,FloatBorder:Normal',
  },
}
M.rename_tab_input_opts = {
  prompt = '> ',
  default_value = '',
  on_close = function()
    vim.cmd.startinsert()
  end,
  on_submit = function(value)
    M.set_tab_name(value)
    vim.cmd.startinsert()
  end
}

function M.set_tab_name(name)
  if #name == 0 then
    return
  end

  -- Surrounding tab name with spaces to avoid collision with files paths in cwd
  local safe_name = ' ' .. name .. ' '
  vim.api.nvim_buf_set_name(0, safe_name)
  vim.cmd('redraw!')
end

function M.create_nui_input()
  local input = Input(M.rename_tab_popup_opts, M.rename_tab_input_opts)

  input:map('n', '<Esc>', function()
    input:unmount()
  end, {noremap = true})

  input:on(event.BufLeave, function()
    input:unmount()
  end)

  return input
end

function M.rename_tab_prompt()
  local input = M.state.nui_input or M.create_nui_input()

  input:mount()
  vim.schedule(function()
    vim.cmd.startinsert()
  end)
end

return M
