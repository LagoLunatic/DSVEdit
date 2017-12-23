
GAME = "aos"
REGION = :cn
LONG_GAME_NAME = "晓月圆舞曲"

AREA_LIST_RAM_START_OFFSET = 0x0800198C # Technically not a list, this points to code that has the the area hard coded, since AoS only has one area.

AREA_INDEX_TO_OVERLAY_INDEX = {
  0 => {
     0 => nil,
     1 => nil,
     2 => nil,
     3 => nil,
     4 => nil,
     5 => nil,
     6 => nil,
     7 => nil,
     8 => nil,
     9 => nil,
    10 => nil,
    11 => nil,
    12 => nil,
  }
}

AREAS_OVERLAY = nil

AREA_INDEX_TO_AREA_NAME = {
   0 => "德库拉的城堡"
}

SECTOR_INDEX_TO_SECTOR_NAME = {
   0 => {
     0 => "荒城回廊",
     1 => "礼拜堂",
     2 => "恶魔城藏书库",
     3 => "舞踏馆",
     4 => "幻梦宫",
     5 => "忘却庭院",
     6 => "时计塔",
     7 => "地下水域",
     8 => "竞技场",
     9 => "恶魔城最上阶",
    10 => "不可侵洞穴",
    11 => "混沌区域",
    12 => "Hardcoded rooms",
  }
}

HARDCODED_ROOM_IDS = [
  0x084F9FA4, # bad end

  0x084FB0B4,
  0x084FB14C,
  0x084FB1E4,
  0x084FB27C,
  0x084FB324,
  0x084FB3BC,
  0x084FB454,
  0x084FB4EC,
  0x084FB5A4,
  0x084FB63C,
  0x084FB6D4,
  0x084FB75C
]

NOTHING_ENTITY_TYPE = 0
ENEMY_ENTITY_TYPE = 1
SPECIAL_OBJECT_ENTITY_TYPE = 2
CANDLE_ENTITY_TYPE = 3
PICKUP_ENTITY_TYPE = 4

ENTITY_TYPE_DESCRIPTIONS = {
  0 => "无",
  1 => "怪物",
  2 => "场景 物体",
  3 => "蜡烛",
  4 => "可拾取道具",
  5 => "二周目道具",
  6 => "全魂收集道具",
}

ENEMY_IDS = (0x00..0x70).to_a
COMMON_ENEMY_IDS = (0x00..0x69).to_a
BOSS_IDS = (0x6A..0x70).to_a

BOSS_DOOR_SUBTYPE = 0x02
BOSS_ID_TO_BOSS_INDEX = {
  0x21 => 0x0B, # 大骷髅
  0x36 => 0x0A, # 曼提利亚
  0x3C => 0x0F, # 大装甲
  0x45 => 0x0C, # 巨人
  0x6A => 0x04, # 收集者
  0x6B => 0x01, # 死神
  0x6C => 0x05, # 死人军团
  0x6D => 0x06, # 巴洛尔
  0x6E => 0x02, # 尤里乌斯
  0x6F => 0x00, # 格拉罕
  0x70 => 0x07, # 混沌
}

WOODEN_DOOR_SUBTYPE = 0x00

AREA_NAME_SUBTYPE = nil

SAVE_POINT_SUBTYPE = 0x1C

COLOR_OFFSETS_PER_256_PALETTE_INDEX = 16

ENEMY_DNA_RAM_START_OFFSET = 0x080E6E50
ENEMY_DNA_FORMAT = [
  # length: 36
  [4, "Create Code"],
  [4, "Update Code"],
  [2, "Item 1"],
  [2, "Item 2"],
  [2, "HP"],
  [2, "MP"],
  [2, "EXP"],
  [1, "稀有魂??"],
  [1, "攻击"],
  [1, "防御"],
  [1, "Unknown 7"],
  [1, "Unknown 8"],
  [1, "魂类型"],
  [1, "魂ID"],
  [1, "Unknown 11"],
  [2, "弱点", :bitfield],
  [2, "抗性", :bitfield],
  [2, "Unknown 12"],
  [2, "Unknown 13"],
  [2, "Unknown 14"],
]
ENEMY_DNA_BITFIELD_ATTRIBUTES = {
  "弱点" => [
    "切割",
    "火",
    "水",
    "雷",
    "暗",
    "光",
    "毒",
    "诅咒",
    "石化",
    "Weakness 10",
    "Weakness 11",
    "杀人披风",
    "Weakness 13",
    "Weakness 14",
    "Weakness 15",
    "Weakness 16",
  ],
  "抗性" => [
    "切割",
    "火",
    "水",
    "雷",
    "暗",
    "光",
    "毒",
    "诅咒",
    "石化",
    "Resistance 10",
    "时间静止",
    "Resistance 12",
    "Resistance 13",
    "Resistance 14",
    "Resistance 15",
    "Resistance 16",
  ],
}

