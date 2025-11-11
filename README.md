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
  'thiru/nvtmux.nvim',

  depedencies = {
    'nvim-lualine/lualine.nvim', -- (optional) Has a nice tabline
    'nvim-telescope/telescope.nvim' -- (optional) Used by the SSH connection picker
  },

  ---@type nvtmux.Config
  opts = {},
}
```

## Configuration

See [config.lua](./lua/nvtmux/config.lua) for details on the configuration.

## Usage

You likely don't want this plugin to start every time you run Neovim as it alters the appearance
and behaviour considerably in order to behave as a terminal multiplexor. So, you can either start
it manually after starting Neovim with the `:NvtmuxStart` command, or you can use this command on
start-up like so:

```shell
nvim +NvtmuxStart
```

As in tmux, nvtmux uses a prefix for many of its commands so that they don't conflict with possibly
nested vim instances. By default this is set to `<C-space>`.

| Keymap       | Description                                    |
|--------------|------------------------------------------------|
| `<C-space>t` | New terminal (tab)                             |
| `<C-space>v` | New terminal (vertical split)                  |
| `<C-space>h` | New terminal (horizontal split)                |
| `<C-space>r` | Rename current tab                             |
| `<C-space>p` | Paste from system clipboard                    |
| `<C-space>l` | Go to last accessed tab                        |
| `<C-space>s` | Launch SSH connection picker                   |
| `<C-space>q` | Safe quit (confirm if multiple terminals open) |

Non-leader key bindings:

| Keymap       | Description                                    |
|--------------|------------------------------------------------|
| `<C-;>`      | Escape terminal mode                           |
| `<C-t>`      | New terminal (tab)                             |
| `<C-S-t>`    | New terminal (vertical split)                  |
| `<C-S-h>`    | New terminal (horizontal split)                |
| `<C-S-r>`    | Rename current tab                             |
| `<C-v>`      | Paste from system clipboard                    |
| `<C-TAB>`    | Next tab                                       |
| `<C-S-k>`    | Next tab                                       |
| `<C-S-TAB>`  | Previous tab                                   |
| `<C-S-j>`    | Previous tab                                   |
| `<C-[NUM]>`  | Go to the specified numbered tab               |
| `<C-tilde>`  | Go to last accessed tab                        |
| `<C-,>`      | Move current tab to the left                   |
| `<C-.>`      | Move current tab to the right                  |

**Auto-Start Command**

It's also possible to specify a command to run when the terminal starts like so:

```shell
nvim +NvtmuxStart --cmd 'lua vim.g.nvtmux_auto_start_cmd = "htop"'
```

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
