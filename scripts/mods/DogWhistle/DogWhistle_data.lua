local mod = get_mod("DogWhistle")
local Breeds = require("scripts/settings/breed/breeds")

-- Auto-populated settings
local elites = {
    {
        setting_id    = "toggle_elites",
        type          = "checkbox",
        default_value = false,
    },
}
local specials = {
    {
        setting_id    = "toggle_specials",
        type          = "checkbox",
        default_value = false,
    },
}
local monsters = {
    {
        setting_id    = "toggle_monsters",
        type          = "checkbox",
        default_value = false,
    },
}

local function add(tbl, breed_name, default_value)
	tbl[#tbl + 1] = {
		setting_id = breed_name,
		type = "checkbox",
		default_value = default_value,
	}
end

for breed_name, breed in pairs(Breeds) do
    if not string.find(breed_name, "_mutator") then -- Do not consider mutator breeds to be different from their base breed
        if breed.tags.minion then
            local default_value = false
            if breed.tags.elite then
                add(elites, breed_name, default_value)
            elseif breed.tags.special or breed.tags.ritualist then
                add(specials, breed_name, default_value)
            elseif breed.tags.monster or breed.tags.captain then
                add(monsters, breed_name, default_value)
            end
        end
    end
end

local function sort_with_toggle_first(tbl)
    table.sort(tbl, function(a, b)
        local a_toggle = string.find(a.setting_id, "toggle") == 1
        local b_toggle = string.find(b.setting_id, "toggle") == 1
        if a_toggle ~= b_toggle then
            return a_toggle
        end
        return a.setting_id < b.setting_id
    end)
end

sort_with_toggle_first(elites)
sort_with_toggle_first(specials)
sort_with_toggle_first(monsters)

-- Manual settings
local widgets = {
	{
		setting_id = "mod_settings",
		type = "group",
		sub_widgets = {
            {
                setting_id    = "mod_enable",
                type          = "checkbox",
                default_value = true,
            },
            {
                setting_id      = "mod_enable_keybind",
                type            = "keybind",
                default_value   = {},
                keybind_trigger = "pressed",
                keybind_type    = "function_call",
                function_name   = "toggle_mod",
            },
            {
                setting_id    = "mod_enable_verbose",
                type          = "checkbox",
                default_value = true,
            },
            {
                setting_id      = "ignore_marked",
                type            = "checkbox",
                default_value   = false,
                tooltip         = "ignore_marked_tooltip",
            },
            {
                setting_id      = "type_priority",
                type            = "dropdown",
                default_value   = "unit_threat_adamant",
                tooltip         = "type_priority_tooltip",
                options         = {
                    { value = "unit_threat_adamant", text = "dog_tag" },
                    { value = "unit_threat", text = "standard_tag" },
                    { value = "none", text = "none" }
                }
            },
		},
	},
    {
        setting_id = "whistle_settings",
        type = "group",
        sub_widgets = {
            {
                setting_id      = "dog_keybind",
                type            = "keybind",
                default_value   = {},
                keybind_trigger = "held",
                keybind_type    = "function_call",
                function_name   = "dog_whistle",
            },
            {
                setting_id      = "whistle_type",
                type            = "dropdown",
                default_value   = "unit_threat_adamant",
                tooltip         = "type_tooltip",
                options         = {
                    { value = "unit_threat_adamant", text = "dog_tag" },
                    { value = "unit_threat", text = "standard_tag" }
                }
            },
        }
    },
    {
        setting_id = "auto_target_settings",
        type = "group",
        sub_widgets = {
            {
				setting_id    = "auto_target",
				type          = "checkbox",
				default_value = false,
			},
            {
                setting_id      = "auto_target_type",
                type            = "dropdown",
                default_value   = "unit_threat_adamant",
                tooltip         = "type_tooltip",
                options         = {
                    { value = "unit_threat_adamant", text = "dog_tag" },
                    { value = "unit_threat", text = "standard_tag" }
                }
            },
            {
                setting_id    = "dog_cooldown",
                type          = "numeric",
                default_value = 0,
                range         = {0, 10},
            },
            {
                setting_id    = "no_retarget",
                type          = "checkbox",
                tooltip       = "no_retarget_tooltip",
                default_value = false,
            }
        }
    },
    {
        setting_id  = "focus_settings",
        type        = "group",
        sub_widgets = {
            --[[
            {
                setting_id    = "other_archetype",
                type          = "dropdown",
                tooltip       = "other_archetype_tooltip",
                default_value = "DISABLED",
                options       = {
                    { value = "DISABLED", text = "other_disabled" },
                    { value = "ENABLED", text = "other_enabled" },
                    { value = "FOCUS_TARGET", text = "other_focus" },
                },
            },
            --]]
            {
                setting_id    = "focus_target_stacks",
                type          = "numeric",
                default_value = 1,
                range         = {1, 8},
                tooltip       = "focus_target_stacks_tooltip",
            },
            {
                setting_id    = "focus_target_retarget",
                type          = "checkbox",
                default_value = false,
                tooltip       = "focus_target_retarget_tooltip",
            }
        },
    },
    {
        setting_id  = "filter_settings",
        type        = "group",
        sub_widgets = {
            {
                setting_id    = "filter_archetype",
                type          = "dropdown",
                default_value = "adamant",
                options       = {
                    { value = "adamant", text = "adamant" },
                    { value = "ogryn", text = "ogryn" },
                    { value = "psyker", text = "psyker" },
                    { value = "veteran", text = "veteran" },
                    { value = "zealot", text = "zealot" },
                }
            },
            {
                setting_id    = "filter_target",
                type          = "dropdown",
                default_value = "MANUAL",
                options       = {
                    { value = "MANUAL", text = "dog_manual" },
                    { value = "AUTO", text = "dog_auto" },
                },
            },
            {
                setting_id    = "toggle_all",
                type          = "checkbox",
                default_value = false,
            }
        },
    },
    {
        setting_id  = "elite_breeds",
        type        = "group",
        sub_widgets = elites,
    },
    {
        setting_id  = "special_breeds",
        type        = "group",
        sub_widgets = specials,
    },
    {
        setting_id  = "monster_breeds",
        type        = "group",
        sub_widgets = monsters,
    },
}

return {
    name         = mod:localize("mod_name"),
	description  = mod:localize("mod_description"),
    is_togglable = true,
	options = {
        widgets = widgets
    }
}