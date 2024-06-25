local M = {}

function M.pp(...)
  local objects = vim.tbl_map(vim.inspect, { ... })
  print(unpack(objects))
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
