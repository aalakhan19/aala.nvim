-- Options
vim.g.mapleader = ' '
vim.g.maplocalleader = 'ü'

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

vim.opt.breakindent = true
-- move by screen line on wrapped text, but keep counts (5j) and relative-number jumps working
vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = 'Down (screen line)' })
vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = 'Up (screen line)' })
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
vim.opt.scrolloff = 5
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.swapfile = false
vim.opt.winborder= 'rounded'

-- Keymaps
local function feed(key)
  return function()
    local k = vim.api.nvim_replace_termcodes(key, true, false, true)
    vim.api.nvim_feedkeys(k, 'm', false)
  end
end

vim.keymap.set('n', 'ö', feed('['), { desc = '[ (prev motions)' })
vim.keymap.set('n', 'ä', feed(']'), { desc = '] (next motions)' })
vim.keymap.set({ 'i', 'c', 't' }, '<D-l>', '@', { desc = '@' })

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { noremap = true, silent = true, desc = 'Half page up (centered)' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { noremap = true, silent = true, desc = 'Half page down (centered)' })
vim.keymap.set('n', '<leader>w', ':write<CR>', { desc = 'Write file' })
vim.keymap.set('n', '<leader>q', ':quit<CR>', { desc = 'Quit window' })
vim.keymap.set('n', '<leader>F', vim.lsp.buf.format, { desc = 'Format buffer' })
vim.keymap.set('v', '<leader>F', function()
  vim.lsp.buf.format({ range = vim.lsp.util.make_range_params().range })
end, { desc = 'Format selection' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show line diagnostics' })

-- one sentence per line (typst prose); typstyle keeps existing line breaks
local abbrevs = { 'z.B', 'z. B', 'd.h', 'd. h', 'u.a', 'u. a', 'bzw', 'ca', 'vgl', 'Abb', 'Tab', 'Kap', 'Nr', 'al', 'usw', 'etc', 'bspw', 'ggf', 'inkl', 'evtl', 's.o', 's. o', 'o.ä', 'Dr', 'Prof' }
local function split_prose(line)
  local pieces = {}
  local indent = line:match '^%s*'
  local start = 1
  local pos = 1
  while true do
    local s, e = line:find('[.!?]%s+', pos)
    if not s then break end
    local nxt = line:sub(e + 1, e + 1)
    local before = line:sub(start, s - 1):match '[%w%.äöüÄÖÜ ]*$' or ''
    local abbr = (before:match '^%a$' or before:match '[%s%.]%a$') and line:sub(s, s) == '.'
    for _, a in ipairs(abbrevs) do
      if before:sub(-#a) == a and line:sub(s, s) == '.' then abbr = true end
    end
    if nxt:match '[A-ZÄÖÜ@#*_]' and not abbr then
      table.insert(pieces, (start == 1 and '' or indent) .. line:sub(start, s))
      start = e + 1
    end
    pos = e + 1
  end
  table.insert(pieces, (start == 1 and '' or indent) .. line:sub(start))
  return pieces
end
-- find the start of a comment (// or /*) in a line, ignoring URLs like https://
local function comment_start(line)
  local init = 1
  while true do
    local s = line:find('/[/*]', init)
    if not s then return nil end
    if line:sub(s - 1, s - 1) ~= ':' then return s end
    init = s + 2
  end
end
local function split_sentences(l1, l2)
  local out = {}
  local in_block = false
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)) do
    if in_block then
      local _, e = line:find('*/', 1, true)
      if e then in_block = false end
      table.insert(out, line)
    elseif line:match '^%s*[=#]' or line:match '^%s*$' then
      table.insert(out, line)
    else
      local cs = comment_start(line)
      local prose, rest = line, ''
      if cs then
        prose, rest = line:sub(1, cs - 1), line:sub(cs)
        if rest:sub(2, 2) == '*' and not rest:find('*/', 3, true) then in_block = true end
      end
      local pieces = split_prose(prose)
      pieces[#pieces] = pieces[#pieces] .. rest
      vim.list_extend(out, pieces)
    end
  end
  vim.api.nvim_buf_set_lines(0, l1 - 1, l2, false, out)
end
vim.api.nvim_create_user_command('SplitSentences', function(o) split_sentences(o.line1, o.line2) end, { range = '%' })
vim.keymap.set('n', '<leader>s', ':%SplitSentences<CR>', { desc = 'Split sentences (buffer)' })
vim.keymap.set('v', '<leader>s', ':SplitSentences<CR>', { desc = 'Split sentences (selection)' })

vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })

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
  'https://github.com/chomosuke/typst-preview.nvim',
  'https://github.com/stevearc/oil.nvim',
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  -- pinned to stable v1: main is the in-development v2 (needs blink.lib + a build step)
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range '1.*' },
  'https://github.com/folke/tokyonight.nvim',
  'https://github.com/AlexandrosAlexiou/kotlin.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/folke/which-key.nvim',
  'https://github.com/pwntester/octo.nvim',
}

