-- =====================================================================
-- BlackMarket & Weapon Factory: DLC Unlock, Blueprint Fix & Outfit Masking
-- RequiredScripts:
--   lib/managers/blackmarketmanager
--   lib/managers/weaponfactorymanager
-- =====================================================================

local safe_primary = {
    weapon_id = "amcar",
    equipped = true,
    global_values = {},
    factory_id = "wpn_fps_ass_amcar",
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

-- Ensure WeaponFactoryManager:blueprint_to_string never crashes on missing factory or nil blueprint
local function patch_weapon_factory(wfm)
    if not wfm or rawget(wfm, "_dlc_blueprint_patched") then
        return
    end
    rawset(wfm, "_dlc_blueprint_patched", true)

    local orig_blueprint_to_string = wfm.blueprint_to_string
    function wfm:blueprint_to_string(factory_id, blueprint, ...)
        if not factory_id or not (tweak_data and tweak_data.weapon and tweak_data.weapon.factory and tweak_data.weapon.factory[factory_id]) then
            factory_id = "wpn_fps_ass_amcar"
            blueprint = (self.get_default_blueprint_by_factory_id and self:get_default_blueprint_by_factory_id(factory_id)) or safe_primary.blueprint
        end
        if not blueprint or type(blueprint) ~= "table" then
            blueprint = (self.get_default_blueprint_by_factory_id and self:get_default_blueprint_by_factory_id(factory_id)) or safe_primary.blueprint or {}
        end
        if orig_blueprint_to_string then
            local status, res = pcall(orig_blueprint_to_string, self, factory_id, blueprint, ...)
            if status and res then
                return res
            end
        end
        return ""
    end
end

if WeaponFactoryManager then
    patch_weapon_factory(WeaponFactoryManager)
end
if managers and managers.weapon_factory then
    patch_weapon_factory(managers.weapon_factory)
end

local function get_safe_primary(current)
    local factory_id = "wpn_fps_ass_amcar"
    local bp
    if managers and managers.weapon_factory and managers.weapon_factory.get_default_blueprint_by_factory_id then
        bp = managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id)
    end
    if not bp and tweak_data and tweak_data.weapon and tweak_data.weapon.factory and tweak_data.weapon.factory[factory_id] then
        bp = tweak_data.weapon.factory[factory_id].default_blueprint
    end
    if not bp or type(bp) ~= "table" or #bp == 0 then
        bp = safe_primary.blueprint
    end

    local cloned_bp = {}
    for _, part_id in ipairs(bp) do
        table.insert(cloned_bp, part_id)
    end

    local result = {}
    if current and type(current) == "table" then
        for k, v in pairs(current) do
            result[k] = v
        end
    end
    result.weapon_id = "amcar"
    result.equipped = true
    result.global_values = {}
    result.factory_id = factory_id
    result.blueprint = cloned_bp
    result.cosmetics = nil
    return result
end

local function get_safe_secondary(current)
    local factory_id = "wpn_fps_pis_g17"
    local bp
    if managers and managers.weapon_factory and managers.weapon_factory.get_default_blueprint_by_factory_id then
        bp = managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id)
    end
    if not bp and tweak_data and tweak_data.weapon and tweak_data.weapon.factory and tweak_data.weapon.factory[factory_id] then
        bp = tweak_data.weapon.factory[factory_id].default_blueprint
    end
    if not bp or type(bp) ~= "table" or #bp == 0 then
        bp = safe_secondary.blueprint
    end

    local cloned_bp = {}
    for _, part_id in ipairs(bp) do
        table.insert(cloned_bp, part_id)
    end

    local result = {}
    if current and type(current) == "table" then
        for k, v in pairs(current) do
            result[k] = v
        end
    end
    result.weapon_id = "glock_17"
    result.equipped = true
    result.global_values = {}
    result.factory_id = factory_id
    result.blueprint = cloned_bp
    result.cosmetics = nil
    return result
end

if BlackMarketManager then
    -- Return safe vanilla weapons when syncing outfit with peers/server
    local orig_equipped_primary = BlackMarketManager.equipped_primary
    function BlackMarketManager:equipped_primary(...)
        local current = orig_equipped_primary and orig_equipped_primary(self, ...)
        if Global.IS_SENDING_OUTFIT then
            return get_safe_primary(current)
        end
        return current
    end

    local orig_equipped_secondary = BlackMarketManager.equipped_secondary
    function BlackMarketManager:equipped_secondary(...)
        local current = orig_equipped_secondary and orig_equipped_secondary(self, ...)
        if Global.IS_SENDING_OUTFIT then
            return get_safe_secondary(current)
        end
        return current
    end

    local orig_equipped_mask = BlackMarketManager.equipped_mask
    function BlackMarketManager:equipped_mask(...)
        local current = orig_equipped_mask and orig_equipped_mask(self, ...)
        if Global.IS_SENDING_OUTFIT then
            if current and current.mask_id then
                local mask_tweak = tweak_data and tweak_data.blackmarket and tweak_data.blackmarket.masks and tweak_data.blackmarket.masks[current.mask_id]
                if mask_tweak and mask_tweak.dlc then
                    return safe_mask
                end
            end
            return current or safe_mask
        end
        return current
    end

    -- Safely serialize mask outfit string during network sync
    local orig_outfit_string_mask = BlackMarketManager._outfit_string_mask
    function BlackMarketManager:_outfit_string_mask(...)
        if orig_outfit_string_mask then
            local status, res = pcall(orig_outfit_string_mask, self, ...)
            if status and res then
                return res
            end
        end
        return "character_locked nothing-nothing no_color_no_material plastic"
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

    -- Verify melee weapon ownership as unlocked
    function BlackMarketManager:is_melee_weapon_unlocked(...)
        return true
    end

    -- Verify grenade / throwable ownership as unlocked
    function BlackMarketManager:is_grenade_unlocked(...)
        return true
    end

    -- Verify character, suit and player style unlocks
    function BlackMarketManager:is_character_unlocked(...)
        return true
    end

    function BlackMarketManager:is_suit_unlocked(...)
        return true
    end

    function BlackMarketManager:is_player_style_unlocked(...)
        return true
    end

    function BlackMarketManager:is_glove_unlocked(...)
        return true
    end

    function BlackMarketManager:is_armor_skin_unlocked(...)
        return true
    end

    function BlackMarketManager:is_weapon_skin_unlocked(...)
        return true
    end

    function BlackMarketManager:is_weapon_color_unlocked(...)
        return true
    end

    -- Force ownership check to pass for DLC items
    function BlackMarketManager:check_ownership(category, name)
        return true
    end
end

log("[DLC Unlocker] BlackMarket Manager and Weapon Factory hooks initialized.")
