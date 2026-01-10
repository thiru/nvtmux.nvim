--- A plugin to use Neovim as a terminal multiplexor.

local M = {}

local default_config = require('nvtmux.config')
local core = require('nvtmux.core')
local ssh = require('nvtmux.ssh')
local u = require('nvtmux.utils')

--- Setup and start plugin.
---
---@param config nvtmux.Config? Custom user configuration
---
---@return nvtmux.Config config The effective configuration in use
function M.setup(config)
  local merged_config = vim.tbl_deep_extend('force', default_config, config)

  core.setup(merged_config)
  ssh.setup(merged_config)

  if merged_config.auto_start then
    core.set_term_opts()
    vim.cmd.terminal()
    vim.cmd.startinsert()
  end

  if vim.g.nvtmux_auto_start_cmd ~= nil and #vim.g.nvtmux_auto_start_cmd > 0 then
    vim.fn.jobstart(vim.g.nvtmux_auto_start_cmd, {term = true})
  end

  return merged_config
end

--- Update the CWD of the current tab.
---@param dir string The new CWD
function M.update_cwd(dir)
  vim.api.nvim_tabpage_set_var(0, 'tabdir', dir)
  vim.cmd('cd ' .. dir)
  vim.opt.titlestring = u.get_tab_name()
end

return M
