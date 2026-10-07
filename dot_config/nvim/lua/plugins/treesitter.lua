return {
    { -- Treesitter parsers and queries
        'nvim-treesitter/nvim-treesitter',
        lazy = false, -- the main branch doesn't support lazy-loading
        build = ':TSUpdate',
        opts = {},
        config = function(_, opts)
            require('nvim-treesitter').setup(opts)

            require('nvim-treesitter').install({
                'bash',
                'c',
                'cpp',
                'cuda',
                'diff',
                'gitcommit',
                'html',
                'json',
                'lua',
                'markdown',
                'markdown_inline',
                'python',
                'query',
                'regex',
                'rust',
                'sql',
                'toml',
                'vim',
                'vimdoc',
                'yaml',
                'zsh'
            })

            -- Start treesitter highlighting for every filetype that has a parser
            vim.api.nvim_create_autocmd('FileType', {
                callback = function(args)
                    pcall(vim.treesitter.start, args.buf)
                end
            })
        end
    },
}
