local tr = require('nvtmux.tab-rename')
local u = require('nvtmux.utils')

local M = {}

M.config = {
  auto_rename_buf = true,
  auto_reconnect = {
    when = 'on_error',
    timeout = 3
  },
}

M.auto_reconnect_when_enum = { 'never', 'always', 'on_error' }
M.telescope = nil

M.setup = function(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts)

  vim.api.nvim_create_user_command(
    'SshPicker',
    M.picker,
    {bang = true,
     desc = 'Open Telescope SSH picker'})
end

M.load_telescope = function()
  M.telescope = {
    loaded = true,
    action_state = require('telescope.actions.state'),
    actions = require('telescope.actions'),
    conf = require('telescope.config').values,
    finders = require('telescope.finders'),
    pickers = require('telescope.pickers')
  }
end

M.parse_ssh_config = function()
  local source_file = vim.uv.os_homedir() .. '/.ssh/config'

  if not vim.uv.fs_stat(source_file) then
    return {}
  end

  local hosts = {}

  for _, line in pairs(vim.fn.readfile(source_file)) do
    local match = string.match(line, "^%s*Host%s+(.+)%s*$")
    if match and match ~= '*' then
      table.insert(hosts, match)
    end
  end

  table.sort(hosts)
  return hosts
end

M.parse_known_hosts = function()
  local source_file = vim.uv.os_homedir() .. '/.ssh/known_hosts'

  if not vim.uv.fs_stat(source_file) then
    return {}
  end

  local hosts = {}

  for _, line in pairs(vim.fn.readfile(source_file)) do
    local match = string.match(line, "^%s*([%w.]+)[%s\\,]")
    if match and not vim.tbl_contains(hosts, match) then
      table.insert(hosts, match)
    end
  end

  table.sort(hosts, u.sort_alpha_before_number)
  return hosts
end

M.parse_hosts = function()
  local hosts = M.parse_ssh_config()

  for _, v in pairs(M.parse_known_hosts()) do
    if not vim.tbl_contains(hosts, v) then
      table.insert(hosts, v)
    end
  end

  return hosts
end

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

M.open_ssh_terminal = function(target)
  local host = M.get_user_sel_host()

  local cmd = 'ssh "' .. host .. '"'
  if M.config.auto_reconnect.when == 'always' then
    cmd = [[sh -c "while true; ]] ..
          [[ssh ']] .. host .. [[' || true; ]] ..
          [[do echo '[nvtmux] Auto-reconnect in ]] ..
          M.config.auto_reconnect.timeout .. [[ second(s)... Press CTRL-C to cancel.'; ]] ..
          [[sleep ]] .. M.config.auto_reconnect.timeout .. [[; done"]]
  elseif M.config.auto_reconnect.when == 'on_error' then
    cmd = [[sh -c "while ! ssh ']] .. host .. [['; ]] ..
          [[do echo '[nvtmux] Auto-reconnect in ]] ..
          M.config.auto_reconnect.timeout .. [[ second(s)... Press CTRL-C to cancel.'; ]] ..
          [[sleep ]] .. M.config.auto_reconnect.timeout .. [[; done"]]
  else
    error('Invalid value for auto-reconnect.when: ' .. M.config.auto_reconnect.when ..
          '. Must be one of: ' .. vim.inspect(M.auto_reconnect_when_enum))
  end
  vim.notify('[nvtmux] ' .. cmd, vim.log.levels.DEBUG)

  -- Open in current buffer
  if target == 'this' then
    local terminal_job_id = vim.fn.getbufvar(vim.fn.bufnr(), 'terminal_job_id')
    -- Use existing terminal if one is already running
    if type(terminal_job_id) == 'number' then
      vim.api.nvim_chan_send(terminal_job_id, cmd .. '\r')
    else
      vim.fn.termopen(cmd)
    end
  -- Open in new tab
  elseif target == 'tab' then
    vim.cmd.tabnew()
    vim.fn.termopen(cmd)
  -- Open in a split
  else
    vim.cmd(target)
    vim.cmd.enew()
    vim.fn.termopen(cmd)
  end

  if (M.config.auto_rename_buf) then
    tr.set_tab_name(host)
  end

  vim.schedule(function()
    vim.cmd.startinsert()
  end)
end

M.picker = function(opts)
  opts = opts or {}

  if M.telescope == nil and (not pcall(M.load_telescope)) then
    error("Telescope is required for nvtmux's SSH picker")
  end

  M.telescope.pickers.new(opts, {
    prompt_title = 'SSH Picker',
    finder = M.telescope.finders.new_table({
      results = M.parse_hosts()
    }),
    sorter = M.telescope.conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      -- Open in the current buffer
      M.telescope.actions.select_default:replace(function()
        M.telescope.actions.close(prompt_bufnr)
        M.open_ssh_terminal('this')
      end)

      -- Open in a new tab
      M.telescope.actions.select_tab:replace(function()
        M.telescope.actions.close(prompt_bufnr)
        M.open_ssh_terminal('tab')
      end)

      -- Open in a horizontal split
      M.telescope.actions.select_horizontal:replace(function()
        M.telescope.actions.close(prompt_bufnr)
        M.open_ssh_terminal('split')
      end)

      -- Open in a vertical split
      M.telescope.actions.select_vertical:replace(function()
        M.telescope.actions.close(prompt_bufnr)
        M.open_ssh_terminal('vsplit')
      end)
      return true
    end,
  }):find()
end

return M
