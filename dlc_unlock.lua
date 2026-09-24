-- COMPREHENSIVE DLC UNLOCKER
-- This script handles all DLC unlocking functions

-- RequiredScript: lib/managers/dlcmanager

-- Store original functions
local original_is_dlc_unlocked = DLCManager.is_dlc_unlocked
local original_has_dlc = DLCManager.has_dlc
local original_is_dlc_enabled = DLCManager.is_dlc_enabled
local original_get_dlc_info = DLCManager.get_dlc_info
local original_is_dlc_available = DLCManager.is_dlc_available
local original_load_dlc_content = DLCManager.load_dlc_content
local original_is_dlc_free = DLCManager.is_dlc_free

-- Override all DLC checking functions
function DLCManager:is_dlc_unlocked(dlc_id)
    return true
end

function DLCManager:has_dlc(dlc_id)
    return true
end

function DLCManager:is_dlc_enabled(dlc_id)
    return true
end

function DLCManager:is_dlc_available(dlc_id)
    return true
end

function DLCManager:is_dlc_free(dlc_id)
    return true
end

function DLCManager:load_dlc_content(dlc_id)
    return true
end

function DLCManager:get_dlc_info(dlc_id)
    local info = original_get_dlc_info and original_get_dlc_info(self, dlc_id) or {}
    if not info then
        info = {
            unlocked = true,
            enabled = true,
            purchased = true,
            name = "DLC " .. tostring(dlc_id)
        }
    else
        info.unlocked = true
        info.enabled = true
        info.purchased = true
        info.is_steam_purchase = false
        info.is_free = true
    end
    return info
end

-- Force all DLC to be marked as unlocked in the global data
Hooks:PostHook(DLCManager, "init", "force_unlock_all_dlc", function(self)
    if Global.dlc_manager and Global.dlc_manager.all_dlc_data then
        for dlc_name, dlc_data in pairs(Global.dlc_manager.all_dlc_data) do
            dlc_data.verified = true
            dlc_data.unlocked = true
        end
    end
    
    if self._dlc_data then
        for dlc_id, dlc_info in pairs(self._dlc_data) do
            dlc_info.unlocked = true
            dlc_info.enabled = true
            dlc_info.purchased = true
        end
    end
    
    log("[DLC Unlocker] All DLC marked as unlocked")
end)