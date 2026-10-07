return {
    { -- Picker, file explorer, terminal and indent guides in one plugin
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        ---@type snacks.Config
        opts = {
            -- Fuzzy picker; also replaces vim.ui.select (e.g. code actions)
            picker = { enabled = true },
            -- File explorer sidebar; also opens for `nvim <dir>`
            explorer = { enabled = true },
            -- Indentation guides, with the current scope highlighted
            indent = { enabled = true },
            -- Nicer vim.ui.input (e.g. LSP rename)
            input = { enabled = true },
            -- Turn off slow features in very large files
            bigfile = { enabled = true },
            -- Floating terminal
            terminal = { win = { position = "float" } },
        },
        init = function()
            -- :q in the last editor window also closes the explorer, so Neovim exits
            vim.api.nvim_create_autocmd("QuitPre", {
                callback = function()
                    local current = vim.api.nvim_get_current_win()
                    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                        local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
                        if win ~= current and vim.api.nvim_win_get_config(win).relative == ""
                            and not filetype:match("^snacks_") then
                            return
                        end
                    end
                    for _, picker in ipairs(Snacks.picker.get({ source = "explorer" })) do
                        picker:close()
                        -- close() removes the windows on the next tick, after :q has run
                        picker.layout:close()
                    end
                end,
            })
        end,
        keys = {
            { "<C-p>", function() Snacks.picker.files() end, desc = "Find files" },
            { "<C-n>", function() Snacks.explorer() end, desc = "Toggle file explorer" },
            { "<C-Space>", function() Snacks.terminal.toggle() end, mode = { "n", "t" }, desc = "Toggle terminal" },

            { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart find files" },
            { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
            { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
            { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },

            { "<leader>sw", function() Snacks.picker.grep_word() end, mode = { "n", "x" }, desc = "Grep word or selection" },
            { "<leader>sh", function() Snacks.picker.help() end, desc = "Help pages" },
            { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
            { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
            { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP symbols" },
            { "<leader>sr", function() Snacks.picker.resume() end, desc = "Resume last picker" },

            { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git status" },
            { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git log" },
        },
    },
}
