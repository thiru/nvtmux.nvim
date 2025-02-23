--- A plugin to use Neovim as a terminal multiplexor.

local M = {}

local default_config = require('nvtmux.config')
local core = require('nvtmux.core')
local ssh = require('nvtmux.ssh')
local tabs = require('nvtmux.tabs')

--- Setup and start plugin.
---
---@param config nvtmux.Config? Custom user configuration
---
---@return nvtmux.Config config The effective configuration in use
function M.setup(config)
  local merged_config = vim.tbl_deep_extend('force', default_config, config)

  core.setup(merged_config)
  tabs.setup()
  ssh.setup(merged_config)
  vim.cmd.terminal()
  vim.cmd.startinsert()

  return merged_config
end

return M
