-- Helper to display local system messages and console logs
local function debug_msg(msg)
    log("[DLC Unlocker] " .. tostring(msg))
    if managers and managers.chat and managers.chat.feed_system_message and ChatManager then
        pcall(function()
            managers.chat:feed_system_message(ChatManager.GAME, "[DLC Unlocker] " .. tostring(msg))
        end)
    end
end

-- Wrap check_send_outfit so that equipped items query the masked versions
if BaseNetworkSession then
    local orig_check_send_outfit = BaseNetworkSession.check_send_outfit
    function BaseNetworkSession:check_send_outfit(peer, ...)
        Global.IS_SENDING_OUTFIT = true
        debug_msg("Sending masked outfit to " .. (peer and ("peer " .. tostring(peer:id())) or "all peers") .. "...")
        local status, res = pcall(orig_check_send_outfit, self, peer, ...)
        Global.IS_SENDING_OUTFIT = nil

        if not status then
            debug_msg("Error in check_send_outfit: " .. tostring(res))
        else
            debug_msg("Masked outfit sent cleanly. Cheater Tag: CLEAN.")
        end
        return res
    end

    -- Monitor ready states and notify when waiting for host
    local orig_on_set_member_ready = BaseNetworkSession.on_set_member_ready
    function BaseNetworkSession:on_set_member_ready(peer_id, ready, state, ...)
        if orig_on_set_member_ready then
            orig_on_set_member_ready(self, peer_id, ready, state, ...)
        end

        local lp = self:local_peer()
        local host = self:server_peer()
        local host_name = host and host:name() or "Host"

        if lp and peer_id == lp:id() and ready then
            debug_msg("You are READY! The lobby is waiting on Host (" .. tostring(host_name) .. ") to launch the heist.")
        end
    end
end

-- Suppress cheater tags from being assigned to the local player and monitor checks
if NetworkPeer then
    local orig_mark_cheater = NetworkPeer.mark_cheater
    function NetworkPeer:mark_cheater(reason, auto_kick, ...)
        local is_local = false
        if managers and managers.network and managers.network:session() then
            local lp = managers.network:session():local_peer()
            if lp and self:id() == lp:id() then
                is_local = true
            end
        end

        if is_local then
            debug_msg("BLOCKED anti-cheat trigger on you! (Reason code: " .. tostring(reason) .. "). Tag suppressed.")
            return
        end

        debug_msg("Peer " .. tostring(self:name() or self:id()) .. " was marked as cheater (Reason: " .. tostring(reason) .. ")")
        if orig_mark_cheater then
            return orig_mark_cheater(self, reason, auto_kick, ...)
        end
    end

    local orig_is_cheater = NetworkPeer.is_cheater
    function NetworkPeer:is_cheater(...)
        local is_local = false
        if managers and managers.network and managers.network:session() then
            local lp = managers.network:session():local_peer()
            if lp and self:id() == lp:id() then
                is_local = true
            end
        end

        if is_local then
            return false
        end

        if orig_is_cheater then
            return orig_is_cheater(self, ...)
        end
        return false
    end

    local orig_set_outfit_string = NetworkPeer.set_outfit_string
    function NetworkPeer:set_outfit_string(str, ...)
        if orig_set_outfit_string then
            local status, res = pcall(orig_set_outfit_string, self, str, ...)
            if not status then
                debug_msg("Warning: set_outfit_string error suppressed: " .. tostring(res))
            end
            return res
        end
    end
end

log("[DLC Unlocker] Network Session and Peer masking initialized with active debug monitoring.")
