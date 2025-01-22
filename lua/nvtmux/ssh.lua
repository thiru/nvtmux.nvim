local tr = require('nvtmux.tab-rename')
local u = require('nvtmux.utils')

local M = {}

M.config = {
  auto_rename_buf = true,
}

M.state = {
  reconnects = {}
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

  vim.api.nvim_create_autocmd('TabEnter', {
    callback = function()
      local bufnrs = vim.fn.tabpagebuflist()
      for _, bufnr in ipairs(bufnrs) do
        M.reconnect(bufnr)
      end
    end,
    group = vim.api.nvim_create_augroup('nvtmux_tabenter_reconnect', {clear = true}),
    pattern = '*',
  })
end

M.reconnect = function(curr_bufnr)
  local reconnect = M.state.reconnects[curr_bufnr]
  if reconnect == nil or reconnect.exit_code == nil then
    return
  end

  local choice = vim.fn.confirm('Reconnect to ' .. reconnect.host .. '?', '&Yes\n&No')
  if choice == 2 then
    return
  end

  local curr_tabnr = u.getTabNumberForBuffer(curr_bufnr)
  local msg = 'Reconnect # ' .. (reconnect.count + 1) .. ' to ' .. reconnect.host .. ' in tab ' .. curr_tabnr
  vim.notify(msg, vim.log.levels.INFO)

  M.open_ssh_terminal(reconnect.target, curr_bufnr)
  M.state.reconnects[curr_bufnr].exit_code = nil
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

M.open_ssh_terminal = function(target, old_bufnr)
  local curr_bufnr = nil
  local host = M.get_user_sel_host()
  local cmd = 'ssh "' .. host .. '"'

  -- Open in the current buffer
  if target == 'this' then
    if old_bufnr == nil then
      local choice = vim.fn.confirm('Replace the current buffer and connect to ' .. host .. '?', '&No\n&Yes')
      if choice == 1 then
        vim.schedule(function()
          vim.cmd.startinsert()
        end)
        return
      end
      curr_bufnr = vim.api.nvim_get_current_buf()
    else
      curr_bufnr = old_bufnr
    end
  -- Open in a new tab
  elseif target == 'tab' then
    if old_bufnr == nil then
      vim.cmd.tabnew()
      curr_bufnr = vim.api.nvim_get_current_buf()
    else
      curr_bufnr = old_bufnr
    end
  -- Open in a new split
  else
    -- HACK: seem to have to delete the buffer if it's in a split otherwise termopen
    -- fails with the notorious modified buffer error
    if old_bufnr ~= nil then
      vim.cmd('bdelete! ' .. old_bufnr)
    end

    vim.cmd(target)
    vim.cmd.enew()
    curr_bufnr = vim.api.nvim_get_current_buf()
  end

  -- Need this to overwrite existing, modified buffer with a new terminal session
  vim.api.nvim_set_option_value('modified', false, {buf=curr_bufnr})

  vim.fn.termopen(
    cmd,
    {
      on_exit = function(_, exit_code, _)
        if M.state.reconnects[curr_bufnr] == nil then
          M.state.reconnects[curr_bufnr] = {bufnr = curr_bufnr, exit_code = exit_code, count = 0, target = target, host = host}
        else
          M.state.reconnects[curr_bufnr].count = M.state.reconnects[curr_bufnr].count + 1
          M.state.reconnects[curr_bufnr].exit_code = exit_code
        end

        if u.getTabNumberForBuffer(curr_bufnr) == vim.fn.tabpagenr() then
          M.reconnect(curr_bufnr)
        end
      end
    })

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
