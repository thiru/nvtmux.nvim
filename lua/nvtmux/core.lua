local _ = require('nvtmux.utils')

local M = {}

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

function M.setup_bufferline(bufferline_opts)
  local success, bufferline = pcall(require, 'bufferline')

  if success then
    local bufferline_setup_spec = {
      options = vim.tbl_extend(
        'error',
        {
          always_show_bufferline = false,
          mode = 'tabs'
        },
        (bufferline_opts or {}))
    }
    bufferline.setup(bufferline_setup_spec)
  end
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
  vim.api.nvim_create_autocmd('TermClose', {
    callback = function()
      -- If we've come into another terminal ensure we're in insert mode
      if vim.fn.mode() == 't' then
        vim.api.nvim_input('i')
      end

      -- Exit if no there are no more terminals open
      vim.schedule(function()
        if not M.is_term_open() then
          vim.cmd(':q')
        end
      end)
    end,
    group = vim.api.nvim_create_augroup('nvtmux', {clear = true}),
    pattern = '*',
  })
end

function M.keybinds(state)
  -- Safe quit
  vim.keymap.set({'n', 'v'},
    '<leader>q',
    function()
      vim.schedule(function()
        if M.is_term_open() then
          local choice = vim.fn.confirm('Quit even though terminals are open?', '&Cancel\n&Quit')
          if choice == 2 then
            vim.cmd(':qall')
          end
        else
          vim.cmd(':qall')
        end
      end)
    end,
    {desc = 'Confirm quitting Neovim when terminals are still open'})

  -- Previous/next tab
  vim.keymap.set({'n', 't'}, '<C-S-TAB>', '<CMD>tabprevious<CR>', {desc = 'Next tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-TAB>', '<CMD>tabnext<CR>', {desc = 'Previous tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-S-j>', '<CMD>tabprevious<CR>', {desc = 'Next tab', silent = true})
  vim.keymap.set({'n', 't'}, '<C-S-k>', '<CMD>tabnext<CR>', {desc = 'Previous tab', silent = true})

  -- Go to tab #
  local function goto_tabnr(tabnr, all_tabs)
    if tabnr <= #all_tabs then
      if vim.fn.mode() == 't' then
        local keys = vim.api.nvim_replace_termcodes('<C-\\><C-n>' .. all_tabs[tabnr].tabnr .. 'gt<CR>i', true, true, true)
        vim.api.nvim_feedkeys(keys, 'n', false)
      else
        vim.cmd('normal ' .. all_tabs[tabnr].tabnr .. 'gt')
      end
    end
  end

  for i=1,9 do
    vim.keymap.set(
      {'i', 'n', 't', 'v'},
      '<C-' .. i .. '>',
      function()
        local all_tabs = vim.fn.gettabinfo()
        if #all_tabs > 1 then
          goto_tabnr(i, all_tabs)
        end
      end,
      {desc = 'Go to tab by index', silent=true})
  end

  -- New tab with terminal
  vim.keymap.set(
    {'n', 't'},
    '<C-t>',
    function()
      vim.cmd('tabnew')
      vim.cmd('terminal')
      vim.cmd('startinsert')

      state.tab_count = state.tab_count + 1
      vim.cmd('file ' .. state.tab_count)
    end,
    {desc = 'Open terminal in new tab'})

  -- New vertical split with terminal
  vim.keymap.set({'n', 't'}, '<C-S-t>', '<C-\\><C-N><C-w>v<C-w><C-w><CMD>terminal<CR><CMD>startinsert<CR>',
    {desc = 'Open terminal in new vertical split'})

  -- New horizontal split with terminal
  vim.keymap.set({'n', 't'}, '<C-S-h>', '<C-\\><C-N><C-w>s<C-w><C-w><CMD>terminal<CR><CMD>startinsert<CR>',
    {desc = 'Open terminal in new horizontal split'})

  -- Terminal - ESC
  vim.keymap.set('t', '<C-space>', '<C-\\><C-n>', {desc = 'Exit terminal mode'})

  -- Paste
  vim.keymap.set('t', '<C-S-v>', '<C-\\><C-n>pi', {desc = 'Paste from system clipboard (in terminal mode)'})

  -- Rename tab
  vim.keymap.set(
    {'n', 't'},
    '<C-n>',
    function()
      vim.ui.input(
        {prompt = 'Tab name: '},
        function(input)
          if input and #input > 0 then
            vim.cmd('file ' .. input)
          end
        end)
    end,
    {desc = 'Rename current tab'})
end

return M
