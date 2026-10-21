-- Prose: check spelling, and wrap long lines between words instead of mid-word. With treesitter
-- only the text is checked, not code spans, code blocks or URLs.
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "text", "gitcommit" },
    callback = function()
        vim.opt_local.spell = true
        vim.opt_local.linebreak = true
    end,
})

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.hl.on_yank() end,
})
