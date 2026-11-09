-- userapps/apps/xmake.lua
--
-- 原版：无脑 includes 所有子目录，导致 ffmpeg / zlib / busybox / micropython
--       这类需要联网下源码包的 app 一起编，离线环境直接失败。
--
-- 改动：支持环境变量 RTT_APPS 指定只编哪些（空格分隔）。
--   不设 RTT_APPS  → 编译除「需要联网下载」之外的全部 app
--   RTT_APPS=hello shm_ping  → 只编这两个
--   RTT_APPS=all   → 和原版一致，全编（需要联网）

local arch = get_config("arch")

-- 这些 app 的第一条命令就会去 GitHub / ffmpeg.org 下载源码包，离线必挂
local network_apps = {
    ["busybox"] = true,
    ["ffmpeg"] = true,
    ["zlib"] = true,
    ["micropython"] = true,
    ["webserver"] = true,
    ["player"] = true,
}

local function want(name)
    local only = os.getenv("RTT_APPS")
    if only == nil or only == "" then
        return not network_apps[name]
    end
    if only == "all" then
        return true
    end
    for w in only:gmatch("%S+") do
        if w == name then
            return true
        end
    end
    return false
end

if arch == "xuantie" then
    local run_apps = {
        "busybox",
        "cpp",
        "hello",
        "shm_ping",
        "shm_pong",
        "smart-fetch",
        "zlib",
    }
    for _, packagedir in ipairs(run_apps) do
        if want(packagedir) then
            local packagefile = path.join(path.join(os.scriptdir(), packagedir), "xmake.lua")
            if os.isfile(packagefile) then
                includes(packagefile)
            end
        end
    end
else
    for _, packagedir in ipairs(os.dirs(path.join(os.scriptdir(), "*"))) do
        local name = path.basename(packagedir)
        local packagefile = path.join(packagedir, "xmake.lua")
        if os.isfile(packagefile) and want(name) then
            includes(packagefile)
        end
    end
end
