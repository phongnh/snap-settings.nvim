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
    local cwd = snap.sync(vim.fn.getcwd)
    return producer(request, {
        cmd = SnapSettings.config.find_tool,
        args = SnapSettings.config.find_args,
        cwd = cwd,
    })
end

M.with = function(opts)
    opts = opts or {}
    opts.cwd = vim.fn.empty(opts.cwd) ~= 1 and opts.cwd or vim.fn.getcwd()

    return function(request)
        return producer(request, {
            cmd = opts.cmd or SnapSettings.config.find_tool,
            args = opts.args or SnapSettings.config.find_args,
            cwd = opts.cwd,
        })
    end
end

return M
