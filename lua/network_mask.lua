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

-- Wrap check_send_outfit so that equipped items query the masked versions
if BaseNetworkSession then
    local orig_check_send_outfit = BaseNetworkSession.check_send_outfit
    function BaseNetworkSession:check_send_outfit(peer, ...)
        -- Set the flag so equipped_*() hooks return vanilla items,
        -- then call the original which handles RPC to the host.
        -- NO pcall — let any errors propagate naturally so PD2's
        -- session state machine can handle them properly.
        Global.IS_SENDING_OUTFIT = true
        local res = orig_check_send_outfit(self, peer, ...)
        Global.IS_SENDING_OUTFIT = false
        return res
    end
end

-- Suppress cheater tags for the local player only
if NetworkPeer then
    local orig_mark_cheater = NetworkPeer.mark_cheater
    function NetworkPeer:mark_cheater(reason, auto_kick, ...)
        -- Only block for local peer; let remote peer marks through
        if managers and managers.network and managers.network:session() then
            local lp = managers.network:session():local_peer()
            if lp and (self == lp or self:id() == lp:id()) then
                return
            end
        end
        if orig_mark_cheater then
            return orig_mark_cheater(self, reason, auto_kick, ...)
        end
    end

    local orig_is_cheater = NetworkPeer.is_cheater
    function NetworkPeer:is_cheater(...)
        -- Only override for local peer
        if managers and managers.network and managers.network:session() then
            local lp = managers.network:session():local_peer()
            if lp and (self == lp or self:id() == lp:id()) then
                return false
            end
        end
        if orig_is_cheater then
            return orig_is_cheater(self, ...)
        end
        return false
    end
end
