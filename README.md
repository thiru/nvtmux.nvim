# nvtmux

**NOTE: This plugin is at a very early, experimental stage. I would say it's not ready for public consumption.**

nvtmux is short for Neovim terminal multiplexor. The intent of this plugin is to use Neovim alone in
place of tools like Tmux. Though Tmux is more than a multiplexor. It also supports persistence and
sessions. I don't plan to support these here as personally don't have a need for them.

## Installation

For lazy.nvim:

```lua
{
  'thiru/nvtmux.nvim',
  opts = {
    colorscheme = 'catppuccin-mocha'
  }
}
```
