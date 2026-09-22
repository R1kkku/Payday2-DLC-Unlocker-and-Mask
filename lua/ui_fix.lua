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

-- 2. Unlock Locked Display State in BlackMarket GUI
if RequiredScript == "lib/managers/menu/blackmarketgui" then
    local orig_update_buy_info = BlackMarketGui._update_buy_info
    function BlackMarketGui:_update_buy_info(data, update)
        orig_update_buy_info(self, data, update)

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
        log("[DLC Unlocker] Blocked MenuCallbackHandler open_dlc_store")
        return
    end

    function MenuCallbackHandler:open_steam_store(...)
        log("[DLC Unlocker] Blocked MenuCallbackHandler open_steam_store")
        return
    end

    function MenuCallbackHandler:buy_dlc(...)
        log("[DLC Unlocker] Blocked MenuCallbackHandler buy_dlc")
        return
    end
end

