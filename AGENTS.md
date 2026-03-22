# AGENTS.md - nvtmux.nvim Development Guide

## Overview

**nvtmux.nvim** is a Neovim plugin that provides terminal multiplexing capabilities. It uses Neovim's built-in terminal emulator with tmux-like tabs, windows, and SSH connection management.

## Project Structure

```
lua/nvtmux/
├── init.lua          # Main entry point, setup function, public API
├── config.lua        # Default configuration and Config type
├── core.lua          # Core functionality (tabs, splits, autocmds)
├── utils.lua         # Shared utility functions
└── ssh/
    ├── init.lua      # SSH module entry point
    ├── launcher.lua  # SSH connection launching and password injection
    ├── picker.lua    # Telescope-based SSH host picker
    └── parser.lua    # SSH config/known_hosts file parser
```

## Build/Test Commands

This plugin has no formal test suite or CI pipeline. Testing is done manually:

```bash
# Manual plugin testing
# 1. Add to your Neovim plugin manager with lazy.nvim:
{ 'path/to/nvtmux.nvim', dependencies = { ... } }

# 2. Run specific functionality manually in Neovim
nvim +NvtmuxStart
```

**Note:** There are no automated lint, format, or test commands. All verification is manual.

## Code Style Guidelines

### General

- **Language:** Lua (LuaJIT compatible, using Neovim's `vim.*` APIs)
- **Indentation:** 2 spaces (no tabs)
- **Line endings:** Unix (LF)
- **File encoding:** UTF-8

### Module Structure

```lua
--- Module description.
-- Prefer module-level docstrings

local M = {}  -- Module table at top of file

local internal_helper = require('nvtmux.utils')  -- Local dependencies

--- Function description.
---@param param_name type Description
---@return type Description
function M.public_function(param_name)
  -- Implementation
end

return M
```

### Imports

- Use `local x = require('namespace.module')` for all dependencies
- Group external deps (vim, telescope) separately from internal deps
- No aliases unless necessary; prefer descriptive `require` paths

```lua
-- External
local telescope = require('telescope')

-- Internal
local core = require('nvtmux.core')
local u = require('nvtmux.utils')  -- 'u' is acceptable for utils
```

### Type Annotations (EmmyLua)

Use EmmyLua annotations for all public functions and types:

```lua
---@class nvtmux.Config
---@field auto_start boolean
---@field leader string
---@field ssh nvtmux.ConfigSsh

--- Setup function description.
---@param config nvtmux.Config?
---@return nvtmux.Config The effective configuration
```

Common types:
- `@param` for parameters
- `@return` for return values
- `@class` for type definitions
- `@field` for class/table fields
- `?` suffix for optional types (e.g., `string?`)

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Modules | lowercase, dot-separated | `nvtmux.core` |
| Functions | snake_case | `open_ssh_terminal` |
| Variables | snake_case | `terminal_job_id` |
| Constants | snake_case | `max_lines_detect` |
| Tables (classes) | PascalCase | `nvtmux.Config` |
| Private module fields | M.field | `M.config`, `M.state` |
| Keymap descriptions | kebab-case | `desc = 'New terminal (tab)'` |

### Keymap Definitions

Use `vim.keymap.set()` with explicit options:

```lua
vim.keymap.set({'n', 't'}, '<C-x>', some_func, {
  desc = 'Description in kebab-case',
  silent = true,
  noremap = true,  -- when appropriate
})
```

### Error Handling

- Use `pcall` for API calls that may fail:
  ```lua
  local ok, result = pcall(vim.api.nvim_xxx, ...)
  if ok then
    -- use result
  end
  ```

- Use `vim.schedule()` for operations that modify buffer/window state from callbacks:
  ```lua
  vim.api.nvim_create_autocmd('TermClose', {
    callback = function()
      vim.schedule(function()
        -- safe to modify buffer/window state here
      end)
    end,
  })
  ```

- Use `vim.notify()` for user-facing messages:
  ```lua
  vim.notify('Message', vim.log.levels.INFO)
  ```

### Neovim API Patterns

- Use `vim.api.nvim_*` functions over legacy `vim.fn.*` when available
- Use `vim.opt.*` for options, not `vim.o`/`vim.bo`
- Use `vim.uv.*` for Lua-based libuv operations
- Buffer/tab/window handles are numbers (bufnr, tabnr, winid)
- Use `vim.tbl_*` utility functions (e.g., `vim.tbl_deep_extend`, `vim.tbl_contains`)

### Terminal Buffer Detection

```lua
-- Check if buffer is a terminal
type(vim.fn.getbufvar(bufnr, 'terminal_job_id')) == 'number'

-- Get terminal job ID
vim.fn.getbufvar(bufnr, 'terminal_job_id')

-- Send data to terminal
vim.api.nvim_chan_send(terminal_job_id, data)
```

### Configuration Pattern

Default config in separate module, merged with user config in `setup()`:

```lua
-- config.lua
local M = {}
M.config = { key = default_value }
return M.config

-- init.lua or other module
function M.setup(user_config)
  local merged = vim.tbl_deep_extend('force', default_config, user_config)
  -- use merged config
end
```

### Whitespace and Formatting

- No trailing whitespace
- No blank lines at end of file
- One blank line between functions (except related setter functions)
- Use string concatenation for simple strings: `'prefix' .. var`
- Use `string.format()` for complex string building
- Use single quotes for strings unless double quotes needed

### Comments

- Use Lua-style `--` comments (not EmmyLua `---` which is for annotations)
- Only comment non-obvious code; code should be self-documenting
- Document the "why", not the "what"
- Keep comments short and meaningful

### Autocommand Groups

Always create named augroups with `clear = true` to avoid duplicate autocmds:

```lua
vim.api.nvim_create_augroup('nvtmux_modulename', {clear = true})
```

### Callback Patterns

Neovim API callbacks receive event data as parameter:

```lua
vim.api.nvim_create_autocmd('DirChangedPre', {
  callback = function(ev)
    -- ev.file contains the directory path
  end,
})
```
