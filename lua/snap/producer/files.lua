local M = {}

local snap = require("snap")
local io = require("snap.common.io")
local string = require("snap.common.string")

local function producer(request, opts)
    local cmd = opts["cmd"]
    local args = opts["args"]
    local cwd = opts["cwd"]
    for data, err, kill in io.spawn(cmd, args, cwd) do
        if request.canceled() then
            kill()
            coroutine.yield(nil)
        elseif err ~= "" then
            coroutine.yield(nil)
        elseif data == "" then
            coroutine.yield({})
        else
            coroutine.yield(string.split(data))
        end
    end
    return nil
end

M.default = function(request)
    local opts = {
        cmd = _G.SnapSettings.config.find_tool,
        args = _G.SnapSettings.config.find_args,
        cwd = vim.fn.getcwd(),
    }
    snap.sync(vim.fn.getcwd)
    return producer(request, opts)
end

M.with = function(opts)
    opts = opts or {}
    opts.cwd = vim.fn.empty(opts.cwd) ~= 1 and opts.cwd or vim.fn.getcwd()

    return function(request)
        local cwd = snap.sync(function()
            return opts.cwd
        end)

        return producer(request, {
            cmd = opts.cmd or _G.SnapSettings.config.find_tool,
            args = opts.args or _G.SnapSettings.config.find_args,
            cwd = cwd,
        })
    end
end

return M
