local M = {}

function M.pp(...)
  local objects = vim.tbl_map(vim.inspect, { ... })
  print(unpack(objects))
end

return M
