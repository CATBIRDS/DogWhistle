-- Written by Norkkom aka "SanctionedPsyker"
local mod = get_mod("DogWhistle")
local Breeds = require("scripts/settings/breed/breeds")
local Archetypes = require("scripts/settings/archetype/archetypes")

--┌───────────────────────┐--
--│ ╔═╗╦  ╔═╗╔╗ ╔═╗╦  ╔═╗ │--
--│ ║ ╦║  ║ ║╠╩╗╠═╣║  ╚═╗ │--
--│ ╚═╝╩═╝╚═╝╚═╝╩ ╩╩═╝╚═╝ │--
--└───────────────────────┘--

local DOG = {
    VERSION = 106,                -- Current mod version
    ENABLED = true,               -- Flag indicating whether or not the mod is enabled
    OWNER   = nil,                -- Player archetype
    SHARED  = false,              -- Flag indicating whether or not non-Arbites classes are allowed to use the mod functionality
    MANUAL  = 0,                  -- Flag indicating whether or not the player has pressed the manual (unmodded) tag keybind. If pressed, this is its timestamp.
    WHISTLE = false,              -- Flag indicating whether or not the player is currently holding the whistle keybind
    IGNORE  = false,              -- Flag indicating whether or not the mod should ignore enemies which are already targeted by another player
    AUTO = {
        ENABLED    = false,       -- Flag indicating whether or not auto-tagging is enabled
        UNTILDEATH = false,       -- Flag indicating whether or not auto-tagging should wait for the current tag to expire before retagging (true = wait for expiration)
    },
    SERVER = nil,                 -- Current target according to the server which would be selected if the player were to tag
    TAGS = {},                    -- List of other player's tags
    LAST = {
        TAG  = nil,               -- Tag ID of the last successful tag made by the player
        TYPE = "",                -- Type of tag (tag.marker_type)
        TIME = 0,                 -- Timestamp of the last successful tag made by the player
        UNIT = nil                -- Last unit that was tagged by the player
    },
    INPUT = {
        SNAPSHOT = 0,             -- Timestamp of the last time the player registered a smart_tag action to the InputService
        COOLDOWN = {
            SERVER = 0.05,        -- Cooldown for the InputService to accept a new smart_tag action
            VETERAN = 0.2,        -- Cooldown for InputService when using Focus Target to prevent duplicate tags
            ADAMANT = 0.35,       -- Minimum cooldown must be at least this long to ensure input is not considered a double-tap
            DOG    = 0,           -- Cooldown for auto-tagging to allow a new tag attempt
        },
    },
    TARGETS = {},                 -- Enemy breeds which are allowed to be targeted
    LOOKUP = {},                  -- Lookup table to more efficiently handle toggle settings for each breed
    FOCUS = {
        STACKS    = 0,            -- Number of current Focus Target stacks held by the player
        APPLIED   = 0,            -- Number of Focus Target stacks currently applied to the last tagged unit
        THRESHOLD = 0,            -- Minimum number of Focus Target stacks required to tag an enemy
        RETARGET  = false         -- Flag indicating whether or not the player is allowed to retarget an enemy that already has Focus Target stacks applied
    },
    MODE = {
        PRIORITY = "",            -- Prioritization selection between Arbitrator tag types
        WHISTLE = "",             -- Desired tag to apply when using the whistle keybind (Arbitrator only)
        AUTO    = "",             -- Desired tag to apply through Auto-Target (Arbitrator only)
    }
}

--┌───────────┐--
--│ ╔╦╗╔═╗╔╦╗ │--
--│ ║║║║ ║ ║║ │--
--│ ╩ ╩╚═╝═╩╝ │--
--└───────────┘--

mod.on_enabled = function()
    DOG.ENABLED = true
end

mod.on_disabled = function()
    DOG.ENABLED = false
end

mod.toggle_mod = function()
    if not Managers.ui:using_input() then
		if DOG.ENABLED then
            DOG.ENABLED = false
        else
            DOG.ENABLED = true
        end
        mod:set("mod_enable", DOG.ENABLED, false)
		if DOG.VERBOSE then
			mod:echo("%s.", DOG.ENABLED and "Enabled" or "Disabled")
		end
	end
end

