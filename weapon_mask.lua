-- WEAPON MASKING SCRIPT
-- This script masks weapons when sending outfit data to servers

-- RequiredScript: lib/managers/blackmarketmanager

-- Store original functions
local original_equipped_primary = BlackMarketManager.equipped_primary
local original_equipped_secondary = BlackMarketManager.equipped_secondary

-- Default primary weapon to send to server
local default_primary = {
    ["weapon_id"] = "amcar",
    ["equipped"] = true,
    ["global_values"] = {},
    ["factory_id"] = "wpn_fps_ass_m4_amcar",
    ["blueprint"] = {
        [1] = "wpn_fps_m4_uupg_b_medium_vanilla",
        [2] = "wpn_fps_m4_lower_reciever",
        [3] = "wpn_fps_amcar_uupg_body_upperreciever",
        [4] = "wpn_fps_amcar_uupg_fg_amcar",
        [5] = "wpn_fps_upg_m4_m_straight_vanilla",
        [6] = "wpn_fps_upg_m4_s_standard_vanilla",
        [7] = "wpn_fps_upg_m4_g_standard_vanilla",
        [8] = "wpn_fps_amcar_bolt_standard",
    }
}

-- Default secondary weapon to send to server
local default_secondary = {
    ["weapon_id"] = "glock_17",
    ["equipped"] = true,
    ["global_values"] = {},
    ["factory_id"] = "wpn_fps_pis_g17",
    ["blueprint"] = {
        [1] = "wpn_fps_pis_g17_body_standard",
        [2] = "wpn_fps_pis_g17_b_standard",
        [3] = "wpn_fps_pis_g17_m_standard",
    }
}

-- Override equipped primary function
function BlackMarketManager:equipped_primary()
    if Global.IS_SENDING_OUTFIT then
        return default_primary
    end
    return original_equipped_primary(self)
end

-- Override equipped secondary function
function BlackMarketManager:equipped_secondary()
    if Global.IS_SENDING_OUTFIT then
        return default_secondary
    end
    return original_equipped_secondary(self)
end

-- Add hook for purchasing checks to prevent "Purchase Required" popups
local original_buy_item = BlackMarketManager.buy_item
function BlackMarketManager:buy_item(item_id, price, dlc_id)
    if dlc_id and dlc_id ~= "" then
        -- Pretend the purchase succeeded immediately
        return true
    end
    return original_buy_item(self, item_id, price, dlc_id)
end