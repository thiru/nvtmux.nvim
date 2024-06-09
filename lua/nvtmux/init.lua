local c = require('nvtmux.core')
local _ = require('nvtmux.utils')

local M = {
  doc = [[
    Use Neovim as a terminal multiplexor, much like tmux but without
    persistance and session management.

    Can be started with the :NvtmuxStart command or on Neovim startup like so:
    nvim --cmd 'lua vim.g.nvtmux_auto_start = true'
    ]],
  state = {
    is_enabled = false
  }
}

function M.setup()
  vim.api.nvim_create_user_command(
    'NvtmuxStart',
    M.start,
    {bang = true,
     desc = 'Start nvtmux mode'})

  if c.is_auto_start() then
    M.start()
  end
end

function M.start()
  M.state.is_enabled = true
  c.set_term_opts()
  c.handle_term_close()
  c.keybinds()
  vim.cmd('terminal')
  vim.cmd('startinsert')
end

function M.is_enabled()
  return M.state.is_enabled
end

return M