mod.on_all_mods_loaded = function()
    mod.populate_breeds()
    DOG.OWNER = mod.get_archetype()
    -- Mod Settings
    DOG.ENABLED = mod:get("mod_enable") or true
    -- Non-Arbites Settings
    DOG.SHARED = mod:get("other_archetype") or "DISABLED"
    DOG.FOCUS.RETARGET = mod:get("focus_target_retarget") or false
    DOG.FOCUS.THRESHOLD = mod:get("focus_target_stacks") or 0
    -- Dog Settings
    DOG.AUTO.ENABLED = mod:get("auto_target") or false
    DOG.IGNORE = mod:get("ignore_marked") or false
    DOG.INPUT.COOLDOWN.DOG = mod:get("dog_cooldown") or 0
    DOG.AUTO.UNTILDEATH = mod:get("no_retarget") or false
    DOG.VERBOSE = mod:get("mod_enable_verbose") or false
    DOG.MODE.WHISTLE = mod:get("whistle_type") or "unit_threat_adamant"
    DOG.MODE.AUTO = mod:get("auto_target_type") or "unit_threat_adamant"
    DOG.MODE.PRIORITY = mod:get("type_priority") or "unit_threat_adamant"
end

mod.on_game_state_changed = function(status, state_name)
    DOG.OWNER = mod.get_archetype()
end

mod.on_setting_changed = function(setting_id)
    -- Target settings
    -- Archetype
    if setting_id == "filter_archetype" then
        local archetype = mod:get(setting_id) or "adamant"
        local filter = mod:get("filter_target") or "MANUAL"
        for breed_name, data in pairs(DOG.TARGETS[archetype][filter]) do
            mod:set(breed_name, data, false)
        end
        mod:set("targets", DOG.TARGETS, false)
    -- Filter
    elseif setting_id == "filter_target" then
        local filter = mod:get(setting_id) or "MANUAL"
        local archetype = mod:get("filter_archetype") or "adamant"
        for breed_name, data in pairs(DOG.TARGETS[archetype][filter]) do
            mod:set(breed_name, data, false)
        end
        mod:set("targets", DOG.TARGETS, false)
    -- Breed
    elseif DOG.LOOKUP[setting_id] then
        local filter = mod:get("filter_target") or "MANUAL"
        local archetype = mod:get("filter_archetype") or "adamant"
        DOG.TARGETS[archetype][filter][setting_id] = mod:get(setting_id) or false
        mod:set("targets", DOG.TARGETS, false)
    end
    -- Toggle all
    if setting_id == "toggle_all" then
        mod.toggle_all()
    end
    -- Toggle by group
    if setting_id == "toggle_elites" or setting_id == "toggle_specials" or setting_id == "toggle_monsters" then
        mod.toggle_group(setting_id)
    end
    -- Non-Arbites settings
    if setting_id == "other_archetype" then
        DOG.SHARED = mod:get(setting_id)
    elseif setting_id == "focus_target_stacks" then
        DOG.FOCUS.THRESHOLD = mod:get(setting_id)
    elseif setting_id == "focus_target_retarget" then
        DOG.FOCUS.RETARGET = mod:get(setting_id)
    end
    -- Tagging settings
    if setting_id == "mod_enable" then
        DOG.ENABLED = mod:get(setting_id)
    elseif setting_id == "ignore_marked" then
        DOG.IGNORE = mod:get(setting_id)
    elseif setting_id == "auto_target" then
        DOG.AUTO.ENABLED = mod:get(setting_id)
    elseif setting_id == "dog_cooldown" then
        DOG.INPUT.COOLDOWN.DOG = mod:get(setting_id)
    elseif setting_id == "no_retarget" then
        DOG.AUTO.UNTILDEATH = mod:get(setting_id)
    elseif setting_id == "mod_enable_verbose" then
        DOG.VERBOSE = mod:get(setting_id)
    elseif setting_id == "whistle_type" then
        DOG.MODE.WHISTLE = mod:get(setting_id)
    elseif setting_id == "auto_target_type" then
        DOG.MODE.AUTO = mod:get(setting_id)
    elseif setting_id == "type_priority" then
        DOG.MODE.PRIORITY = mod:get(setting_id)
    end
end

