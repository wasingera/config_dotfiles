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
            end,
        },
    },
}
