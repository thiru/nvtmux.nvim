--- Telescope-based interface for picking SSH connections.

local M = {}

local launcher = require('nvtmux.ssh.launcher')

--- Setup the SSH module.
---@param config nvtmux.Config
M.setup = function(config)
  launcher.setup(config)
end

return M
