# nvtmux

**_NOTE:_ This plugin is alpha quality and probably not ready for public consumption.**

nvtmux is short for Neovim terminal multiplexor.

## Rationale

I use the terminal a lot and I want to have the full power of vim at my disposal to navigate its
contents. Even the most popular terminal apps (e.g. Alacritty, Kitty, Wezterm) have a fraction of
the capabilities of vim when it comes to navigating text. So, I use Neovim's terminal emulator.

I also like the multiplexing capabilities of tools like tmux, such as tabs and windows. Vim also
has these capabilities but the out-of-the-box experience is not at all ergonomic when used in
conjunction with the terminal emulator. The aim of this plugin is to improve this workflow.

## Installation

Minimal lazy.nvim config:

```lua
{
  'thiru/nvtmux.nvim'
}
```

## Configuration

Detailed lazy.nvim config:

```lua
{
  'thiru/nvtmux.nvim',
  -- See below for why cond is used
  cond = vim.g.nvtmux_auto_start == true,
  depedencies = {
    'nvim-telescope/telescope.nvim'}, -- For the SSH connection picker (optional)
  opts = {
    colorscheme = 'catppuccin-mocha',
    leader = '<C-a>',
    ssh = {
      -- Auto-reconnect SSH connections (on prompt)
      auto_reconnect = true,
      -- Whether to automically rename the tab/buffer to the hostname of the SSH connection
      auto_rename_buf = true,
      -- Whether to cache passwords/passphrases when prompted
      cache_passwords = true,
      -- Lua patterns used to detect an SSH password prompt
      password_detect_patterns = {
        'password:$',
        '^Enter passphrase for key'},
    },
  },
}
```

## Usage

You probably don't always want to start this plugin since it alters the appears and behaviour of
Neovim to behave as a terminal multiplexor. This is the purpose of the `cond` expression in the
Lazy config above.

I would recommend creating an alias or shortcut in your OS to start Neovim like so:

```shell
nvim --cmd 'lua vim.g.nvtmux_auto_start = true'
```

As in tmux, nvtmux uses a prefix for most of its commands so that they don't conflict with possibly
nested vim instances. By default this is set to `<C-a>`.

| Keymap      | Description                                    |
|-------------|------------------------------------------------|
| `<C-;>`     | Escape terminal mode                           |
| `<C-space>` | Launch which-key with terminal-specific cmds   |
| `<C-t>`     | New terminal (tab)                             |
| `<C-a>t`    | New terminal (tab)                             |
| `<C-S-t>`   | New terminal (vertical split)                  |
| `<C-a>v`    | New terminal (vertical split)                  |
| `<C-S-h>`   | New terminal (horizontal split)                |
| `<C-a>h`    | New terminal (horizontal split)                |
| `<C-a>h`    | New terminal (horizontal split)                |
| `<C-S-r>`   | Rename current tab                             |
| `<C-a>r`    | Rename current tab                             |
| `<C-v>`     | Paste from system clipboard                    |
| `<C-a>p`    | Paste from system clipboard                    |
| `<C-TAB>`   | Next tab                                       |
| `<C-S-k>`   | Next tab                                       |
| `<C-S-TAB>` | Previous tab                                   |
| `<C-S-j>`   | Previous tab                                   |
| `<C-[NUM]>` | Go to the specified numbered tab               |
| `<C-tilde>` | Go to last accessed tab                        |
| `<C-a>l`    | Go to last accessed tab                        |
| `<C-,>`     | Move current tab to the left                   |
| `<C-.>`     | Move current tab to the right                  |
| `<leader>q` | Safe quit (confirm if multiple terminals open) |
| `<C-a>q`    | Safe quit (confirm if multiple terminals open) |
| `<C-a>s`    | Launch SSH connection picker                   |

### SSH Connection Picker

To start the Telescope SSH connection picker use the keymap defined above or run:

```vim
:SshPicker
```

All actions will start an instance of Neovim's terminal emulator. The default action (`<CR>`)
will use the current buffer. You can also use Telescope's alternative actions to open the SSH
connection in a new:

- tab (`<C-t>`)
- horizontal split (`<C-x>`)
- vertical split (`<C-v>`)

Note, the above bindings are Telescope defaults. You can change these in your Telescope config.