TEXT_LIST_START_OFFSET = 0x084D2D44
TEXT_RANGE = (0..0xB4E)
TEXT_REGIONS = {
  "Character Names" => (0..0xA),
  "Events" => (0xB..0x5A),
  "Item Names" => (0x5B..0xE2),
  "Red Soul Names" => (0xE3..0x119),
  "Unused Blue Soul Name" => (0x11A..0x11A),
  "Blue Soul Names" => (0x11B..0x132),
  "Yellow Soul Names" => (0x133..0x155),
  "Ability Soul Names" => (0x156..0x15B),
  "Item Descriptions" => (0x15C..0x1E3),
  "Red Soul Descriptions" => (0x1E4..0x21A),
  "Unused Blue Soul Description" => (0x21B..0x21B),
  "Blue Soul Descriptions" => (0x21C..0x233),
  "Yellow Soul Descriptions" => (0x234..0x256),
  "Ability Soul Descriptions" => (0x257..0x25C),
  "Enemy Names" => (0x25D..0x2CD),
  "Enemy Descriptions" => (0x2CE..0x33E),
  "Menus" => (0x33F..0x392),
  "Music Names" => (0x393..0x3AF),
  "Menus 2" => (0x3B0..0x3B6),
  "Uncategorized" => (0x3B7..0x3C3),
  "French" => (0x3C4..0xB87),
  "German" => (0x788..0xB4B),
  "Language Names" => (0xB4C..0xB4E),
}
TEXT_REGIONS_OVERLAYS = {
  "Character Names" => nil,
  "Events" => nil,
  "Item Names" => nil,
  "Red Soul Names" => nil,
  "Unused Blue Soul Name" => nil,
  "Blue Soul Names" => nil,
  "Yellow Soul Names" => nil,
  "Ability Soul Names" => nil,
  "Item Descriptions" => nil,
  "Red Soul Descriptions" => nil,
  "Unused Blue Soul Description" => nil,
  "Blue Soul Descriptions" => nil,
  "Yellow Soul Descriptions" => nil,
  "Ability Soul Descriptions" => nil,
  "Enemy Names" => nil,
  "Enemy Descriptions" => nil,
  "Menus" => nil,
  "Music Names" => nil,
  "Menus 2" => nil,
  "Uncategorized" => nil,
  "French" => nil,
  "German" => nil,
  "Language Names" => nil,
}
STRING_DATABASE_START_OFFSET = 0x080E7F38
STRING_DATABASE_ORIGINAL_END_OFFSET = 0x080F58D6
STRING_DATABASE_ALLOWABLE_END_OFFSET = STRING_DATABASE_ORIGINAL_END_OFFSET
TEXT_COLOR_NAMES = {
  0x00 => "TRANSPARENT",
  0x01 => "WHITE",
  0x02 => "GREY",
  0x03 => "PINK",
  0x04 => "BROWN",
  0x05 => "AZURE",
  0x06 => "DARKBLUE",
  0x07 => "YELLOW",
  0x08 => "ORANGE",
  0x09 => "LIGHTGREEN",
  0x0A => "GREEN",
  0x0B => "BRIGHTPINK",
  0x0C => "PURPLE",
  0x0D => "BROWN2",
  0x0E => "BLACK",
  0x0F => "BLACK2",
}

SPECIAL_OBJECT_IDS = (0..0x37)
SPECIAL_OBJECT_CREATE_CODE_LIST = 0x084BCD5C	# -E0
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x084BCE3C    #may not right

