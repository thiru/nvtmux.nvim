local u = require('nvtmux.utils')

local M = {}

function M.setup()
  M.telescope = {}

  M.telescope.success = pcall(function ()
    M.telescope = {
      action_state = require('telescope.actions.state'),
      actions = require('telescope.actions'),
      conf = require('telescope.config').values,
      finders = require('telescope.finders'),
      pickers = require('telescope.pickers'),
      themes = require("telescope.themes"),
      success = true,
    }
  end)

  if M.telescope.success then
    vim.api.nvim_create_user_command(
      'NvtmuxTelescopeSshPicker',
      function ()
        M.remote_hosts(M.telescope.themes.get_dropdown({}))
      end,
      {bang = true,
       desc = 'Start nvtmux mode'})
  end
end

function M.parse_ssh_config()
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

function M.parse_known_hosts()
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

function M.parse_hosts()
  local hosts = M.parse_ssh_config()

  for _, v in pairs(M.parse_known_hosts()) do
    if not vim.tbl_contains(hosts, v) then
      table.insert(hosts, v)
    end
  end

  return hosts
end

function M.remote_hosts(opts)
  if not M.telescope.success then
    return
  end

  opts = opts or {}
  M.telescope.pickers.new(opts, {
    prompt_title = 'SSH Selector',
    finder = M.telescope.finders.new_table({
      results = M.parse_hosts()
    }),
    sorter = M.telescope.conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      M.telescope.actions.select_default:replace(function()
        M.telescope.actions.close(prompt_bufnr)
        local selection = M.telescope.action_state.get_selected_entry()
        local host = ''
        if selection == nil then
          host = M.telescope.action_state.get_current_line()
        else
          host = selection[1]
        end
        -- Adding spaces around name to avoid collision with real paths
        local safe_name = ' ' .. host .. ' '
        vim.cmd.tabnew()
        vim.fn.termopen('ssh ' .. host)
        vim.api.nvim_buf_set_name(0, safe_name)
        vim.schedule(function()
          vim.cmd.startinsert()
        end)
      end)
      return true
    end,
  }):find()
end

return M
