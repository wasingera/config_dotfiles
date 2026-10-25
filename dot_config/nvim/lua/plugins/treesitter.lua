return {
    { -- Treesitter parsers and queries
        "nvim-treesitter/nvim-treesitter",
        lazy = false, -- the main branch doesn't support lazy-loading
        build = ":TSUpdate",
        opts = {},
        config = function(_, opts)
            require("nvim-treesitter").setup(opts)

            require("nvim-treesitter").install({
                "bash",
                "c",
                "cmake",
                "cpp",
                "cuda",
                "diff",
                "gitcommit",
                "html",
                "json",
                "latex",
                "lua",
                "markdown",
                "markdown_inline",
                "python",
                "query",
                "regex",
                "rust",
                "sql",
                "toml",
                "vim",
                "vimdoc",
                "yaml",
                "zsh",
            })

            -- Start treesitter highlighting for every filetype that has a parser, except LaTeX:
            -- vimtex highlights it itself, and its conceal and math text objects need that syntax.
            -- The latex parser stays installed for snacks.image.
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    if args.match == "tex" then return end
                    pcall(vim.treesitter.start, args.buf)
                end,
            })
        end,
    },
}