ITEM_LOCAL_ID_RANGES = {
  0x02 => (0x00..0x1F), # consumable
  0x03 => (0x00..0x3A), # weapon
  0x04 => (0x00..0x2C), # armor
}
ITEM_GLOBAL_ID_RANGE = (0..0x87)
SKILL_GLOBAL_ID_RANGE = (0x88..0xFA)
SKILL_LOCAL_ID_RANGE = nil # souls in AoS are split into multiple different types.
PICKUP_GLOBAL_ID_RANGE = (0..0xFA)

PICKUP_SUBTYPES_FOR_ITEMS = (0x02..0x04)
PICKUP_SUBTYPES_FOR_SKILLS = (0x05..0xFF)

NEW_GAME_STARTING_AREA_INDEX_OFFSET = nil
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x084BCCF0
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x084BCCF1
NEW_GAME_STARTING_X_POS_OFFSET = 0x084BCCF6
NEW_GAME_STARTING_Y_POS_OFFSET = 0x084BCCF8

TRANSITION_ROOM_LIST_POINTER = 0x084E5268
FAKE_TRANSITION_ROOMS = []

ITEM_ICONS_PALETTE_POINTER = 0x081CFAC8
GLYPH_ICONS_PALETTE_POINTER = nil
ITEM_ICONS_GFX_POINTERS = [0x081A0CD4, 0x081A2CD8, 0x081A4CDC]

CONSUMABLE_FORMAT = [
  # length: 16
  [2, "道具ID"],
  [2, "图标"],
  [4, "价格"],
  [1, "类型"],
  [1, "Unknown 1"],
  [2, "参数A"],
  [4, "Unused"],
]
WEAPON_FORMAT = [
  # length: 28
  [2, "道具ID"],
  [2, "图标"],
  [4, "价格"],
  [1, "攻击方式"],
  [1, "Unknown 1"],
  [1, "攻击力"],
  [1, "防御力"],
  [1, "Str属性增加"],
  [1, "Con属性增加"],
  [1, "Int属性增加"],
  [1, "Luck属性增加"],
  [2, "属性", :bitfield],
  [1, "GFX Index"],
  [1, "Sprite Index"],
  [1, "Unknown 2"],
  [1, "色盘"],
  [1, "攻击频率"],
  [1, "连击"],
  [2, "攻击音效"],
  [2, "Unknown 3"],
]
ARMOR_FORMAT = [
  # length: 20
  [2, "道具ID"],
  [2, "图标"],
  [4, "价格"],
  [1, "类型"],
  [1, "Unknown 1"],
  [1, "攻击力"],
  [1, "防御力"],
  [1, "Str属性增加"],
  [1, "Con属性增加"],
  [1, "Int属性增加"],
  [1, "Luck属性增加"],
  [2, "抗性", :bitfield],
  [1, "Unknown 2"],
  [1, "Unknown 3"],
]
RED_SOUL_FORMAT = [
  # length: 16
  [4, "Code"],
  [2, "使用动画"],
  [2, "消耗MP"],
  [1, "同屏限制"],
  [1, "Unknown 1"],
  [2, "攻击力"],
  [2, "属性", :bitfield],
  [2, "参数A"],
]
BLUE_SOUL_FORMAT = [
  # length: 12
  [4, "Code"],
  [1, "消耗MP"],
  [1, "1为按住 2为按一次R键"],
  [2, "Unknown 1"],
  [4, "Player effect/Varies"],
]
YELLOW_SOUL_FORMAT = [
  # length: 12
  [4, "Code"],
  [2, "Unknown 1"],
  [2, "Stat to raise"],
  [4, "Player effect/Stat pts"],
]
JULIUS_SKILL_FORMAT = RED_SOUL_FORMAT
ITEM_TYPES = [
  {
    name: "道具",
    list_pointer: 0x084D1D48,
    count: 0x20,
    format: CONSUMABLE_FORMAT # length 16
  },
  {
    name: "武器",
    list_pointer: 0x084D1F48,
    count: 0x3B,
    format: WEAPON_FORMAT # length 28
  },
  {
    name: "防具",
    list_pointer: 0x084D25BC,
    count: 0x2D,
    format: ARMOR_FORMAT # length 20
  },
  {
    name: "红魂",
    list_pointer: 0x080DFAE0,
    count: 0x38,
    kind: :skill,
    format: RED_SOUL_FORMAT # length: 16
  },
  {
    name: "蓝魂",
    list_pointer: 0x080DFE74,
    count: 0x19,
    kind: :skill,
    format: BLUE_SOUL_FORMAT # length: 12
  },
  {
    name: "黄魂",
    list_pointer: 0x080E0050,
    count: 0x24,
    kind: :skill,
    format: YELLOW_SOUL_FORMAT # length: 12
  },
  {
    name: "尤里乌斯技能",
    list_pointer: 0x080E0420,
    count: 0x4,
    kind: :skill,
    format: JULIUS_SKILL_FORMAT # length: 16
  },
]
ITEM_BITFIELD_ATTRIBUTES = {
  "属性" => [
    "切割",
    "火",
    "水",
    "雷",
    "暗",
    "光",
    "毒",
    "诅咒",
    "石化",
    "Unknown 10",
    "Unknown 11",
    "杀人披风",
    "伤害减半",
    "是否有硬直",
    "Unknown 15",
    "Unknown 16",
  ],
  "抗性" => [
    "切割",
    "火",
    "水",
    "雷",
    "暗",
    "光",
    "毒",
    "诅咒",
    "石化",
    "Unknown 10",
    "Unknown 11",
    "Unknown 12",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
  ],
}

