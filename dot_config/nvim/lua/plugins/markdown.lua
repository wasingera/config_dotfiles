return {
    { -- Render headings, lists, tables and code blocks inside markdown buffers
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {
            -- Off: snacks.image renders math as real images instead (snacks.lua)
            latex = { enabled = false },
        },
        keys = {
            { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Toggle markdown rendering" },
        },
    },
}
