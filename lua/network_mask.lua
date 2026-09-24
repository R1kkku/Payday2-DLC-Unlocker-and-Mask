-- =====================================================================
-- Network Session: Outfit Sending Wrapper & Cheat Check Bypass
-- RequiredScript: lib/network/base/basenetworksession
-- =====================================================================

-- Wrap check_send_outfit so that equipped items query the masked versions
-- pcall ensures IS_SENDING_OUTFIT always resets even if the original errors,
-- preventing stuck loading when multiple peers join simultaneously
local orig_check_send_outfit = BaseNetworkSession.check_send_outfit
function BaseNetworkSession:check_send_outfit(peer)
    Global.IS_SENDING_OUTFIT = true
    local ok, err = pcall(orig_check_send_outfit, self, peer)
    Global.IS_SENDING_OUTFIT = false
    if not ok then
        log("[DLC Unlocker] Error in check_send_outfit: " .. tostring(err))
    end
end

log("[DLC Unlocker] Network Session outfit masking initialized.")
