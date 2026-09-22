-- =====================================================================
-- Network Session: Outfit Sending Wrapper & Cheat Check Bypass
-- RequiredScript: lib/network/base/basenetworksession
-- =====================================================================

-- Wrap check_send_outfit so that equipped items query the masked versions
local orig_check_send_outfit = BaseNetworkSession.check_send_outfit
function BaseNetworkSession:check_send_outfit(peer, ...)
    Global.IS_SENDING_OUTFIT = true
    local status, res = pcall(orig_check_send_outfit, self, peer, ...)
    Global.IS_SENDING_OUTFIT = nil

    if not status then
        log("[DLC Unlocker] Error in check_send_outfit: " .. tostring(res))
    end
    return res
end

log("[DLC Unlocker] Network Session outfit masking initialized.")

