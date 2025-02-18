--- Default configuration.

local M = {}

---@class nvtmux.Config
---@field colorscheme string? Optional colour scheme override. I find this useful as I prefer a light theme while editing and a dark theme for terminals.
---@field leader string A leader key is used for many key binds to avoid conflicting with nested vim instances. Tmux uses a similar approach with its default being CTRL-B.
---@field ssh.auto_reconnect boolean Automatically reconnect disconnected sessions on user prompt
---@field ssh.auto_rename_tab boolean Automatically rename the current tab to the SSH connection name
---@field ssh.password_detection table? Attempt to detect SSH authentication requests. Passwords will be cached and reused for future connections.
---@field ssh.password_detection.enabled boolean Enable SSH authentication request detection.
---@field ssh.password_detection.patterns string[] Lua patterns used to detect an SSH authentication request
---@field ssh.password_detection.max_lines_detect number When an SSH authentication request, at most this many lines will be inspected. This is an optimisation attempt in order to reduce unnecessary processing after a login has succeeded.
M.config = {
  colorscheme = nil,
  leader = '<C-space>',
  ssh = {
    auto_reconnect = true,
    auto_rename_tab = true,
    password_detection = {
      enabled = true,
      patterns = {
        'password:$',
        '^Enter passphrase for key.*:$'
      },
      max_lines_detect = 50
    }
  }
}

return M.config
