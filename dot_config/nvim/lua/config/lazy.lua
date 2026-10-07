-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim. The leader is set in config/options.lua, which runs first.
require("lazy").setup({
    spec = {
        { import = "plugins" },
    },
    -- Colorscheme used while installing plugins on a fresh machine
    install = { colorscheme = { "catppuccin" } },
    -- Check for plugin updates in the background, without notifying
    checker = { enabled = true, notify = false },
    -- Don't announce every reload after editing the config
    change_detection = { notify = false },
    -- No plugin here needs luarocks
    rocks = { enabled = false },
})
