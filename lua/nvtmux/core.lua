local u = require('nvtmux.utils')
local tabs = require('nvtmux.tabs')

local M = {}

M.config = {
  colorscheme = nil,
  leader = '<C-space>'
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts)
  M.set_term_opts()
  M.setup_autocmds()
  M.set_default_keybinds()
  tabs.init()
end

function M.set_term_opts()
  vim.opt.cursorline = false
  vim.opt.scrolloff = 0
  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.opt.signcolumn = 'no'
  vim.opt.laststatus = 0
  vim.opt.cmdheight = 0
  vim.opt.title = true

  if M.config.colorscheme ~= nil then
    vim.cmd.colorscheme(M.config.colorscheme)
  end
end

function M.setup_autocmds()
  vim.api.nvim_create_autocmd('TabEnter', {
    callback = function ()
      -- Update window title
      vim.opt.titlestring = tabs.get_tab_name()

      -- When switching tabs ensure we're in terminal insert mode
      vim.schedule(function ()
        if u.is_terminal_buf() and vim.fn.mode() ~= 't' then
          vim.cmd.startinsert()
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

  -- Ensure we're in insert mode if we've come into another terminal buffer
  vim.api.nvim_create_autocmd('TermClose', {
    callback = function()
      -- HACK: Not sure why I need to set `startinsert` in a timeout. It doesn't seem to work otherwise.
      if u.is_terminal_buf() then
        local timer = vim.uv.new_timer()
        timer:start(10, 0, function()
          timer:stop()
          timer:close()
          vim.schedule(function()
            vim.cmd.startinsert()
          end)
        end)
      end
    end,
    group = vim.api.nvim_create_augroup('nvtmux_termclose', {}),
    pattern = '*',
  })

  -- Exit if no there are no more terminals open
  vim.api.nvim_create_autocmd('TermLeave', {
    callback = function()
      vim.schedule(function()
        if u.num_terms_open() == 0 then
          vim.cmd.quit()
        end
      end)
    end,
    group = vim.api.nvim_create_augroup('nvtmux_termleave', {}),
    pattern = '*',
  })
end

function M.new_tab()
  vim.cmd('tabnew')
  vim.cmd.terminal()
  vim.cmd.startinsert()
end

function M.rename_tab_prompt()
  local curr_name = tabs.get_tab_name()
  local new_name = vim.fn.input('Tab Name', curr_name)

  if #new_name > 0 then
    tabs.set_tab_name(new_name)
  end
end

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

function M.go_to_tab(num)
  local tab_handles = vim.api.nvim_list_tabpages()
  if (#tab_handles > 1) and (num <= #tab_handles) then
    vim.api.nvim_set_current_tabpage(tab_handles[num])
  end
end

function M.move_tab(dir)
  if dir == 'left' then
    vim.cmd('-tabmove')
  else
    vim.cmd('+tabmove')
  end

  vim.cmd('redraw!')
end

function M.set_default_keybinds()
  -- Terminal ESC
  vim.keymap.set('t', '<C-;>', '<C-\\><C-n>', {desc = 'Terminal mode -> normal mode'})

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

  -- Last accessed tab
  vim.keymap.set({'n', 't'}, '<C-`>', '<CMD>:tabnext #<CR>', {desc = 'Go to last accessed tab', silent = true})
  vim.keymap.set({'n', 't'}, M.config.leader .. 'l', '<CMD>:tabnext #<CR>', {desc = 'Go to last accessed tab', silent = true})

  -- New terminal tab
  vim.keymap.set({'n', 't'}, '<C-t>', M.new_tab, {desc = 'New terminal (tab)'})
  vim.keymap.set({'n', 't'}, M.config.leader .. 't',
    function()
      M.new_tab()
      M.rename_tab_prompt()
    end,
    {desc = 'New terminal (tab)'})

  -- New vertical split terminal
  vim.keymap.set(
    {'n', 't'},
    '<C-S-t>',
    function()
      vim.cmd.vsplit()
      vim.cmd.enew()
      vim.cmd.terminal()
      vim.cmd.startinsert()
    end,
    {desc = 'New terminal (vertical split)'})
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
    '<C-S-h>',
    function()
      vim.cmd.split()
      vim.cmd.enew()
      vim.cmd.terminal()
      vim.cmd.startinsert()
    end,
    {desc = 'New terminal (horizontal split)'})
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
  vim.keymap.set({'n', 't'}, '<C-,>', function() M.move_tab('left') end, {desc = 'Move tab left'})
  vim.keymap.set({'n', 't'}, '<C-.>', function() M.move_tab('right') end, {desc = 'Move tab right'})

  -- SSH picker
  vim.keymap.set({'n', 't'}, M.config.leader .. 's', '<CMD>SshPicker<CR>', {desc = 'Launch [S]SH connection picker'})
end

return M
