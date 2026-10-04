-- =====================================================================
-- UI Fixes: Block DLC Store Prompts & Unlock GUI Item Displays
-- RequiredScripts:
--   lib/managers/menu/menucomponentmanager
--   lib/managers/menu/blackmarketgui
--   lib/managers/menu/inventorygui
--   lib/managers/menu/mainmenugui
--   lib/managers/menu/lootdropscreencomponent
-- =====================================================================

-- 1. Block Store Links from MenuComponentManager
if RequiredScript == "lib/managers/menu/menucomponentmanager" or MenuComponentManager then
    if MenuComponentManager then
        function MenuComponentManager:open_dlc_store(dlc_id)
            log("[DLC Unlocker] Blocked DLC store redirect for: " .. tostring(dlc_id))
            return
        end

        function MenuComponentManager:open_dlc_purchase(dlc_id)
            log("[DLC Unlocker] Blocked DLC purchase redirect for: " .. tostring(dlc_id))
            return
        end

        function MenuComponentManager:open_store(...)
            log("[DLC Unlocker] Blocked general store redirect")
            return
        end
    end
end

-- 2. Unlock Locked Display State & Enable Coin Purchasing in BlackMarket GUI
if RequiredScript == "lib/managers/menu/blackmarketgui" or BlackMarketGui then
    if BlackMarketGui and not rawget(BlackMarketGui, "_dlc_bm_gui_patched") then
        rawset(BlackMarketGui, "_dlc_bm_gui_patched", true)

        local orig_populate_mods = BlackMarketGui.populate_mods
        function BlackMarketGui:populate_mods(data, ...)
            if orig_populate_mods then
                orig_populate_mods(self, data, ...)
            end

            if data and type(data) == "table" then
                local no_items_text = managers.localization and managers.localization:text("bm_menu_no_items")
                for _, slot_data in ipairs(data) do
                    if type(slot_data) == "table" and slot_data.name and slot_data.name ~= "empty" then
                        -- Remove DLC and lock restrictions so mod is eligible to be purchased with coins
                        slot_data.dlc_locked = nil
                        slot_data.lock_texture = nil
                        slot_data.lock_color = nil

                        local amount = type(slot_data.unlocked) == "number" and slot_data.unlocked or (slot_data.unlocked and 1 or 0)

                        if amount > 0 then
                            -- Player has item in inventory stock: allow crafting with cash
                            if slot_data.corner_text and no_items_text and slot_data.corner_text.selected_text == no_items_text then
                                slot_data.corner_text = nil
                            end

                            if not slot_data.equipped and slot_data.can_afford then
                                local has_buy = false
                                for _, btn in ipairs(slot_data) do
                                    if btn == "wm_buy" then
                                        has_buy = true
                                        break
                                    end
                                end
                                if not has_buy then
                                    table.insert(slot_data, 1, "wm_buy")
                                end
                            end
                        else
                            -- Player does NOT have item in stock: remove craft button so it must be purchased with coins first
                            for i = #slot_data, 1, -1 do
                                if slot_data[i] == "wm_buy" then
                                    table.remove(slot_data, i)
                                end
                            end
                        end

                        -- Always allow purchasing the mod using Continental Coins (wm_buy_mod) if safehouse is unlocked
                        if managers.custom_safehouse and managers.custom_safehouse:unlocked() then
                            local has_coin_buy = false
                            for _, btn in ipairs(slot_data) do
                                if btn == "wm_buy_mod" then
                                    has_coin_buy = true
                                    break
                                end
                            end
                            if not has_coin_buy then
                                table.insert(slot_data, "wm_buy_mod")
                            end
                        end
                    end
                end
            end
        end

        local orig_purchase_weapon_mod_cb = BlackMarketGui.purchase_weapon_mod_callback
        if orig_purchase_weapon_mod_cb then
            function BlackMarketGui:purchase_weapon_mod_callback(data, ...)
                if data and data.name and tweak_data and tweak_data.weapon and tweak_data.weapon.factory and tweak_data.weapon.factory.parts then
                    local part_td = tweak_data.weapon.factory.parts[data.name]
                    if part_td and part_td.is_event_mod then
                        part_td.is_event_mod = nil
                    end
                end
                return orig_purchase_weapon_mod_cb(self, data, ...)
            end
        end

        local orig_update_buy_info = BlackMarketGui._update_buy_info
        if orig_update_buy_info then
            function BlackMarketGui:_update_buy_info(data, update)
                orig_update_buy_info(self, data, update)

                if data and data.locked and not data.empty_slot then
                    data.locked = false
                    data.dlc_locked = nil

                    if self._slots and self._slots[data.slot] and self._slots[data.slot].refresh then
                        self._slots[data.slot]:refresh()
                    end
                end
            end
        end
    end
