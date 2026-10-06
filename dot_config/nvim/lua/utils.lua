-- ~/.local/state/colorscheme/mode holds "dark" or "light". On the desktop it's
-- written by `colorscheme` (switched at sunrise/sunset); elsewhere by whatever
-- the machine uses, if anything.
local mode_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/colorscheme"

local M = {}

-- The current mode, "dark" or "light"; dark when the mode file is missing.
function M.mode()
    local file = io.open(mode_dir .. "/mode", "r")
    if not file then
        return "dark"
    end
    local mode = vim.trim(file:read("*a"))
    file:close()
    return mode == "light" and "light" or "dark"
end

function M.is_dark_mode()
    return M.mode() == "dark"
end

-- Call on_change(mode) each time the mode file is written. Watches the
-- directory, so it keeps working if the file is replaced. Does nothing if
-- the directory doesn't exist.
function M.watch_mode(on_change)
    local uv = vim.uv or vim.loop
    local watcher = uv.new_fs_event()
    watcher:start(mode_dir, {}, function(err, filename)
        if not err and filename == "mode" then
            vim.schedule(function() on_change(M.mode()) end)
        end
    end)
end

return M
