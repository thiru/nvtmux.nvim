--- Various domain-agnostic utilities.

local M = {}

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

return M
