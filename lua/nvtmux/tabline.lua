--- Various facilities around tabs.

local M = {}

local u = require('nvtmux.utils')

--- Setup the tabline.
function M.setup()
  _G.nvtmux_tabline = M.set_tabline
  vim.opt.tabline = '%!v:lua.nvtmux_tabline()'
end

--- Function used to generate the tabline text.
---@return string tabline The text for the tab
function M.set_tabline()
  local tabline = ''
  local current_tab = vim.api.nvim_get_current_tabpage()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local tabnr = vim.api.nvim_tabpage_get_number(tab)
    local tabnr_super = M.superscript_number(tabnr)
    local tabname = u.get_tab_name(tab)

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

--- Gets a superscript number for the given number.
---@param num number
---@return string superscript The superscript character or an empty string if the given number is greater than 10
function M.superscript_number(num)
  local super_map = {'¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹', '⁰'}
  return super_map[num] or ''
end

return M
