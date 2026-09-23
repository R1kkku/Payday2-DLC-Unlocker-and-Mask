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
        color_a = { id = "nothing" },
        color_b = { id = "nothing" },
        color_c = { id = "strip_paint" },
        pattern = { id = "no_color_no_material" },
        material = { id = "plastic" }
    }
}


-- Ensure WeaponFactoryManager never crashes on missing factory or nil blueprint
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
            if status and res and type(res) == "string" and res ~= "" then
                return res
            end
            local def_bp = (self.get_default_blueprint_by_factory_id and self:get_default_blueprint_by_factory_id(factory_id)) or safe_primary.blueprint
            status, res = pcall(orig_blueprint_to_string, self, factory_id, def_bp)
            if status and res and type(res) == "string" and res ~= "" then
                return res
            end
        end
        return "1"
    end

    local orig_unpack_blueprint_from_string = wfm.unpack_blueprint_from_string
    function wfm:unpack_blueprint_from_string(factory_id, blueprint_string, ...)
        if not factory_id or not (tweak_data and tweak_data.weapon and tweak_data.weapon.factory and tweak_data.weapon.factory[factory_id]) then
            factory_id = "wpn_fps_ass_amcar"
        end
        local factory = tweak_data and tweak_data.weapon and tweak_data.weapon.factory
        local entry = factory and factory[factory_id]
        if not entry or not entry.uses_parts then
            return (self.get_default_blueprint_by_factory_id and self:get_default_blueprint_by_factory_id(factory_id)) or {}
        end
        if not blueprint_string or type(blueprint_string) ~= "string" or blueprint_string == "" or blueprint_string == "nil" then
            return (self.get_default_blueprint_by_factory_id and self:get_default_blueprint_by_factory_id(factory_id)) or {}
        end
        if orig_unpack_blueprint_from_string then
            local status, res = pcall(orig_unpack_blueprint_from_string, self, factory_id, blueprint_string, ...)
            if status and res and type(res) == "table" and #res > 0 then
                return res
            end
        end
        return (self.get_default_blueprint_by_factory_id and self:get_default_blueprint_by_factory_id(factory_id)) or {}
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

