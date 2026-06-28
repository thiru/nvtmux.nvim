--- SSH module for connecting to remote hosts.

local M = {}

local launcher = require('tabnv.ssh.launcher')

--- Setup the SSH module.
---@param config tabnv.Config
M.setup = function(config)
  launcher.setup(config)
end

return M
