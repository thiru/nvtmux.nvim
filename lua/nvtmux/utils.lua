--- Various domain-agnostic utilities.

local M = {}

-- Get path with home directory replaced with tilde.
function M.replace_home_with_tilde(path)
  local home_dir = vim.uv.os_homedir() or ''
  if vim.startswith(path, home_dir) then
    return '~' .. string.sub(path, #home_dir + 1)
  else
    return path
  end
end

--- Get the name of the respective tab.
---@param tab any A tab page handle
function M.get_tab_name(tab)
  tab = tab or vim.api.nvim_get_current_tabpage()

  local ok, name = pcall(vim.api.nvim_tabpage_get_var, tab, 'tabname')
  if ok then
    return name
  else
    -- Fallback to the active buffer's filename
    local win = vim.api.nvim_tabpage_get_win(tab)
    local buf = vim.api.nvim_win_get_buf(win)
    local bufname = vim.api.nvim_buf_get_name(buf)
    return bufname:match("([^/\\]+)$") or "[No Name]"
  end
end

--- Set the current tab's name to what is given.
---@param name string
function M.set_tab_name(name)
  vim.api.nvim_tabpage_set_var(0, 'tabname', name)
  vim.api.nvim_tabpage_set_var(0, 'has_custom_tabname', true)
  vim.cmd('redraw!')
end

--- Determine if the current buffer is a terminal.
function M.is_terminal_buf()
  return type(vim.fn.getbufvar(vim.fn.bufnr(), 'terminal_job_id')) == 'number'
end

--- Count the number of terminals currently running.
function M.num_terms_open()
  local num_terms = 0

  for _, v in pairs(vim.fn.getbufinfo({buflisted = 1})) do
    if type(v.variables.terminal_job_id) == 'number' then
      num_terms = num_terms + 1
    end
  end

  return num_terms
end

--- Update the window title according to an optional user-defined prefix and tab name.
function M.update_window_title()
  vim.opt.titlestring = (vim.g.nvtmux_window_prefix or '') .. M.get_tab_name()
end

--- Sort the given such that strings starting with alphabetic characters precede those starting
--- with numeric characters.
--- This is useful for the SSH picker as we probably want named connections to be more visible that IP addresses.
---@param a string
---@param b string
---@return boolean diff
function M.sort_alpha_before_number(a, b)
  local a_is_alphabetic = string.match(a, "%a.*")
  local b_is_alphabetic = string.match(b, "%a.*")

  if a_is_alphabetic and not b_is_alphabetic then
    return true
  elseif not a_is_alphabetic and b_is_alphabetic then
    return false
  end

  return a < b
end

--- Get details of valid buffers in the current tab.
function M.buffer_tabs()
  local tabnr = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(tabnr)
  local buffers = {}

  for _, win in ipairs(windows) do
    local buf_id = vim.api.nvim_win_get_buf(win)
    if not buffers[buf_id] then
      local buf_info = {
        id = buf_id,
        name = vim.api.nvim_buf_get_name(buf_id),
        is_valid = vim.api.nvim_buf_is_valid(buf_id),
        is_loaded = vim.api.nvim_buf_is_loaded(buf_id),
        is_modified = vim.api.nvim_get_option_value('modified', {buf=buf_id}),
        is_listed = vim.api.nvim_get_option_value('buflisted', {buf=buf_id}),
        -- filetype = vim.api.nvim_get_option_value('filetype', {buf=buf_id}),
        -- line_count = vim.api.nvim_buf_line_count(buf_id)
      }

      if buf_info.is_valid and buf_info.is_listed and buf_info.is_loaded then
        table.insert(buffers, buf_info)
      end
    end
  end

  return buffers
end

--- Determine if the current tab is empty.
function M.is_empty_tab()
  local buffers = M.buffer_tabs()

  if #buffers == 0 then
    return true
  end

  return #buffers == 1 and buffers[1].name == '' and buffers[1].is_modified == false
end

--- Update the current tab's name to the CWD, but only if a custom name was not already given.
function M.auto_set_tab_name(path)
  local tab = vim.api.nvim_get_current_tabpage()

  -- If a custom name was set then just keep using it
  local ok = pcall(vim.api.nvim_tabpage_get_var, tab, 'has_custom_tabname')
  if ok then
    return
  end

  if vim.bo[vim.api.nvim_get_current_buf()].buftype == 'terminal' then
    local name = M.replace_home_with_tilde(path)
    vim.api.nvim_tabpage_set_var(tab, 'tabname', name)
  end
end

return M
