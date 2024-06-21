local M = {}

local shortpath = function(path)
    local short = vim.fn.fnamemodify(path, ":~:.")
    if vim.fn.has("win32unix") == 0 then
        short = vim.fn.pathshorten(short)
    end
    local is_win = (vim.fn.has("win32") == 1) or (vim.fn.has("win64") == 1)
    local slash = (is_win and not vim.opt.shellslash) and "\\" or "/"
    return vim.fn.empty(short) == 1 and ("~" .. slash)
        or (short .. (string.find(short, vim.fn.escape(slash, "\\") .. "$") ~= nil and "" or slash))
end

local H = {}

H.default_config = {
    find_tool = "fd",
    follow_links = 0,
    find_no_ignore_vcs = 0,
    grep_no_ignore_vcs = 0,
    ctags_bin = "ctags",
    preview = false,
    mappings = {
        ["enter-split"] = { "<C-x>" },
        ["enter-tab"] = { "<C-t>" },
        ["enter-vsplit"] = { "<C-v>" },
        ["select-all"] = { "<C-z>" },
        ["prev-item"] = { "<Up>", "<C-k>" },
        ["next-item"] = { "<Down>", "<C-j>" },
        ["prev-page"] = { "<C-p>", "<PageUp>" },
        ["next-page"] = { "<C-n>", "<PageDown>" },
        ["view-page-down"] = { "<C-f>" },
        ["view-page-up"] = { "<C-b>" },
        ["view-toggle-hide"] = { ";", "<C-\\>" },
        enter = { "<CR>" },
        exit = { "<Esc>", "<C-c>" },
        next = { "<C-q>" },
        select = { "<Tab>" },
        unselect = { "<S-Tab>" },
    },
}

