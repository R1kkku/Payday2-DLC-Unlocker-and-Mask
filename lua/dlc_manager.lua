-- =====================================================================
-- DLC Manager & Platform Unlocker
-- RequiredScript: lib/managers/dlcmanager
-- =====================================================================

-- Ensure Global DLC data tables exist and are protected against nil indexing
Global.dlc_manager = Global.dlc_manager or {}
Global.dlc_manager.all_dlc_data = Global.dlc_manager.all_dlc_data or {}
Global.dlc_save = Global.dlc_save or { packages = {} }
Global.dlc_save.packages = Global.dlc_save.packages or {}

-- Safety metatable: any lookup for an unknown DLC entry returns a valid unlocked entry
-- This permanently prevents crashes like: "attempt to index local 'entry' (a nil value)"
setmetatable(Global.dlc_manager.all_dlc_data, {
    __index = function(t, key)
        if not key then
            return nil
        end
        local val = {
            verified = true,
            unlocked = true,
            enabled = true,
            purchased = true,
            is_dlc = true
        }
        rawset(t, key, val)
        return val
    end
})

local function unlock_dlc_manager(manager_class)
    if not manager_class or type(manager_class) ~= "table" then
        return
    end
    if rawget(manager_class, "_dlc_unlocked") then
        DBG("DLC", "  Already unlocked, skipping")
        return
    end
    rawset(manager_class, "_dlc_unlocked", true)
    DBG("DLC", "  Applying unlock overrides...")

    function manager_class:is_dlc_unlocked(dlc_id)
        return true
    end

    function manager_class:has_dlc(dlc_id)
        return true
    end

    function manager_class:is_dlc_enabled(dlc_id)
        return true
    end

    function manager_class:is_dlc_available(dlc_id)
        return true
    end

    function manager_class:is_dlc_free(dlc_id)
        return true
    end

    function manager_class:has_full_game()
        return true
    end

    function manager_class:is_installing()
        return false
    end

    function manager_class:can_unlock_dlc(...)
        return true
    end

    function manager_class:chk_dlc(...)
        return true
    end

    function manager_class:chk_content(...)
        return true
    end

    function manager_class:is_content_unlocked(...)
        return true
    end

    function manager_class:is_mask_unlocked(...)
        return true
    end

    function manager_class:is_weapon_unlocked(...)
        return true
    end

    function manager_class:has_coronet(...)
        return true
    end

    function manager_class:has_career(...)
        return true
    end

    function manager_class:has_pd2_clan(...)
        return true
    end

    function manager_class:has_dlc_or_milestone(...)
        return true
    end

    function manager_class:check_sub_dlc(...)
        return true
    end

    function manager_class:verify_dlc(...)
        return true
    end

    function manager_class:load_dlc_content(...)
        return true
    end

    function manager_class:get_dlc_info(dlc_id)
        return {
            name = "DLC " .. tostring(dlc_id),
            unlocked = true,
            enabled = true,
            purchased = true,
            verified = true,
            is_dlc = true,
            is_steam_purchase = false
        }
    end

    -- Safe wrapper around give_dlc_and_verify_blackmarket to catch any unexpected errors
    function manager_class:give_dlc_and_verify_blackmarket()
        pcall(function()
            if self.give_dlc_package then
                self:give_dlc_package()
            end
        end)
        if managers.blackmarket then
            pcall(function()
                if managers.blackmarket.verify_dlc_items then
                    managers.blackmarket:verify_dlc_items()
                end
            end)
        end
    end

    -- Override give_dlc_package to mark all packages owned and use pcall on original
    local orig_give_dlc_package = manager_class.give_dlc_package
    function manager_class:give_dlc_package()
        Global.dlc_save = Global.dlc_save or { packages = {} }
        Global.dlc_save.packages = Global.dlc_save.packages or {}

        if tweak_data and tweak_data.dlc then
            for package_id, data in pairs(tweak_data.dlc) do
                Global.dlc_save.packages[package_id] = true
            end
        end

        if orig_give_dlc_package then
            pcall(orig_give_dlc_package, self)
        end
        return true
    end
