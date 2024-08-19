local tr = require('nvtmux.tab-rename')
local _ = require('nvtmux.utils')

local M = {
  state = {
    is_enabled = false,
  }
}

function M.is_terminal_buf()
  return type(vim.fn.getbufvar(vim.fn.bufnr(), 'terminal_job_id')) == 'number'
end

function M.num_terms_open()
  local num_terms = 0

  for _, v in pairs(vim.fn.getbufinfo({buflisted = 1})) do
    if type(v.variables.terminal_job_id) == 'number' then
      num_terms = num_terms + 1
    end
  end

  return num_terms
end

function M.set_term_opts(opts)
  vim.opt.cursorline = false
  vim.opt.scrolloff = 0
  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.opt.signcolumn = 'no'
  vim.opt.laststatus = 0
  vim.opt.title = true
  if opts.colorscheme ~= nil then
    vim.cmd.colorscheme(opts.colorscheme)
  end
end

function M.setup_autocmds()
  vim.api.nvim_create_autocmd('TabEnter', {
    callback = function ()
      -- Update window title
      vim.opt.titlestring = vim.fn.getbufvar('%', 'tab_title') .. ''

      -- When switching tabs ensure we're in terminal insert mode
      vim.schedule(function ()
        if M.is_terminal_buf() and vim.fn.mode() ~= 't' then
          vim.cmd.startinsert()
        end
      end)
    end,
    group = vim.api.nvim_create_augroup('nvtmux_tabenter', {clear = true}),
    pattern = '*',
  })

  vim.api.nvim_create_autocmd('TermClose', {
    callback = function()
      -- HACK: If we've come into another terminal buffer, ensure we're in insert mode.
      -- Not sure why I need to set `startinsert` in a timeout. It doesn't seem to work otherwise.
      if M.is_terminal_buf() then
        local timer = vim.uv.new_timer()
        timer:start(10, 0, function()
          timer:stop()
          timer:close()
          vim.schedule(function()
            vim.cmd.startinsert()
          end)
        end)
      end

      -- Exit if no there are no more terminals open
      vim.schedule(function()
        if M.num_terms_open() == 0 then
          vim.cmd.quit()
        end
      end)
    end,
    group = vim.api.nvim_create_augroup('nvtmux_termclose', {clear = true}),
    pattern = '*',
  })
end

function M.new_tab()
  vim.cmd('tabnew')
  vim.cmd.terminal()
  vim.cmd.startinsert()
end

function M.rename_tab_prompt()
  tr.state.last_bufnr = vim.api.nvim_get_current_buf()
  local input = tr.state.nui_input or tr.create_nui_input()

  input:mount()
  vim.schedule(function()
    vim.cmd.startinsert()
  end)
end

function M.safe_quit()
  vim.schedule(function()
    if M.num_terms_open() > 1 then
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
  local has_whichkey = pcall(function() require('which-key') end)

  -- Prefix to launch which-key
  if has_whichkey then
    vim.keymap.set('t', '<C-a>', '<C-\\><C-N><CMD>WhichKey <C-a><CR>', {desc = 'Launch which-key with terminal-specific functions'})
  end

  -- Terminal - ESC
  vim.keymap.set('t', '<C-space>', '<C-\\><C-n>', {desc = 'Exit terminal mode'})

  -- Paste
  vim.keymap.set('t', '<C-S-v>', '<C-\\><C-n>pi', {desc = 'Paste from system clipboard'})
  if has_whichkey then
    vim.keymap.set('n', '<C-a>p', 'pi', {desc = 'Paste from system clipboard'})
  end

  -- Safe quit
  vim.keymap.set('n', '<leader>q', M.safe_quit, {desc = 'Quit (confirm if multiple terms open)'})
  if has_whichkey then
    vim.keymap.set('n', '<C-a>q', M.safe_quit, {desc = 'Quit (confirm if multiple terms open)'})
  end

  -- Previous/next tab
  vim.keymap.set({'n', 't'}, '<C-S-TAB>', '<CMD>tabprevious<CR>', {desc = 'Next tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-TAB>', '<CMD>tabnext<CR>', {desc = 'Previous tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-S-j>', '<CMD>tabprevious<CR>', {desc = 'Next tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-S-k>', '<CMD>tabnext<CR>', {desc = 'Previous tab', silent = true})

  -- Go to tab by index
  for i=1,9 do
    vim.keymap.set(
      {'i', 'n', 't', 'v'},
      '<C-' .. i .. '>',
      function()
        M.go_to_tab(i)
      end,
      {desc = 'Go to tab by index', silent=true})
  end

  -- Last accessed tab
  vim.keymap.set({'n', 't'}, '<C-`>', '<CMD>:tabnext #<CR>', {desc = 'Go to last accessed tab', silent = true})
  if has_whichkey then
    vim.keymap.set('n', '<C-a>l', '<CMD>:tabnext #<CR>', {desc = 'Go to last accessed tab', silent = true})
  end

  -- New terminal tab
  vim.keymap.set({'n', 't'}, '<C-t>', M.new_tab, {desc = 'New terminal (tab)'})
  if has_whichkey then
    vim.keymap.set('n', '<C-a>t',
      function()
        M.new_tab()
        M.rename_tab_prompt()
      end,
      {desc = 'New terminal (tab)'})
  end

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
  if has_whichkey then
    vim.keymap.set(
      'n',
      '<C-a>v',
      function()
        vim.cmd.vsplit()
        vim.cmd.enew()
        vim.cmd.terminal()
        vim.cmd.startinsert()
      end,
      {desc = 'New terminal (vertical split)'})
  end

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
  if has_whichkey then
    vim.keymap.set(
      {'n', 't'},
      '<C-a>h',
      function()
        vim.cmd.split()
        vim.cmd.enew()
        vim.cmd.terminal()
        vim.cmd.startinsert()
      end,
      {desc = 'New terminal (horizontal split)'})
  end

  -- Rename tab
  vim.keymap.set({'n', 't'}, '<C-S-r>', M.rename_tab_prompt, {desc = 'Rename tab'})
  if has_whichkey then
    vim.keymap.set('n', '<C-a>r', M.rename_tab_prompt, {desc = 'Rename tab'})
  end

  -- Move tab left/right
  vim.keymap.set({'n', 't'}, '<C-,>', function() M.move_tab('left') end, {desc = 'Move tab left'})
  vim.keymap.set({'n', 't'}, '<C-.>', function() M.move_tab('right') end, {desc = 'Move tab right'})
end

return M
