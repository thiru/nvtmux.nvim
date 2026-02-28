# AGENTS.md - nvtmux.nvim Development Guide

This document provides guidelines for agents working on the nvtmux.nvim Neovim plugin.

## Project Overview

nvtmux (Neovim Terminal Multiplexor) is a Neovim plugin that provides tmux-like terminal multiplexing capabilities using Neovim's built-in terminal emulator. Written in Lua for Neovim 0.10+.

## Directory Structure

```
lua/nvtmux/
├── init.lua        -- Main entry point, setup function
├── config.lua      -- Default configuration
├── core.lua        -- Core functionality, keybindings, autocmds
├── utils.lua       -- Utility functions
└── ssh/
    ├── init.lua    -- SSH module entry
    ├── launcher.lua -- SSH connection launcher with password detection
    ├── picker.lua  -- Telescope-based SSH host picker
    └── parser.lua  -- SSH config/known_hosts parser
```

## Build/Lint/Test Commands

There are no formal test or lint commands configured.

For manual verification:
- Test plugin by loading in Neovim: `nvim --headless -u NONE -c "set rtp+=." -c "lua require('nvtmux')" -c "qa!"`
- Use `luacheck` for static analysis if installed: `luacheck lua/`

### Running a Single Test (Manual)

Since there are no automated tests, test manually by:
1. Starting Neovim with the plugin loaded
2. Triggering the feature being developed
3. Verifying expected behavior

## Code Style Guidelines

### General Principles

- **Target Neovim version**: 0.10+ (use modern Lua API)
- **Indentation**: 2 spaces
- **Line length**: Under 120 chars when possible
- **No trailing whitespace**

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Modules/Files | snake_case | `ssh/launcher.lua` |
| Functions/Variables | snake_case | `get_tab_name`, `num_terms_open` |
| Table Keys | snake_case | `{ auto_start = true }` |
| Constants | UPPER_SNAKE_CASE | `MAX_LINES_DETECT` |
| Class-like tables | PascalCase | `BufferCache` |

### Imports

```lua
local core = require('nvtmux.core')
local u = require('nvtmux.utils')
local api = vim.api
```

Use `local` for all module-level variables, use short aliases (`u` for utils), and avoid circular requires.

### Formatting

Use blank lines to separate logical sections, trailing commas in tables, and single quotes for strings.

### Types and Annotations

Use LuaDoc-style annotations (compatible with `lua-language-server`):

```lua
---@class nvtmux.Config
---@field auto_start boolean Automatically start terminal mode.
---@field leader string Leader key for keybindings.

--- Setup the plugin.
---@param config nvtmux.Config? Custom user configuration
---@return nvtmux.Config config The effective configuration
function M.setup(config)
  -- ...
end
```

### Error Handling

Use `pcall` for Neovim API calls that may fail, `vim.schedule` for callbacks that may interact with Neovim UI, and `vim.notify` for user-visible messages.

### Keybindings

Use `vim.keymap.set` with descriptive `desc`:

```lua
vim.keymap.set('t', '<C-;>', '<C-\\><C-n>', {desc = 'Terminal -> normal mode'})
vim.keymap.set({'n', 't'}, M.config.leader .. 'q', M.safe_quit, {desc = 'Quit'})
```

- Always provide a `desc` option
- Use mode prefixes: `'n'` (normal), `'t'` (terminal), `{'n', 't'}` (both)

### User Commands

Use `vim.api.nvim_create_user_command`:

```lua
vim.api.nvim_create_user_command('NvtmuxStart', function()
  M.set_term_opts()
  vim.cmd.terminal()
  vim.cmd.startinsert()
end, {})
```

### Autocommands

Use `vim.api.nvim_create_autocmd` with callback functions and augroups:

```lua
vim.api.nvim_create_autocmd('TabEnter', {
  callback = function()
    -- handler code
  end,
  group = vim.api.nvim_create_augroup('nvtmux_tabenter', {clear = true}),
  pattern = '*',
})
```

### State Management

Store module state in the module table:

```lua
local M = {
  state = {},
  config = nil
}
```

### Neovim API Preferences

Prefer new API: `vim.api.nvim_create_autocmd` over `vim.cmd`, `vim.api.nvim_create_user_command` over `vim.cmd`, `vim.keymap.set` over `vim.api.nvim_set_keymap`, and `vim.opt` over `vim.o`/`vim.bo`/`vim.wo`.

### Commit Message Style

Use clear, concise commit messages: start with verb ("Add", "Fix", "Refactor", "Update") and keep subject line under 72 characters.

### Pull Request Process

1. Create feature branch from `develop`
2. Ensure changes work with Neovim 0.10+
3. Test manually with `:NvtmuxStart`
4. Update README.md if adding new features
5. Submit PR against `develop` branch

## Quick Reference

| Task | Command |
|------|---------|
| Keybinding | `vim.keymap.set('n', '<leader>x', fn, {desc})` |
| Command | `vim.api.nvim_create_user_command('Name', fn, {})` |
| Autocmd | `vim.api.nvim_create_autocmd('Event', {callback=fn})` |
| Terminal buf | `vim.fn.getbufvar(bufnr, 'terminal_job_id')` |
