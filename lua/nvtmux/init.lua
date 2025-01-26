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
  opts = opts or {}

  vim.api.nvim_create_user_command(
    'NvtmuxStart',
    function ()
      M.start(opts)
    end,
    {bang = true,
     desc = 'Start nvtmux mode'})

  vim.api.nvim_create_user_command(
    'NvtmuxSshPwdReinject',
    function(fopts)
      ssh.ssh_pwd_reinject(fopts.args)
    end,
    {bang = true,
     nargs = 1,
     desc = 'Request SSH password injection from cache'})

  M.start(opts)
  ssh.setup(opts.ssh)
end

function M.start(opts)
  c.setup(opts)
  vim.cmd.terminal()
  vim.cmd.startinsert()
end

return M