mod.update = function()
    if DOG.ENABLED then
        -- Refresh current Focus Target stacks each frame when applicable
        if DOG.OWNER and DOG.OWNER == "veteran" then
            if mod.focus_target_equipped() then
                DOG.FOCUS.STACKS = mod.held_stacks()
            end
        end
    end
end

--┌────────────────────────┐--
--│ ╔═╗╔═╗╔╦╗╔╦╗╦╔╗╔╔═╗╔═╗ │--
--│ ╚═╗║╣  ║  ║ ║║║║║ ╦╚═╗ │--
--│ ╚═╝╚═╝ ╩  ╩ ╩╝╚╝╚═╝╚═╝ │--
--└────────────────────────┘--

-- Builds DOG.TARGETS (for identifying valid enemies) and DOG.LOOKUP (for settings lookup)
mod.populate_breeds = function()
    local cache_version = mod:get("version") or 0
    -- Versions below 1.0.4 needs to have settings converted
    local update
    if cache_version < 104 then
        local cache_targets = mod:get("targets")
        if cache_targets then
            -- Set existing target data to adamant class data
            update = cache_targets
            mod:set("targets", nil, false)
            mod:set("version", 104, false) -- Hardcoded version for this patch step in case later versions need incremental updates
        end
    end
    -- Update version if not handled by previous logic
    mod:set("version", DOG.VERSION, false)
    -- Set defaults on first start or after update
    if update or mod:get("targets") == nil then
        -- Build target structure
        for class, _ in pairs(Archetypes) do
            local id = string.match(class, "([^_]+)") -- zealot_archetype -> zealot
            if update and id == "adamant" then
                DOG.TARGETS[id] = update
            else
                DOG.TARGETS[id] = {
                    MANUAL = {},
                    AUTO   = {},
                }
                for breed_name, _ in pairs(Breeds) do
                    DOG.TARGETS[id].MANUAL[breed_name] = false
                    DOG.TARGETS[id].AUTO[breed_name] = false
                    if not DOG.LOOKUP[breed_name] then
                        DOG.LOOKUP[breed_name] = true
                    end
                end
            end
        end
        mod:set("targets", DOG.TARGETS, false)
    end
    DOG.TARGETS = mod:get("targets")
    -- Double-checking settings
    for class, _ in pairs(Archetypes) do
        local id = string.match(class, "([^_]+)") -- zealot_archetype -> zealot
        DOG.TARGETS[id] = DOG.TARGETS[id] or { MANUAL = {}, AUTO = {} }
        DOG.TARGETS[id].MANUAL = DOG.TARGETS[id].MANUAL or {}
        DOG.TARGETS[id].AUTO = DOG.TARGETS[id].AUTO or {}
        for breed_name, _ in pairs(Breeds) do
            if DOG.TARGETS[id].MANUAL[breed_name] == nil then
                DOG.TARGETS[id].MANUAL[breed_name] = false
            end
            if DOG.TARGETS[id].AUTO[breed_name] == nil then
                DOG.TARGETS[id].AUTO[breed_name] = false
            end
            if not DOG.LOOKUP[breed_name] then
                DOG.LOOKUP[breed_name] = true
            end
        end
    end
    -- Update settings/UI
    local filter = mod:get("filter_target") or "MANUAL"
    local archetype = mod:get("filter_archetype") or "adamant"
    for breed_name, data in pairs(DOG.TARGETS[archetype][filter]) do
        mod:set(breed_name, data, false)
    end
    mod:set("targets", DOG.TARGETS, false)
end

-- Toggles all enemies based on the current settings (toggles on if majority off, toggles off if majority on)
mod.toggle_all = function()
    local enabled, total = 0, 0
    -- Tally how many are enabled to determine whether this toggle should be enabling or disabling
    for breed_name, _ in pairs(Breeds) do
        if Breeds[breed_name].tags.elite or Breeds[breed_name].tags.special or Breeds[breed_name].tags.ritualist or Breeds[breed_name].tags.monster or Breeds[breed_name].tags.captain or Breeds[breed_name].tags.cultist_captain then
            if mod:get(breed_name) then
                enabled = enabled + 1
            end
            total = total + 1
        end
    end
    -- Set desired state to true if less than or equal to 50% are enabled, false otherwise
    local toggle_state = (enabled / total) * 100 <= 50 and true or false
    -- Toggle
    for breed_name, _ in pairs(Breeds) do
        if Breeds[breed_name].tags.elite or Breeds[breed_name].tags.special or Breeds[breed_name].tags.ritualist or Breeds[breed_name].tags.monster or Breeds[breed_name].tags.captain or Breeds[breed_name].tags.cultist_captain then
            mod:set(breed_name, toggle_state, true)
        end
    end
    mod:set("toggle_all", false, false)
