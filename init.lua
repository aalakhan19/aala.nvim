-- Clone 'mini.deps' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath 'data' .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.deps'
if not vim.loop.fs_stat(mini_path) then
	vim.cmd 'echo "Installing `mini.deps`" | redraw'
	local clone_cmd = {
		'git',
		'clone',
		'--filter=blob:none',
		'https://github.com/nvim-mini/mini.deps',
		mini_path,
	}
	vim.fn.system(clone_cmd)
	vim.cmd 'packadd mini.deps | helptags ALL'
	vim.cmd 'echo "Installed `mini.deps`" | redraw'
end

-- Set up 'mini.deps' (customize to your liking)
require('mini.deps').setup { path = { package = path_package } }

local add = MiniDeps.add

-- Theme
add {
	source = 'vague-theme/vague.nvim',
}

vim.cmd 'colorscheme vague'

--options
vim.opt.langmap = 'ö[,ä]'
for _, mode in ipairs({ 'n', 'x', 'o' }) do
	vim.keymap.set(mode, 'ö', '[', { remap = true })
	vim.keymap.set(mode, 'ä', ']', { remap = true })
end

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

vim.g.mapleader = ' '

add 'nmac427/guess-indent.nvim'
require('guess-indent').setup()

vim.api.nvim_create_autocmd('TextYankPost', {
	desc = 'Highlight when yanking (copying) text',
	group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

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

add 'nvim-mini/mini.surround'
require('mini.surround').setup()

add 'nvim-mini/mini.ai'
require('mini.ai').setup {
	n_lines = 500,
}

add 'nvim-mini/mini.statusline'
require('mini.statusline').setup()


add {
	source = 'nvim-telescope/telescope.nvim',
	depends = { 'nvim-lua/plenary.nvim' },
}
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')

local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>f', builtin.find_files)
vim.keymap.set('n', '<leader>g', builtin.grep_string)
vim.keymap.set('n', '<leader>st', builtin.builtin)

add 'stevearc/oil.nvim'

require('oil').setup {
	default_file_explorer = true,
}
vim.keymap.set('n', '-', ':Oil<CR>')

add {
	source = 'nvim-treesitter/nvim-treesitter',
	hooks = {
		post_checkout = function()
			vim.cmd 'TSUpdate'
		end,
	},
}

require('nvim-treesitter.configs').setup {
	highlight = { enable = true },
	auto_install = true,
}

add 'neovim/nvim-lspconfig'
add 'mason-org/mason.nvim'

require('mason').setup()
vim.lsp.enable { 'lua_ls', 'csharp_ls' }

vim.keymap.set('n', 'gd', builtin.lsp_definitions)
vim.keymap.set('n', 'gr', builtin.lsp_references)

add { source = 'saghen/blink.cmp', checkout = 'v1.7.0' }
require('blink.cmp').setup {
	keymap = { preset = 'enter' },
	signature = { enabled = true },
	completion = { documentation = { auto_show = true } },
}

add 'windwp/nvim-autopairs'
require("nvim-autopairs").setup()
