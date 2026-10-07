return {
    { -- Completion engine
        'saghen/blink.cmp',
        -- Snippets for the snippet source
        dependencies = { 'rafamadriz/friendly-snippets' },
        -- Release tags come with a prebuilt fuzzy matcher
        version = '1.*',

        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            -- The default preset (<C-space> opens, <C-y> accepts, <C-e> closes), plus
            -- <Tab>/<S-Tab> to move through the menu or, with no menu, between snippet
            -- placeholders, and <CR> to accept
            keymap = {
                preset = 'default',

                ['<Tab>']   = { 'select_next', 'snippet_forward', 'fallback' },
                ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
                ['<CR>']    = { 'accept', 'fallback' }
            },

            completion = {
                -- Show documentation next to the menu without asking
                documentation = { auto_show = true },
                -- Nothing is selected until <Tab>, which inserts the item as you go
                list = {
                    selection = { preselect = false, auto_insert = true },
                }
            },

            sources = {
                default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
                providers = {
                    -- Neovim API and plugin module completions from lazydev.nvim
                    lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
                },
            },
        },
        opts_extend = { "sources.default" },
    }
}