end

-- Toggles a set of enemies based on the group setting (toggles on if majority off, toggles off if majority on)
mod.toggle_group = function(group_setting)
    local map = {
        toggle_elites = "elite",
        toggle_specials = "special",
        toggle_monsters = "monster",
    }
    local map_alt = {toggle_specials = "ritualist", toggle_monsters = "captain"} -- Alternate tags for enemies which do not exactly match a group but should be included in them
    local map_admonition = { toggle_monsters = "cultist_captain" }
    -- Tally how many are enabled to determine whether this toggle should be enabling or disabling the group
    local enabled, total = 0, 0
    for breed_name, _ in pairs(Breeds) do
        if Breeds[breed_name].tags[map[group_setting]] or Breeds[breed_name].tags[map_alt[group_setting]] or Breeds[breed_name].tags[map_admonition[group_setting]] then
            if mod:get(breed_name) then
                enabled = enabled + 1
            end
            total = total + 1
        end
    end
    -- Set desired state to true if less than or equal to 50% are enabled, false otherwise
    local toggle_state = (enabled / total) * 100 <= 50 and true or false
    -- Toggle
    for breed_name, _ in pairs(Breeds) do
        if Breeds[breed_name].tags[map[group_setting]] or Breeds[breed_name].tags[map_alt[group_setting]] or Breeds[breed_name].tags[map_admonition[group_setting]] then
            mod:set(breed_name, toggle_state, true)
        end
    end
    mod:set(group_setting, false, false)
end

--┌───────────────────────┐--
--│ ╦ ╦╔═╗╦  ╔═╗╔═╗╦═╗╔═╗ │--
--│ ╠═╣║╣ ║  ╠═╝║╣ ╠╦╝╚═╗ │--
--│ ╩ ╩╚═╝╩═╝╩  ╚═╝╩╚═╚═╝ │--
--└───────────────────────┘--

-- Returns current player archetype, or nil if unavailable
mod.get_archetype = function()
    local archetype
    local player = Managers.player:local_player_safe(1)
    if player then
        local profile = player:profile()
        if profile then
            archetype = profile.archetype and profile.archetype.name
        end
    end
    return archetype
end

-- Returns true if the player is playing as the Veteran archetype with the Focus Target keystone equipped
mod.focus_target_equipped = function()
    if DOG.OWNER == "veteran" then
        local player = Managers.player:local_player_safe(1)
        local player_unit = player and player.player_unit
        local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
        if buff_extension and buff_extension:has_buff_using_buff_template("veteran_improved_tag") then
            return true
        end
    end
    return false
end

-- Returns true if the player has disabled the dog while playing as Arbites
mod.dog_hater = function()
    if DOG.OWNER  == "adamant" then
        local player = Managers.player:local_player_safe(1)
        local player_unit = player and player.player_unit
        local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
        if buff_extension and buff_extension:has_buff_using_buff_template("adamant_disable_companion_buff") then
            return true
        end
    end
    return false
end

-- Returns the number of Focus Target stacks held by the player
mod.held_stacks = function()
    local focus_target = "veteran_improved_tag"
    local stacks = 0
    local player = Managers.player:local_player_safe(1)
    local player_unit = player and player.player_unit
    local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
    local buffs = buff_extension and buff_extension._buffs
    if buffs then
        for index, _ in ipairs (buffs) do
            local name = buffs[index] and buffs[index]._template and buffs[index]._template.name
            if name and string.find(name, focus_target) ~= nil then
                template_data = buffs[index]._template_data
                if template_data then
                    stacks = template_data.talent_resource_component and template_data.talent_resource_component.current_resource or 0
                    break
                end
            end
        end
    end
    return stacks
end

