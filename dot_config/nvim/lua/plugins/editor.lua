return {
    { -- Automatically insert closing brackets/braces/etc.
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        opts = {}
    },
    {
        'tpope/vim-eunuch'
    },
    { -- Shows the available keys after a prefix such as <leader>, g or ]
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            spec = {
                { "<leader>c", group = "code" },
                { "<leader>f", group = "find" },
                { "<leader>g", group = "git" },
                { "<leader>h", group = "hunks" },
                { "<leader>s", group = "search" },
                { "<leader>u", group = "toggles" },
            },
        },
    },
}