end

-- 3. Unlock Locked Display State in Inventory GUI
if RequiredScript == "lib/managers/menu/inventorygui" then
    local orig_update_info = InventoryGui.update_info
    function InventoryGui:update_info(data)
        orig_update_info(self, data)

        if data and data.locked and not data.empty_slot then
            data.locked = false
            data.unlocked = true
            data.dlc_locked = nil

            if self._slots and self._slots[data.slot] and self._slots[data.slot].refresh then
                self._slots[data.slot]:refresh()
            end
        end
    end
end

-- 4. Strip Store Purchase Callbacks from Main Menu Items
if RequiredScript == "lib/managers/menu/mainmenugui" then
    local orig_create_item = MainMenuGui._create_item
    function MainMenuGui:_create_item(item, i)
        local result = orig_create_item(self, item, i)

        if item and item._parameters and item._parameters.callback then
            local cb = item._parameters.callback
            if cb == "open_dlc_store" or cb == "open_dlc_purchase" then
                item._parameters.callback = nil
            end
        end

        return result
    end
end

-- 5. Unlock Loot Drop Screen Items
if RequiredScript == "lib/managers/menu/lootdropscreencomponent" then
    local orig_make_fine_text = LootDropScreenComponent._make_fine_text
    function LootDropScreenComponent:_make_fine_text(text)
        local result = orig_make_fine_text(self, text)

        if self._data and self._data.item_entry then
            local item_entry = self._data.item_entry
            if item_entry and item_entry.dlc_locked then
                item_entry.dlc_locked = nil
                item_entry.locked = false
                item_entry.unlocked = true
            end
        end

        return result
    end

    local orig_create_items = LootDropScreenComponent.create_items
    function LootDropScreenComponent:create_items()
        local result = orig_create_items(self)

        if self._items then
            for _, item in ipairs(self._items) do
                if item.dlc_locked then
                    item.dlc_locked = nil
                end
                if item.locked then
                    item.locked = false
                end
                item.unlocked = true
            end
        end

        return result
    end
end

-- 6. Block Store Redirects from MenuCallbackHandler
if MenuCallbackHandler then
    function MenuCallbackHandler:open_dlc_store(...)
        return
    end

    function MenuCallbackHandler:open_steam_store(...)
        return
    end

    function MenuCallbackHandler:buy_dlc(...)
        return
    end
end

-- 7. Fix HUDLootScreen crash when panel is nil (Crime Spree / Game Mode transitions)
if HUDLootScreen and not rawget(HUDLootScreen, "_dlc_fix_patched") then
    rawset(HUDLootScreen, "_dlc_fix_patched", true)
    local orig_init = HUDLootScreen.init
    function HUDLootScreen:init(hud, ...)
        if hud and not hud.panel then
            if managers and managers.hud and managers.hud._create_hud_chat_access then
                hud.panel = managers.gui_data and managers.gui_data:create_saferect_workspace() and managers.gui_data:create_saferect_workspace():panel()
            end
        end
        if orig_init then
            return orig_init(self, hud, ...)
        end
    end
end

if HUDManager and not rawget(HUDManager, "_dlc_fix_patched") then
    rawset(HUDManager, "_dlc_fix_patched", true)
    local orig_setup_lootscreen_hud = HUDManager.setup_lootscreen_hud
    function HUDManager:setup_lootscreen_hud(...)
        local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2 or Idstring("guis/player_info_hud_fullscreen_pd2"))
        if not hud or not hud.panel then
            local ws = managers.gui_data and managers.gui_data:create_saferect_workspace()
            if ws then
                self._hud_lootscreen = HUDLootScreen:new(nil, ws, ws:panel())
                return
            end
        end
        if orig_setup_lootscreen_hud then
            local status, res = pcall(orig_setup_lootscreen_hud, self, ...)
            if status then
                return res
            end
        end
    end
