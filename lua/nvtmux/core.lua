--- Contains the core functionality of this plugin.

local M = {
  state = {}
}

local u = require('nvtmux.utils')

--- Setup core aspects of the plugin.
---@param config nvtmux.Config
function M.setup(config)
  M.config = config
  M.save_original_opts()
  M.set_keybinds()
  M.create_usercmds()
  M.create_autocmds()
end

function M.save_original_opts()
  M.state.original_opts = {
    cursorline = vim.opt.cursorline:get(),
    number = vim.opt.number:get(),
    relativenumber = vim.opt.relativenumber:get(),
    scrolloff = vim.opt.scrolloff:get(),
    signcolumn = vim.opt.signcolumn:get(),
    title = vim.opt.title:get(),
  }
end

--- Set (subjectively) optimal settings for a good terminal experience.
function M.set_term_opts()
  vim.opt.cursorline = false
  vim.opt.scrolloff = 0
  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.opt.signcolumn = 'no'
  vim.opt.title = true

  if M.config.colorscheme and (vim.g.colors_name ~= M.config.colorscheme) then
    M.state.original_opts.colors_name = vim.g.colors_name
    vim.cmd.colorscheme(M.config.colorscheme)
  end

  M.state.is_term_tab = true
end

-- Undo options set in `M.set_term_opts`.
function M.unset_term_opts()
  vim.opt.cursorline = M.state.original_opts.cursorline
  vim.opt.scrolloff = M.state.original_opts.scrolloff
  vim.opt.number = M.state.original_opts.number
  vim.opt.relativenumber = M.state.original_opts.relativenumber
  vim.opt.signcolumn = M.state.original_opts.signcolumn
  vim.opt.title = M.state.original_opts.title

  if M.state.original_opts.colors_name then
    vim.cmd.colorscheme(M.state.original_opts.colors_name)
  end

  M.state.is_term_tab = false
end

--- Create user commands.
function M.create_usercmds()
  vim.api.nvim_create_user_command('NvtmuxStart', function()
    M.set_term_opts()
    vim.cmd.terminal()
    vim.cmd.startinsert()
  end, {})
end

--- Create various auto-commands to provide a more seamless experience such as:
--- - updating the OS window title to that of the current tab
--- - ensure we're in insert mode after switching to another tab
--- - setting optimal terminal options or undoing them
function M.create_autocmds()
  vim.api.nvim_create_autocmd('TabEnter', {
    callback = function ()
      u.update_window_title()

      vim.schedule(function ()
        if u.is_terminal_buf() then
          local ok, tabdir = pcall(vim.api.nvim_tabpage_get_var, 0, 'tabdir')
          if ok then
            vim.cmd('cd ' .. tabdir)
          end

          if M.config.on_tab_changed then
            M.config.on_tab_changed(true)
          end
          if not M.state.is_term_tab then
            M.set_term_opts()
          end
          -- When switching tabs ensure we're in terminal insert mode
          if vim.fn.mode() ~= 't' then
            vim.cmd.startinsert()
          end
        else
          if M.config.on_tab_changed then
            M.config.on_tab_changed(false)
          end
          if M.state.is_term_tab then
            M.unset_term_opts()
          end
        end
      end)
    end,
    group = vim.api.nvim_create_augroup('nvtmux_tabenter', {clear = true}),
    pattern = '*',
  })

  -- Avoid 'modifiable is off' message and allow terminal to be editable
  vim.api.nvim_create_autocmd('TermOpen', {
    callback = function()
      vim.opt_local.modifiable = true
    end,
    group = vim.api.nvim_create_augroup('nvtmux_termopen', {}),
    pattern = '*',
  })

  vim.api.nvim_create_autocmd('TermClose', {
    callback = function()
      -- Avoid "Process exited 0" message
      vim.api.nvim_input('<CR>')

      -- Ensure we're in insert mode if we've come into another terminal buffer
      -- HACK: Not sure why I need to set `startinsert` in a timeout. It doesn't seem to work otherwise.
      if u.is_terminal_buf() then
        local timer = vim.uv.new_timer()
        if timer ~= nil then
          timer:start(10, 0, function()
            timer:stop()
            timer:close()
            vim.schedule(function()
              -- NOTE: ensure we're still in a terminal buffer
              if u.is_terminal_buf() then
                vim.cmd.startinsert()
              end
            end)
          end)
        end
      end
    end,
    group = vim.api.nvim_create_augroup('nvtmux_termclose', {}),
    pattern = '*',
  })

  -- Close tab if empty, or exit Neovim altogether if this is also the last tab
  vim.api.nvim_create_autocmd('TermLeave', {
    callback = function()
      vim.schedule(function()
        if M.state.is_term_tab and u.is_empty_tab() then
          local tabs = vim.api.nvim_list_tabpages()
          if #tabs == 1 then
            vim.cmd.quit()
          else
            vim.cmd.tabclose()
          end
        end
      end)
    end,
    group = vim.api.nvim_create_augroup('nvtmux_termleave', {}),
    pattern = '*',
  })

  -- Use CWD for tab name if custom name not already set
  -- NOTE: The DirChangedPre event is used instead of DirChanged in order capture the original
  -- path before vim alters it by resolving symlinks.
  vim.api.nvim_create_autocmd('DirChangedPre', {
    callback = function(ev)
      u.auto_set_tab_name(ev.file)
    end,
    group = vim.api.nvim_create_augroup('nvtmux_dirchangedpre', {}),
    pattern = '*',
  })
