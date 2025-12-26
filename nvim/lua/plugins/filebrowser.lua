return {
    { -- File explorer setup
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        opts = {},
        keys = {
            { [[<C-n>]], [[<cmd>NvimTreeToggle<cr>]], desc="Toggle the NvimTree file browser" }
        }
    }
}
