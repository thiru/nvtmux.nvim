local c = require('nvtmux.core')
local _ = require('nvtmux.utils')

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

function M.parse_hosts()
  local source_file = vim.uv.os_homedir() .. '/.ssh/config'

  if not vim.uv.fs_stat(source_file) then
    return {'No remote hosts found in ' .. source_file}
  end

  local hosts = {}

  for _, line in pairs(vim.fn.readfile(source_file)) do
    local match = string.match(line, "^%s*Host%s+(.+)%s*$")
    if match and match ~= '*' then
      table.insert(hosts, match)
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
        vim.cmd.tabnew()
        vim.fn.termopen('ssh ' .. host)
        c.set_tab_name(host)
        vim.schedule(function()
          vim.cmd.startinsert()
        end)
      end)
      return true
    end,
  }):find()
end

return M
