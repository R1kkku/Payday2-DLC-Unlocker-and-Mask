-- =====================================================================
-- BlackMarket Manager: DLC Unlock & Multiplayer Outfit Masking
-- RequiredScript: lib/managers/blackmarketmanager
-- =====================================================================

local safe_primary = {
    weapon_id = "amcar",
    equipped = true,
    global_values = {},
    factory_id = "wpn_fps_ass_m4_amcar",
    blueprint = {
        "wpn_fps_m4_uupg_b_medium_vanilla",
        "wpn_fps_m4_lower_reciever",
        "wpn_fps_amcar_uupg_body_upperreciever",
        "wpn_fps_amcar_uupg_fg_amcar",
        "wpn_fps_upg_m4_m_straight_vanilla",
        "wpn_fps_upg_m4_s_standard_vanilla",
        "wpn_fps_upg_m4_g_standard_vanilla",
        "wpn_fps_amcar_bolt_standard"
    }
}

local safe_secondary = {
    weapon_id = "glock_17",
    equipped = true,
    global_values = {},
    factory_id = "wpn_fps_pis_g17",
    blueprint = {
        "wpn_fps_pis_g17_body_standard",
        "wpn_fps_pis_g17_b_standard",
        "wpn_fps_pis_g17_m_standard"
    }
}

local safe_mask = {
    mask_id = "character_locked",
    blueprint = {
        color = { id = "nothing" },
        color_a = { id = "nothing" },
        color_b = { id = "nothing" },
        pattern = { id = "no_color_no_material" },
        material = { id = "plastic" }
    }
}

local function get_safe_primary()
    local factory_id = "wpn_fps_ass_m4_amcar"
    local bp = (managers.weapon_factory and managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id)) or safe_primary.blueprint
    return {
        weapon_id = "amcar",
        equipped = true,
        global_values = {},
        factory_id = factory_id,
        blueprint = bp
    }
end

local function get_safe_secondary()
    local factory_id = "wpn_fps_pis_g17"
    local bp = (managers.weapon_factory and managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id)) or safe_secondary.blueprint
    return {
        weapon_id = "glock_17",
        equipped = true,
        global_values = {},
        factory_id = factory_id,
        blueprint = bp
    }
end

-- Return safe vanilla weapons when syncing outfit with peers/server
local orig_equipped_primary = BlackMarketManager.equipped_primary
function BlackMarketManager:equipped_primary(...)
    if Global.IS_SENDING_OUTFIT then
        return get_safe_primary()
    end
    return orig_equipped_primary(self, ...)
end

local orig_equipped_secondary = BlackMarketManager.equipped_secondary
function BlackMarketManager:equipped_secondary(...)
    if Global.IS_SENDING_OUTFIT then
        return get_safe_secondary()
    end
    return orig_equipped_secondary(self, ...)
end

local orig_equipped_mask = BlackMarketManager.equipped_mask
function BlackMarketManager:equipped_mask(...)
    if Global.IS_SENDING_OUTFIT then
        local current = orig_equipped_mask and orig_equipped_mask(self, ...)
        if current and current.mask_id then
            local mask_tweak = tweak_data and tweak_data.blackmarket and tweak_data.blackmarket.masks and tweak_data.blackmarket.masks[current.mask_id]
            if mask_tweak and mask_tweak.dlc then
                return safe_mask
            end
        end
        return current or safe_mask
    end
    return orig_equipped_mask(self, ...)
end

-- Safely serialize mask outfit string during network sync
local orig_outfit_string_mask = BlackMarketManager._outfit_string_mask
function BlackMarketManager:_outfit_string_mask(...)
    if Global.IS_SENDING_OUTFIT then
        local current = orig_equipped_mask and orig_equipped_mask(self)
        if current and current.mask_id then
            local mask_tweak = tweak_data and tweak_data.blackmarket and tweak_data.blackmarket.masks and tweak_data.blackmarket.masks[current.mask_id]
            if not (mask_tweak and mask_tweak.dlc) and orig_outfit_string_mask then
                local status, res = pcall(orig_outfit_string_mask, self, ...)
                if status and res then
                    return res
                end
            end
        end
        return " character_locked nothing-nothing no_color_no_material plastic"
    end
    if orig_outfit_string_mask then
        local status, res = pcall(orig_outfit_string_mask, self, ...)
        if status and res then
            return res
        end
    end
    return " character_locked nothing-nothing no_color_no_material plastic"
end

-- Allow purchasing any item without DLC lock popups
local orig_buy_item = BlackMarketManager.buy_item
function BlackMarketManager:buy_item(item_id, price, dlc_id)
    if dlc_id and dlc_id ~= "" then
        return true
    end
    if orig_buy_item then
        return orig_buy_item(self, item_id, price, dlc_id)
    end
    return true
end

-- Bypass inventory DLC verification checks to prevent item stripping and crashes
function BlackMarketManager:verify_dlc_items()
    return true
end

-- Verify weapon ownership as unlocked
function BlackMarketManager:is_weapon_unlocked(weapon_id)
    return true
end

-- Verify mask ownership as unlocked
function BlackMarketManager:is_mask_unlocked(mask_id)
    return true
end

-- Verify weapon mod ownership as unlocked
function BlackMarketManager:is_weapon_mod_unlocked(...)
    return true
end

-- Force ownership check to pass for DLC items
function BlackMarketManager:check_ownership(category, name)
    return true
end

log("[DLC Unlocker] BlackMarket Manager masking and ownership hooks initialized.")
