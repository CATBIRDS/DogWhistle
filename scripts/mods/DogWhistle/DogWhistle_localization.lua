local Breeds = require("scripts/settings/breed/breeds")
local Archetypes = require("scripts/settings/archetype/archetypes")

-- Text coloring function
local crayon = function(text, color_name)
    local color = Color[color_name](255, true)
	local color_code = string.format("{#color(%s,%s,%s)}", color[2], color[3], color[4])
    local reset_code = "{#reset()}"
    if color_code and text and type(text) == "string" then
        return color_code .. text .. reset_code
    end
end

-- Simplified Chinese localization provided by jcyl2023
-- Traditional Chinese localization provided by SyuanTsai

local localization = {
    --  ┌─┐┬ ┬┌─┐┬─┐┌─┐┌┬┐                        
    --  └─┐├─┤├─┤├┬┘├┤  ││                        
    --  └─┘┴ ┴┴ ┴┴└─└─┘─┴┘  
    type_tooltip = {
        en = string.format(
            crayon("This setting only applies to the Arbitrator class.", "terminal_text_header_disabled").."\n"..
            "Determines the type of tag applied to enemies for this tagging method."
        ),
        ["zh-cn"] = string.format(
            crayon("仅适用于法务官", "terminal_text_header_disabled").."\n"..
            "决定标记的类型"
        ),
    },
    dog_tag = {
        en = "Cyber-Mastiff Attack Command",
        ["zh-cn"] = "智能獒犬 攻击命令",
	    ["zh-tw"] = "電子獒犬攻擊指令",
    },
    standard_tag = {
        en = "Standard Tag",
        ["zh-cn"] = "普通标记",
	    ["zh-tw"] = "一般標記",
    },
    none = {
        en = "None",
        ["zh-cn"] = "无",
	    ["zh-tw"] = "無",
    },
    --  ┌┬┐┌─┐┌┬┐                                 
    --  ││││ │ ││                                 
    --  ┴ ┴└─┘─┴┘  
    mod_name = {
        en = "Dog Whistle",
        ["zh-cn"] = "狗哨 / 自动标记",
	    ["zh-tw"] = "狗哨",
    },
    mod_settings = {
        en = "Mod Settings",
        ["zh-cn"] = "MOD设置",
        ["zh-tw"] = "模組設定",
    },
    mod_enable = {
        en = "Enable/Disable Mod",
        ["zh-cn"] = "模组启停",
        ["zh-tw"] = "模組啟用/停用",
    },
    mod_enable_keybind = {
        en = "Enable/Disable Mod (Toggle)",
        ["zh-cn"] = "切换式模组启停",
        ["zh-tw"] = "切換式模組啟用/停用",
    },
    mod_enable_verbose = {
        en = "Notify on Mod Enabled/Disabled",
        ["zh-cn"] = "模组状态通知",
        ["zh-tw"] = "模組狀態通知",
    },
    ignore_marked = {
        en = "Ignore Already Targeted Enemies",
	    ["zh-cn"] = "忽略已标记目标",
        ["zh-tw"] = "忽略已標記敵人",
    },
    ignore_marked_tooltip = {
        en = string.format("If enabled, the mod will not target enemies which already have been marked by another Arbitrator's Cyber-Mastiff.\n"..
                           "When using Focus Target, this will ignore enemies with stacks of Focus Target from any other player.\n"),
	    ["zh-cn"] = string.format("启用后，狗哨模组不会锁定已被另一个法务官的智能獒犬标记的敌人\n"..
                                  "老兵基石聚焦目标（金标）已被其他玩家标记，也会忽略）\n"),
        ["zh-tw"] = string.format("若啟用，模組將不會標記已被其他法務官的電子獒犬標記的敵人。\n"..
                                  "使用聚焦目標時，這將忽略任何其他玩家施加的聚焦目標層數的敵人。\n"),
    },
    type_priority = {
        en = "Tag Prioritization",
        ["zh-cn"] = "标记优先级",
        ["zh-tw"] = "標記優先等級",
    },
    type_priority_tooltip = {
        en = string.format(
            crayon("This setting only applies to the Arbitrator class.", "terminal_text_header_disabled").."\n"..
            crayon("Cyber-Mastiff Attack Command","terminal_text_body_sub_header")..": The mod will always allow Cyber-Mastiff Attack Commands to override Standard Tags, regardless of other settings.\n"..
            crayon("Standard Tag","terminal_text_body_sub_header")..": The mod will allow Standard Tags to override Cyber-Mastiff Attack Commands, regardless of other settings.\n"..
            crayon("None","terminal_text_body_sub_header")..": The mod will not prioritize either tag type over the other."
        ),
        ["zh-cn"] = string.format(
            crayon("仅适用于法务官", "terminal_text_header_disabled").."\n"..
            crayon("智能獒犬 攻击命令","terminal_text_body_sub_header")..": 模组始终允许【智能獒犬攻击命令覆盖标准标签】，不论其他设置\n"..
            crayon("标准标记","terminal_text_body_sub_header")..": 模组始终允许【标准标记覆盖智能獒犬攻击命令】，不管其他设置\n"..
            crayon("无","terminal_text_body_sub_header")..": 模组不运行任何一种标签类型"
	    ),
        ["zh-tw"] = string.format(
            crayon("此設定僅適用於法務官職業。", "terminal_text_header_disabled").."\n"..
            crayon("電子獒犬攻擊指令","terminal_text_body_sub_header").."：模組將始終允許電子獒犬攻擊指令覆蓋一般標記，無論其他設置如何。\n"..
            crayon("一般標記","terminal_text_body_sub_header").."：模組將允許一般標記覆蓋電子獒犬攻擊指令，無論其他設置如何。\n"..
            crayon("無","terminal_text_body_sub_header").."：模組不會優先考慮任何一種標記類型。"
        ),
    },
    --  ┬ ┬┬ ┬┬┌─┐┌┬┐┬  ┌─┐                       
    --  │││├─┤│└─┐ │ │  ├┤                        
    --  └┴┘┴ ┴┴└─┘ ┴ ┴─┘└─┘ 
    whistle_settings = {
        en = "Whistle Settings",
	    ["zh-cn"] = "哨子设置",
        ["zh-tw"] = "哨兵設定",
    },
    dog_keybind = {
        en = "Whistle Keybind",
        ["zh-cn"] = "标记按键设置",
        ["zh-tw"] = "哨兵按鍵設定",
    },
    whistle_type = {
        en = "Whistle Tag Type",
	    ["zh-cn"] = "哨子模式类型",
        ["zh-tw"] = "哨兵標記類型",
    },
    --  ┌─┐┬ ┬┌┬┐┌─┐  ┌┬┐┌─┐┬─┐┌─┐┌─┐┌┬┐          
    --  ├─┤│ │ │ │ │───│ ├─┤├┬┘│ ┬├┤  │           
    --  ┴ ┴└─┘ ┴ └─┘   ┴ ┴ ┴┴└─└─┘└─┘ ┴  
    auto_target_settings = {
        en = "Auto-Target Settings",
	    ["zh-cn"] = "自动标记设置",
        ["zh-tw"] = "自動標記設定",
    },
    auto_target = {
        en = "Auto-Target",
        ["zh-cn"] = "自动标记",
        ["zh-tw"] = "自動標記",
    },
    auto_target_type = {
        en = "Auto-Target Tag Type",
	["zh-cn"] = "自动标记模式类型",
        ["zh-tw"] = "自動標記類型",
    },
    dog_cooldown = {
        en = "Auto-Target Cooldown",
        ["zh-cn"] = "自动标记冷却时间",
        ["zh-tw"] = "自動標記冷卻時間",
    },
    no_retarget = {
        en = "Do not Auto-Retarget",
        ["zh-cn"] = "禁止重复锁定",
        ["zh-tw"] = "禁止重新鎖定",
    },
    no_retarget_tooltip = {
        en = "If enabled, the mod will wait until any existing targets have expired before assigning a new one through Auto-Target.",
        ["zh-cn"] = "若启用此选项，该模组会等待现有目标全部过期/失效后，再通过自动锁定功能分配新目标。",
        ["zh-tw"] = "若啟用此選項，模組將等待現有目標全部過期/失效後，再通過自動鎖定功能分配新目標。",
    },
    --  ┌─┐┌─┐┌─┐┬ ┬┌─┐  ┌┬┐┌─┐┬─┐┌─┐┌─┐┌┬┐       
    --  ├┤ │ ││  │ │└─┐   │ ├─┤├┬┘│ ┬├┤  │        
    --  └  └─┘└─┘└─┘└─┘   ┴ ┴ ┴┴└─└─┘└─┘ ┴   
    focus_settings = {
        en = "Focus Target Settings",
        ["zh-cn"] = "非法务官专属设置",
        ["zh-tw"] = "老兵-專注目標設定",
    },
    focus_target_stacks = {
        en = "Focus Target Stacks",
        ["zh-cn"] = "聚焦目标层数（金标）",
        ["zh-tw"] = "專注目標（金標）層數",
    },
    focus_target_stacks_tooltip = {
        en = "The mod will only tag enemies when at/above this number of Focus Target stacks.",
        ["zh-cn"] = "该模组仅在聚焦目标叠加层数达到或超过该设定数值时才会标记敌人",
        ["zh-tw"] = "模組僅在專注目標疊加層數達到或超過該設定數值時才會標記敵人",
    },
    focus_target_retarget = {
        en = "Focus Target Retargeting",
        ["zh-cn"] = "禁止重复锁定",
        ["zh-tw"] = "專注目標重標記規則",
    },
    focus_target_retarget_tooltip = {
        en = string.format(
        crayon("Disabled","terminal_text_body_sub_header")..": The mod will not reapply Focus Target tagging to enemies with an existing Focus Target tag.\n"..
        crayon("Enabled","terminal_text_body_sub_header")..": The mod will reapply Focus Target tagging to enemies with existing Focus Target tags, if current Focus Target stacks are higher than the amount applied to the target."),
        ["zh-cn"] = string.format(
        crayon("禁用状态","terminal_text_body_sub_header").."：模组不会对已经金标敌人再次重新标记，不论聚焦目标层数是多少\n"..
        crayon("启用状态","terminal_text_body_sub_header").."：聚焦目标层数高于设定层数阈值，无论是否已被标记，都会重新锁定"),
        ["zh-tw"] = string.format(
        crayon("停用狀態","terminal_text_body_sub_header").."：模組不會對已存在專注目標標記的敵人重新施加標記，無論疊加層數如何變化。\n"..
        crayon("啟用狀態", "terminal_text_body_sub_header") .. "：若當前專注目標的疊加層數高於目標現有標記的層數，模組將對已存在標記的敵人強制更新層數標記。")
    },
    --  ┌─┐┬  ┬  ┌─┐┬ ┬┌─┐┌┬┐  ┌─┐┌┐┌┌─┐┌┬┐┬┌─┐┌─┐
    --  ├─┤│  │  │ ││││├┤  ││  ├┤ │││├┤ ││││├┤ └─┐
    --  ┴ ┴┴─┘┴─┘└─┘└┴┘└─┘─┴┘  └─┘┘└┘└─┘┴ ┴┴└─┘└─┘
    filter_settings = {
        en = "Allowed Enemies",
        ["zh-cn"] = "职业设置",
        ["zh-tw"] = "允許選定的敵人",
    },
    filter_target = {
        en = "Apply Filter To",
        ["zh-cn"] = "标记模式",
        ["zh-tw"] = "將篩選器應用於",
    },
    dog_manual = {
        en = "Whistle",
        ["zh-cn"] = "口哨指令",
        ["zh-tw"] = "哨兵指令",
    },
    dog_auto = {
        en = "Auto-Target",
        ["zh-cn"] = "自动标记",
        ["zh-tw"] = "自動標記",
    },
    filter_archetype = {
        en = "Class Selection",
	    ["zh-cn"] = "职业选择",
        ["zh-tw"] = "職業選擇",
    },
    elite_breeds = {
        en = "Elites",
        ["zh-cn"] = "精英",
        ["zh-tw"] = "精英",
        ru = "элита",
    },
    special_breeds = {
        en = "Specialists",
        ["zh-cn"] = "专家",
        ["zh-tw"] = "專家",
        ru = "специалист",
    },
    monster_breeds = {
        en = "Monsters/Captains",
        ["zh-cn"] = "怪物/连长",
        ["zh-tw"] = "巨獸/隊長",
        ru = "монстр/капитан",
    },
    toggle_all = {
        en = "TOGGLE ALL",
        ["zh-cn"] = "全选开关",
        ["zh-tw"] = "全選開關",
    },
    toggle_elites = {
        en = "TOGGLE ELITES",
        ["zh-cn"] = "精英全选",
        ["zh-tw"] = "精英全選",
    },
    toggle_specials = {
        en = "TOGGLE SPECIALISTS",
        ["zh-cn"] = "专家全选",
        ["zh-tw"] = "專家全選",
    },
    toggle_monsters = {
        en = "TOGGLE MONSTERS/CAPTAINS",
        ["zh-cn"] = "boss全选",
        ["zh-tw"] = "巨獸/隊長全選",
    },
    --  ┌┬┐┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐┌┬┐┌─┐┌┬┐
    --   ││├┤ ├─┘├┬┘├┤ │  ├─┤ │ ├┤  ││
    --  ─┴┘└─┘┴  ┴└─└─┘└─┘┴ ┴ ┴ └─┘─┴┘
    other_archetype = {
        en = "Apply to Standard Tagging",
        ["zh-cn"] = "应用于标准标记",
        ["zh-tw"] = "應用於一般標記",
    },
    other_archetype_tooltip = {
        en = "When enabled, the mod's functionality will also be applied to standard tagging for non-Arbitrator classes.",
        ["zh-cn"] = "开启后，模组功能将同时作用于非法务官职业的标准标记",
        ["zh-tw"] = "開啟後，模組功能將同時作用於非仲裁者職業的一般標記",
    },
    other_disabled = {
        en = "Disabled",
        ["zh-cn"] = "关闭",
        ["zh-tw"] = "停用",
    },
    other_enabled = {
        en = "Enabled",
        ["zh-cn"] = "开启",
        ["zh-tw"] = "啟用",
    },
    other_focus = {
        en = "Focus Target Only",
        ["zh-cn"] = "仅限聚焦目标（金标）",
        ["zh-tw"] = "僅限專注目標（金標）",
    },
}

