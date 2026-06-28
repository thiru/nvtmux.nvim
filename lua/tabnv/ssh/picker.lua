--- Picker module for SSH connections. Supports telescope.nvim and fzf-lua.

local M = {}

local ssh_parser = require('tabnv.ssh.parser')

M.selected_host = ''

--- Setup the picker.
---@param config table SSH config (tabnv.Config.ssh)
---@param on_picker_action fun(target: string) This function is run when a picker selection is made
---@see tabnv.ssh.laucher.open_ssh_terminal
M.setup = function(config, on_picker_action)
  M.on_picker_action = on_picker_action
  M.config = config

  vim.api.nvim_create_user_command(
    'SshPicker',
    M.picker,
    {bang = true,
     desc = 'Open SSH connection picker'})
end

--- Get the host the user selected from the picker.
---@return string hostname The selected host name
M.get_user_sel_host = function()
  return M.selected_host
end

--- Open the SSH picker with the appropriate backend.
---@param opts table? Options for the picker
M.picker = function(opts)
  opts = opts or {}
  M.selected_host = ''

  local picker = M.config.picker or 'auto'

  if picker == 'telescope' or (picker == 'auto' and pcall(require, 'telescope.actions.state')) then
    M.picker_telescope(opts)
  elseif picker == 'fzf-lua' or (picker == 'auto' and pcall(require, 'fzf-lua')) then
    M.picker_fzf_lua()
  else
    vim.notify(
      "SSH picker requires telescope.nvim or fzf-lua. Install one or set ssh.picker in config.",
      vim.log.levels.ERROR)
  end
end

M.picker_telescope = function(opts)
  local action_state = require('telescope.actions.state')
  local actions = require('telescope.actions')
  local conf = require('telescope.config').values
  local finders = require('telescope.finders')
  local pickers = require('telescope.pickers')

  pickers.new(opts, {
    prompt_title = 'SSH Picker',
    finder = finders.new_table({results = ssh_parser.parse_hosts()}),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        M.selected_host = sel and sel[1] or action_state.get_current_line()
        M.on_picker_action('this')
      end)

      actions.select_tab:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        M.selected_host = sel and sel[1] or action_state.get_current_line()
        M.on_picker_action('tab')
      end)

      actions.select_horizontal:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        M.selected_host = sel and sel[1] or action_state.get_current_line()
        M.on_picker_action('split')
      end)

      actions.select_vertical:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        M.selected_host = sel and sel[1] or action_state.get_current_line()
        M.on_picker_action('vsplit')
      end)

      return true
    end,
  }):find()
end

M.picker_fzf_lua = function()
  local fzf_lua = require('fzf-lua')

  fzf_lua.fzf_exec(ssh_parser.parse_hosts(), {
    prompt = 'SSH Picker ',
    actions = {
      ["default"] = function(selected)
        if selected and #selected > 0 then
          M.selected_host = selected[1]
          M.on_picker_action('this')
        end
      end,
      ["ctrl-t"] = function(selected)
        if selected and #selected > 0 then
          M.selected_host = selected[1]
          M.on_picker_action('tab')
        end
      end,
      ["ctrl-s"] = function(selected)
        if selected and #selected > 0 then
          M.selected_host = selected[1]
          M.on_picker_action('split')
        end
      end,
      ["ctrl-v"] = function(selected)
        if selected and #selected > 0 then
          M.selected_host = selected[1]
          M.on_picker_action('vsplit')
        end
      end,
    },
  })
end

return M
