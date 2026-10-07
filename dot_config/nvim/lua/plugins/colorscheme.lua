local utils = require('utils')

return {
    { -- The catppuccin colorscheme
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false, -- load the colorscheme before runtime
        priority = 1000, -- and before every other plugin
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
}
