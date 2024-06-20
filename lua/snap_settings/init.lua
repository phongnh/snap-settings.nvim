local M = {}

local H = {}

H.default_config = {
    find_tool = "fd",
    follow_links = 0,
    find_no_ignore_vcs = 0,
    grep_no_ignore_vcs = 0,
    preview = false,
}

H.setup_config = function(config)
    vim.validate({ config = { config, "table", true } })
    config = vim.tbl_deep_extend("force", vim.deepcopy(H.default_config), config or {})

    vim.validate({
        find_tool = { config.find_tool, "string" },
        follow_links = { config.follow_links, "number" },
        find_no_ignore_vcs = { config.find_no_ignore_vcs, "number" },
        grep_no_ignore_vcs = { config.grep_no_ignore_vcs, "number" },
        preview = { config.preview, "boolean" },
    })

    return config
end

H.apply_config = function(config)
    SnapSettings.config = config

    if vim.fn.executable(config.find_tool) == 1 then
        config.find_tool = config.find_tool
    elseif vim.fn.executable("fd") == 1 then
        config.find_tool = "fd"
    elseif vim.fn.executable("rg") == 1 then
        config.find_tool = "rg"
    else
        config.find_tool = "fd"
    end

    H.build_find_args()
    H.build_find_all_args()
    H.build_grep_args()

    vim.api.nvim_create_user_command("ToggleSnapFollowLinks", function()
        if config.follow_links == 0 then
            config.follow_links = 1
            print("Snap follows symlinks!")
        else
            config.follow_links = 0
            print("Snap does not follow symlinks!")
        end

        H.build_find_args()
        H.build_grep_args()
    end, {})
end

H.build_find_args = function()
    local find_args = {
        fd = { "--type", "file", "--color", "never", "--hidden" },
        rg = { "--files", "--color", "never", "--ignore-dot", "--ignore-parent", "--hidden" },
    }

    if SnapSettings.config.find_tool == "rg" then
        SnapSettings.config.find_args = find_args["rg"]
    else
        SnapSettings.config.find_args = find_args["fd"]
    end

    if SnapSettings.config.follow_links == 1 then
        table.insert(SnapSettings.config.find_args, "--follow")
    end

    if SnapSettings.config.find_no_ignore_vcs == 1 then
        table.insert(SnapSettings.config.find_args, "--no-ignore-vcs")
    end

    return SnapSettings.config.find_args
end

H.build_find_all_args = function()
    local find_all_args = {
        fd = { "--type", "file", "--color", "never", "--no-ignore", "--hidden", "--follow" },
        rg = { "--files", "--color", "never", "--no-ignore", "--hidden", "--follow" },
    }

    if SnapSettings.config.find_tool == "rg" then
        SnapSettings.config.find_all_args = find_all_args["rg"]
    else
        SnapSettings.config.find_all_args = find_all_args["fd"]
    end

    return SnapSettings.config.find_all_args
end

H.build_grep_args = function()
    SnapSettings.config.grep_args = {
        "--color",
        "never",
        "-H",
        "--no-heading",
        "--line-number",
        "--smart-case",
        "--hidden",
        "--max-columns=4096",
    }

    if SnapSettings.config.follow_links == 1 then
        table.insert(SnapSettings.config.grep_args, "--follow")
    end

    if SnapSettings.config.find_no_ignore_vcs == 1 then
        table.insert(SnapSettings.config.grep_args, "--no-ignore-vcs")
    end

    return SnapSettings.config.grep_args
end

function M.setup(config)
    -- Export module
    _G.SnapSettings = M

    -- Setup config
    config = H.setup_config(config)

    -- Apply config
    H.apply_config(config)
end

return M
