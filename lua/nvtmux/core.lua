local _ = require('nvtmux.utils')

local M = {
  state = {
    is_enabled = false,
  }
}

function M.is_auto_start()
  return vim.g.nvtmux_auto_start == true
end

function M.is_term_open()
  for _, v in pairs(vim.fn.getbufinfo({buflisted = 1})) do
    if v.variables.terminal_job_id ~= nil then
      return true
    end
  end
  return false
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

function M.handle_term_close()
  -- When switching tabs ensure we're in terminal insert mode
  vim.api.nvim_create_autocmd('TabEnter', {
    callback = function ()
      vim.schedule(function ()
        local terminal_job_id = vim.fn.getbufvar(vim.fn.bufnr(), 'terminal_job_id')
        if terminal_job_id ~= nil and vim.fn.mode() ~= 't' then
          vim.cmd.startinsert()
        end
      end)
    end,
    group = vim.api.nvim_create_augroup('nvtmux_tabenter', {clear = true}),
    pattern = '*',
  })

  vim.api.nvim_create_autocmd('TermClose', {
    callback = function()
      -- If we've come into another terminal ensure we're in insert mode
      if vim.fn.mode() == 't' then
        vim.api.nvim_input('i')
      end

      -- Exit if no there are no more terminals open
      vim.schedule(function()
        if not M.is_term_open() then
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
  local initial_mode = vim.fn.mode()

  local keys = vim.api.nvim_replace_termcodes("<C-\\><C-n>:file ", true, true, true)
  vim.api.nvim_feedkeys(keys, 'n', false)

  if initial_mode == 't' or initial_mode == 'i' then
    vim.schedule(function()
      vim.cmd('startinsert')
    end)
  end
end

function M.safe_quit()
  vim.schedule(function()
    if M.is_term_open() then
      local choice = vim.fn.confirm('Quit even though terminals are open?', '&Cancel\n&Quit')
      if choice == 2 then
        vim.cmd.qall()
      end
    else
      vim.cmd.qall()
    end
  end)
end

function M.go_to_tab(num)
  local all_tabs = vim.fn.gettabinfo()
  if #all_tabs > 1 then
    if num <= #all_tabs then
      if vim.fn.mode() == 't' then
        local keys = vim.api.nvim_replace_termcodes('<C-\\><C-n>' .. all_tabs[num].tabnr .. 'gt<CR>i', true, true, true)
        vim.api.nvim_feedkeys(keys, 'n', false)
      else
        vim.cmd('normal ' .. all_tabs[num].tabnr .. 'gt')
      end
    end
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
  -- Terminal - ESC
  vim.keymap.set('t', '<C-space>', '<C-\\><C-n>', {desc = 'Exit terminal mode'})

  -- Paste
  vim.keymap.set('t', '<C-S-v>', '<C-\\><C-n>pi', {desc = 'Paste from system clipboard (in terminal mode)'})

  -- Safe quit
  vim.keymap.set(
    {'n', 'v'},
    '<leader>q',
    M.safe_quit,
    {desc = 'Confirm quitting Neovim when terminals are still open'})

  -- Previous/next tab
  vim.keymap.set({'n', 't'}, '<C-S-TAB>', '<CMD>tabprevious<CR>', {desc = 'Next tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-TAB>', '<CMD>tabnext<CR>', {desc = 'Previous tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-S-j>', '<CMD>tabprevious<CR>', {desc = 'Next tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-S-k>', '<CMD>tabnext<CR>', {desc = 'Previous tab', silent = true})

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

  -- New terminal tab
  vim.keymap.set(
    {'n', 't'},
    '<C-t>',
    M.new_tab,
    {desc = 'Open terminal in new tab'})

  -- New vertical split terminal
  vim.keymap.set(
    {'n', 't'},
    '<C-S-t>',
    '<C-\\><C-N><C-w>v<C-w><C-w><CMD>terminal<CR><CMD>startinsert<CR>',
    {desc = 'Open terminal in new vertical split'})

  -- New horizontal split terminal
  vim.keymap.set(
    {'n', 't'},
    '<C-S-h>',
    '<C-\\><C-N><C-w>s<C-w><C-w><CMD>terminal<CR><CMD>startinsert<CR>',
    {desc = 'Open terminal in new horizontal split'})

  -- Rename tab
  vim.keymap.set(
    {'n', 't'},
    '<C-S-r>',
    M.rename_tab_prompt,
    {desc = 'Rename current tab'})

  -- Move tab left/right
  vim.keymap.set({'n', 't'}, '<C-,>', function() M.move_tab('left') end, {desc = 'Move tab to the left'})
  vim.keymap.set({'n', 't'}, '<C-.>', function() M.move_tab('right') end, {desc = 'Move tab to the right'})

  vim.keymap.set({'n', 't'}, '<C-S-s>', '<CMD>:NvtmuxTelescopeSshPicker<CR>', {desc = 'Telescope SSH picker'})
end

return M
