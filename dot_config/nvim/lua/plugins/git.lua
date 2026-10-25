return {
    { -- Git markers alongside numbers
        "lewis6991/gitsigns.nvim",
        opts = {
            on_attach = function(bufnr)
                local gitsigns = require("gitsigns")

                local function map(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc }) end

                -- Jump between hunks; in diff mode, between changes as usual
                map("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gitsigns.nav_hunk("next")
                    end
                end, "Next hunk")
                map("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gitsigns.nav_hunk("prev")
                    end
                end, "Previous hunk")

                map("n", "<leader>hs", gitsigns.stage_hunk, "Stage hunk")
                map("n", "<leader>hr", gitsigns.reset_hunk, "Reset hunk")
                map(
                    "x",
                    "<leader>hs",
                    function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
                    "Stage selected lines"
                )
                map(
                    "x",
                    "<leader>hr",
                    function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
                    "Reset selected lines"
                )
                map("n", "<leader>hp", gitsigns.preview_hunk, "Preview hunk")
                map("n", "<leader>hb", function() gitsigns.blame_line({ full = true }) end, "Blame line")
                map("n", "<leader>hd", gitsigns.diffthis, "Diff against the index")

                -- "ih" selects the hunk under the cursor, e.g. dih, yih
                map({ "o", "x" }, "ih", gitsigns.select_hunk, "Select hunk")

                -- Neovim checks a buffer's mappings newest first. When gitsigns attaches after
                -- which-key has put its <leader> trigger on the buffer, the <leader>h... maps
                -- come first, and Neovim waits 'timeoutlen' for more keys before the menu
                -- opens. Re-creating the trigger makes it the newest again.
                vim.api.nvim_buf_call(bufnr, function()
                    for _, mode in ipairs({ "n", "x" }) do
                        local trigger = vim.fn.maparg(vim.g.mapleader, mode, false, true)
                        if trigger.buffer == 1 and (trigger.desc or ""):find("which-key-trigger", 1, true) then
                            vim.keymap.del(mode, vim.g.mapleader, { buffer = bufnr })
                            vim.fn.mapset(mode, false, trigger)
                        end
                    end
                end)
            end,
        },
    },
}