OVERLAY_FILE_FOR_ENEMY_AI = {}
REUSED_ENEMY_INFO = {
  0x07 => {init_code: 0x0806F090}, # killer fish
  0x08 => {init_code: 0x080F8664}, # bone pillar
  0x0B => {init_code: 0x0807620C}, # white dragon
  0x0F => {init_code: 0x08073C2C, palette_offset: 1}, # siren -> harpy
  0x10 => {palette_offset: 1}, # tiny devil
  0x11 => {init_code: 0x08091744}, # durga -> curly
  0x12 => {palette_offset: 1}, # rock armor
  0x13 => {init_code: 0x0807C898}, # giant ghost
  0x15 => {init_code: 0x080AF0A0}, # minotaur
  0x17 => {init_code: 0x08078F3C}, # arachne
  0x19 => {palette_offset: 1}, # evil butcher
  0x1C => {init_code: 0x0808801C, palette_offset: 1}, # catoblepas
  0x21 => {init_code: 0x080973CC}, # creaking skull
  0x22 => {init_code: 0x0807F6F4, palette_offset: 2, gfx_sheet_ptr_index: 1}, # wooden golem
  0x25 => {palette_offset: 1}, # lilith -> succubus
  0x2B => {palette_offset: 1}, # curly
  0x2D => {palette_offset: 1}, # red crow -> blue crow
  0x2E => {init_code: 0x080BA5BC}, # cockatrice
  0x30 => {init_code: 0x0808F9FC, palette_offset: 2}, # devil
  0x35 => {init_code: 0x0807F6F4, gfx_sheet_ptr_index: 1}, # golem
  0x36 => {init_code: 0x08072638}, # manticore
  0x37 => {init_code: 0x08084A6C, palette_offset: 1}, # gremlin => gargoyle
  0x3C => {init_code: 0x0808C5F0}, # great armor
  0x3E => {init_code: 0x080ABDBC}, # giant worm
  0x41 => {init_code: 0x080F8674}, # fish head
  0x43 => {init_code: 0x080862F0}, # triton
  0x45 => {init_code: 0x080AB79C}, # big golem
  0x47 => {init_code: 0x080ABDBC, palette_offset: 1}, # poison worm
  0x48 => {init_code: 0x0808F9FC}, # arc demon
  0x49 => {init_code: 0x080B644C, sprite: 0x081E6774}, # cagnazzo 4DB0F8 4DF1EA
  0x4A => {palette_offset: 1}, # ripper
  0x4B => {init_code: 0x08077C58}, # werejaguar
  0x50 => {init_code: 0x0807F6F4, palette_offset: 3}, # flesh golem TODO
  0x54 => {init_code: 0x08077C58, palette_offset: 1}, # weretiger
  0x58 => {init_code: 0x080AF0A0, palette_offset: 1}, # red minotaur
  0x5B => {init_code: 0x080B644C, palette_offset: 2, sprite: 0x081F2E9C}, # skull millione  2 not sure
  0x5C => {init_code: 0x080973CC, palette_offset: 1}, # giant skeleton
  0x5D => {init_code: 0x080A0AB8}, # gladiator
  0x60 => {init_code: 0x080979FC}, # mimic
  0x61 => {init_code: 0x0809AAB0}, # stolas
  0x62 => {init_code: 0x0806CCE0, palette_offset: 1}, # erinys -> valkyrie
  0x63 => {init_code: 0x080B644C, palette_offset: 1, sprite: 0x0824A334}, # lubicant
  0x64 => {init_code: 0x080BA5BC, palette_offset: 1}, # basilisk
  0x65 => {init_code: 0x0807F6F4, palette_offset: 1, gfx_sheet_ptr_index: 1}, # iron golem
  0x66 => {init_code: 0x0808F9FC, palette_offset: 1}, # demon lord
  0x67 => {init_code: 0x0808C5F0, palette_offset: 1}, # final guard
  0x68 => {init_code: 0x0808F9FC, palette_offset: 3}, # flame demon
  0x69 => {init_code: 0x0808C5F0, palette_offset: 2}, # shadow knight
  0x6A => {gfx_wrapper: 0x080F8188, sprite: 0x0821C190, palette: 0x0820A780}, # headhunter
  0x6B => {gfx_wrapper: 0x080F8720}, # death
  0x6C => {gfx_wrapper: 0x080F8348, sprite: 0x082258fc, palette: 0x0820AC4C}, # legion
  0x6D => {gfx_wrapper: 0x080F8684, sprite: 0x08244220}, # balore
  0x6E => {gfx_wrapper: 0x080F87A8}, # julius
  0x6F => {init_code: 0x080F7994}, # graham
  0x70 => {gfx_wrapper: 0x080F8454, palette: 0x0820AD70}, # chaos
}
ENEMY_FILES_TO_LOAD_LIST = nil
BEST_SPRITE_FRAME_FOR_ENEMY = {
  0x00 => 0x03,
  0x01 => 0x06,
  0x06 => 0x11,
  0x07 => 0x08,
  0x0E => 0x07,
  0x10 => 0x04,
  0x16 => 0x10,
  0x17 => 0x1D,
  0x21 => 0x16,
  0x22 => 0x01,
  0x2A => 0x07,
  0x30 => 0x05,
  0x36 => 0x03,
  0x3C => 0x0E,
  0x3D => 0x08,
  0x3E => 0x07,
  0x48 => 0x07,
  0x4D => 0x0A,
  0x50 => 0x10,
  0x51 => 0x09,
  0x5C => 0x16,
  0x60 => 0x0D,
  0x65 => 0x02,
  0x66 => 0x08,
  0x67 => 0x11,
  0x68 => 0x05,
  0x69 => 0x12,
  0x6A => 0x02,
  0x6B => 0x33,
  0x6C => 0x34,
  0x70 => 0x02,
}
BEST_SPRITE_OFFSET_FOR_ENEMY = {}