-- Returns the number of Focus Target stacks applied to an enemy
mod.applied_stacks = function(target_unit)
    local stacks = 0
    local focus_target = "veteran_improved_tag_debuff"
    if target_unit then
        local buff_extension = ScriptUnit.has_extension(target_unit, "buff_system")
        local buffs = buff_extension and buff_extension._buffs
        if buffs then
            for index, _ in ipairs (buffs) do
                local name = buffs[index] and buffs[index]._template and buffs[index]._template.name
                if name and string.find(name, focus_target) ~= nil then
                    stacks = buffs[index] and buffs[index]._template_context and buffs[index]._template_context.stack_count
                    break
                end
            end
        end
    end
    return stacks
end

-- Returns true if the current archetype settings allow for a tag to be applied (assumes target is valid). Tag permission may be denied later based on other settings.
mod.allowed_for_archetype = function()
    if not DOG.OWNER then
        return false
    end
    -- Focus Target Veteran logic
    if DOG.OWNER == "veteran" and mod.focus_target_equipped() then
        -- Refresh applied stacks count (stupid, but necessary)
        DOG.FOCUS.APPLIED = mod.applied_stacks(DOG.LAST.UNIT)
        local threshold = DOG.FOCUS.THRESHOLD
        local stacks = DOG.FOCUS.STACKS
        local applied = DOG.FOCUS.APPLIED
        local retarget = DOG.FOCUS.RETARGET
        -- If threshold is set, the player must have at least that many stacks available
        if threshold > 0 then
            if stacks >= threshold then
                -- If retargeting is allowed, player must have more available stacks than the target has applied
                if retarget and DOG.SERVER == DOG.LAST.UNIT then
                    return applied < stacks
                -- If retargeting is not allowed, the target being aimed at must not be the last unit tagged
                else
                    return DOG.SERVER ~= DOG.LAST.UNIT
                end
            end
        else
            if retarget and DOG.SERVER == DOG.LAST.UNIT then
                return applied < stacks
            else
                return DOG.SERVER ~= DOG.LAST.UNIT
            end
        end
        return false
    end
    -- Arbites logic
    if DOG.OWNER == "adamant" then
        -- Allow new tag if looking at a different target
        if DOG.SERVER ~= DOG.LAST.UNIT then
            return true
        -- Allow if attempting to apply a different type of tag (type validity is checked in mod.allowed_target())
        elseif mod.get_tag_type() ~= DOG.LAST.TYPE then
            return true
        else
            return false
        end
    end
    -- Everyone else: allow new tags only if looking at a different target
    if DOG.SERVER ~= DOG.LAST.UNIT then
        return true
    else
        return false
    end
end

-- Returns the tag type to track based on current settings, or nil if either no archetype is set or no tag type is valid
mod.get_tag_type = function()
    if DOG.OWNER then
        -- Arbites
        if DOG.OWNER == "adamant" then
            -- Lone Wolf
            if mod.dog_hater() then
                return "unit_threat"
            end
            -- If Whistle is active then use that tag type
            if DOG.WHISTLE then
                return DOG.MODE.WHISTLE
            end
            -- If Auto-Target is enabled while not using the Whistle keybind, then use Auto-Target tag type
            if DOG.AUTO.ENABLED then
                return DOG.MODE.AUTO
            end
            return "unit_threat_adamant"
        -- Non-Arbites
        else
            -- Focus Target Veteran
            if DOG.OWNER == "veteran" and mod.focus_target_equipped() then
                return "unit_threat_veteran"
            -- Anyone else
            else
                return "unit_threat"
            end
        end
    end
end


--┌────────────────────────────┐--
--│ ╔╦╗╔═╗╔═╗  ╔═╗╔╦╗╦ ╦╔═╗╔═╗ │--
--│  ║║║ ║║ ╦  ╚═╗ ║ ║ ║╠╣ ╠╣  │--
--│ ═╩╝╚═╝╚═╝  ╚═╝ ╩ ╚═╝╚  ╚   │--
--└────────────────────────────┘--