end

-- Apply overrides to all known DLC manager classes across PC/Steam/Epic/Windows
local dlc_classes = {
    GenericDLCManager,
    WINDLCManager,
    WinSteamDLCManager,
    SteamDLCManager,
    WindirDLCManager,
    EOSDLCManager,
    EpicDLCManager,
    DLCManager
}

for i, cls in ipairs(dlc_classes) do
    if cls then
        DBG("DLC", "Unlocking DLC class #" .. i .. ": " .. tostring(cls))
        unlock_dlc_manager(cls)
    end
end

-- Function to force unlock all internal data structures
local function apply_full_unlock(self)
    Global.dlc_save = Global.dlc_save or { packages = {} }
    Global.dlc_save.packages = Global.dlc_save.packages or {}

    -- Unlock tweak_data.dlc entries
    if tweak_data and tweak_data.dlc then
        for package_id, dlc_data in pairs(tweak_data.dlc) do
            Global.dlc_save.packages[package_id] = true
            if type(dlc_data) == "table" then
                dlc_data.free = true
                dlc_data.verified = true
                dlc_data.unlocked = true
                dlc_data.enabled = true
                dlc_data.purchased = true
            end
        end
    end

    -- Unlock internal instance tables
    if self and self._dlc_data then
        for dlc_id, dlc_info in pairs(self._dlc_data) do
            if type(dlc_info) == "table" then
                dlc_info.unlocked = true
                dlc_info.enabled = true
                dlc_info.purchased = true
                dlc_info.verified = true
            end
        end
    end

    -- Unlock Global.dlc_manager.all_dlc_data entries and ensure safety metatable persists
    if Global.dlc_manager and Global.dlc_manager.all_dlc_data then
        if not getmetatable(Global.dlc_manager.all_dlc_data) then
            setmetatable(Global.dlc_manager.all_dlc_data, {
                __index = function(t, key)
                    if not key then
                        return nil
                    end
                    local val = {
                        verified = true,
                        unlocked = true,
                        enabled = true,
                        purchased = true,
                        is_dlc = true
                    }
                    rawset(t, key, val)
                    return val
                end
            })
        end

        for dlc_name, dlc_data in pairs(Global.dlc_manager.all_dlc_data) do
            if type(dlc_data) == "table" then
                dlc_data.verified = true
                dlc_data.unlocked = true
                dlc_data.enabled = true
                dlc_data.purchased = true
            end
        end
    end
end

-- Apply initialization hooks to whichever classes exist
local hook_targets = {
    { GenericDLCManager, "UltimateDLC_Generic_Init" },
    { WINDLCManager, "UltimateDLC_WIN_Init" },
    { WinSteamDLCManager, "UltimateDLC_WinSteam_Init" },
    { SteamDLCManager, "UltimateDLC_Steam_Init" },
    { WindirDLCManager, "UltimateDLC_Windir_Init" },
    { EOSDLCManager, "UltimateDLC_EOS_Init" },
    { EpicDLCManager, "UltimateDLC_Epic_Init" },
    { DLCManager, "UltimateDLC_DLC_Init" }
}

for _, target in ipairs(hook_targets) do
    local cls, hook_name = target[1], target[2]
    if cls and cls.init then
        Hooks:PostHook(cls, "init", hook_name, function(self)
            DBG("DLC", "PostHook fired: " .. hook_name)
            apply_full_unlock(self)
            unlock_dlc_manager(self)
        end)
    end
end

-- Run immediate unlock pass on startup
DBG("DLC", "Running immediate startup unlock pass...")
apply_full_unlock(nil)

DBG("DLC", "DLC Manager fully initialized.")
log("[DLC Unlocker] DLC Manager successfully initialized with full unlocks and nil protection.")
