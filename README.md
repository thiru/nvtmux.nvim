# tabnv

<div align="center">
  <img src="logo.svg" alt="logo">
</div>

## what

a [neovim](https://neovim.io/) plugin that turns your editor into a terminal multiplexer

## why

- vim motions are the most efficient means of navigating text
- terminal output is essentially text
- neovim has a terminal emulator built in
- the default experience of managing terminals and regular buffers in neovim is not ergonomic
- with [neovide](https://neovide.dev/) we have a fully cross-platform terminal without compromises

## how - installation

### vim.pack

```lua
vim.pack.add{'https://github.com/thiru/tabnv.nvim'}
```

### lazy.nvim

```lua
{
  'thiru/tabnv.nvim',
  ---@type tabnv.Config
  opts = {},
}
```

optional dependency if using the SSH picker (pick one):
- [telescope](https://github.com/nvim-telescope/telescope.nvim)
- [fzf-lua](https://github.com/ibhagwan/fzf-lua)

## how - usage

- start neovim normally
  - `<C-t>` to get a tab with a terminal
  - `<C-S-t>` to get a tab with a regular emtpy buffer
- start neovim with a terminal
  - `nvim +TabnvStart`

### common key binds

| Keymap      | Description                           |
|-------------|---------------------------------------|
| `<C-space>` | Escape terminal mode (to Normal mode) |
| `<C-t>`     | New terminal tab                      |
| `<C-S-t>`   | New tab (non-terminal)                |
| `<C-j>`     | Go to previous tab                    |
| `<C-k>`     | Go to next tab                        |
| `<C-[1-9]>` | Go to the specified numbered tab      |
| `<C-TAB>`   | Go to last active tab                 |
| `<C-S-r>`   | Rename current tab                    |
| `<C-,>`     | Move current tab to the left          |
| `<C-.>`     | Move current tab to the right         |
| `<C-v>`     | Paste from system clipboard           |

### leader key binds

| Keymap      | Description                                     |
|-------------|-------------------------------------------------|
| `<leader>t` | New terminal tab                                |
| `<leader>f` | New floating, centred terminal                  |
| `<leader>v` | New terminal (vertical split)                   |
| `<leader>h` | New terminal (horizontal split)                 |
| `<leader>r` | Rename current tab                              |
| `<leader>p` | Paste from system clipboard                     |
| `<leader>a` | Go to last accessed tab                         |
| `<leader>s` | Launch SSH connection picker                    |
| `<leader>d` | Close current tab                               |
| `<leader>w` | Set a window prefix (shown in the title)        |
| `<leader>q` | Safe quit (confirms if multiple terminals open) |

**auto-start command**

you can specify a command to run when the terminal starts via a global variable:

```shell
nvim +TabnvStart --cmd 'lua vim.g.tabnv_auto_start_cmd = "htop"'
```

## how - config

- see [config.lua](./lua/tabnv/config.lua) for the full configuration with defaults
- below is a summary of the available options

```lua
{
  -- optional colour scheme override (useful if you prefer a different theme for terminals)
  colorscheme = nil,

  -- the "leader" key used for many key binds (see keymap tables below)
  -- this avoids conflicts with nested vim instances (similar to tmux's Ctrl-B)
  leader = '<C-;>',

  -- callback invoked right before a terminal buffer is created
  on_before_term_created = nil,

  -- callback invoked right after a terminal buffer is created
  on_after_term_created = nil,

  -- callback invoked on tab change
  on_tab_changed = nil,

  ssh = {
    -- automatically reconnect SSH sessions when they disconnect
    auto_reconnect = true,

    -- automatically rename the tab to the SSH hostname when connecting
    auto_rename_tab = true,

    password_detection = {
      -- attempt to detect SSH password prompts and cache entered passwords
      enabled = true,

      -- lua patterns used to detect an SSH authentication request
      patterns = {
        'password:$',
        '^Enter passphrase for key.*:$',
      },
    },

    -- picker backend: 'auto' (try telescope first, then fzf-lua), 'telescope', or 'fzf-lua'
    picker = 'auto',
  },
}
```

## feature summary

### automatic tab naming

- tabs are automatically named after their current working directory
- if a terminal's directory changes (via `cd` or OSC 7 escape sequences), the tab name updates accordingly
- if you manually rename a tab (e.g. via  `<C-S-r>`), the automatic naming is disabled for that tab
and your custom name is preserved.

### window title

- the window/tab title is composed from
  - an optional window prefix (set via `<leader>w`)
  - the tab name itself

### floating terminal

- a centred, floating terminal window can be opened with `<leader>f`
- this is useful for quick commands without leaving your current layout

### osc 7 directory change support

- handles OSC 7 escape sequences (emitted by modern shells via [`osc7`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/osc7) or similar) to track directory changes inside the terminal
- the tab name and CWD are updated automatically

### auto-close empty tabs

- when you exit a shell in a terminal tab (TermLeave), the tab is automatically closed if it's empty
- if it's the last tab, neovim quits entirely

### tab mode and cursor position preservation

- saves and restores the mode (terminal Insert or Normal)
- and cursor position when switching between windows in a tab, so you don't lose your place

### ssh connection picker

- the ssh picker parses `~/.ssh/config` and `~/.ssh/known_hosts` and lets you quickly connect to any host
- it supports **telescope.nvim** and **fzf-lua**
- start the picker with `<leader>s` or by running
  - `:SshPicker`
- the default action (`<CR>`) will replace the current buffer
- alternative actions let you open the connection in a
  - **new tab** (`<C-t>`)
  - **horizontal split** (`<C-s>`)
  - **vertical split** (`<C-v>`)

#### auto-reconnect

- when `ssh.auto_reconnect` is enabled (default: `true`)
  - the SSH session is wrapped in a loop
  - and prompts you to press ENTER to reconnect after the session ends

#### password detection & caching

- when `ssh.password_detection.enabled` is `true` (default)
  - terminal output is monitored for ssh password prompts
  - and caches entered password so you don't have to re-enter it
