-- Formatters whose default style may not be the project's. These format on save
-- only when the project has one of the listed config files, so other people's
-- code isn't rewritten. <leader>cf formats regardless.
local project_config = {
    c = { ".clang-format", "_clang-format" },
    cpp = { ".clang-format", "_clang-format" },
    cuda = { ".clang-format", "_clang-format" },
    lua = { "stylua.toml", ".stylua.toml" },
    python = { "ruff.toml", ".ruff.toml", "pyproject.toml" },
    sh = { ".editorconfig" },
    bash = { ".editorconfig" },
}

return {
    { -- Formatting, with the LSP formatter as fallback
        "stevearc/conform.nvim",
        event = "BufWritePre",
        cmd = "ConformInfo",
        ---@module "conform"
        ---@type conform.setupOpts
        opts = {
            formatters_by_ft = {
                c = { "clang-format" },
                cpp = { "clang-format" },
                cuda = { "clang-format" },
                lua = { "stylua" },
                python = { "ruff_format" },
                rust = { "rustfmt" },
                sh = { "shfmt" },
                bash = { "shfmt" },
            },
            default_format_opts = { lsp_format = "fallback" },
            format_on_save = function(bufnr)
                if vim.g.autoformat == false then
                    return
                end
                local markers = project_config[vim.bo[bufnr].filetype]
                if markers and not vim.fs.root(bufnr, markers) then
                    return
                end
                return { timeout_ms = 500 }
            end,
        },
        init = function()
            -- After startup, once snacks.nvim has loaded
            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                once = true,
                callback = function()
                    Snacks.toggle
                        .new({
                            name = "Format on save",
                            get = function() return vim.g.autoformat ~= false end,
                            set = function(state) vim.g.autoformat = state end,
                        })
                        :map("<leader>uf")
                end,
            })
        end,
        keys = {
            {
                "<leader>cf",
                function() require("conform").format() end,
                mode = { "n", "x" },
                desc = "Format buffer or selection",
            },
        },
    },
}