COMMON_SPRITE = {desc: "Common", sprite: 0x081D3BB4, gfx_files: [0x0819E4CC], palette: 0x081CFAC8, palette_offset: 3} #1 may be right

OVERLAY_FILE_FOR_SPECIAL_OBJECT = {}
REUSED_SPECIAL_OBJECT_INFO = {
  0x00 => {init_code: 0x0804BF24}, # wooden door
  0x01 => {init_code: 0x080323B8}, # pushable crate TODO: sprite file can't be found, gfx and palette are fine
  0x02 => COMMON_SPRITE.merge(palette_offset: 2),
  0x03 => COMMON_SPRITE.merge(palette_offset: 2),
  0x04 => COMMON_SPRITE.merge(palette_offset: 2),
  0x05 => COMMON_SPRITE,
  0x06 => {init_code:         -1}, # darkness door
  0x07 => {init_code:         -1},
  0x08 => {init_code: 0x084FC904},
  0x09 => {init_code: 0x084FC904},
  0x0C => {init_code:         -1},
  0x0E => {init_code: 0x084FCB14}, # destructible
  0x0F => COMMON_SPRITE,
  0x12 => {init_code:         -1}, # multiple different background visuals
  0x1C => {palette_offset: 1},
  0x1F => {init_code: 0x080542B4, palette_offset: 2},
  0x20 => {init_code:         -1},
  0x29 => {init_code: 0x084FCDD0, palette_offset: 6},
  0x2A => {init_code: 0x084FCDD0, palette_offset: 6},
  0x2D => {palette_offset: 2},
  0x2E => {palette_offset: 5},
  0x32 => {palette_offset: 1},
  0x34 => {palette_offset: 2},
  0x36 => {init_code:         -1},
}
SPECIAL_OBJECT_FILES_TO_LOAD_LIST = nil
BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT = {
  0x00 => 0x01,
  0x02 => 0x3F,
  0x03 => 0x3F,
  0x04 => 0x3F,
  0x05 => 0x7D,
  0x0F => 0x4A,
  0x1B => 0x02,
  0x1C => 0x0C,
  0x1D => 0x0B,
  0x1F => 0x0A,
  0x24 => 0x05,
  0x26 => 0x02,
  0x34 => 0x03,
}
BEST_SPRITE_OFFSET_FOR_SPECIAL_OBJECT = {
  0x00 => {x: -8},
}

