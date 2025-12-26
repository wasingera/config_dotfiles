return {
    { -- Fuzzy file browser
        'nvim-telescope/telescope.nvim',
        tag = 'v0.2.0',
        dependencies = { 
            { 'nvim-lua/plenary.nvim' },
            { 
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release --target install'
            }
        },
        opts = {},
        keys = {
            { [[<C-p>]], [[<cmd>Telescope find_files<cr>]], desc="Telescope File Browser" }
        },
        config = function()
            require('telescope').load_extension('fzf')
        end
    }
}
