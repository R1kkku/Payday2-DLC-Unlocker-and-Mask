-- RequiredScript: lib/setups/gamesetup

-- Force all DLC to be marked as unlocked in the save data
Hooks:PostHook(GameSetup, "load_start_menu_resources", "force_dlc_unlock_on_start", function(self)
    if not Global.dlc_save then
        Global.dlc_save = { packages = {} }
    end
    
    if not Global.dlc_save.packages then
        Global.dlc_save.packages = {}
    end
    
    -- Mark all DLC packages as purchased
    if tweak_data.dlc then
        for package_id, data in pairs(tweak_data.dlc) do
            Global.dlc_save.packages[package_id] = true
        end
    end
    
    log("[DLC Unlocker] DLC data fixed on start")
end)

-- Force all DLC to be marked as unlocked when loading a save
Hooks:PostHook(SavefileManager, "load_progress", "force_dlc_unlock_on_load", function(self)
    if not Global.dlc_save then
        Global.dlc_save = { packages = {} }
    end
    
    if not Global.dlc_save.packages then
        Global.dlc_save.packages = {}
    end
    
    -- Mark all DLC packages as purchased
    if tweak_data.dlc then
        for package_id, data in pairs(tweak_data.dlc) do
            Global.dlc_save.packages[package_id] = true
        end
    end
    
    log("[DLC Unlocker] DLC data fixed on load")
end)

-- Force all DLC to be marked as unlocked when saving
Hooks:PostHook(SavefileManager, "save_progress", "force_dlc_unlock_on_save", function(self)
    if not Global.dlc_save then
        Global.dlc_save = { packages = {} }
    end
    
if not Global.dlc_save.packages then
        Global.dlc_save.packages = {}
    end
    
    -- Mark all DLC packages as purchased
    if tweak_data.dlc then
        for package_id, data in pairs(tweak_data.dlc) do
            Global.dlc_save.packages[package_id] = true
        end
    end
    
    log("[DLC Unlocker] DLC data fixed on save")
end)