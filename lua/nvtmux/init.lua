--- A plugin to use Neovim as a terminal multiplexor.

local M = {}

local default_config = require('nvtmux.config')
local core = require('nvtmux.core')
local ssh = require('nvtmux.ssh')

--- Setup and start plugin.
---
---@param config nvtmux.Config? Custom user configuration
---
---@return nvtmux.Config config The effective configuration in use
function M.setup(config)
  local merged_config = vim.tbl_deep_extend('force', default_config, config)

  vim.api.nvim_create_user_command('NvtmuxStart', function()
    M.start(merged_config)
  end, {})

  if merged_config.auto_start then
    M.start(merged_config)
  end

  return merged_config
end

--- Start terminal mode.
---@param config nvtmux.Config Custom user configuration
function M.start(config)
  core.setup(config)
  ssh.setup(config)

  if vim.g.nvtmux_auto_start_cmd ~= nil and #vim.g.nvtmux_auto_start_cmd > 0 then
    vim.fn.jobstart(vim.g.nvtmux_auto_start_cmd, {term = true})
  else
    vim.cmd.terminal()
  end

  vim.cmd.startinsert()
end

return M
