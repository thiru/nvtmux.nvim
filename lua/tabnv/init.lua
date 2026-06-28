--- A plugin to use Neovim as a terminal multiplexor.

local M = {}

local default_config = require('tabnv.config')
local core = require('tabnv.core')
local ssh = require('tabnv.ssh')
local u = require('tabnv.utils')

M.new_tab = core.new_tab
M.new_float_term = core.new_float_term

--- Setup and start plugin.
---
---@param config tabnv.Config? Custom user configuration
---
---@return tabnv.Config config The effective configuration in use
function M.setup(config)
  local merged_config = vim.tbl_deep_extend('force', default_config, config)

  core.setup(merged_config)
  ssh.setup(merged_config)

  if vim.g.tabnv_auto_start_cmd ~= nil and #vim.g.tabnv_auto_start_cmd > 0 then
    u.with_timer(100, function()
      vim.schedule(function()
        vim.fn.feedkeys(vim.g.tabnv_auto_start_cmd .. "\r\n")
      end)
    end)
  end

  return merged_config
end

--- Set the git branch for the current tab.
--- This would for example be done from an external process like a shell.
function M.set_git_branch(branch)
  if branch and #branch then
    vim.api.nvim_tabpage_set_var(0, 'tabbranch', branch)
  else
    vim.api.nvim_tabpage_set_var(0, 'tabbranch', '')
  end
end

return M
