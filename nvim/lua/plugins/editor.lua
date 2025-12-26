return {
    { -- The catppuccin colorscheme
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false, -- load the colorscheme before runtime
        config = function()
            -- vim.cmd([[colorscheme catppuccin-latte]])
            -- vim.cmd([[colorscheme catppuccin-frappe]])
            vim.cmd([[colorscheme catppuccin-macchiato]])
            -- vim.cmd([[colorscheme catppuccin-mocha]])
        end
    },
    { -- Automatically insert closing brackets/braces/etc.
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        opts = {}
    },
    { -- Treesitter configuration
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        build = ':TSUpdate',
        opts = {},
        config = function(_, opts)
            require'nvim-treesitter'.setup(opts)

            require'nvim-treesitter'.install({
                'bash',
                'c',
                'cpp',
                'cuda',
                'html',
                'lua',
                'python',
                'rust',
                'sql',
                'zsh'
            })

            -- Automatically attempt to enable treesitter for all filetypes
            vim.api.nvim_create_autocmd('FileType', {
                pattern = {
                    '*'
                },
                callback = function()
                    local hasStarted = pcall(vim.treesitter.start)

                    if not hasStarted then
                        -- vim.notify('No treesitter parser installed for this language!', vim.log.levels.INFO)
                    end
                end
            })

            -- If quitting, then close the file explorer
            vim.api.nvim_create_autocmd({"QuitPre"}, {
                callback = function() vim.cmd("NvimTreeClose") end,
            })
        end
    },
    -- { -- Align around symbols/regex/etc.
    --     'junegunn/vim-easy-align',
    --     config = false,
    --     keys = {
    --         -- Visual mode alignment
    --         {
    --             "ga",
    --             "<expr>EasyAlign",
    --             desc = "EasyAlign (Visual)",
    --             mode = "v",
    --             expr = true
    --         },
    --         -- Operator mode alignment (requires an extra motion, e.g., `gaip`)
    --         {
    --             "ga",
    --             function()
    --                 vim.api.nvim_command("EasyAlign")
    --             end,
    --             desc = "EasyAlign (Operator)",
    --             mode = "n",
    --             expr = true
    --         },
    --     }
    -- },
    { -- Bottom bar
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = {}
    },
    { -- Advanced commenting support
        'numToStr/Comment.nvim',
        opts = {}
    },
    { -- Indendation lines
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        ---@module "ibl"
        ---@type ibl.config
        opts = {},
    }
}
