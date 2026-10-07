-- Set before lazy.nvim loads, so plugin mappings pick up the right leader
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Indent with 4 spaces; <Tab> and <BS> move in 4-space steps
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

-- Line numbers, and highlight the current line
vim.opt.number = true
vim.opt.cursorline = true

-- Always show the sign column, so gitsigns and diagnostics don't shift the text
vim.opt.signcolumn = "yes"

-- Keep some context above and below the cursor
vim.opt.scrolloff = 8

-- Wrapped lines keep their indentation
vim.opt.breakindent = true

-- Open vertical splits to the right and horizontal splits below
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Case-insensitive search, unless the pattern has a capital letter
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Preview :s substitutions in a split as you type
vim.opt.inccommand = "split"

-- Keep undo history across restarts
vim.opt.undofile = true

-- Ask to save changes instead of refusing to :q
vim.opt.confirm = true

-- Faster CursorHold, used by gitsigns and LSP document highlights
vim.opt.updatetime = 250

-- Rounded borders on every floating window (hover, signature help, diagnostics)
vim.opt.winborder = "rounded"

-- Show diagnostics inline and sort them by severity
vim.diagnostic.config({
    virtual_text = true,
    severity_sort = true,
    float = {
        focusable = false,
        source = true,
        header = "",
        prefix = "",
    },
    -- Show the diagnostic in a float after jumping with [d and ]d
    jump = {
        on_jump = function(_, bufnr) vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false }) end,
    },
})