-- Returns true if filter settings allow for the current target, and there is an appropriate keybind/auto-tag state
mod.allowed_target = function()
    if not DOG.AUTO.ENABLED and not DOG.WHISTLE then return false end
    local filter = DOG.WHISTLE and "MANUAL" or "AUTO"
    local server_target = DOG.SERVER
    local target_data = server_target and ScriptUnit.has_extension(server_target, "unit_data_system")
    local target_breed = target_data and target_data:breed()
    local target_name = target_breed and target_breed.name
    -- Ignore check
    if mod.ignore_tag(server_target, target_breed) then
        return false
    end
    -- Treat mutator breeds as their base breed
    if target_name and string.find(target_name, "_mutator") then
        target_name = string.gsub(target_name, "_mutator", "") 
        -- Manual fix for ritualists as the base breed is cultist but the mutator is chaos
        if target_name == "chaos_ritualist" then
            target_name = "cultist_ritualist"
        end
    end
    -- Arbites prioritization
    if DOG.OWNER == "adamant" then
        local tag_type = mod.get_tag_type()
        local priority = DOG.MODE.PRIORITY
        -- Only filter by priority if one is set
        if priority ~= "none" then
            if DOG.LAST.TAG then
                local last_type = DOG.LAST.TYPE
                -- Deny if the last tag type is not the same as the current tag type, and the current tag type is not the priority
                if last_type ~= tag_type and tag_type ~= priority then
                    return false
                end
            end
        end
    end
    return DOG.TARGETS and DOG.TARGETS[DOG.OWNER] and DOG.TARGETS[DOG.OWNER][filter] and DOG.TARGETS[DOG.OWNER][filter][target_name]
end

-- Set flag to request dog targeting when keybind is held. Resets to false when released, and does not override any updates from other functions.
mod.dog_whistle = function(true_while_held)
    DOG.WHISTLE = true_while_held
end

-- Returns true if a valid tag has been made after the whistle input was made
mod.tagged_after_whistle = function()
    if DOG.LAST.TAG then
        -- Allow manual retagging if looking at a different unit/not looking at a unit
        if DOG.SERVER ~= DOG.LAST.UNIT or DOG.LAST.TYPE ~= DOG.MODE.WHISTLE then
            return false
        end
        -- Consider whistle completed if the last tag took place after the whistle input was made
        if DOG.LAST.TIME > DOG.INPUT.SNAPSHOT then
            return true
        end
    end
    return false
end

-- Returns true if NOT allowed to tag right now
mod.on_cooldown = function(type)
    -- Server cooldown
    if type == "server" then
        local cooldown = DOG.INPUT.COOLDOWN.SERVER
        -- Use longer cooldown for Focus Target Veteran to prevent.. weirdness
        if DOG.OWNER == "veteran" and mod.focus_target_equipped() then
            cooldown = DOG.INPUT.COOLDOWN.VETERAN
        end
        -- Use longer for Arbites when attempting a standard tag to prevent triggering a dog tag via double-tap
        if DOG.OWNER == "adamant" and mod.get_tag_type() == "unit_threat" then
            cooldown = DOG.INPUT.COOLDOWN.ADAMANT
        end
        if DOG.INPUT.SNAPSHOT and (DOG.INPUT.SNAPSHOT + cooldown) > Managers.time:time("main") then
            return true
        end
    -- Auto-Target cooldown
    elseif type == "auto" then
        if DOG.LAST.TIME and (DOG.LAST.TIME + DOG.INPUT.COOLDOWN.DOG) > Managers.time:time("main") then
            return true
        end
    end
    return false
end

-- returns true if the current tag or tag target should be ignored
mod.ignore_tag = function(unit, breed)
    local ignore = false
    -- Ignore enemies which are already targeted by another player
    if DOG.IGNORE then
        local marker
        -- Adamant only cares about dog tags
        if DOG.OWNER == "adamant" and not mod.dog_hater() then
            marker = "unit_threat_adamant"
        -- Veteran only cares about Focus Target tags
        elseif DOG.OWNER == "veteran" and mod.focus_target_equipped() then
            marker = "unit_threat_veteran"
        end
        if marker then
            if not DOG.TAGS[marker] then
                DOG.TAGS[marker] = {}
            end
            for _, ally_tag in pairs(DOG.TAGS[marker]) do
                local tag_unit = ally_tag and ally_tag.UNIT
                if tag_unit and tag_unit == unit then
                    -- Arbites with dog active: skip non-boss enemies
                    if marker == "unit_threat_adamant" then
                        local not_big = breed and breed.tags and not (breed.tags.monster or breed.tags.captain or breed.tags.cultist_captain or breed.tags.ogryn)
                        local not_mutant = breed and breed.name and type(breed.name) == "string" and string.find(breed.name, "mutant") == nil
                        if not_big and not_mutant then
                            ignore = true
                        end
                    end
                    -- Focus Target: skip if target has less stacks than the player
                    if marker == "unit_threat_veteran" then
                        local stacks = mod.applied_stacks(tag_unit)
                        if stacks >= DOG.FOCUS.STACKS then
                            ignore = true
                        end
                    end
                    break
                end
            end
        end
    end
    return ignore
