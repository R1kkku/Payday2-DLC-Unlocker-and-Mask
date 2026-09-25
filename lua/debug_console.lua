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

-- Session timestamp (YYYY-MM-DD_HH-MM-SS) generated once per game launch
if not state.session_id then
    state.session_id = os.date("%Y-%m-%d_%H-%M-%S")
end

local LOGS_DIR = MOD_PATH .. "logs/"
local SESSION_LOG_NAME = "debug_log_" .. state.session_id .. ".txt"
local SESSION_LOG_FILE = LOGS_DIR .. SESSION_LOG_NAME

-- Ensure logs directory exists
local function ensure_logs_dir()
    local win_dir = (MOD_PATH .. "logs"):gsub("/", "\\")
    if SystemFS and SystemFS.make_dir then
        pcall(function() SystemFS:make_dir(MOD_PATH .. "logs") end)
    end
    if file and file.CreateDirectory then
        pcall(function() file.CreateDirectory(MOD_PATH .. "logs") end)
    end
    os.execute('if not exist "' .. win_dir .. '" mkdir "' .. win_dir .. '" 2>nul')
end
ensure_logs_dir()

-- Resolve absolute paths once
if not state.abs_base_path then
    local handle = io.popen("cd")
    local cwd = nil
    if handle then
        cwd = handle:read("*l")
        handle:close()
    end
    if not cwd or cwd == "" then
        cwd = "C:\\Program Files (x86)\\Steam\\steamapps\\common\\PAYDAY 2"
    end
    state.abs_base_path = cwd .. "\\" .. MOD_PATH:gsub("/", "\\")
end
state.abs_log_path = state.abs_base_path .. LOG_NAME
state.abs_session_path = state.abs_base_path .. "logs\\" .. SESSION_LOG_NAME

-- Start time — only set once per game session
state.start_time = state.start_time or os.clock()

-- Open/reopen the log file handles (handles don't survive across script reloads)
local open_mode = state.console_opened and "a" or "w"

local _session_handle = io.open(SESSION_LOG_FILE, open_mode)
if _session_handle then
    _session_handle:setvbuf("line")
end

local _latest_handle = io.open(LOG_FILE, open_mode)
if _latest_handle then
    _latest_handle:setvbuf("line")
end

local function write_to_log_files(content)
    if _session_handle then
        _session_handle:write(content)
        _session_handle:flush()
    end
    if _latest_handle then
        _latest_handle:write(content)
        _latest_handle:flush()
    end
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
        bat:write("echo   Session ID:  " .. state.session_id .. "\n")
        bat:write("echo   Session Log: " .. state.abs_session_path .. "\n")
        bat:write("echo   Latest Log:  " .. state.abs_log_path .. "\n")
        bat:write("echo ============================================================\n")
        bat:write("echo.\n")
        bat:write('powershell -NoProfile -Command "Get-Content -Path \'' .. state.abs_session_path .. '\' -Wait -Tail 200"\n')
        bat:write("pause\n")
        bat:close()

        local abs_bat = state.abs_base_path .. "tail_debug.bat"
        os.execute('start "" "' .. abs_bat .. '"')
    end
end

-- Core debug function
local function DBG(tag, msg, ...)
    if not _session_handle and not _latest_handle then
        return
    end

    -- Open console on very first message of the game session
    if not state.console_opened then
        local header = "=============================================================\n" ..
                       "  UltimateDLC Debug Console\n" ..
                       "  Started:     " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
                       "  Session Log: logs/" .. SESSION_LOG_NAME .. "\n" ..
                       "  Latest Log:  " .. LOG_NAME .. "\n" ..
                       "=============================================================\n\n"
        write_to_log_files(header)
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
    write_to_log_files(line)

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
    DBG("SYSTEM", "Debug console closing.")
    if _session_handle then
        _session_handle:close()
        _session_handle = nil
    end
    if _latest_handle then
        _latest_handle:close()
        _latest_handle = nil
    end
end

-- Export globally
_G.DBG = DBG
_G.DBG_TABLE = DBG_TABLE
_G.DBG_CLOSE = DBG_CLOSE

-- Initial message
DBG("SYSTEM", "Debug module loaded. console_opened=" .. tostring(state.console_opened))