H.setup_config = function(config)
    vim.validate({ config = { config, "table", true } })
    config = vim.tbl_deep_extend("force", vim.deepcopy(H.default_config), config or {})
    config.mappings = vim.tbl_deep_extend("force", vim.deepcopy(H.default_config.mappings), config.mappings or {})

    vim.validate({
        find_tool = { config.find_tool, "string" },
        follow_links = { config.follow_links, "number" },
        find_no_ignore_vcs = { config.find_no_ignore_vcs, "number" },
        grep_no_ignore_vcs = { config.grep_no_ignore_vcs, "number" },
        ctags_bin = { config.ctags_bin, "string" },
        preview = { config.preview, "boolean" },
        mappings = { config.mappings, "table", true },
    })

    vim.validate({
        ["mappings.enter-split"] = { config.mappings["enter-split"], "table", true },
        ["mappings.enter-tab"] = { config.mappings["enter-tab"], "table", true },
        ["mappings.enter-vsplit"] = { config.mappings["enter-vsplit"], "table", true },
        ["mappings.select-all"] = { config.mappings["select-all"], "table", true },
        ["mappings.prev-item"] = { config.mappings["prev-item"], "table", true },
        ["mappings.next-item"] = { config.mappings["next-item"], "table", true },
        ["mappings.prev-page"] = { config.mappings["prev-page"], "table", true },
        ["mappings.next-page"] = { config.mappings["next-page"], "table", true },
        ["mappings.view-page-down"] = { config.mappings["view-page-down"], "table", true },
        ["mappings.view-page-up"] = { config.mappings["view-page-up"], "table", true },
        ["mappings.view-toggle-hide"] = { config.mappings["view-toggle-hide"], "table", true },
        ["mappings.enter"] = { config.mappings["enter"], "table", true },
        ["mappings.exit"] = { config.mappings["exit"], "table", true },
        ["mappings.next"] = { config.mappings["next"], "table", true },
        ["mappings.select"] = { config.mappings["select"], "table", true },
        ["mappings.unselect"] = { config.mappings["unselect"], "table", true },
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

    vim.api.nvim_create_user_command("SnapFiles", function(opts)
        local cwd = vim.fn.empty(opts.args) ~= 1 and opts.args or vim.fn.getcwd()
        M.files({ cwd = cwd })
    end, { nargs = "?", complete = "dir" })

    local snap = require("snap")
    local file = snap.config.file:with({
        consumer = "fzy",
        layout = snap.get("layout").centered,
        mappings = SnapSettings.config.mappings,
        preview = SnapSettings.config.preview,
    })
    local vimgrep = snap.config.vimgrep:with({
        consumer = "fzf",
        producer = "ripgrep.vimgrep",
        args = SnapSettings.config.grep_args,
        layout = snap.get("layout").bottom,
        mappings = SnapSettings.config.mappings,
    })

    snap.register.command("files", function()
        M.files()
    end)

    snap.register.command("all_files", function()
        M.files({
            prompt = "All Files>",
            cmd = SnapSettings.config.find_tool,
            args = SnapSettings.config.find_all_args,
        })
    end)

    snap.register.command("git_files", function()
        M.git_files()
    end)

    snap.register.command("root", function()
        local cwd = vim.find_buffer_project_dir()
        cwd = vim.fn.empty(cwd) ~= 1 and cwd or vim.fn.getcwd()
        M.git_files({
            prompt = string.format("%s>", shortpath(cwd)),
            cwd = cwd,
        })
    end)

    snap.register.command("buffer_dir", function()
        M.files({
            prompt = "Buffer Dir>",
            cwd = vim.fn.expand("%" .. vim.fn["repeat"](":h", vim.v.count1)),
        })
    end)

    snap.register.command("oldfiles", file({ combine = { "vim.buffer", "vim.oldfile" } }))
    snap.register.command("buffers", file({ producer = "vim.buffer" }))
    snap.register.command("live_grep", vimgrep({}))
    snap.register.command("live_grep_cword", vimgrep({ filter_with = "cword" }))
    snap.register.command("live_grep_selection", vimgrep({ filter_with = "selection" }))

    snap.register.command("boutline", function()
        local fzy = snap.get("consumer.fzy")
        local boutline = snap.get("producer.boutline")
        local select_file = snap.get("select.boutline")
        local buf = vim.api.nvim_get_current_buf()

        snap.run({
            prompt = "BOutline>",
            producer = fzy(boutline.with({ buf = buf })),
            select = select_file.select(buf),
            multiselect = select_file.multiselect(buf),
            layout = snap.get("layout").centered,
            mappings = SnapSettings.config.mappings,
            hide_views = not SnapSettings.config.preview,
            views = { snap.get("preview.file") },
        })
    end)
end

H.build_find_args = function()
    local find_args = {
        fd = { "--type", "file", "--color", "never", "--hidden" },
        rg = { "--files", "--line-buffered", "--color", "never", "--ignore-dot", "--ignore-parent", "--hidden" },
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
        rg = { "--files", "--line-buffered", "--color", "never", "--no-ignore", "--hidden", "--follow" },
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
        "--line-buffered",
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

function M.files(opts)
    opts = opts or {}

    local snap = require("snap")
    local fzy = snap.get("consumer.fzy")
    local files = snap.get("producer.files")
    local select_files = snap.get("select.files")
    local config = SnapSettings.config
    local cwd = vim.fn.empty(opts.cwd) ~= 1 and opts.cwd or vim.fn.getcwd()

    opts = vim.tbl_deep_extend("force", {
        prompt = "Files>",
        producer = fzy(files.with({
            cmd = opts.cmd or config.find_tool,
            args = opts.args or config.find_args,
            cwd = cwd,
        })),
        select = select_files.select(cwd),
        multiselect = select_files.multiselect(cwd),
        layout = snap.get("layout").centered,
        mappings = config.mappings,
        hide_views = not config.preview,
        views = { snap.get("preview.file") },
    }, opts)

    snap.run(opts)
end

function M.git_files(opts)
    opts = opts or {}

    local snap = require("snap")
    local fzy = snap.get("consumer.fzy")
    local try = snap.get("consumer.try")
    local files = snap.get("producer.files")
    local cwd = vim.fn.empty(opts.cwd) ~= 1 and opts.cwd or vim.fn.getcwd()

    M.files({
        prompt = opts.prompt or "Git Files>",
        producer = fzy(try(
            files.with({
                cmd = "git",
                args = { "ls-files", "--cached", "--others", "--exclude-standard" },
                cwd = cwd,
            }),
            files.with({
                cmd = SnapSettings.config.find_tool,
                args = SnapSettings.config.find_args,
                cwd = cwd,
            })
        )),
        cwd = cwd,
    })
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
