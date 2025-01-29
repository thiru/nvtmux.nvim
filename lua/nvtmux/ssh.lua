local u = require('nvtmux.utils')
local tabs = require('nvtmux.tabs')

local M = {
  config = {
    auto_reconnect = true,
    auto_rename_buf = true,
    cache_passwords = true,
    password_detect_patterns = {
      'password:$',
      '^Enter passphrase for key.*:$'},
    password_detect_max_lines = 50
  },
  state = {
    ssh_cache = {},
    telescope = nil
  }
}

M.setup = function(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts)

  vim.api.nvim_create_user_command(
    'SshPicker',
    M.picker,
    {bang = true,
     desc = 'Open Telescope SSH picker'})
end

M.load_telescope = function()
  M.state.telescope = {
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
  local selection = M.state.telescope.action_state.get_selected_entry()
  local host = ''

  if selection == nil then
    host = M.state.telescope.action_state.get_current_line()
  else
    host = selection[1]
  end

  return host
end

M.ssh_pwd_reinject = function(bufnr)
  vim.schedule(function ()
    local ssh_cache = M.state.ssh_cache[tonumber(bufnr)]
    ssh_cache.reinject = true
    ssh_cache.stdout_line_count = 0
  end)
end

M.open_ssh_terminal = function(target)
  local host = M.get_user_sel_host()
  local cmd = nil

  -- Open in the current buffer
  if target == 'this' then
    local confirm = vim.fn.input('Wipe out the current buffer and connect to ' .. host .. '?', 'yes')
    if vim.trim(confirm) ~= 'yes' then
      vim.schedule(function()
        vim.cmd.startinsert()
      end)
      return
    else
      -- Need this to overwrite existing, modified buffer with a new terminal session
      vim.api.nvim_set_option_value('modified', false, {buf=vim.api.nvim_get_current_buf()})
    end
  -- Open in a new tab
  elseif target == 'tab' then
    vim.cmd.tabnew()
  -- Open in a new split
  else
    vim.cmd(target)
    vim.cmd.enew()
  end

  local bufnr = vim.api.nvim_get_current_buf()

  if not M.config.auto_reconnect then
    cmd = 'ssh "' .. host .. '"'
  else
    local ssh_cmd_nested = "(ssh '" .. host .. "' || true)"
    local confirm_msg = "'Press any key to reconnect to " .. host .. " (CTRL-C to cancel) '"
    local nvim_server_name = vim.v.servername:gsub('\\', '\\\\')
    cmd = ' bash -c "' .. ssh_cmd_nested ..
          ' && while read -n 1 -p ' .. confirm_msg .. ' yn && echo ' ..
          (M.config.cache_passwords and " && nvim --server '" .. nvim_server_name  .. '\' --remote-expr \'execute(\\"NvtmuxSshPwdReinject ' .. bufnr .. '\\")\'' or '') ..
          ' ;do ' .. ssh_cmd_nested .. '; done"'
  end

  vim.notify('Connecting to ' .. host, vim.log.levels.INFO)

  if M.config.cache_passwords then
    M.state.ssh_cache[bufnr] = {
      pwd = '',
      reinject = false,
      -- Count stdout lines processed so we don't keep trying to detect an SSH password prompt for too long
      stdout_line_count = 0}
    local ssh_cache = M.state.ssh_cache[bufnr]

    vim.fn.termopen(
      cmd,
      {
        on_stdout = function(chan_id, data, _)
          if not M.config.cache_passwords then
            return
          end

          if ssh_cache.reinject or (#ssh_cache.pwd == 0) then
            for _, line in ipairs(data) do
              line = vim.trim(line)
              ssh_cache.stdout_line_count = ssh_cache.stdout_line_count + 1
              if ssh_cache.stdout_line_count > M.config.password_detect_max_lines then
                return
              end
              for _, pattern in ipairs(M.config.password_detect_patterns) do
                if (line:find(pattern)) then
                  if #ssh_cache.pwd == 0 then
                    vim.schedule(function()
                      local msg = 'Enter password here to cache:'
                      ssh_cache.pwd = (vim.fn.inputsecret(msg) or '')
                      if #ssh_cache.pwd > 0 then
                        vim.fn.chansend(chan_id, ssh_cache.pwd .. '\n')
                      end
                    end)
                  end
                  if ssh_cache.reinject then
                    ssh_cache.reinject = false
                    vim.fn.chansend(chan_id, ssh_cache.pwd .. '\n')
                  end
                  break
                end
              end
            end
          end
        end})
  else
    vim.fn.termopen(cmd)
  end

  if (M.config.auto_rename_buf) then
    tabs.set_tab_name(host)
  end

  vim.schedule(function()
    vim.cmd.startinsert()
  end)
end

M.picker = function(opts)
  opts = opts or {}

  if M.state.telescope == nil and (not pcall(M.load_telescope)) then
    error("Telescope is required for nvtmux's SSH picker")
  end

  M.state.telescope.pickers.new(opts, {
    prompt_title = 'SSH Picker',
    finder = M.state.telescope.finders.new_table({
      results = M.parse_hosts()
    }),
    sorter = M.state.telescope.conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      -- Open in the current buffer
      M.state.telescope.actions.select_default:replace(function()
        M.state.telescope.actions.close(prompt_bufnr)
        M.open_ssh_terminal('this')
      end)

      -- Open in a new tab
      M.state.telescope.actions.select_tab:replace(function()
        M.state.telescope.actions.close(prompt_bufnr)
        M.open_ssh_terminal('tab')
      end)

      -- Open in a horizontal split
      M.state.telescope.actions.select_horizontal:replace(function()
        M.state.telescope.actions.close(prompt_bufnr)
        M.open_ssh_terminal('split')
      end)

      -- Open in a vertical split
      M.state.telescope.actions.select_vertical:replace(function()
        M.state.telescope.actions.close(prompt_bufnr)
        M.open_ssh_terminal('vsplit')
      end)
      return true
    end,
  }):find()
end

return M
