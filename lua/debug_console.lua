-- =====================================================================
-- Debug Console: Opens a CMD window that live-streams mod debug output
-- RequiredScript: (loaded first via mod.txt, before all other scripts)
--
-- Usage: After requiring this file, call DBG("tag", "message") anywhere.
-- A single CMD window opens on game start and stays open.
-- =====================================================================

-- Use Global table (survives PD2 level transitions) to prevent respawning
Global._ultimatedlc_debug = Global._ultimatedlc_debug or {}
local state = Global._ultimatedlc_debug

-- If DBG is already defined globally, just bail — nothing to do
if _G.DBG and state.console_opened then
    return
end

local MOD_PATH = "mods/Payday2-DLC-Unlocker-and-Mask/"
local LOG_NAME = "debug_log.txt"
local LOG_FILE = MOD_PATH .. LOG_NAME
local MOD_TAG  = "[UltimateDLC]"

-- Resolve absolute path once
if not state.abs_log_path then
    local handle = io.popen("cd")
    if handle then
        local cwd = handle:read("*l")
        handle:close()
        if cwd and cwd ~= "" then
            state.abs_log_path = cwd .. "\\" .. MOD_PATH:gsub("/", "\\") .. LOG_NAME
        end
    end
    if not state.abs_log_path then
        state.abs_log_path = "C:\\Program Files (x86)\\Steam\\steamapps\\common\\PAYDAY 2\\" .. MOD_PATH:gsub("/", "\\") .. LOG_NAME
    end
end

-- Start time — only set once per game session
state.start_time = state.start_time or os.clock()

-- Open/reopen the log file handle (file handles don't survive across script reloads)
local _log_handle = io.open(LOG_FILE, state.console_opened and "a" or "w")
if _log_handle then
    _log_handle:setvbuf("line")
end

-- Open the CMD window ONCE per game launch
local function open_console_window()
    if state.console_opened then
        return
    end
    state.console_opened = true

    -- Write a batch file to avoid quoting issues with spaces/parentheses in path
    local bat_path = MOD_PATH .. "tail_debug.bat"
    local bat = io.open(bat_path, "w")
    if bat then
        bat:write("@echo off\n")
        bat:write("title UltimateDLC Debug Console\n")
        bat:write("color 0A\n")
        bat:write("echo ============================================================\n")
        bat:write("echo   UltimateDLC Debug Console - Live Output\n")
        bat:write("echo   Log: " .. state.abs_log_path .. "\n")
        bat:write("echo ============================================================\n")
        bat:write("echo.\n")
        bat:write('powershell -NoProfile -Command "Get-Content -Path \'' .. state.abs_log_path .. '\' -Wait -Tail 200"\n')
        bat:write("pause\n")
        bat:close()

        local abs_bat = state.abs_log_path:gsub(LOG_NAME, "tail_debug.bat")
        os.execute('start "" "' .. abs_bat .. '"')
    end
end

-- Core debug function
local function DBG(tag, msg, ...)
    if not _log_handle then
        return
    end

    -- Open console on very first message of the game session
    if not state.console_opened then
        _log_handle:write("=============================================================\n")
        _log_handle:write("  UltimateDLC Debug Console\n")
        _log_handle:write("  Started: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
        _log_handle:write("=============================================================\n\n")
        _log_handle:flush()
        open_console_window()
    end

    -- Timestamp relative to game start
    local elapsed = os.clock() - state.start_time
    local mins = math.floor(elapsed / 60)
    local secs = elapsed - (mins * 60)
    local timestamp = string.format("[%02d:%06.3f]", mins, secs)

    -- Format
    local formatted_tag = tag and ("[" .. tag .. "]") or ""
    local text
    if msg then
        local extras = {...}
        if #extras > 0 then
            local parts = {tostring(msg)}
            for _, v in ipairs(extras) do
                table.insert(parts, tostring(v))
            end
            text = table.concat(parts, " ")
        else
            text = tostring(msg)
        end
    else
        text = ""
    end

    local line = string.format("%s %s %s %s\n", timestamp, MOD_TAG, formatted_tag, text)
    _log_handle:write(line)
    _log_handle:flush()

    -- Also send to BLT log
    log(MOD_TAG .. " " .. formatted_tag .. " " .. text)
end

-- Table dumper
local function DBG_TABLE(tag, label, tbl, max_depth)
    max_depth = max_depth or 2
    if type(tbl) ~= "table" then
        DBG(tag, label .. " = " .. tostring(tbl) .. " (" .. type(tbl) .. ")")
        return
    end

    local function dump(t, indent, depth)
        if depth > max_depth then
            DBG(tag, indent .. "... (max depth)")
            return
        end
        for k, v in pairs(t) do
            if type(v) == "table" then
                DBG(tag, indent .. tostring(k) .. " = {")
                dump(v, indent .. "  ", depth + 1)
                DBG(tag, indent .. "}")
            else
                DBG(tag, indent .. tostring(k) .. " = " .. tostring(v))
            end
        end
    end

    DBG(tag, label .. " = {")
    dump(tbl, "  ", 1)
    DBG(tag, "}")
end

-- Shutdown
local function DBG_CLOSE()
    if _log_handle then
        DBG("SYSTEM", "Debug console closing.")
        _log_handle:close()
        _log_handle = nil
    end
end

-- Export globally
_G.DBG = DBG
_G.DBG_TABLE = DBG_TABLE
_G.DBG_CLOSE = DBG_CLOSE

-- Initial message
DBG("SYSTEM", "Debug module loaded. console_opened=" .. tostring(state.console_opened))
