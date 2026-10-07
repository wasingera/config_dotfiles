return {
    { -- Automatically enables all installed LSPs
        "mason-org/mason-lspconfig.nvim",
        opts = {
            -- Installed on a fresh machine
            ensure_installed = { "clangd", "lua_ls", "basedpyright", "rust_analyzer" },
            -- stylua is installed as a formatter, not a language server
            automatic_enable = { exclude = { "stylua" } },
        },
        dependencies = {
            { -- Package manager for Language Server Protocol (LSP) executables
                "mason-org/mason.nvim",
                opts = {},
                config = function(_, opts)
                    require("mason").setup(opts)

                    -- Formatters for conform.nvim (formatting.lua). clang-format and
                    -- rustfmt come from the system toolchains.
                    local registry = require("mason-registry")
                    registry.refresh(function()
                        for _, name in ipairs({ "stylua", "ruff", "shfmt" }) do
                            local package = registry.get_package(name)
                            if not package:is_installed() and not package:is_installing() then
                                package:install()
                            end
                        end
                    end)
                end
            },
            { -- Base LSP configurations
                "neovim/nvim-lspconfig",
                config = function()
                    -- Keymaps for buffers with an LSP attached. K (hover), [d and ]d
                    -- (diagnostics) are Neovim defaults.
                    vim.api.nvim_create_autocmd('LspAttach', {
                        desc = 'LSP actions',
                        callback = function(args)
                            local function map(mode, lhs, rhs, desc, opts)
                                opts = vim.tbl_extend('force', { buffer = args.buf, desc = desc }, opts or {})
                                vim.keymap.set(mode, lhs, rhs, opts)
                            end

                            map('n', 'gd', function() Snacks.picker.lsp_definitions() end, 'Go to definition')
                            map('n', 'gD', function() Snacks.picker.lsp_declarations() end, 'Go to declaration')
                            map('n', 'gi', function() Snacks.picker.lsp_implementations() end, 'List implementations')
                            map('n', 'go', function() Snacks.picker.lsp_type_definitions() end, 'Go to type definition')
                            -- nowait: don't wait for the built-in grn/gra/grr/... mappings
                            map('n', 'gr', function() Snacks.picker.lsp_references() end, 'List references', { nowait = true })
                            map('n', '<C-k>', vim.lsp.buf.signature_help, 'Signature help')
                            map('n', '<F2>', vim.lsp.buf.rename, 'Rename symbol')
                            map({ 'n', 'x' }, '<F4>', vim.lsp.buf.code_action, 'Code action')
                            map('n', 'gl', vim.diagnostic.open_float, 'Show diagnostics')
                        end
                    })
                end
            },
        },
    },
}
