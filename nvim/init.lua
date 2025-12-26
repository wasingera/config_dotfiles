require("config.lazy")

-- Set the number of spaces a <Tab> in the file counts for
vim.opt.tabstop = 4

-- Set the number of spaces used for each step of (auto)indent
vim.opt.shiftwidth = 4

-- Convert tabs to spaces
vim.opt.expandtab = true

-- Optional: Set softtabstop to 4 to make <Tab> and <BS> (backspace) operate in 4-space increments
vim.opt.softtabstop = 4

-- Set line numbers
vim.opt.number = true

-- Highlight current line
vim.opt.cursorline = true

-- Vertical split to the right
vim.opt.splitright = true

-- Horizontal split below
vim.opt.splitbelow = true

-- Enable inlinedebug warning and error printouts
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = {
        focusable = false,
        style = 'minimal',
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
    },
})
