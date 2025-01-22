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

return M
