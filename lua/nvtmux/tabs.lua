local M = {}

function M.init()
  _G.nvtmux_tabline = M.set_tabline
  vim.opt.tabline = '%!v:lua.nvtmux_tabline()'
end

function M.set_tabline()
  local tabline = ''
  local current_tab = vim.api.nvim_get_current_tabpage()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local tabnr = vim.api.nvim_tabpage_get_number(tab)
    local tabnr_super = M.superscript_number(tabnr)
    local tabname = M.get_tab_name(tab)

    -- Highlight active tab
    if tab == current_tab then
      tabline = tabline .. '%#TabLineSel#' .. tabnr_super .. ' ' .. tabname .. ' %#TabLine#'
    else
      tabline = tabline .. '%#TabLine#' .. tabnr_super .. ' ' .. tabname .. ' '
    end
  end

  -- Add spacer to separate tabs from buffer list (if any)
  tabline = tabline .. '%T%#TabLineFill#%='
  return tabline
end

function M.get_tab_name(tab)
  tab = tab or vim.api.nvim_get_current_tabpage()

  local ok, name = pcall(vim.api.nvim_tabpage_get_var, tab, 'tabname')
  if ok then
    return name
  else
    -- Fallback to active buffer's filename
    local win = vim.api.nvim_tabpage_get_win(tab)
    local buf = vim.api.nvim_win_get_buf(win)
    local bufname = vim.api.nvim_buf_get_name(buf)
    return bufname:match("([^/\\]+)$") or "[No Name]"
  end
end

function M.set_tab_name(name)
  vim.api.nvim_tabpage_set_var(0, 'tabname', name)
  vim.opt.titlestring = name
  vim.cmd('redraw!')
end

function M.superscript_number(n)
  local super_map = {'¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹', '⁰'}
  return super_map[n] or ''
end

return M