end

-- Returns true if the player is allowed to tag regardless of the UNTILDEATH setting
mod.allowed_to_bypass_until_death = function()
    -- Focus Target Veteran can bypass the until death restriction if they have enough stacks and focus retargeting is enabled
    if mod.focus_target_equipped() and DOG.FOCUS.RETARGET then
        if DOG.SERVER == DOG.LAST.UNIT and DOG.FOCUS.STACKS > DOG.FOCUS.APPLIED then
        return true
        end
    end
    -- Arbites can bypass restriction if they are attempting to apply a different tag type than the last one
    if DOG.OWNER == "adamant" then
        local already_prioritized = DOG.LAST.TYPE == DOG.MODE.PRIORITY or DOG.MODE.PRIORITY == "none"
        local priority = DOG.MODE.PRIORITY
        -- Whistle is trying to override
        if DOG.WHISTLE and DOG.MODE.WHISTLE == priority and not already_prioritized then
            return true
        elseif DOG.AUTO.ENABLED and DOG.MODE.AUTO == priority and not already_prioritized then
            return true
        end
    end
    -- Everyone else is denied
    return false
end

--┌─────────────────┐--
--│ ╦ ╦╔═╗╔═╗╦╔═╔═╗ │--
--│ ╠═╣║ ║║ ║╠╩╗╚═╗ │--
--│ ╩ ╩╚═╝╚═╝╩ ╩╚═╝ │--
--└─────────────────┘--

-- Collect current tags available to the player as determined by the server, and update local tag data accordingly
mod:hook_safe(CLASS.SmartTagSystem, "update", function(self, context, dt, t, ...)
    if DOG.ENABLED then
        local player = Managers.player:local_player_safe(1)
        local desired_tag = mod.get_tag_type()
        -- Fetch all current tags
        for tag_id, tag in pairs(self._all_tags) do
            local template = tag and tag._template
            if template and template.marker_type and string.find(template.marker_type, "unit_threat") then
                local tagger_player = tag:tagger_player()
                local marker = template.marker_type
                -- Add new tags which belong to other players to DOG.TAGS.ALLY
                if tagger_player and tagger_player ~= player then
                    if not DOG.TAGS[marker] then
                        DOG.TAGS[marker] = {}
                    end
                    if not DOG.TAGS[marker][tag_id] then
                        DOG.TAGS[marker][tag_id] = {
                            TAG = tag_id,
                            UNIT = tag:target_unit(),
                        }
                    end
                end
                -- Add new tags which belong to the player to DOG.TAGS
                if tagger_player and tagger_player == player then
                    -- Check if we are currently whistling, or auto-targeting
                    local mode = DOG.WHISTLE and "MANUAL" or DOG.AUTO.ENABLED and "AUTO" or "MANUAL"
                    local unit = tag:target_unit()
                    local data = ScriptUnit.has_extension(unit, "unit_data_system")
                    local breed = data and data:breed()
                    local enemy = breed and breed.name
                    local valid_target = DOG.MANUAL > 0 or (marker == desired_tag) and enemy and DOG.TARGETS[DOG.OWNER] and DOG.TARGETS[DOG.OWNER][mode] and DOG.TARGETS[DOG.OWNER][mode][enemy]
                    -- Ignore check
                    if mod.ignore_tag(unit, breed) then
                        valid_target = false
                    end
                    if valid_target and DOG.LAST.TAG ~= tag_id then
                        if DOG.MANUAL ~= 0 then
                            DOG.MANUAL = 0 -- Reset manual tag flag after a successful tag
                        end
                        DOG.LAST.TAG = tag_id
                        DOG.LAST.TYPE = marker
                        DOG.LAST.UNIT = unit
                        -- Track the number of Focus Target stacks applied to the target unit if the Focus Target keystone is equipped
                        if mod.focus_target_equipped() then
                            DOG.FOCUS.APPLIED = mod.applied_stacks(DOG.LAST.UNIT)
                            DOG.FOCUS.STACKS = 0
                        end
                        -- Update cooldown to operate off of most recent new tag timestamp
                        DOG.LAST.TIME = Managers.time:time("main") -- not using t to ensure all comparisons operate off "main" time rather than "game" time
                    end
                end
            end
        end
        -- Remove expired tags from other players
        for _, list in pairs(DOG.TAGS) do
            for tag_id, _ in pairs(list) do
                if not self._all_tags[tag_id] then
                    list[tag_id] = nil
                end
            end
        end
        -- Reset DOG.LAST if own tag expires
        if not self._all_tags[DOG.LAST.TAG] then
            DOG.LAST.TAG = nil
            DOG.LAST.TYPE = ""
            DOG.LAST.TIME = 0
            DOG.LAST.UNIT = nil
            DOG.FOCUS.APPLIED = 0
        end
    end
end)

