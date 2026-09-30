-- =====================================================================
-- Network Mask: Safe Outfit Transmission & Local Cheater Suppression
-- RequiredScripts:
--   lib/network/base/basenetworksession
--   lib/network/base/networkpeer
--   lib/managers/hudmanagerpd2
--
-- DESIGN: Multi-layered cheater suppression:
--   Layer 1: Block mark_cheater / set_cheater for local peer
--   Layer 2: Force is_cheater() to return false for local peer
--   Layer 3: Nuke verify_outfit / verify_job / verify_character for local peer
--   Layer 4: Block HUDManager cheater display for local peer
--   Layer 5: Block all cheater-related chat messages for local peer
--   Layer 6: Intercept the managers.hud set_cheater_name call
-- =====================================================================

-- Helper: get local peer ID safely
local function get_local_peer_id()
    if managers and managers.network and managers.network:session() then
        local lp = managers.network:session():local_peer()
        if lp and lp.id then
            return lp:id()
        end
    end
    return nil
end

-- Helper: check if a peer is the local player
local function is_local_peer(peer)
    if not peer then return false end
    local local_id = get_local_peer_id()
    if not local_id then return false end
    local peer_id = peer.id and peer:id()
    return peer_id and peer_id == local_id
end

-- =====================================================================
-- 1. Outfit Masking: Wrap check_send_outfit
-- =====================================================================
if BaseNetworkSession then
    local orig_check_send_outfit = BaseNetworkSession.check_send_outfit
    function BaseNetworkSession:check_send_outfit(peer, ...)
        Global.IS_SENDING_OUTFIT = true
        pcall(orig_check_send_outfit, self, peer, ...)
        Global.IS_SENDING_OUTFIT = false
    end

    -- Hook on_peer_sync_complete to force-clear cheater flag after sync
    if BaseNetworkSession.on_peer_sync_complete then
        local orig_on_peer_sync_complete = BaseNetworkSession.on_peer_sync_complete
        function BaseNetworkSession:on_peer_sync_complete(peer, ...)
            local res = orig_on_peer_sync_complete(self, peer, ...)
            if peer and is_local_peer(peer) then
                peer._cheater = nil
            end
            return res
        end
    end
end

-- =====================================================================
-- 2. NetworkPeer Cheater Suppression (ALL known paths)
-- =====================================================================
if NetworkPeer then
    -- 2a. mark_cheater — completely block for local peer
    local orig_mark_cheater = NetworkPeer.mark_cheater
    function NetworkPeer:mark_cheater(reason, auto_kick, ...)
        if is_local_peer(self) then
            return
        end
        if orig_mark_cheater then
            return orig_mark_cheater(self, reason, auto_kick, ...)
        end
    end

    -- 2b. is_cheater — always false for local peer
    local orig_is_cheater = NetworkPeer.is_cheater
    function NetworkPeer:is_cheater(...)
        if is_local_peer(self) then
            return false
        end
        if orig_is_cheater then
            return orig_is_cheater(self, ...)
        end
        return false
    end

    -- 2c. set_cheater — if it exists
    if NetworkPeer.set_cheater then
        local orig_set_cheater = NetworkPeer.set_cheater
        function NetworkPeer:set_cheater(reason, ...)
            if is_local_peer(self) then
                return
            end
            if orig_set_cheater then
                return orig_set_cheater(self, reason, ...)
            end
        end
    end

    -- 2d. NUKE verify_outfit for local peer — this is the ROOT CAUSE
    --     verify_outfit() calls _verify_outfit_data() which SHOULD skip local peer,
    --     but then calls mark_cheater() which may be a C++ native that sets
    --     internal state before our Lua hook can intercept.
    local orig_verify_outfit = NetworkPeer.verify_outfit
    function NetworkPeer:verify_outfit(...)
        if is_local_peer(self) then
            return
        end
        if orig_verify_outfit then
            return orig_verify_outfit(self, ...)
        end
    end

    -- 2e. NUKE verify_job for local peer
    local orig_verify_job = NetworkPeer.verify_job
    if orig_verify_job then
        function NetworkPeer:verify_job(job, ...)
            if is_local_peer(self) then
                return
            end
            return orig_verify_job(self, job, ...)
        end
    end

    -- 2f. NUKE verify_character for local peer
    local orig_verify_character = NetworkPeer.verify_character
    if orig_verify_character then
        function NetworkPeer:verify_character(...)
            if is_local_peer(self) then
                return
            end
            return orig_verify_character(self, ...)
        end
    end

    -- 2g. NUKE _verify_outfit_data for local peer
    local orig_verify_outfit_data = NetworkPeer._verify_outfit_data
    if orig_verify_outfit_data then
        function NetworkPeer:_verify_outfit_data(...)
            if is_local_peer(self) then
                return nil
            end
            return orig_verify_outfit_data(self, ...)
        end
    end

    -- 2h. Direct _cheater field protection via set_outfit_string
    local orig_peer_set_outfit_string = NetworkPeer.set_outfit_string
    if orig_peer_set_outfit_string then
        function NetworkPeer:set_outfit_string(outfit_string, ...)
            local res = orig_peer_set_outfit_string(self, outfit_string, ...)
            if is_local_peer(self) and self._cheater then
                self._cheater = nil
            end
            return res
        end
    end

    -- 2i. Periodic scrubber in update
    local orig_peer_update = NetworkPeer.update
    if orig_peer_update then
        function NetworkPeer:update(...)
            local res = orig_peer_update(self, ...)
            if is_local_peer(self) and self._cheater then
                self._cheater = nil
                self._cheater_reason = nil
            end
            return res
        end
    end