OTHER_SPRITES = [
  COMMON_SPRITE,
  
  {desc: "Breakable walls 1", pointer: 0x084FC904},
  {desc: "Breakable walls 2", pointer: 0x084FC910},
  {desc: "Breakable walls 3", pointer: 0x084FC91C},
  {desc: "Breakable walls 4", pointer: 0x084FC928},
  {desc: "Breakable walls 5", pointer: 0x084FC934},
  {desc: "Breakable walls 6", pointer: 0x084FC940},
  {desc: "Breakable walls 7", pointer: 0x084FC94C},
  {desc: "Breakable walls 8", pointer: 0x084FC958},
  
  {desc: "Destructible 0", pointer: 0x084FCB14},
  {desc: "Destructible 1", pointer: 0x084FCB20},
  {desc: "Destructible 2", pointer: 0x084FCB2C},
  {desc: "Destructible 3", pointer: 0x084FCB38},
  {desc: "Destructible 4", pointer: 0x084FCB44},
  {desc: "Destructible 5", pointer: 0x084FCB50},
  {desc: "Destructible 6", pointer: 0x084FCB5C},
  {desc: "Destructible 7", pointer: 0x084FCB68},
  {desc: "Destructible 8", pointer: 0x084FCB74},
  {desc: "Destructible 9", pointer: 0x084FCB80},
  {desc: "Destructible A", pointer: 0x084FCB8C},
  {desc: "Destructible B", pointer: 0x084FCB98},
  {desc: "Destructible C", pointer: 0x084FCBA4},
  {desc: "Destructible D", pointer: 0x084FCBB0},
  
  {desc: "Background window", pointer: 0x084FCCA8},
  {desc: "Background rushing water", pointer: 0x084FCCC0},
  {desc: "Background moon", pointer: 0x084FCCD8},
  
  {desc: "unknown", pointer: 0x084FCDD0},
  {desc: "unknown", pointer: 0x084FCDE0},
  {desc: "unknown", pointer: 0x084FCDF0},
  {desc: "unknown", pointer: 0x084FCE00},
  {desc: "unknown", pointer: 0x084FCE10},
  {desc: "unknown", pointer: 0x084FCE20},
  {desc: "unknown", pointer: 0x084FCE30},
  {desc: "unknown", pointer: 0x084FCE40},
  #{desc: "unknown", pointer: 0x084FCE50}, source is error too
  
  {desc: "xxxxxx", pointer: 0x080F794C},
  {desc: "xxxxxx", pointer: 0x080F7958},
  {desc: "Mina event actor", pointer: 0x080F7964},
  {desc: "Arikado event actor", pointer: 0x080F7970},
  {desc: "Yoko event actor", pointer: 0x080F797C},
  {desc: "Hammer event actor", pointer: 0x080F7988},
  {desc: "Graham event actor", pointer: 0x080F79A0},
  {desc: "J", pointer: 0x080F79AC},
  {desc: "J 2", sprite: 0x08211868, palette: 0x081D1A88, gfx_files: [0x081C9864, 0x081CA868, 0x081CB86C, 0x081CC870]},
  {desc: "xxxxxx", pointer: 0x080F79C4},
  {desc: "xxxxxx", pointer: 0x080F79D0},
  {desc: "xxxxxx", pointer: 0x080F79DC},
  {desc: "Somacula event actor", pointer: 0x080F79E8},
  
  {desc: "Giant Bat", pointer: 0x080B5C38, gfx_wrapper: 0x080F8694},
  {desc: "Chaos 2", gfx_wrapper: 0x080F84AC, palette: 0x081D09E7, sprite: 0x08231424},
]

