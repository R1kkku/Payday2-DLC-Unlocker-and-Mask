-- === NETWORK FIX ===
if RequiredScript == "lib/network/base/basenetworksession" then
    local o_check_send_outfit = BaseNetworkSession.check_send_outfit
    local o_check_cheating = BaseNetworkSession.check_cheating
    local o_update_player_data = BaseNetworkSession.update_player_data

    -- Mask outfit data (send safe weapons)
    function BaseNetworkSession:check_send_outfit(peer)
        Global.IS_SENDING_OUTFIT = true
        o_check_send_outfit(self, peer)
        Global.IS_SENDING_OUTFIT = false
    end

    -- Bypass cheating checks for DLC
    function BaseNetworkSession:check_cheating(...)
        -- Return true to pass all checks (safe for now)
        return true
    end

    -- Force player data to show as having all DLCs
    function BaseNetworkSession:update_player_data(player)
        o_update_player_data(self, player)
        if player and player.data then
            -- Force the player data to think they own all DLCs
            -- This prevents the client from asking the server to unlock them
            player.data.dlc_unlocked = true
        end
    end

    -- Prevent Steam Store Redirects
    -- The game often checks if a DLC is unlocked before showing the store link.
    -- By forcing the check to return true, we prevent the store from opening.
    local o_open_dlc_store = MenuComponentManager.open_dlc_store
    function MenuComponentManager:open_dlc_store(dlc_id)
        -- Block the store from opening
        log("[DLC_Unlock_Fixed] Blocked attempt to open DLC store for: " .. tostring(dlc_id))
        return
    end

    -- Block DLC purchase prompts
    local o_open_dlc_purchase = MenuComponentManager.open_dlc_purchase
    function MenuComponentManager:open_dlc_purchase(dlc_id)
        log("[DLC_Unlock_Fixed] Blocked DLC purchase prompt for: " .. tostring(dlc_id))
        return
    end

    log("[DLC_Unlock_Fixed] Network fix loaded")
end