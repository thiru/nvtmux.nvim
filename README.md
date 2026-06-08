# nvtmux

> **Note:** This plugin is still in the experimental phase and may make breaking changes.

nvtmux is short for NeoVim Terminal MUltipleXor.

## Rationale

I use the terminal a lot and I want to have the full power of vim at my disposal to navigate its
contents. Even the most popular terminal apps (e.g. Ghostty, Kitty) have a fraction of the
capabilities of vim when it comes to navigating text. So, I use Neovim's terminal emulator.

I also like the multiplexing capabilities of tools like tmux, such as tabs and windows. Vim also
has these capabilities but the out-of-the-box experience is not at all ergonomic when used in
conjunction with the terminal emulator. The aim of this plugin is to improve this workflow.

## Installation

Minimal lazy.nvim config:

```lua
{
  'thiru/nvtmux.nvim',

  dependencies = {
    'nvim-telescope/telescope.nvim', -- (optional) Used by the SSH connection picker
  },

  ---@type nvtmux.Config
  opts = {},
}
```

## Configuration

See [config.lua](./lua/nvtmux/config.lua) for the full configuration with defaults. Below is a
summary of the available options:

```lua
{
  -- Optional colour scheme override. Useful if you prefer a different theme for terminals
  -- (e.g. a dark theme while using a light theme for editing).
  colorscheme = nil,

  -- The "leader" key used for many key binds (see keymap tables below).
  -- This avoids conflicts with nested vim instances (similar to tmux's Ctrl-B).
  leader = '<C-;>',

  -- Callback invoked right before a terminal buffer is created.
  on_before_term_created = nil,

  -- Callback invoked right after a terminal buffer is created.
  on_after_term_created = nil,

  -- Callback invoked on tab change. Receives a boolean indicating whether the
  -- newly entered tab is a terminal tab.
  on_tab_changed = nil,

  ssh = {
    -- Automatically reconnect SSH sessions when they disconnect. A wrapper
    -- script loops and prompts the user to reconnect.
    auto_reconnect = true,

    -- Automatically rename the tab to the SSH hostname when connecting.
    auto_rename_tab = true,

    password_detection = {
      -- Attempt to detect SSH password prompts and cache entered passwords.
      enabled = true,

      -- Lua patterns used to detect an SSH authentication request.
      patterns = {
        'password:$',
        '^Enter passphrase for key.*:$',
      },
    },
  },
}
```

## Usage

You likely don't want this plugin to start every time you run Neovim as it alters the appearance
and behaviour considerably in order to behave as a terminal multiplexor. So, you can either start
it manually after starting Neovim with the `:NvtmuxStart` command, or you can use this command on
start-up like so:

```shell
nvim +NvtmuxStart
```

As in tmux, nvtmux uses a leader key for many of its commands so that they don't conflict with
possibly nested vim instances. By default this is set to `<C-;>` (configurable via the `leader`
option).

### Leader key bindings

| Keymap       | Description                                      |
|--------------|--------------------------------------------------|
| `<leader>t`  | New terminal (tab)                               |
| `<leader>f`  | New floating, centred terminal                   |
| `<leader>v`  | New terminal (vertical split)                    |
| `<leader>h`  | New terminal (horizontal split)                  |
| `<leader>r`  | Rename current tab                               |
| `<leader>p`  | Paste from system clipboard                      |
| `<leader>a`  | Go to alternate (last accessed) tab              |
| `<leader>s`  | Launch SSH connection picker                     |
| `<leader>d`  | Close current tab                                |
| `<leader>w`  | Set a window prefix (shown in the title)         |
| `<leader>q`  | Safe quit (confirms if multiple terminals open)  |

### Non-leader key bindings

| Keymap         | Description                                      |
|----------------|--------------------------------------------------|
| `<C-space>`    | Escape terminal mode (back to Normal mode)       |
| `<C-j>`        | Terminal mode: Send Down arrow                   |
| `<C-k>`        | Terminal mode: Send Up arrow                     |
| `<C-S-t>`      | New terminal (tab)                               |
| `<C-S-r>`      | Rename current tab                               |
| `<C-v>`        | Paste from system clipboard                      |
| `<C-TAB>`      | Next tab                                         |
| `<C-S-TAB>`    | Previous tab                                     |
| `<C-S-k>`      | Next tab (alternative)                           |
| `<C-S-j>`      | Previous tab (alternative)                       |
| `<C-[1-9]>`    | Go to the specified numbered tab                 |
| `<C-\`>`       | Go to alternate (last accessed) tab              |
| `<C-,>`        | Move current tab to the left                     |
| `<C-.>`        | Move current tab to the right                    |

**Auto-Start Command**

It's also possible to specify a command to run when the terminal starts via a global variable:

```shell
nvim +NvtmuxStart --cmd 'lua vim.g.nvtmux_auto_start_cmd = "htop"'
```

## Features

### Automatic tab naming

Tabs are automatically named after their current working directory. If a terminal's directory
changes (via `cd` or OSC 7 escape sequences), the tab name updates accordingly.

If you manually rename a tab (e.g. via  `<C-S-r>`), the automatic naming is disabled for that tab
and your custom name is preserved.

### Window title

The window/tab title is composed from an optional window prefix (set via `<leader>w`) and the
tab name itself. This prefix can be used to group related terminals, analogous to tmux windows.

### Floating terminal

A centred, floating terminal window can be opened with `<leader>f`. This is useful for quick
commands without leaving your current layout.

### OSC 7 directory change support

The plugin handles OSC 7 escape sequences (emitted by modern shells via
[`osc7`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/osc7) or similar) to track
directory changes inside the terminal. The tab name and CWD are updated automatically.

### Auto-close empty tabs

When you exit a shell in a terminal tab (TermLeave), the tab is automatically closed if it's
empty. If it's the last tab, Neovim quits entirely.

### Tab mode and cursor position preservation

The plugin saves and restores the mode (terminal Insert or Normal) and cursor position when
switching between windows in a tab, so you don't lose your place.

### SSH Connection Picker

The built-in SSH picker uses Telescope to parse `~/.ssh/config` and `~/.ssh/known_hosts` and
lets you quickly connect to any host via a Neovim terminal.

Start the picker with `<leader>s` or by running:

```vim
:SshPicker
```

The default action (`<CR>`) will replace the current buffer. Telescope's alternative actions let
you open the connection in a:

- **new tab** (`<C-t>`)
- **horizontal split** (`<C-x>`)
- **vertical split** (`<C-v>`)

> **Note:** The above alternative action bindings are Telescope defaults. You can change them
> in your Telescope config.

#### Auto-reconnect

When `ssh.auto_reconnect` is enabled (default: `true`), the SSH session is wrapped in a loop
that prompts you to press ENTER to reconnect after the session ends.

#### Password detection & caching

When `ssh.password_detection.enabled` is `true` (default), the plugin monitors terminal output
for SSH password prompts (using the configured Lua patterns). When a prompt is detected:

1. A `inputsecret()` prompt appears for the password.
2. The password is cached in memory keyed by hostname.
3. On subsequent connections to the same host, the cached password is pre-filled.