end

--- Create a new tab with a terminal and enter insert mode.
function M.new_tab()
  vim.cmd('tabnew')
  vim.cmd.terminal()
  vim.cmd.startinsert()
  u.auto_set_tab_name(vim.fn.getcwd())
end

--- Show prompt to rename the current tab.
function M.rename_tab_prompt()
  local curr_name = u.get_tab_name()
  local new_name = vim.fn.input('Tab Name: ', curr_name)

  if #new_name > 0 then
    u.set_tab_name(new_name)
    u.update_window_title()
  end
end

--- Show prompt to set a window prefix.
function M.set_window_prefix_prompt()
  local curr_prefix = vim.g.nvtmux_window_prefix or ''
  local new_prefix = vim.fn.input('Window Prefix: ', curr_prefix)

  if #new_prefix > 0 then
    vim.g.nvtmux_window_prefix = new_prefix
    u.update_window_title()
  end
end

--- Safely quit Neovim. I.e. if more than one terminal session is open prompt the user first.
function M.safe_quit()
  vim.schedule(function()
    if u.num_terms_open() > 1 then
      local choice = vim.fn.confirm('Quit even though terminals are open?', '&Cancel\n&Quit')
      if choice == 2 then
        vim.cmd('qall!')
      end
    else
      vim.cmd('qall!')
    end
  end)
end