vim.cmd 'colorscheme tokyonight-night'

require('guess-indent').setup()
require('mini.icons').setup()
-- plugins like octo.nvim expect nvim-web-devicons
MiniIcons.mock_nvim_web_devicons()
require('mini.surround').setup()
require('mini.ai').setup { n_lines = 100 }
require('mini.statusline').setup()
require('mini.pairs').setup()
local toggle_preview = require('telescope.actions.layout').toggle_preview
require('telescope').setup {
  defaults = {
    -- long paths: show the filename first, then the dimmed directory
    path_display = { 'filename_first' },
    -- prompt on top, best match right below it
    sorting_strategy = 'ascending',
    layout_config = { prompt_position = 'top' },
    preview = { hide_on_startup = true },
    mappings = {
      i = { ['<C-o>'] = toggle_preview },
      n = { ['<C-o>'] = toggle_preview },
    },
  },
}
require('which-key').setup()
require('which-key').add {
  { '<leader>f', group = 'Find' },
  { '<leader>h', group = 'Git hunks' },
  { '<leader>t', group = 'Toggle' },
}

require('typst-preview').setup {
  dependencies_bin = { ['tinymist'] = 'tinymist' },
  open_cmd = 'open -a Firefox %s',
  -- always preview the whole thesis, even when started from a chapter file
  get_main_file = function(path)
    return vim.fs.find('main.typ', { path = path, upward = true })[1] or path
  end,
  get_root = function(path)
    local main = vim.fs.find('main.typ', { path = path, upward = true })[1]
    return main and vim.fs.dirname(main) or vim.fs.dirname(path)
  end,
}

require('oil').setup { default_file_explorer = true }
vim.keymap.set('n', '-', ':Oil<CR>', { desc = 'Open parent directory (Oil)' })

-- inside an Octo review tab, pick among the PR's changed files and open them in the review diff
local function find_files()
  local ok, reviews = pcall(require, 'octo.reviews')
  local layout = ok and reviews.get_current_layout()
  if not layout then return require('telescope.builtin').find_files() end
  local pickers, finders = require 'telescope.pickers', require 'telescope.finders'
  local actions, state = require 'telescope.actions', require 'telescope.actions.state'
  pickers.new({}, {
    prompt_title = 'PR Files',
    finder = finders.new_table {
      results = layout.files,
      entry_maker = function(file)
        local display = function() return require('telescope.utils').transform_path({}, file.path) end
        return { value = file, display = display, ordinal = file.path }
      end,
    },
    sorter = require('telescope.config').values.generic_sorter {},
    attach_mappings = function(bufnr)
      actions.select_default:replace(function()
        local entry = state.get_selected_entry()
        actions.close(bufnr)
        if entry then layout:set_current_file(entry.value) end
      end)
      return true
    end,
  }):find()