end

-- 8. Fix Crime Spree ModifierLessConcealment crash when opening Inventory Menu
local function patch_modifier_less_concealment(cls)
    if not cls or rawget(cls, "_patched_groupai") then
        return
    end
    rawset(cls, "_patched_groupai", true)

    local orig_modify_value = cls.modify_value
    function cls:modify_value(id, value, ...)
        if id == "player_visibility" then
            if not managers.groupai or not managers.groupai.state or not managers.groupai:state() or not managers.groupai:state().whisper_mode then
                return value
            end
        end
        if orig_modify_value then
            local ok, res = pcall(orig_modify_value, self, id, value, ...)
            if ok and res ~= nil then
                return res
            end
        end
        return value
    end
end

if ModifierLessConcealment then
    patch_modifier_less_concealment(ModifierLessConcealment)
end

if ModifiersManager and not rawget(ModifiersManager, "_dlc_fix_patched") then
    rawset(ModifiersManager, "_dlc_fix_patched", true)
    local orig_modify_value = ModifiersManager.modify_value
    function ModifiersManager:modify_value(id, value, ...)
        if id == "player_visibility" then
            if not managers.groupai or not managers.groupai.state or not managers.groupai:state() or not managers.groupai:state().whisper_mode then
                return value
            end
        end
        if orig_modify_value then
            local ok, res = pcall(orig_modify_value, self, id, value, ...)
            if ok and res ~= nil then
                return res
            end
        end
        return value
    end
end

-- 9. Protect PlayerInventoryGui against Crime Spree concealment crash and unhandled exceptions
if PlayerInventoryGui and not rawget(PlayerInventoryGui, "_dlc_fix_patched") then
    rawset(PlayerInventoryGui, "_dlc_fix_patched", true)

    local orig_init = PlayerInventoryGui.init
    function PlayerInventoryGui:init(...)
        if ModifierLessConcealment then
            patch_modifier_less_concealment(ModifierLessConcealment)
        end
        if orig_init then
            local ok, err = pcall(orig_init, self, ...)
            if not ok then
                log("[DLC Unlocker] Warning in PlayerInventoryGui:init: " .. tostring(err))
            end
        end
        self._boxes = self._boxes or {}
        self._text_buttons = self._text_buttons or {}
    end

    local orig_mouse_moved = PlayerInventoryGui.mouse_moved
    function PlayerInventoryGui:mouse_moved(...)
        if not self._boxes or type(self._boxes) ~= "table" then
            return false
        end
        if orig_mouse_moved then
            return orig_mouse_moved(self, ...)
        end
        return false
    end

    local orig_mouse_pressed = PlayerInventoryGui.mouse_pressed
    function PlayerInventoryGui:mouse_pressed(...)
        if not self._boxes or type(self._boxes) ~= "table" then
            return false
        end
        if orig_mouse_pressed then
            return orig_mouse_pressed(self, ...)
        end
        return false
    end

    local orig_mouse_released = PlayerInventoryGui.mouse_released
    function PlayerInventoryGui:mouse_released(...)
        if not self._boxes or type(self._boxes) ~= "table" then
            return false
        end
        if orig_mouse_released then
            return orig_mouse_released(self, ...)
        end
        return false
    end
end

if MenuComponentManager and not rawget(MenuComponentManager, "_dlc_inv_patched") then
    rawset(MenuComponentManager, "_dlc_inv_patched", true)

    local orig_create_inventory_gui = MenuComponentManager._create_inventory_gui
    function MenuComponentManager:_create_inventory_gui(...)
        if ModifierLessConcealment then
            patch_modifier_less_concealment(ModifierLessConcealment)
        end
        if orig_create_inventory_gui then
            return orig_create_inventory_gui(self, ...)
        end
    end
end


