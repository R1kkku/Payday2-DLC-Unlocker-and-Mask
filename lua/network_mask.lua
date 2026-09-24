-- =====================================================================
-- Network Mask: Safe Outfit Transmission & Local Cheater Suppression
-- RequiredScripts:
--   lib/network/base/basenetworksession
--   lib/network/base/networkpeer
--
-- DESIGN: Minimal hooks only. NO pcall wrapping — PD2's internal state
-- machine relies on errors propagating correctly for peer initialization,
-- outfit sync callbacks, and loading queue management. Wrapping these
-- in pcall corrupts the session state (peers stuck with no status, lobby
-- hangs, loading queue blocked).
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
    DBG("NET", "BaseNetworkSession detected — hooking check_send_outfit")
    local orig_check_send_outfit = BaseNetworkSession.check_send_outfit
    function BaseNetworkSession:check_send_outfit(peer, ...)
        local peer_id = peer and peer.id and peer:id() or "?"
        DBG("NET", ">>> check_send_outfit CALLED for peer " .. tostring(peer_id))
        Global.IS_SENDING_OUTFIT = true
        local res = orig_check_send_outfit(self, peer, ...)
        Global.IS_SENDING_OUTFIT = false
        DBG("NET", "    IS_SENDING_OUTFIT reset to false. Result: " .. tostring(res))
        return res
    end
else
    DBG("NET", "WARNING: BaseNetworkSession is NIL — check_send_outfit hook SKIPPED")
end

-- =====================================================================
-- 2. NetworkPeer Cheater Suppression (ALL known paths)
-- =====================================================================
if NetworkPeer then
    DBG("NET", "NetworkPeer detected — hooking ALL cheater paths")

    -- 2a. mark_cheater — the standard path
    local orig_mark_cheater = NetworkPeer.mark_cheater
    function NetworkPeer:mark_cheater(reason, auto_kick, ...)
        local peer_id = self.id and self:id() or "?"
        DBG("CHEAT", "!!! mark_cheater CALLED | peer=" .. tostring(peer_id) .. " | reason=" .. tostring(reason) .. " | kick=" .. tostring(auto_kick))

        if is_local_peer(self) then
            DBG("CHEAT", "    >>> BLOCKED mark_cheater for LOCAL peer")
            return
        end

        DBG("CHEAT", "    Allowing mark_cheater for REMOTE peer " .. tostring(peer_id))
        if orig_mark_cheater then
            return orig_mark_cheater(self, reason, auto_kick, ...)
        end
    end

    -- 2b. is_cheater — queried by HUD/UI to show the tag
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

    -- 2c. set_cheater — some versions use this instead of mark_cheater
    if NetworkPeer.set_cheater then
        local orig_set_cheater = NetworkPeer.set_cheater
        function NetworkPeer:set_cheater(reason, ...)
            local peer_id = self.id and self:id() or "?"
            DBG("CHEAT", "!!! set_cheater CALLED | peer=" .. tostring(peer_id) .. " | reason=" .. tostring(reason))
            if is_local_peer(self) then
                DBG("CHEAT", "    >>> BLOCKED set_cheater for LOCAL peer")
                return
            end
            if orig_set_cheater then
                return orig_set_cheater(self, reason, ...)
            end
        end
    end

    -- 2d. Direct _cheater field protection — nuke it on the local peer
    --     PD2 may set self._cheater = true directly, bypassing our hooks
    local orig_peer_set_outfit_string = NetworkPeer.set_outfit_string
    if orig_peer_set_outfit_string then
        function NetworkPeer:set_outfit_string(outfit_string, ...)
            local res = orig_peer_set_outfit_string(self, outfit_string, ...)
            -- After outfit is set, force clear cheater flag on local peer
            if is_local_peer(self) and self._cheater then
                DBG("CHEAT", "!!! Clearing _cheater flag set during set_outfit_string for LOCAL peer")
                self._cheater = false
            end
            return res
        end
    end

    -- 2e. chk_peer_outfit / verify_outfit — host-side outfit verification
    if NetworkPeer.chk_outfit then
        local orig_chk_outfit = NetworkPeer.chk_outfit
        function NetworkPeer:chk_outfit(...)
            if is_local_peer(self) then
                DBG("CHEAT", "chk_outfit called for LOCAL peer — returning clean")
                return true
            end
            return orig_chk_outfit(self, ...)
        end
    end

    if NetworkPeer.verify_outfit then
        local orig_verify_outfit = NetworkPeer.verify_outfit
        function NetworkPeer:verify_outfit(...)
            if is_local_peer(self) then
                DBG("CHEAT", "verify_outfit called for LOCAL peer — returning clean")
                return true
            end
            return orig_verify_outfit(self, ...)
        end
    end

    -- 2f. Periodic cheater flag scrubber — clears _cheater on local peer
    --     This catches ANY code path that sets the flag directly
    local orig_peer_update = NetworkPeer.update
    if orig_peer_update then
        function NetworkPeer:update(...)
            local res = orig_peer_update(self, ...)
            if is_local_peer(self) and self._cheater then
                DBG("CHEAT", "!!! SCRUBBED _cheater flag on LOCAL peer during update()")
                self._cheater = false
                self._cheater_reason = nil
            end
            return res
        end
    end

