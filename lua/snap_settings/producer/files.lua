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

return producer
