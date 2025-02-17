---@module "nvtmux"
local M = {}

local c = require('nvtmux.core')
local ssh = require('nvtmux.ssh')

function M.setup(opts)
  opts = opts or {}
  c.setup(opts)
  ssh.setup(opts.ssh)
  vim.cmd.terminal()
  vim.cmd.startinsert()
end

return M
