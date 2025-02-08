--- Launches SSH connections in Neovim terminal emulator.
-- @module nvtmux.ssh.launcher
local M = {}

local picker = require('nvtmux.ssh.picker')
local tabs = require('nvtmux.tabs')

M.state = {
  ssh_cache = {}
}

--- Setup the launcher.
-- @return nil
M.setup = function(opts)
  M.config = opts
  M.create_user_commands()
  picker.setup(M.open_ssh_terminal)
end

M.create_user_commands = function()
  vim.api.nvim_create_user_command(
    'NvtmuxSshPwdReinject',
    function(opts)
      M.ssh_pwd_reinject(opts.args)
    end,
    {bang = true,
     nargs = 1,
     desc = 'Request SSH password injection from cache'})
end

--- Alter SSH cache for the specified buffer in order to automatically inject the cached password.
-- @param bufnr string The respective buffer number
-- @return nil
M.ssh_pwd_reinject = function(bufnr)
  vim.schedule(function ()
    local ssh_cache = M.state.ssh_cache[tonumber(bufnr)]
    ssh_cache.reinject = true
    ssh_cache.stdout_line_count = 0
  end)
end

--- Launch a new SSH terminal.
-- @param target string Specifies the target of the terminal session. This is one of:
-- - this - the current window
-- - tab - a new tab
-- - * - a vim target command like `split`, `vsplit`, etc.
-- @return nil
M.open_ssh_terminal = function(target)
  local host = picker.get_user_sel_host()
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
    local confirm_msg = "'Press ENTER to reconnect to " .. host .. " (CTRL-C to cancel) '"
    local nvim_server_name = vim.v.servername:gsub('\\', '\\\\')
    cmd = ' sh -c "' ..
          'while true;' ..
          ' do ' .. ssh_cmd_nested .. ';' ..
          ' printf ' .. confirm_msg .. ';' ..
          ' read -r dummy </dev/tty;' ..
          (M.config.cache_passwords and " nvim --server '" .. nvim_server_name  .. '\' --remote-expr \'execute(\\"NvtmuxSshPwdReinject ' .. bufnr .. '\\")\';' or '') ..
          ' done"'
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

  if (M.config.auto_rename_tab) then
    tabs.set_tab_name(host)
  end

  vim.schedule(function()
    vim.cmd.startinsert()
  end)
end

return M