end
vim.keymap.set('n', '<leader>ff', find_files, { desc = 'Find files (PR files in Octo review)' })
vim.keymap.set('n', '<leader>fp', '<cmd>Telescope builtin<CR>', { desc = 'Find telescope pickers' })
vim.keymap.set('n', '<leader>fg','<cmd>Telescope live_grep<CR>', { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>', { desc = 'Find buffers' })
vim.keymap.set('n', '<leader>fd', '<cmd>Telescope diagnostics<CR>', { desc = 'Find diagnostics' })
vim.keymap.set('n', '<leader>fD', '<cmd>Telescope lsp_definitions<CR>', { desc = 'Find LSP definitions' })
vim.keymap.set('n', '<leader>fr', '<cmd>Telescope lsp_references<CR>', { desc = 'Find LSP references' })
vim.keymap.set('n', '<leader>fo', '<cmd>Telescope lsp_document_symbols<CR>', { desc = 'Find document symbols' })

-- GitHub PR review (uses gh auth)
-- use_local_fs: right side of reviews is the real file on disk, so LSP, edits and gd work
require('octo').setup { picker = 'telescope', use_local_fs = true }
vim.keymap.set('n', '<leader>o', '<cmd>Octo actions<CR>', { desc = 'Octo actions' })

-- Treesitter (main branch: highlighting/indent/fold are opt-in per filetype)
require('nvim-treesitter').install { 'c', 'lua', 'vimdoc', 'c_sharp', 'templ', 'rust', 'html', 'java' }

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
vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
-- remember which main file includes each file, so chapters get the bibliography
vim.lsp.config('tinymist', { settings = { projectResolution = 'lockDatabase', formatterMode = 'typstyle' } })
-- auto-pin main.typ so chapter files compile in the context of the whole thesis
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= 'tinymist' then return end
    local main = vim.fs.find('main.typ', { path = vim.api.nvim_buf_get_name(args.buf), upward = true })[1]
    if main then
      client:exec_cmd { title = 'pin', command = 'tinymist.pinMain', arguments = { main } }
    end
  end,
})
-- grammar/spell check (LanguageTool) for the thesis text
vim.lsp.config('ltex_plus', {
  -- nightly build: stable 18.7.0 mis-parses a sentence ending in a Typst @key citation
  cmd = { vim.fn.expand '~/.local/share/nvim/ltex-ls-plus-nightly/ltex-ls-plus-19.0.0-alpha.54+2026-11-03.ge2a43c10/bin/ltex-ls-plus' },
  -- only attach to thesis chapter files
  root_dir = function(bufnr, on_dir)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name:match '/chapters/[^/]+%.typ$' then
      on_dir(vim.fs.dirname(name))
    end
  end,
  settings = {
    ltex = {
      language = 'de-DE',
      dictionary = { ['de-DE'] = { 'ECS', 'Entity', 'Component', 'Systems', 'citation', '(citatio' } },
    },
  },
})
-- Java: lombok agent (shipped with mason's jdtls) and JDK 21 for projects; jdtls itself needs JDK 25+ (homebrew openjdk)
vim.env.JDTLS_JVM_ARGS = '-javaagent:' .. vim.fn.stdpath 'data' .. '/mason/share/jdtls/lombok.jar'
vim.lsp.config('jdtls', {
  cmd_env = { JAVA_HOME = '/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home' },
  settings = {
    java = {
      configuration = {
        runtimes = {
          { name = 'JavaSE-21', path = vim.fn.trim(vim.fn.system '/usr/libexec/java_home -v 21'), default = true },
        },
      },
    },
  },
})
-- multi-module Maven: use the repo root, not the nearest module pom.xml
vim.lsp.config('kotlin_lsp', {
  root_markers = { { 'settings.gradle', 'settings.gradle.kts', 'mvnw', '.git' }, { 'pom.xml', 'build.gradle', 'build.gradle.kts', 'workspace.json' } },
})
vim.lsp.enable { 'lua_ls', 'csharp_ls', 'tinymist', 'gopls', 'clangd', 'kotlin_lsp', 'ltex_plus', 'jdtls' }
vim.diagnostic.config { virtual_text = true }

require('blink.cmp').setup {
  keymap = { preset = 'enter' },
  completion = {
    documentation = { auto_show = true },
  },
  signature = { enabled = true },
}

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

require('gitsigns').setup{
  word_diff = false,
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map('n', ']h', function()
      if vim.wo.diff then
        vim.cmd.normal({']h', bang = true})
      else
        gitsigns.nav_hunk('next')
      end
    end, { desc = 'Next git hunk' })

    map('n', '[h', function()
      if vim.wo.diff then
        vim.cmd.normal({'[h', bang = true})
      else
        gitsigns.nav_hunk('prev')
      end
    end, { desc = 'Previous git hunk' })

    -- Actions
    map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Stage hunk' })
    map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Reset hunk' })

    map('v', '<leader>hs', function()
      gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, { desc = 'Stage selected lines' })

    map('v', '<leader>hr', function()
      gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, { desc = 'Reset selected lines' })

    map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'Stage buffer' })
    map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'Reset buffer' })
    map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'Preview hunk' })
    map('n', '<leader>hi', gitsigns.preview_hunk_inline, { desc = 'Preview hunk inline' })

    map('n', '<leader>hb', function()
      gitsigns.blame_line({ full = true })
    end, { desc = 'Blame line' })

    map('n', '<leader>hd', gitsigns.diffthis, { desc = 'Diff against index' })

    map('n', '<leader>hD', function()
      gitsigns.diffthis('~')
    end, { desc = 'Diff against last commit' })

    map('n', '<leader>hQ', function() gitsigns.setqflist('all') end, { desc = 'All hunks to quickfix' })
    map('n', '<leader>hq', gitsigns.setqflist, { desc = 'Buffer hunks to quickfix' })

    -- Toggles
    map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = 'Toggle line blame' })
    map('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = 'Toggle word diff' })

    -- Text object
    map({'o', 'x'}, 'ih', gitsigns.select_hunk, { desc = 'Git hunk' })
  end
}
