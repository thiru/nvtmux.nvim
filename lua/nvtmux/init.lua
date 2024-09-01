local c = require('nvtmux.core')
local ssh = require('nvtmux.ssh')
local _ = require('nvtmux.utils')

local M = {
  doc = [[
    Use Neovim as a terminal multiplexor, much like tmux but without
    persistance and session management.
    ]],
  core = c
}

function M.setup(opts)
  local opts = opts or {}

  vim.api.nvim_create_user_command(
    'NvtmuxStart',
    function ()
      M.start(opts)
    end,
    {bang = true,
     desc = 'Start nvtmux mode'})

  M.start(opts)
  ssh.setup(opts.ssh)
end

function M.start(opts)
  c.set_term_opts(opts)
  c.setup_autocmds()
  c.set_default_keybinds()
  vim.cmd.terminal()
  vim.cmd.startinsert()
end

return M
