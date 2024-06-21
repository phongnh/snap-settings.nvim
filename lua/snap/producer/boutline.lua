local M = {}

local snap = require("snap")
local io = require("snap.common.io")
local string = require("snap.common.string")
local formatter = require("snap.formatter.boutline")

local TAB = vim.fn["repeat"](vim.fn.nr2char(0xa0), 4)

local function producer(request, opts)
    local cmd = opts["cmd"]
    local args = opts["args"]
    local cwd = opts["cwd"]
    local buf = opts["buf"]
    local result = ""
    for data, err, kill in io.spawn(cmd, args, cwd) do
        if request.canceled() then
            kill()
            coroutine.yield(nil)
        elseif err ~= "" then
            coroutine.yield(nil)
        elseif data == "" then
            coroutine.yield({})
        else
            result = result .. data
            -- coroutine.yield(string.split(data))
        end
    end
    for _, line in ipairs(string.split(result)) do
        local item = snap.sync(function()
            return formatter(line, buf)
        end)
        coroutine.yield({ table.concat(item, TAB) })
    end
    return nil
end

-- TODO: Enforce language
M.build_ctags_args = function(buf)
    local language_mappings = {
        cpp = "c++",
    }
    local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
    local language = language_mappings[filetype] or filetype
    local ctags_args = {
        "-f",
        "-",
        "--sort=no",
        "--excmd=number",
        vim.api.nvim_buf_get_name(buf),
    }
    return ctags_args
end

local build_default_opts = function()
    return { cmd = SnapSettings.config.ctags_bin, args = M.build_ctags_args(0), cwd = vim.fn.getcwd() }
end

M.default = function(request)
    local opts = snap.sync(build_default_opts)
    return producer(request, opts)
end

M.with = function(opts)
    opts = opts or {}
    opts.cmd = opts.cmd or SnapSettings.config.ctags_bin
    opts.args = opts.args or M.build_ctags_args(opts.buf)

    return function(request)
        local cwd = snap.sync(vim.fn.getcwd)

        return producer(request, { cmd = opts.cmd, args = opts.args, buf = opts.buf, cwd = cwd })
    end
end

return M
