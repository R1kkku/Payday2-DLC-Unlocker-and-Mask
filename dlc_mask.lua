-- DLC MASKING SCRIPT
-- This script masks DLC ownership from servers

-- RequiredScript: lib/managers/dlcmanager

-- Store original functions
local original_is_dlc_unlocked = DLCManager.is_dlc_unlocked
local original_has_dlc = DLCManager.has_dlc
local original_is_dlc_enabled = DLCManager.is_dlc_enabled
local original_get_dlc_info = DLCManager.get_dlc_info

-- Override DLC checking functions to always return true
function DLCManager:is_dlc_unlocked(dlc_id)
    return true
end

function DLCManager:has_dlc(dlc_id)
    return true
end

function DLCManager:is_dlc_enabled(dlc_id)
    return true
end

function DLCManager:get_dlc_info(dlc_id)
    local info = original_get_dlc_info and original_get_dlc_info(self, dlc_id) or {}
    info.unlocked = true
    info.enabled = true
    info.purchased = true
    return info
end

-- Force all DLCs to be marked as verified
Hooks:PostHook(DLCManager, "init", "dlc_mask_init", function(self)
    if Global.dlc_manager and Global.dlc_manager.all_dlc_data then
        for dlc_name, dlc_data in pairs(Global.dlc_manager.all_dlc_data) do
            dlc_data.verified = true
        end
    end
end)

-- Handle the 'available' check which often blocks content loading
function DLCManager:is_dlc_available(dlc_id)
    return true
end

-- Additional hook to force all DLCs to be loaded in memory
function DLCManager:load_dlc_content(dlc_id)
    return true
end