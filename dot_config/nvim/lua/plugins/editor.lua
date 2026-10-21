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
    { -- Ctrl+h/j/k/l move between splits and on into tmux panes; Alt+h/j/k/l resize both
        "smart-splits-nvim/smart-splits.nvim",
        version = "^3.0.0",
        lazy = false, -- it tells tmux at startup that this pane is nvim (@pane-is-vim)
        dependencies = { "smart-splits-nvim/backend-tmux" },
        config = function()
            local splits = require("smart-splits")
            splits.setup({
                mux = {
                    backend = "smart-splits-backend-tmux",
                    -- outside tmux it just moves between splits; that's not worth a warning
                    warn_if_unusable = false,
                },
            })
            local keys = {
                { "<C-h>", splits.move_cursor_left, "Go to the left split or pane" },
                { "<C-j>", splits.move_cursor_down, "Go to the split or pane below" },
                { "<C-k>", splits.move_cursor_up, "Go to the split or pane above" },
                { "<C-l>", splits.move_cursor_right, "Go to the right split or pane" },
                { "<A-h>", splits.resize_left, "Resize left" },
                { "<A-j>", splits.resize_down, "Resize down" },
                { "<A-k>", splits.resize_up, "Resize up" },
                { "<A-l>", splits.resize_right, "Resize right" },
            }
            for _, key in ipairs(keys) do
                vim.keymap.set("n", key[1], key[2], { desc = key[3] })
            end
        end,
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