--------------------------------------------------------------------------
-- PLEASE DO NOT EDIT BEYOND THIS POINT IF YOU ARE ADDING LOCALIZATIONS --
--------------------------------------------------------------------------

-- Automated localization for enemy names
for breed_name, breed in pairs(Breeds) do
	if breed.tags.minion then
		local display_name = Localize(breed.display_name)
		localization[breed_name] = {
			en = display_name
		}
	end
end

-- Automated localization for archetypes
for class, template in pairs(Archetypes) do
    local id = string.match(class, "([^_]+)") -- zealot_archetype -> zealot, etc.
    local loc = template.archetype_name
    localization[id] = {
        en = Localize(loc)
    }
end

-- Randomized automated localization for mod description
local mod_descriptions = {
    -- Pox Hound lines
    "loc_ogryn_b__hunting_circumstance_start_b_03",                              -- "Not scared of scrawny mutts..."
    "loc_psyker_female_b__hunting_circumstance_start_b_01",                      -- "No Beloved, I don't think I want to play with these dogs."
    "loc_training_ground_psyker_a__wave_start_hounds_a_01",                      -- "Good dogs! Seek! Find!"
    "loc_training_ground_psyker_a__wave_start_hounds_a_02",                      -- "It is hunting time. Watch out for the teeth!"
    "loc_veteran_female_a__combat_pause_circumstance_zealot_c_hound_b_02",       -- "Something else is barking... Oh, it's you."
    -- Cyber-Mastiff lines
    "loc_adamant_male_a__adamant_male_a_psyker_bonding_conversation_01_a_01",    -- "You are making my Cyber-Mastiff nervous."
    "loc_psyker_female_c__adamant_female_b_psyker_bonding_conversation_57_a_01", -- "Your Cyber-Mastiff ... she has a particular skill for cadaver retrieval."
}
local description = Localize(mod_descriptions[math.random(1, #mod_descriptions)])
localization.mod_description = {en = description}

return localization