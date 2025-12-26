-- Only uncomment this line if wanting to use non-default values
require'nvim-treesitter'.setup()

require'nvim-treesitter'.install({
    'bash',
    'c',
    'cpp',
    'cuda',
    'html',
    'lua',
    'python',
    'rust',
    'sql',
    'zsh'
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = {
        '*'
    },
    callback = function()
        local hasStarted = pcall(vim.treesitter.start)

        if not hasStarted then
            vim.notify('No treesitter parser installed for this language!', vim.log.levels.INFO)
        end
    end
})