if BlackMarketManager and not rawget(BlackMarketManager, "_dlc_bm_patched") then
    rawset(BlackMarketManager, "_dlc_bm_patched", true)

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
            return safe_mask
        end
        return current
    end

    local orig_equipped_melee_weapon = BlackMarketManager.equipped_melee_weapon
    function BlackMarketManager:equipped_melee_weapon(...)
        if Global.IS_SENDING_OUTFIT then
            return "weapon"
        end
        if orig_equipped_melee_weapon then
            return orig_equipped_melee_weapon(self, ...)
        end
        return "weapon"
    end

    local orig_equipped_grenade = BlackMarketManager.equipped_grenade
    function BlackMarketManager:equipped_grenade(...)
        if Global.IS_SENDING_OUTFIT then
            return "frag", 0
        end
        if orig_equipped_grenade then
            local grenade, amount = orig_equipped_grenade(self, ...)
            if grenade and grenade ~= "" then
                return grenade, amount or 0
            end
        end
        return "frag", 0
    end

    local orig_equipped_player_style = BlackMarketManager.equipped_player_style
    function BlackMarketManager:equipped_player_style(...)
        if Global.IS_SENDING_OUTFIT then
            return "suit"
        end
        if orig_equipped_player_style then
            return orig_equipped_player_style(self, ...)
        end
        return "suit"
    end

    local orig_equipped_suit_variation = BlackMarketManager.equipped_suit_variation
    function BlackMarketManager:equipped_suit_variation(...)
        if Global.IS_SENDING_OUTFIT then
            return "default"
        end
        if orig_equipped_suit_variation then
            return orig_equipped_suit_variation(self, ...)
        end
        return "default"
    end

    local orig_equipped_glove_id = BlackMarketManager.equipped_glove_id
    function BlackMarketManager:equipped_glove_id(...)
        if Global.IS_SENDING_OUTFIT then
            return "default"
        end
        if orig_equipped_glove_id then
            return orig_equipped_glove_id(self, ...)
        end
        return "default"
    end

    local orig_equipped_armor_skin = BlackMarketManager.equipped_armor_skin
    function BlackMarketManager:equipped_armor_skin(...)
        if Global.IS_SENDING_OUTFIT then
            return "none"
        end
        if orig_equipped_armor_skin then
            return orig_equipped_armor_skin(self, ...)
        end
        return "none"
    end

    local orig_equipped_character = BlackMarketManager.equipped_character
    function BlackMarketManager:equipped_character(...)
        if orig_equipped_character then
            local char = orig_equipped_character(self, ...)
            if char and char ~= "" then
                return char
            end
        end
        return "russian"
    end

    -- Safely serialize mask outfit string during network sync (exactly 4 space-separated tokens with leading space)
    local orig_outfit_string_mask = BlackMarketManager._outfit_string_mask
    function BlackMarketManager:_outfit_string_mask(...)
        if Global.IS_SENDING_OUTFIT then
            return " character_locked plastic no_color_no_material nothing-nothing-strip_paint"
        end
        if orig_outfit_string_mask then
            local status, res = pcall(orig_outfit_string_mask, self, ...)
            if status and res and type(res) == "string" and res ~= "" then
                return res
            end
        end
        return " character_locked plastic no_color_no_material nothing-nothing-strip_paint"
    end

    -- Ensure outfit_string always returns a valid, clean, masked string across all network transmissions
    local orig_outfit_string = BlackMarketManager.outfit_string
    function BlackMarketManager:outfit_string(...)
        local was_sending = Global.IS_SENDING_OUTFIT
        Global.IS_SENDING_OUTFIT = true
        local status, res
        if orig_outfit_string then
            status, res = pcall(orig_outfit_string, self, ...)
        end
        Global.IS_SENDING_OUTFIT = was_sending
        if status and res and type(res) == "string" and res ~= "" then
            return res
        end
        local current_grenade = (self.equipped_grenade and self:equipped_grenade()) or "frag"
        return "character_locked plastic no_color_no_material nothing-nothing-strip_paint level_1-level_1-level_1-none-suit-default-default russian wpn_fps_ass_amcar 1 wpn_fps_pis_g17 1 nil 0 nil 0 0 weapon " .. tostring(current_grenade) .. " 42_0 nil-1-0 nil-1-0"
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

    -- Force ownership check to pass for DLC items safely
    local orig_check_ownership = BlackMarketManager.check_ownership
    function BlackMarketManager:check_ownership(category, name)
        if orig_check_ownership then
            local ok, res = pcall(orig_check_ownership, self, category, name)
            if ok and res ~= nil then
                return res
            end
        end
        return true
    end

    -- Protect visibility_modifiers against Crime Spree modifierlessconcealment crash in menu
    local orig_visibility_modifiers = BlackMarketManager.visibility_modifiers
    function BlackMarketManager:visibility_modifiers(...)
        if orig_visibility_modifiers then
            local ok, res = pcall(orig_visibility_modifiers, self, ...)
            if ok and res ~= nil then
                return res
            end
        end
        return 0
    end

    -- Safeguard player_loadout_data so inventory GUI never crashes on unhandled nil or missing weapon skins
    local orig_player_loadout_data = BlackMarketManager.player_loadout_data
    if orig_player_loadout_data then
        function BlackMarketManager:player_loadout_data(...)
            local ok, a, b, c, d, e, f, g, h, i, j = pcall(orig_player_loadout_data, self, ...)
            if ok and a then
                return a, b, c, d, e, f, g, h, i, j
            end
            local empty_string = (managers.localization and managers.localization:to_upper_text("menu_loadout_empty")) or ""
            local fallback = {
                primary = { item_texture = false, info_text = empty_string, info_icons = {} },
                secondary = { item_texture = false, info_text = empty_string, info_icons = {} },
                melee_weapon = { item_texture = false, info_text = empty_string },
                grenade = { item_texture = false, info_text = empty_string },
                armor = { item_texture = false, info_text = empty_string },
                deployable = { item_texture = false, info_text = empty_string },
                mask = { item_texture = false, info_text = empty_string },
                character = { item_texture = false, info_text = empty_string },
                outfit = { armor = { item_texture = false, info_text = empty_string } }
            }
            return fallback, fallback.primary, fallback.secondary, fallback.melee_weapon, fallback.grenade, fallback.armor, fallback.deployable, fallback.mask, fallback.character, fallback.outfit
        end
    end

    -- Safeguard unpack_outfit_from_string against any invalid peer/player outfit string
    local orig_unpack_outfit_from_string = BlackMarketManager.unpack_outfit_from_string
    if orig_unpack_outfit_from_string then
        function BlackMarketManager:unpack_outfit_from_string(outfit_string, ...)
            local status, res = pcall(orig_unpack_outfit_from_string, self, outfit_string, ...)
            if status and res and type(res) == "table" and res.primary and res.secondary then
                return res
            end
            local fallback = {
                character = (self._defaults and self._defaults.character) or "russian",
                mask = {
                    mask_id = (self._defaults and self._defaults.mask) or "character_locked",
                    blueprint = {
                        color_a = { id = "nothing" },
                        color_b = { id = "nothing" },
                        color_c = { id = "strip_paint" },
                        pattern = { id = "no_color_no_material" },
                        material = { id = "plastic" }
                    }
                },
                armor = tostring((self._defaults and self._defaults.armor) or "level_1"),
                armor_current = tostring((self._defaults and self._defaults.armor) or "level_1"),
                armor_current_state = tostring((self._defaults and self._defaults.armor) or "level_1"),
                armor_skin = "none",
                player_style = "none",
                suit_variation = "default",
                glove_id = (self._defaults and self._defaults.glove_id) or "default",
                primary = {
                    factory_id = "wpn_fps_ass_amcar",
                    blueprint = (managers.weapon_factory and managers.weapon_factory:get_default_blueprint_by_factory_id("wpn_fps_ass_amcar")) or safe_primary.blueprint,
                    cosmetics = nil
                },
                secondary = {
                    factory_id = "wpn_fps_pis_g17",
                    blueprint = (managers.weapon_factory and managers.weapon_factory:get_default_blueprint_by_factory_id("wpn_fps_pis_g17")) or safe_secondary.blueprint,
                    cosmetics = nil
                },
                melee_weapon = (self._defaults and self._defaults.melee_weapon) or "weapon",
                grenade = (self._defaults and self._defaults.grenade) or "frag",
                deployable = nil,
                deployable_amount = 0,
                secondary_deployable = nil,
                secondary_deployable_amount = 0,
                concealment_modifier = 0,
                skills = {}
            }
            return fallback
        end
    end
end

log("[DLC Unlocker] BlackMarket Manager and Weapon Factory hooks initialized.")
