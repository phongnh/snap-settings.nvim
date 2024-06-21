local function formatter(line, buf)
    local columns = vim.split(line, "\t")
    local line_length = #(tostring(vim.api.nvim_buf_line_count(buf)))
    local linenr = tonumber(columns[3]:sub(1, -3))
    local prefix = string.format("%" .. tostring(line_length) .. "s", linenr)
    local line = vim.trim(vim.api.nvim_buf_get_lines(buf, linenr - 1, linenr, false)[1])
    -- local line = line:gsub(columns[1], string.format("\x1b[34m%s\x1b[m", columns[1]))
    return { prefix, line }
end

return formatter
