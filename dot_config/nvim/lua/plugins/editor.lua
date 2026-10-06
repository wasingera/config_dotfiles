local utils = require('utils')

return {
    { -- The catppuccin colorscheme
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false, -- load the colorscheme before runtime
        config = function()
            -- The flavour follows 'background': flavours.dark or flavours.light
            require("catppuccin").setup({ background = require("flavours") })
            vim.o.background = utils.mode()
            vim.cmd.colorscheme("catppuccin")

            -- Switch along with the desktop while running
            utils.watch_mode(function(mode)
                vim.o.background = mode
                vim.cmd.colorscheme("catppuccin")
            end)
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
            vim.api.nvim_create_autocmd("BufEnter", {
                nested = true,
                callback = function()
                    if #vim.api.nvim_list_wins() == 1 and require("nvim-tree.utils").is_nvim_tree_buf() then
                        vim.cmd "quit"
                    end
                end
            })
        end
    },
    {
        'tpope/vim-eunuch'
    },
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