--- Go to the specified tab number
---@param num number
function M.go_to_tab(num)
  local tab_handles = vim.api.nvim_list_tabpages()
  if (#tab_handles > 1) and (num <= #tab_handles) then
    vim.api.nvim_set_current_tabpage(tab_handles[num])
  end
end

--- Move the current tab in the respective direction.
---@param dir number Moves the current tab to the left if negative and to the right if positive.
function M.move_tab(dir)
  if dir == 0 then
    return
  elseif dir < 0 then
    vim.cmd('-tabmove')
  elseif dir > 0 then
    vim.cmd('+tabmove')
  end

  vim.cmd('redraw!')
end

--- Define key bindings. These are mostly leader-key-based.
function M.set_keybinds()
  -- Terminal ESC
  vim.keymap.set('t', '<C-;>', '<C-\\><C-n>', {desc = 'Terminal mode -> normal mode'})

  -- Up/down
  vim.keymap.set('t', '<C-j>', '<Down>', {desc = 'Terminal mode -> down arrow'})
  vim.keymap.set('t', '<C-k>', '<Up>', {desc = 'Terminal mode -> up arrow'})

  -- Paste
  vim.keymap.set('t', '<C-v>',
    function()
      local terminal_job_id = vim.fn.getbufvar(vim.fn.bufnr(), 'terminal_job_id')
      vim.api.nvim_chan_send(terminal_job_id, vim.fn.getreg('+'))
    end,
    {desc = 'Paste from system clipboard'})
  vim.keymap.set('t', M.config.leader .. 'p',
    function()
      local terminal_job_id = vim.fn.getbufvar(vim.fn.bufnr(), 'terminal_job_id')
      vim.api.nvim_chan_send(terminal_job_id, vim.fn.getreg('+'))
    end,
    {desc = 'Paste from system clipboard'})

  -- Safe quit
  vim.keymap.set({'n', 't'}, M.config.leader .. 'q', M.safe_quit, {desc = 'Quit (confirm if multiple terms open)'})

  -- Previous/next tab
  vim.keymap.set({'n', 't'}, '<C-S-TAB>', '<CMD>tabprevious<CR>', {desc = 'Previous tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-TAB>', '<CMD>tabnext<CR>', {desc = 'Next tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-S-j>', '<CMD>tabprevious<CR>', {desc = 'Previous tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-S-k>', '<CMD>tabnext<CR>', {desc = 'Next tab', silent = true})

  -- Go to tab by index
  for i=1,9 do
    vim.keymap.set(
      {'i', 'n', 't', 'v'},
      '<C-' .. i .. '>',
      function() M.go_to_tab(i) end,
      {desc = 'Go to tab by index', silent=true})
  end

  -- Alternate tab
  vim.keymap.set({'n', 't'}, '<C-`>', '<CMD>:tabnext #<CR>', {desc = 'Go to alternate tab', silent = true})
  vim.keymap.set({'n', 't'}, M.config.leader .. 'a', '<CMD>:tabnext #<CR>', {desc = 'Go to alternate tab', silent = true})

  -- New terminal tab
  vim.keymap.set('t', '<C-t>', M.new_tab, {desc = 'New terminal (tab)'})
  vim.keymap.set({'n', 't'}, M.config.leader .. 't', M.new_tab, {desc = 'New terminal (tab)'})

  -- Tab close
  vim.keymap.set('n', M.config.leader .. 'd', '<CMD>tabclose<CR>', {desc = 'Close tab'})

  -- New vertical split terminal
  vim.keymap.set(
    {'n', 't'},
    M.config.leader .. 'v',
    function()
      vim.cmd.vsplit()
      vim.cmd.enew()
      vim.cmd.terminal()
      vim.cmd.startinsert()
    end,
    {desc = 'New terminal (vertical split)'})

  -- New horizontal split terminal
  vim.keymap.set(
    {'n', 't'},
    M.config.leader .. 'h',
    function()
      vim.cmd.split()
      vim.cmd.enew()
      vim.cmd.terminal()
      vim.cmd.startinsert()
    end,
    {desc = 'New terminal (horizontal split)'})

  -- Rename tab
  vim.keymap.set({'n', 't'}, '<C-S-r>', M.rename_tab_prompt, {desc = 'Rename tab'})
  vim.keymap.set({'n', 't'}, M.config.leader .. 'r', M.rename_tab_prompt, {desc = 'Rename tab'})

  -- Move tab left/right
  vim.keymap.set({'n', 't'}, '<C-,>', function() M.move_tab(-1) end, {desc = 'Move tab left'})
  vim.keymap.set({'n', 't'}, '<C-.>', function() M.move_tab(1) end, {desc = 'Move tab right'})

  -- SSH picker
  vim.keymap.set({'n', 't'}, M.config.leader .. 's', '<CMD>SshPicker<CR>', {desc = 'Launch [S]SH connection picker'})

  -- Window prefix
  vim.keymap.set({'n', 't'}, M.config.leader .. 'w', M.set_window_prefix_prompt, {desc = 'Set [W]indow Prefix'})
end

return M
