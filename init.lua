-- Options
vim.g.mapleader = ' '

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = false
vim.opt.autoindent = true
vim.opt.smarttab = true
vim.opt.swapfile = false
vim.opt.winborder = 'rounded'

vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldlevelstart = 99

-- Keymaps
local function feed(key)
  return function()
    local k = vim.api.nvim_replace_termcodes(key, true, false, true)
    vim.api.nvim_feedkeys(k, 'm', false)
  end
end

vim.keymap.set('n', 'ö', feed('['), { desc = '[' })
vim.keymap.set('n', 'ä', feed(']'), { desc = ']' })

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { noremap = true, silent = true })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>w', ':write<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')
vim.keymap.set('n', '<leader>F', vim.lsp.buf.format)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)

vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gr', vim.lsp.buf.references)

-- Autocommands
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Plugins
vim.pack.add {
  'https://github.com/vague-theme/vague.nvim',
  'https://github.com/nmac427/guess-indent.nvim',
  'https://github.com/nvim-mini/mini.icons',
  'https://github.com/nvim-mini/mini.surround',
  'https://github.com/nvim-mini/mini.ai',
  'https://github.com/nvim-mini/mini.statusline',
  'https://github.com/nvim-mini/mini.pairs',
  'https://github.com/nvim-mini/mini.pick',
  'https://github.com/nvim-mini/mini.extra',
  'https://github.com/chomosuke/typst-preview.nvim',
  'https://github.com/stevearc/oil.nvim',
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/mason-org/mason.nvim',
}

vim.cmd 'colorscheme vague'

require('guess-indent').setup()
require('mini.icons').setup()
require('mini.surround').setup()
require('mini.ai').setup { n_lines = 100 }
require('mini.statusline').setup()
require('mini.pairs').setup()
require('mini.pick').setup()
require('mini.extra').setup()

require('typst-preview').setup {
  dependencies_bin = { ['tinymist'] = 'tinymist' },
  open_cmd = 'firefox %s -P typst-preview --class typst-preview',
}

require('oil').setup { default_file_explorer = true }
vim.keymap.set('n', '-', ':Oil<CR>')

vim.keymap.set('n', '<leader>ff', '<cmd>Pick files<CR>')
vim.keymap.set('n', '<leader>fg', '<cmd>Pick grep_live<CR>')
vim.keymap.set('n', '<leader>fb', '<cmd>Pick buffers<CR>')
vim.keymap.set('n', '<leader>fd', '<cmd>Pick diagnostic<CR>')
vim.keymap.set('n', '<leader>fD', "<cmd>Pick lsp scope='definition'<CR>")
vim.keymap.set('n', '<leader>fr', "<cmd>Pick lsp scope='references'<CR>")

-- Treesitter (main branch: highlighting/indent/fold are opt-in per filetype)
require('nvim-treesitter').install { 'lua', 'vimdoc', 'c_sharp', 'templ', 'rust', 'html' }

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name == 'nvim-treesitter' and (ev.data.kind == 'install' or ev.data.kind == 'update') then
      vim.cmd 'TSUpdate'
    end
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  callback = function(ev)
    local ok = pcall(vim.treesitter.start, ev.buf)
    if ok then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- LSP
require('mason').setup()
vim.lsp.enable { 'lua_ls', 'csharp_ls', 'tinymist', 'gopls', 'templ', 'html', 'htmx' }
vim.diagnostic.config { virtual_text = true }

-- Native completion (nvim 0.12+)
vim.opt.completeopt = 'menuone,noselect,popup'

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method 'textDocument/completion' then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

-- Godot integration
if vim.fn.filereadable(vim.fn.getcwd() .. '/project.godot') == 1 then
  local addr = './godot.pipe'
  if vim.fn.has 'win32' == 1 then
    -- Windows can't pipe so use localhost. Make sure this is configured in Godot
    -- Exec Path: nvim
    -- Exec Flags: --server 127.0.0.1:6004 --remote-send "<esc>:n {file}<CR>:call cursor({line},{col})<CR>"
    addr = '127.0.0.1:6004'
  end
  vim.fn.serverstart(addr)
end
