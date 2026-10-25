return {
    { -- LaTeX documents: continuous compile with latexmk, PDF viewer with SyncTeX, motions and text objects
        "lervag/vimtex",
        lazy = false, -- vimtex loads itself for .tex files and breaks inverse search when lazy-loaded
        init = function()
            -- zathura_simple: the plain zathura method finds its window with xdotool, which
            -- doesn't work on Wayland. Forward search still reuses the open window.
            vim.g.vimtex_view_method = vim.fn.has("mac") == 1 and "skim" or "zathura_simple"

            -- snacks.image draws math as images, so vimtex only conceals in text (quotes, accents,
            -- \emph). Its math conceals (\pi as π) would show through next to the image.
            vim.g.vimtex_syntax_conceal = {
                greek = 0,
                math_bounds = 0,
                math_delimiters = 0,
                math_fracs = 0,
                math_super_sub = 0,
                math_symbols = 0,
            }
            -- Conceal is what hides the source under snacks' images; the cursor line shows it again
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "tex",
                callback = function() vim.opt_local.conceallevel = 2 end,
            })
        end,
    },
}