end

-- =====================================================================
-- 3. HUDManager — block ALL cheater display for local peer
-- =====================================================================
if HUDManager and not rawget(HUDManager, "_dlc_cheater_patched") then
    rawset(HUDManager, "_dlc_cheater_patched", true)

    -- 3a. mark_cheater
    local orig_hud_mark_cheater = HUDManager.mark_cheater
    function HUDManager:mark_cheater(peer_id, ...)
        local local_id = get_local_peer_id()

        -- Block for local peer (either by ID match or host=peer1)
        if peer_id and local_id and tonumber(peer_id) == tonumber(local_id) then
            return
        end
        if peer_id and tonumber(peer_id) == 1 and Network:is_server() then
            return
        end

        if orig_hud_mark_cheater then
            return orig_hud_mark_cheater(self, peer_id, ...)
        end
    end

    -- 3b. set_cheater_name — the nameplate "CHEATER" text setter
    if HUDManager.set_cheater_name then
        local orig_set_cheater_name = HUDManager.set_cheater_name
        function HUDManager:set_cheater_name(peer_id, ...)
            local local_id = get_local_peer_id()
            if peer_id and local_id and tonumber(peer_id) == tonumber(local_id) then
                return
            end
            if peer_id and tonumber(peer_id) == 1 and Network:is_server() then
                return
            end
            if orig_set_cheater_name then
                return orig_set_cheater_name(self, peer_id, ...)
            end
        end
    end

    -- 3c. set_name_label — hook the nameplate setter to strip CHEATER from name
    if HUDManager.set_name_label then
        local orig_set_name_label = HUDManager.set_name_label
        function HUDManager:set_name_label(data, ...)
            if data and type(data) == "table" then
                local local_id = get_local_peer_id()
                local peer_id = data.id or data.peer_id
                if peer_id and local_id and tonumber(peer_id) == tonumber(local_id) then
                    data.is_cheater = false
                    data.cheater = false
                    if data.name then
                        -- Strip any existing CHEATER text from name
                        data.name = data.name:gsub("%s*CHEATER%s*", "")
                    end
                end
            end
            if orig_set_name_label then
                return orig_set_name_label(self, data, ...)
            end
        end
    end
end

-- =====================================================================
-- 4. VoteManager — block auto-kick for local peer
-- =====================================================================
if VoteManager and not rawget(VoteManager, "_dlc_patched") then
    rawset(VoteManager, "_dlc_patched", true)

    local orig_kick_auto = VoteManager.kick_auto
    function VoteManager:kick_auto(reason, peer, loading, ...)
        if peer and is_local_peer(peer) then
            return
        end
        if orig_kick_auto then
            return orig_kick_auto(self, reason, peer, loading, ...)
        end
    end
end

-- =====================================================================
-- 5. Chat message suppression — hide cheater notifications for local
-- =====================================================================
if managers and managers.chat then
    local orig_receive_message = managers.chat.receive_message_by_peer
    if orig_receive_message then
        function managers.chat:receive_message_by_peer(channel_id, peer, message, ...)
            if peer and is_local_peer(peer) and message then
                local lower_msg = message:lower()
                if lower_msg:find("cheat") then
                    return
                end
            end
            return orig_receive_message(self, channel_id, peer, message, ...)
        end
    end
end