else
    DBG("NET", "WARNING: NetworkPeer is NIL — cheater hooks SKIPPED")
end

-- =====================================================================
-- 3. HUDManager:mark_cheater — blocks the UI CHEATER label
--    This is often called INDEPENDENTLY of NetworkPeer:mark_cheater
-- =====================================================================
if HUDManager and not rawget(HUDManager, "_dlc_cheater_patched") then
    rawset(HUDManager, "_dlc_cheater_patched", true)

    local orig_hud_mark_cheater = HUDManager.mark_cheater
    function HUDManager:mark_cheater(peer_id, ...)
        local local_id = get_local_peer_id()
        DBG("CHEAT", "!!! HUDManager:mark_cheater CALLED | peer_id=" .. tostring(peer_id) .. " | local_id=" .. tostring(local_id))

        if peer_id and local_id and tonumber(peer_id) == tonumber(local_id) then
            DBG("CHEAT", "    >>> BLOCKED HUD cheater label for LOCAL peer")
            return
        end

        -- Also block peer_id 1 when we are host (host is always peer 1)
        if peer_id and tonumber(peer_id) == 1 then
            if managers and managers.network and managers.network:session() and managers.network:session():is_host() then
                DBG("CHEAT", "    >>> BLOCKED HUD cheater label for HOST (peer 1)")
                return
            end
        end

        DBG("CHEAT", "    Allowing HUD cheater label for peer " .. tostring(peer_id))
        if orig_hud_mark_cheater then
            return orig_hud_mark_cheater(self, peer_id, ...)
        end
    end
end

-- =====================================================================
-- 4. BaseNetworkSession outfit verification hooks (host-side checks)
-- =====================================================================
if BaseNetworkSession then
    -- chk_peer_outfit_data — host validates incoming outfit data
    if BaseNetworkSession.on_peer_outfit_loaded then
        local orig_on_peer_outfit_loaded = BaseNetworkSession.on_peer_outfit_loaded
        function BaseNetworkSession:on_peer_outfit_loaded(peer, ...)
            local res = orig_on_peer_outfit_loaded(self, peer, ...)
            -- After outfit is validated, clear any cheater flag on local peer
            if peer and is_local_peer(peer) and peer._cheater then
                DBG("CHEAT", "!!! Clearing _cheater flag after on_peer_outfit_loaded for LOCAL peer")
                peer._cheater = false
                peer._cheater_reason = nil
            end
            return res
        end
    end
end

DBG("NET", "network_mask.lua fully loaded — ALL cheater paths hooked")
