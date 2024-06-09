local u = require('nvtmux.utils')

local helpers = {}
local state = {
  is_enabled = false
}

local M = {
  helpers = helpers,
  state = state,
}

function M.setup()
  M.start()
end

function M.start()
  print('TODO: nvtmux start')
end

return M
