return {
    { -- Automatically insert closing brackets/braces/etc.
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        opts = {}
    },
    {
        'tpope/vim-eunuch'
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
