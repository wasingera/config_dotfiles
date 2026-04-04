return {
    is_dark_mode = function()
        -- Run terminal command to read system interface style
        local handle = assert(io.open(os.getenv('HOME') .. "/.local/state/colorscheme/mode", "r"))
        local result = handle:read("*a")
        handle:close()

        -- Trim whitespace and check for "Dark"
        result = result:gsub("%s+", "")
        return result == "dark"
    end
}
