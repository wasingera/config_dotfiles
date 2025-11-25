call plug#begin()

" Copilot
" Plug 'github/copilot.vim'

" LSP and DAP package manager
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'

" Searching plugin
Plug 'ggandor/leap.nvim'

" Git signs in gutter
Plug 'lewis6991/gitsigns.nvim'

" Color schemes
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'shaunsingh/solarized.nvim'
Plug 'projekt0n/github-nvim-theme'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }

" Utility functions
Plug 'nvim-lua/plenary.nvim'

" Terminal
Plug 'akinsho/toggleterm.nvim', {'tag' : '*'}

" Telescope
Plug 'nvim-telescope/telescope.nvim', { 'branch': '0.1.x' }
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }

" Indendation lines
Plug 'lukas-reineke/indent-blankline.nvim'

" Autopair stuff
Plug 'windwp/nvim-autopairs'

" Status line
Plug 'nvim-lualine/lualine.nvim'
Plug 'kyazdani42/nvim-web-devicons'

" Commenter
" Plug 'tpope/vim-commentary'
Plug 'numToStr/Comment.nvim'

" Emmet
Plug 'mattn/emmet-vim'

" Treesitter
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" LSP Support
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'

Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
" Plug 'hrsh7th/cmp-vsnip'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-nvim-lua'

Plug 'simrat39/rust-tools.nvim'

"  Snippets
Plug 'L3MON4D3/LuaSnip'
" Plug 'hrsh7th/vim-vsnip'
" Plug 'rafamadriz/friendly-snippets'

" Auto setup completion
" Plug 'VonHeikemen/lsp-zero.nvim'

" File Explorer
Plug 'nvim-tree/nvim-tree.lua'

" Alignment and formatting
Plug 'junegunn/vim-easy-align'

" Repeat plugin actions
Plug 'tpope/vim-repeat'

" Writing
Plug 'folke/zen-mode.nvim'

call plug#end()

" set colorscheme
" colorscheme catppuccin-latte
colorscheme catppuccin-macchiato

" Tabs to spaces
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent

" Window split directions
set splitright
set splitbelow

" Highlight current line
set cursorline

" Line numbers
set number

" Rofi theme highlighting
au BufRead,BufNewFile *.rasi setfiletype rasi

" File Browser setup
lua require('nvim-tree-config')
nnoremap <C-n> :NvimTreeToggle<Cr>

" Easy Align
nmap ga <Plug>(EasyAlign)
xmap ga <Plug>(EasyAlign)

" Find files using Telescope command-line sugar.
nnoremap <C-p> <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

imap <silent><script><expr> <C-J> copilot#Accept("\<CR>")
let g:copilot_no_tab_map = v:true

" Treesitter setup
lua require'nvim-treesitter.configs'.setup{highlight={enable=true}}
" lua require('nvim-treesitter-config')

" Lualine setup -- use default config
lua require('lualine').setup()

" Luasnip config
" lua require('luasnip-config')

" Autocloser setup
lua require('nvim-autopairs').setup()

" Git signs in gutter setup
lua require('gitsigns').setup()

" Search setup
lua require('leap').add_default_mappings()

" FZF enable for file searcher
lua require('telescope').load_extension('fzf')

" Initialize completion
lua require("mason").setup()
lua require("mason-lspconfig").setup()
lua require('nvim-cmp-config')
" lua require('lsp-zero-config')
"
" Setup commenter
lua require('Comment').setup()

" Setup Terminal
lua require('toggleterm-config')
