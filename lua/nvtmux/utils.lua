local M = {}

function M.is_terminal_buf()
  return type(vim.fn.getbufvar(vim.fn.bufnr(), 'terminal_job_id')) == 'number'
end

function M.num_terms_open()
  local num_terms = 0

  for _, v in pairs(vim.fn.getbufinfo({buflisted = 1})) do
    if type(v.variables.terminal_job_id) == 'number' then
      num_terms = num_terms + 1
    end
  end

  return num_terms
end

function M.getTabNumberForBuffer(bufnr)
  for t = 1, vim.fn.tabpagenr('$') do
    local buflist = vim.fn.tabpagebuflist(t)
    for _, buf in ipairs(buflist) do
      if buf == bufnr then
        return t
      end
    end
  end
  return -1  -- buffer not found in any tabs
end

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

function M.get_tab_name()
  local found, tab_name = pcall(function() return vim.api.nvim_buf_get_var(0, 'tab_title') end)

  if found then
    return tab_name
  else
    return ''
  end
end

function M.set_tab_name(name)
  if vim.g.loaded_taboo == 1 then
    vim.cmd('TabooRename ' .. name)
  else
    -- Surrounding tab name with spaces to avoid collision with files paths in cwd
    local safe_name = ' ' .. name .. ' '
    vim.api.nvim_buf_set_name(0, safe_name)
  end

  vim.api.nvim_buf_set_var(0, 'tab_title', name)
  vim.opt.titlestring = name
end

return M