-- Collect the server's intended target should tagging be initiated
mod:hook_safe(CLASS.PlayerUnitSmartTargetingExtension, "targeting_data", function(self)
    if DOG.ENABLED then
        local smart_unit = self._targeting_data and self._targeting_data.unit
        DOG.SERVER = smart_unit or nil
    end
end)

-- Input Interception
mod:hook(CLASS.InputService, "_get", function(func, self, action_name)
    if DOG.ENABLED and action_name == "smart_tag" then
        -- Actual input value collection
        local action_rule = self._actions[action_name]
        local out
        if action_rule.filter then
            out = action_rule.eval_func(action_rule.eval_obj, action_rule.eval_param)
        else
            out = action_rule.default_func()
            local action_type = action_rule.type
            local combiner = InputService.ACTION_TYPES[action_type].combine_func
            for _, cb in ipairs(action_rule.callbacks) do
                out = combiner(out, cb())
            end
        end
        -- Non-mod tagging (i.e. player pressed the vanilla tagging input)
        if out then
            DOG.MANUAL = Managers.time:time("main")
            DOG.INPUT.SNAPSHOT = Managers.time:time("main")
            return out
        end
        -- Reset MANUAL flag after 0.2 seconds (DOG.INPUT.COOLDOWN.VETERAN for convenience) - enough time to register a tag, but short enough to avoid false positives
        if DOG.MANUAL and (DOG.MANUAL + DOG.INPUT.COOLDOWN.VETERAN) < Managers.time:time("main") then
            DOG.MANUAL = 0
        end
        -- Mod-driven tagging
        -- Disable whistle after successful tag
        if DOG.WHISTLE then
            if mod.tagged_after_whistle() then
                DOG.WHISTLE = false
            end
        end
        if mod.allowed_target() and not mod.on_cooldown("server") and mod.allowed_for_archetype() then
            -- Manual whistle tagging
            if DOG.WHISTLE then
                DOG.INPUT.SNAPSHOT = Managers.time:time("main")
                return true
            end
            -- If this is an auto-tag, continue if allowed by cooldown, altering behavior depending on UNTILDEATH setting
            if DOG.AUTO.ENABLED and not mod.on_cooldown("auto") then
                -- If UNTILDEATH is enabled, do nothing while there is a current tagged target, otherwise tag - tags will be cleared automatically upon death or expiration 
                if DOG.AUTO.UNTILDEATH then
                    if DOG.LAST.TAG and not mod.allowed_to_bypass_until_death()then
                        return func(self, action_name)
                    end
                    DOG.INPUT.SNAPSHOT = Managers.time:time("main")
                    return true
                -- If UNTILDEATH is disabled, tag as often as the cooldown and target filtration allows
                end
                DOG.INPUT.SNAPSHOT = Managers.time:time("main")
                return true
            end
        end
    end
    return func(self, action_name)
end)