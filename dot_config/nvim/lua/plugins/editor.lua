return {
    { -- Automatically insert closing brackets/braces/etc.
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {},
    },
    {
        "tpope/vim-eunuch",
    },
    { -- More a/i text objects: arguments (a), function calls (f), tags (t), any quote (q) or bracket (b)
        "nvim-mini/mini.ai",
        version = "*",
        event = "VeryLazy",
        opts = {},
    },
    { -- Add, delete and replace surroundings: sa, sd, sr (e.g. saiw" or sd))
        "nvim-mini/mini.surround",
        version = "*",
        keys = {
            { "sa", mode = { "n", "x" }, desc = "Add surrounding" },
            { "sd", desc = "Delete surrounding" },
            { "sr", desc = "Replace surrounding" },
            { "sf", desc = "Find surrounding (right)" },
            { "sF", desc = "Find surrounding (left)" },
            { "sh", desc = "Highlight surrounding" },
        },
        opts = {},
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
