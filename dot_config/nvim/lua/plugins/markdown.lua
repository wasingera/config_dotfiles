return {
    { -- Render headings, lists, tables and code blocks inside markdown buffers
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {
            -- Needs the latex parser plus utftex or latex2text, which aren't installed
            latex = { enabled = false },
        },
        keys = {
            { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Toggle markdown rendering" },
        },
    },
}
