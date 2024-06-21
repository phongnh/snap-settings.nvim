local M = {}

local file = require("snap.select.common.file")

M.select = function(cwd)
    local get_filename = function(selection)
        if vim.fn.empty(cwd) ~= 1 then
            return { filename = string.format("%s/%s", cwd, selection) }
        end
        return { filename = tostring(selection) }
    end
    return file(get_filename)
end

M.multiselect = function(cwd)
    local select = M.select(cwd)

    return function(selections, winnr)
        for index, selection in ipairs(selections) do
            select(selection, #selections == index and winnr or false)
        end
        return nil
    end
end

return M
