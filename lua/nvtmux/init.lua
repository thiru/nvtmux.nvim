--- A plugin to use Neovim as a terminal multiplexor.

local M = {}

local default_config = require('nvtmux.config')
local core = require('nvtmux.core')
local ssh = require('nvtmux.ssh')
local tabline = require('nvtmux.tabline')

--- Setup and start plugin.
---
---@param config nvtmux.Config? Custom user configuration
---
---@return nvtmux.Config config The effective configuration in use
function M.setup(config)
  local merged_config = vim.tbl_deep_extend('force', default_config, config)

  core.setup(merged_config)
  tabline.setup()
  ssh.setup(merged_config)

  if vim.g.nvtmux_auto_start_cmd ~= nil and #vim.g.nvtmux_auto_start_cmd > 0 then
    vim.fn.jobstart(vim.g.nvtmux_auto_start_cmd, {term = true})
  else
    vim.cmd.terminal()
  end

  vim.cmd.startinsert()

  return merged_config
end

return M
