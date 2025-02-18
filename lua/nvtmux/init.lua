--- A plugin to use Neovim as a terminal multiplexor.

local M = {}

local config = require('nvtmux.config')
local core = require('nvtmux.core')
local ssh = require('nvtmux.ssh')
local tabs = require('nvtmux.tabs')

--- Setup and start this plugin.
---
---@param user_config nvtmux.Config? Custom user configuration
---
---@return nvtmux.Config config The effective configuration used by the plugin
function M.setup(user_config)
  local merged_config = vim.tbl_deep_extend('force', config, user_config)

  core.setup(merged_config)
  tabs.setup()
  ssh.setup(merged_config)
  vim.cmd.terminal()
  vim.cmd.startinsert()

  return merged_config
end

return M
