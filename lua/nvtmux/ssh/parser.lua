--- Parses the user's SSH config and known_hosts files for hosts
-- @module nvtmux.ssh.parser
local M = {}

local u = require('nvtmux.utils')

--- Parse the user's SSH config for hosts.
-- @return table A list of host names
M.parse_ssh_config = function()
  local source_file = vim.uv.os_homedir() .. '/.ssh/config'

  local hosts = {}

  if not vim.uv.fs_stat(source_file) then
    return hosts
  end

  for _, line in pairs(vim.fn.readfile(source_file)) do
    local match = string.match(line, "^%s*Host%s+(.+)%s*$")
    if match and match ~= '*' then
      table.insert(hosts, match)
    end
  end

  table.sort(hosts)
  return hosts
end

--- Parse the user's known_hosts file for hosts.
-- @return table A list of host names
M.parse_known_hosts = function()
  local source_file = vim.uv.os_homedir() .. '/.ssh/known_hosts'

  local hosts = {}

  if not vim.uv.fs_stat(source_file) then
    return hosts
  end

  for _, line in pairs(vim.fn.readfile(source_file)) do
    local match = string.match(line, "^%s*([%w.]+)[%s\\,]")
    if match and not vim.tbl_contains(hosts, match) then
      table.insert(hosts, match)
    end
  end

  table.sort(hosts, u.sort_alpha_before_number)
  return hosts
end

--- Parse hosts from the user's SSH config and known_hosts files.
-- @return table A list of host names
M.parse_hosts = function()
  local hosts = M.parse_ssh_config()

  for _, v in pairs(M.parse_known_hosts()) do
    if not vim.tbl_contains(hosts, v) then
      table.insert(hosts, v)
    end
  end

  return hosts
end

return M
