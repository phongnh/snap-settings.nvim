local M = {}

local TAB = vim.fn["repeat"](vim.fn.nr2char(0xa0), 4)

local file = require("snap.select.common.file")

local function parse(line)
    local parts = vim.split(tostring(line), TAB)
    return { lnum = tonumber(vim.trim(parts[1])), col = 0, text = parts[2] }
end

M.select = function(buf)
    local get_filename = function(selection)
        local result = parse(selection)
        return { filename = vim.api.nvim_buf_get_name(buf), line = result["lnum"] }
    end
    return file(get_filename)
end

M.multiselect = function(buf)
    local filename = vim.api.nvim_buf_get_name(buf)

    local parse_with_filename = function(line)
        return vim.tbl_extend("force", { filename = filename }, parse(line))
    end

    return function(selections, winnr)
        vim.fn.setqflist(vim.tbl_map(parse_with_filename, selections))
        vim.fn.setqflist({}, "a", { title = "BOutline: " .. filename })

        vim.api.nvim_command("copen")
        return vim.api.nvim_command("cfirst")
    end
end

return M
