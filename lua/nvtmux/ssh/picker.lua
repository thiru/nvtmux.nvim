--- Telescope-based interface for picking SSH connections.

local M = {}

local ssh_parser = require('nvtmux.ssh.parser')

--- Setup the picker.
---@param on_picker_action fun(target: string) This function is run when a picker selection is made
---@see nvtmux.ssh.laucher.open_ssh_terminal
M.setup = function(on_picker_action)
  M.on_picker_action = on_picker_action
  M.create_picker_user_command()
end

--- Create a user command to open the picker.
M.create_picker_user_command = function()
  vim.api.nvim_create_user_command(
    'SshPicker',
    M.picker,
    {bang = true,
     desc = 'Open Telescope SSH picker'})
end

--- Load all necessary Telescope modules.
M.load_telescope = function()
  M.telescope = {
    action_state = require('telescope.actions.state'),
    actions = require('telescope.actions'),
    conf = require('telescope.config').values,
    finders = require('telescope.finders'),
    pickers = require('telescope.pickers')
  }
end

--- Get the host the user selected from the picker.
---@return string hostname The selected host name
M.get_user_sel_host = function()
  local selection = M.telescope.action_state.get_selected_entry()
  local host = ''

  if selection == nil then
    host = M.telescope.action_state.get_current_line()
  else
    host = selection[1]
  end

  return host
end

--- Open the SSH picker.
---@param opts table? Options for Telescope
M.picker = function(opts)
  opts = opts or {}

  -- Telescope is lazy loaded here
  if M.telescope == nil and (not pcall(M.load_telescope)) then
    error("Telescope is required for nvtmux's SSH picker")
  end

  M.telescope.pickers.new(opts, {
    prompt_title = 'SSH Picker',
    finder = M.telescope.finders.new_table({
      results = ssh_parser.parse_hosts()
    }),
    sorter = M.telescope.conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      -- Open in the current buffer
      M.telescope.actions.select_default:replace(function()
        M.telescope.actions.close(prompt_bufnr)
        M.on_picker_action('this')
      end)

      -- Open in a new tab
      M.telescope.actions.select_tab:replace(function()
        M.telescope.actions.close(prompt_bufnr)
        M.on_picker_action('tab')
      end)

      -- Open in a horizontal split
      M.telescope.actions.select_horizontal:replace(function()
        M.telescope.actions.close(prompt_bufnr)
        M.on_picker_action('split')
      end)

      -- Open in a vertical split
      M.telescope.actions.select_vertical:replace(function()
        M.telescope.actions.close(prompt_bufnr)
        M.on_picker_action('vsplit')
      end)
      return true
    end,
  }):find()
end

return M
