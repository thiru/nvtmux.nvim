--- Telescope-based interface for picking SSH connections.
-- @module nvtmux.ssh
local M = {}

local launcher = require('nvtmux.ssh.launcher')

--- Default config for the SSH module
M.config = {
  auto_reconnect = true,
  auto_rename_tab = true,
  cache_passwords = true,
  password_detect_patterns = {
    'password:$',
    '^Enter passphrase for key.*:$'
  },
  password_detect_max_lines = 50
}

--- Setup the SSH module.
-- @return nil
M.setup = function(opts)
  M.config = vim.tbl_deep_extend('force', M.config, (opts or {}))
  launcher.setup(M.config)
end

return M
