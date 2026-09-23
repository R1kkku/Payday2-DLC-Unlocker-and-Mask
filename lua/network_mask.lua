-- =====================================================================
-- Network Mask: Safe Outfit Transmission & Local Cheater Suppression
-- RequiredScripts:
--   lib/network/base/basenetworksession
--   lib/network/base/networkpeer
-- =====================================================================

-- Wrap check_send_outfit so that equipped items query the masked versions
if BaseNetworkSession then
    local orig_check_send_outfit = BaseNetworkSession.check_send_outfit
    function BaseNetworkSession:check_send_outfit(peer, ...)
        local was_sending = Global.IS_SENDING_OUTFIT
        Global.IS_SENDING_OUTFIT = true
        local status, res
        if orig_check_send_outfit then
            status, res = pcall(orig_check_send_outfit, self, peer, ...)
        end
        Global.IS_SENDING_OUTFIT = was_sending
        if status then
            return res
        end
    end
end

-- Suppress cheater tags from being assigned to the local player and protect set_outfit_string
if NetworkPeer then
    local orig_mark_cheater = NetworkPeer.mark_cheater
    function NetworkPeer:mark_cheater(reason, auto_kick, ...)
        local is_local = false
        if managers and managers.network and managers.network:session() then
            local lp = managers.network:session():local_peer()
            if (lp and self:id() == lp:id()) or self == lp then
                is_local = true
            end
        end

        if is_local then
            return
        end

        if orig_mark_cheater then
            return orig_mark_cheater(self, reason, auto_kick, ...)
        end
    end

    local orig_is_cheater = NetworkPeer.is_cheater
    function NetworkPeer:is_cheater(...)
        local is_local = false
        if managers and managers.network and managers.network:session() then
            local lp = managers.network:session():local_peer()
            if (lp and self:id() == lp:id()) or self == lp then
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
            if status then
                return res
            end
        end
    end
end