CANDLE_FRAME_IN_COMMON_SPRITE = 0x1E
MONEY_FRAME_IN_COMMON_SPRITE = 0x21
CANDLE_SPRITE = COMMON_SPRITE.merge(palette_offset: 3)
MONEY_SPRITE = COMMON_SPRITE.merge(palette_offset: 2)

WEAPON_GFX_LIST_START = 0x084BD024
WEAPON_GFX_COUNT = 0x2F
WEAPON_SPRITES_LIST_START = 0x084BD0E0
WEAPON_PALETTE_LIST = 0x081CF984
SKILL_GFX_LIST_START = 0x080E13BC
SKILL_GFX_COUNT = 0x22
RED_SOUL_INDEX_TO_SKILL_GFX_INDEX = {
  0x00 => nil,
  0x01 => 0x00,
  0x02 => 0x03,
  0x03 => 0x07,
  0x04 => 0x00,
  0x05 => 0x00,
  0x06 => 0x12,
  0x07 => 0x0B,
  0x08 => 0x1F,
  0x09 => 0x07,
  0x0A => 0x15,
  0x0B => 0x00,
  0x0C => 0x15,
  0x0D => 0x18,
  0x0E => 0x00,
  0x0F => 0x04,
  0x10 => 0x10,
  0x11 => 0x14,
  0x12 => 0x01,
  0x13 => 0x01,
  0x14 => 0x0A,
  0x15 => 0x11,
  0x16 => 0x1B,
  0x17 => 0x0E,
  0x18 => 0x18,
  0x19 => 0x00,
  0x1A => 0x0C,
  0x1B => 0x20,
  0x1C => 0x16,
  0x1D => 0x11,
  0x1E => 0x07,
  0x1F => 0x17,
  0x20 => 0x21,
  0x21 => 0x0D,
  0x22 => 0x01,
  0x23 => 0x08,
  0x24 => 0x08,
  0x25 => 0x0F,
  0x26 => 0x19,
  0x27 => 0x13,
  0x28 => 0x07,
  0x29 => 0x12,
  0x2A => 0x18,
  0x2B => 0x1C,
  0x2C => 0x11,
  0x2D => 0x09,
  0x2E => 0x02,
  0x2F => 0x00,
  0x30 => 0x05,
  0x31 => 0x1D,
  0x32 => 0x1E,
  0x33 => 0x06,
  0x34 => 0x15,
  0x35 => 0x1A,
  0x36 => 0x1B,
  0x37 => 0x01,
}
BLUE_SOUL_REUSED_SPRITE_INFO = {
  0x00 => {init_code: -1}, # ---
  0x02 => {init_code: -1}, # giant bat
  0x03 => {init_code: -1}, # black panther
  0x04 => {init_code: 0x0802EF66}, # buer
  0x06 => {init_code: 0x0802EC24}, # giant ghost
  0x0F => {init_code: -1}, # medusa head
  0x12 => {init_code: 0x0802DE62}, # devil
  0x13 => {init_code: 0x0802DE62}, # manticore
  0x14 => {init_code: 0x08030AAD}, # curly
}

