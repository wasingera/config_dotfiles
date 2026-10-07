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
                opts = {}
            },
            { -- Base LSP configurations
                "neovim/nvim-lspconfig",
                config = function()
                    -- Keymaps for buffers with an LSP attached. K (hover), [d and ]d
                    -- (diagnostics) are Neovim defaults.
                    vim.api.nvim_create_autocmd('LspAttach', {
                        desc = 'LSP actions',
                        callback = function(args)
                            local function map(mode, lhs, rhs, desc)
                                vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
                            end

                            map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
                            map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
                            map('n', 'gi', vim.lsp.buf.implementation, 'List implementations')
                            map('n', 'go', vim.lsp.buf.type_definition, 'Go to type definition')
                            map('n', 'gr', vim.lsp.buf.references, 'List references')
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
