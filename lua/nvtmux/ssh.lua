local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local tconf = require('telescope.config').values
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local u = require('nvtmux.utils')

local M = {}

M.auto_reconnect_when_enum = { 'never', 'always', 'on_error' }

M.config = {
  auto_rename_buf = true,
  auto_reconnect = {
    when = 'on_error',
    timeout = 3
  },
}

M.setup = function(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts)

  vim.api.nvim_create_user_command(
    'Ssht',
    M.picker,
    {bang = true,
     desc = 'Open Telescope SSH picker'})
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

M.rename_tab_or_buf = function(name)
  if vim.g.loaded_taboo == 1 then
    vim.cmd('TabooRename ' .. name)
  else
    -- Adding spaces around name to avoid collision with a path which may exist locally
    local safe_name = ' ' .. name .. ' '

    -- Intentionally suppressing rename error. This usually happens when a buffer with the same name
    -- exists. So, if it fails we just keep the default name, which seems good enough.
    pcall(function() vim.api.nvim_buf_set_name(0, safe_name) end)
  end

  -- Nvtmux plugin uses this var to display window title
  vim.api.nvim_buf_set_var(0, 'tab_title', name)

  -- Set window title
  vim.opt.titlestring = name
end

M.get_user_sel_host = function()
  local selection = action_state.get_selected_entry()
  local host = ''

  if selection == nil then
    host = action_state.get_current_line()
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
          [[do echo '[telescope-ssh] Auto-reconnect in ]] ..
          M.config.auto_reconnect.timeout .. [[ second(s)... Press CTRL-C to cancel.'; ]] ..
          [[sleep ]] .. M.config.auto_reconnect.timeout .. [[; done"]]
  elseif M.config.auto_reconnect.when == 'on_error' then
    cmd = [[sh -c "while ! ssh ']] .. host .. [['; ]] ..
          [[do echo '[telescope-ssh] Auto-reconnect in ]] ..
          M.config.auto_reconnect.timeout .. [[ second(s)... Press CTRL-C to cancel.'; ]] ..
          [[sleep ]] .. M.config.auto_reconnect.timeout .. [[; done"]]
  else
    error('Invalid value for auto-reconnect.when: ' .. M.config.auto_reconnect.when ..
          '. Must be one of: ' .. vim.inspect(M.auto_reconnect_when_enum))
  end
  vim.notify('[telescope-ssh] ' .. cmd, vim.log.levels.DEBUG)

  -- Open in current buffer
  if target == 'this' then
    local terminal_job_id = vim.fn.getbufvar(vim.fn.bufnr(), 'terminal_job_id')
    -- Use existing terminal if already running here
    if type(terminal_job_id) == 'number' then
      -- Not auto-reconnecting SSH session here since it's easy enough to reconnect by running the
      -- last command.
      vim.api.nvim_chan_send(terminal_job_id, 'ssh "' .. host .. '"\r')
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
    M.rename_tab_or_buf(host)
  end

  vim.schedule(function()
    vim.cmd.startinsert()
  end)
end

M.picker = function(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = 'SSH Picker',
    finder = finders.new_table({
      results = M.parse_hosts()
    }),
    sorter = tconf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      -- Open in the current buffer
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        M.open_ssh_terminal('this')
      end)

      -- Open in a new tab
      actions.select_tab:replace(function()
        actions.close(prompt_bufnr)
        M.open_ssh_terminal('tab')
      end)

      -- Open in a horizontal split
      actions.select_horizontal:replace(function()
        actions.close(prompt_bufnr)
        M.open_ssh_terminal('split')
      end)

      -- Open in a vertical split
      actions.select_vertical:replace(function()
        actions.close(prompt_bufnr)
        M.open_ssh_terminal('vsplit')
      end)
      return true
    end,
  }):find()
end

return M