MAP_TILE_METADATA_LIST_START_OFFSET = nil
MAP_TILE_METADATA_START_OFFSET = 0x080F58D8
MAP_TILE_LINE_DATA_LIST_START_OFFSET = nil
MAP_TILE_LINE_DATA_START_OFFSET = 0x080F7058
MAP_LENGTH_DATA_START_OFFSET = nil
MAP_NUMBER_OF_TILES = 3008
MAP_SECRET_DOOR_LIST_START_OFFSET = nil
MAP_SECRET_DOOR_DATA_START_OFFSET = 0x080F7638
ABYSS_MAP_TILE_METADATA_START_OFFSET = nil
ABYSS_MAP_TILE_LINE_DATA_START_OFFSET = nil
ABYSS_MAP_NUMBER_OF_TILES = nil
ABYSS_MAP_SECRET_DOOR_DATA_START_OFFSET = nil

WARP_ROOM_LIST_START = 0x084FC8BC
WARP_ROOM_COUNT = 8

MAP_FILL_COLOR = [0, 0, 224, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [248, 248, 8, 255]
MAP_SECRET_FILL_COLOR = [0, 128, 0, 255]
MAP_ENTRANCE_FILL_COLOR = [0, 0, 0, 0] # Area entrances don't exist in AoS.
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [0, 200, 200, 255]
MAP_DOOR_CENTER_PIXEL_COLOR = MAP_DOOR_COLOR
MAP_SECRET_DOOR_COLOR = [248, 248, 0, 255]

AREA_MUSIC_LIST_START_OFFSET = nil
SECTOR_MUSIC_LIST_START_OFFSET = 0x084BCF74
AVAILABLE_BGM_POOL_START_OFFSET = nil
SONG_INDEX_TO_TEXT_INDEX = [
  "Silence",
  0x393,
  0x394,
  0x395,
  0x396,
  0x397,
  0x398,
  0x399,
  0x39A,
  0x39B,
  0x39C,
  0x39D,
  0x39E,
  0x39F,
  0x3A0,
  0x3A1,
  0x3A2,
  0x3A3,
  0x3A4,
  0x3A5,
  0x3A7,
  0x3A8,
  0x3A9,
  "Premonition (Duplicate)",
  0x3AD,
  "Premonition (Duplicate 2)",
  0x3AB,
  0x3AC,
  "Forbidden Area (Duplicate)",
  "Prologue(Theme of Mina) (Duplicate)",
  "Hammer's Shop (Duplicate)",
  0x3A6,
  0x3AA,
  0x3AE,
  "Dracula's fate (Duplicate)",
  0x3AF,
  "You're Not Alone (Duplicate)",
  "Ambience",
  "Ambience (Duplicate)",
  "Rushing Water Ambience",
  "Ambience (Legion?)",
  "Ambience (Legion)",
  "Ambience (???)",
  "Ambience (??? 2)",
  "Ambience (??? 3)",
  "Ambience (Before Chaos)",
]

NEW_OVERLAY_ID = nil
NEW_OVERLAY_FREE_SPACE_START = nil
NEW_OVERLAY_FREE_SPACE_MAX_SIZE = nil
ASSET_MEMORY_START_HARDCODED_LOCATION = nil

ROM_FREE_SPACE_START = 0x651170
ROM_FREE_SPACE_SIZE = 0x1AEE90

TEST_ROOM_SAVE_FILE_INDEX_LOCATION = 0x0800298E    #cant find try modify
TEST_ROOM_AREA_INDEX_LOCATION      = nil
TEST_ROOM_SECTOR_INDEX_LOCATION    = 0x08002994
TEST_ROOM_ROOM_INDEX_LOCATION      = 0x08002996
TEST_ROOM_X_POS_LOCATION           = 0x080029B8
TEST_ROOM_Y_POS_LOCATION           = 0x080029BC
TEST_ROOM_OVERLAY = nil

SHOP_ITEM_POOL_LIST = 0x084FD55C
SHOP_ITEM_POOL_COUNT = 3
SHOP_ALLOWABLE_ITEMS_LIST = 0x084FD2EC
SHOP_NUM_ALLOWABLE_ITEMS = 0x82
SHOP_ITEM_POOL_REQUIRED_EVENT_FLAG_HARDCODED_LOCATIONS = [nil, 0x080659B6, 0x080659C8]

FAKE_FREE_SPACES = []

MAGIC_SEAL_COUNT = 0
MAGIC_SEAL_LIST_START = nil
MAGIC_SEAL_FOR_BOSS_LIST_START = nil
