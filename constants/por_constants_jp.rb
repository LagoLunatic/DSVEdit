
# This file is loaded after the USA constants file. It only needs to specify things that are different from the USA version.

REGION = :jp

AREA_LIST_RAM_START_OFFSET = 0x020D3B78

MAX_ALLOWABLE_ROOM_OVERLAY_SIZE = 132672

MAP_TILE_METADATA_LIST_START_OFFSET = 0x020D3BF0
MAP_TILE_LINE_DATA_LIST_START_OFFSET = 0x020D3C2C
MAP_LENGTH_DATA_START_OFFSET = 0x020B3B58
MAP_SIZES_LIST_START_OFFSET = 0x020B3B3C
MAP_DRAW_OFFSETS_LIST_START_OFFSET = 0x020D3AE0
MAP_SECRET_DOOR_LIST_START_OFFSET = 0x020D3B00
MAP_ROW_WIDTHS_LIST_START_OFFSET = 0x020D3C68

AREA_MUSIC_LIST_START_OFFSET = 0x020D416C
SECTOR_MUSIC_LIST_START_OFFSET = 0x020D417C
AVAILABLE_BGM_POOL_START_OFFSET = 0x020D4A40
# sound test data at: 022D3DFC
SONG_INDEX_TO_TEXT_INDEX = [
  "Silence",
  0x5EE,
  0x5EF,
  0x5F0,
  0x5F1,
  0x5F2,
  0x5F3,
  0x5F4,
  0x5F5,
  0x5F6,
  0x5F7,
  0x5F8,
  0x5F9,
  0x5FA,
  0x5FB,
  0x5FC,
  0x5FE,
  0x604,
  0x5FD,
  0x5FF,
  0x601,
  0x602,
  0x603,
  0x610,
  0x605,
  0x600,
  0x606,
  0x607,
  0x608,
  0x609,
  0x60A,
  0x60B,
  0x60C,
  0x60D,
  0x60E,
  0x60F,
  0x611,
]

ASSET_LIST_START = 0x020C237C
ASSET_LIST_END = 0x020D399B

ENEMY_DNA_RAM_START_OFFSET = 0x020B27AC

REUSED_ENEMY_INFO[0x46] = {init_code: 0x0228C510, palette_offset: 3} # red axe armor -> axe armor
REUSED_ENEMY_INFO[0x4E] = {init_code: 0x022CD89C} # flame demon
REUSED_ENEMY_INFO[0x58] = {init_code: 0x0226CEF4, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1} # buster armor -> crossbow armor
REUSED_ENEMY_INFO[0x5C] = {init_code: 0x022CD020, palette_list_ptr_index: 1} # gorgon -> catoplepas
REUSED_ENEMY_INFO[0x5E] = {init_code: 0x02254F40} # tanjelly -> slime
REUSED_ENEMY_INFO[0x63] = {init_code: 0x0225AB74} # vice beetle -> spittle bone
REUSED_ENEMY_INFO[0x72] = {init_code: 0x022CE4B4, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1} # poison worm -> sand worm
REUSED_ENEMY_INFO[0x79] = {init_code: 0x0228C510, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1} # double axe armor -> axe armor
REUSED_ENEMY_INFO[0x7A] = {init_code: 0x022CD89C, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1} # demon
REUSED_ENEMY_INFO[0x98] = {gfx_wrapper: 0x02215048, sprite: 0x02132A44, palette: 0x022BA78C} # whip's memory
RICHTERS_LIST_OF_GFX_POINTERS = 0x02217DD8

ENEMY_FILES_TO_LOAD_LIST = 0x020C210C

COMMON_SPRITE = {desc: "Common", sprite: 0x022A9B64, gfx_wrapper: 0x020B4170, palette: 0x022AA460}

SPECIAL_OBJECT_CREATE_CODE_LIST = 0x02217288
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x02217598
REUSED_SPECIAL_OBJECT_INFO[0x00] = {init_code: 0x020E93A4}
REUSED_SPECIAL_OBJECT_INFO[0x01] = {init_code: 0x020E93A4}
REUSED_SPECIAL_OBJECT_INFO[0x1A] = {init_code: 0x020E969C} # portrait
REUSED_SPECIAL_OBJECT_INFO[0x22] = COMMON_SPRITE
REUSED_SPECIAL_OBJECT_INFO[0x76] = {init_code: 0x020E96A8} # portrait
REUSED_SPECIAL_OBJECT_INFO[0x82] = COMMON_SPRITE
REUSED_SPECIAL_OBJECT_INFO[0x86] = {init_code: 0x020E969C} # portrait
REUSED_SPECIAL_OBJECT_INFO[0x87] = {init_code: 0x020E96A8} # portrait
REUSED_SPECIAL_OBJECT_INFO[0xB6] = {init_code: 0x02215378}
REUSED_SPECIAL_OBJECT_INFO[0xB7] = {init_code: 0x02215388}
REUSED_SPECIAL_OBJECT_INFO[0xB8] = {init_code: 0x02215398}
REUSED_SPECIAL_OBJECT_INFO[0xB9] = {init_code: 0x022153A8}
REUSED_SPECIAL_OBJECT_INFO[0xBA] = {init_code: 0x022153B8}
REUSED_SPECIAL_OBJECT_INFO[0xBB] = {init_code: 0x022153C8}
REUSED_SPECIAL_OBJECT_INFO[0xBC] = {init_code: 0x022153D8}
REUSED_SPECIAL_OBJECT_INFO[0xBD] = {init_code: 0x022153E8}
REUSED_SPECIAL_OBJECT_INFO[0xBE] = {init_code: 0x022153F8}
SPECIAL_OBJECT_FILES_TO_LOAD_LIST = 0x020D6218

WEAPON_GFX_LIST_START = 0x02218A98
SKILL_GFX_LIST_START = 0x022186A0

OTHER_SPRITES = [
  COMMON_SPRITE,
  
  {pointer: 0x02217F1C, desc: "Jonathan player"},
  {pointer: 0x02217F70, desc: "Charlotte player"},
  {pointer: 0x02217FC8, desc: "Stella player"},
  {pointer: 0x02218018, desc: "Loretta player"},
  {pointer: 0x02218070, desc: "Richter player"},
  {pointer: 0x022180C8, desc: "Maria player"},
  {pointer: 0x02218120, desc: "Old Axe Armor player"},
  
  {pointer: 0x020E9390, desc: "Destructibles 0"},
  {pointer: 0x020E93A4, desc: "Destructibles 1"},
  {pointer: 0x020E93B8, desc: "Destructibles 2"},
  {pointer: 0x020E93CC, desc: "Destructibles 3"},
  {pointer: 0x020E93E0, desc: "Destructibles 4"},
  {pointer: 0x020E93F4, desc: "Destructibles 5"},
  {pointer: 0x020E9408, desc: "Destructibles 6"},
  {pointer: 0x020E941C, desc: "Destructibles 7"},
  {pointer: 0x020E9430, desc: "Destructibles 8"},
  {pointer: 0x020E9444, desc: "Destructibles 9"},
  {pointer: 0x020E9458, desc: "Destructibles 10"},
  {pointer: 0x020E946C, desc: "Destructibles 11"},
  {pointer: 0x020E9480, desc: "Destructibles 12"},
  {pointer: 0x020E9494, desc: "Destructibles 13"},
  {pointer: 0x020E94A8, desc: "Destructibles 14"},
  {pointer: 0x020E94BC, desc: "Destructibles 15"},
  {pointer: 0x020E969C, desc: "Portrait frame 0"},
  {pointer: 0x020E96A8, desc: "Portrait frame 1"},
  {pointer: 0x020E96B4, desc: "Portrait painting 0"},
  {pointer: 0x020E96C0, desc: "Portrait painting 1"},
  {pointer: 0x020E96CC, desc: "Portrait painting ???"}, # broken
  {pointer: 0x020E96D8, desc: "Portrait painting 3"},
  
  {pointer: 0x020693A0, desc: "Breakable walls 1", gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1},
  {pointer: 0x020693A0, desc: "Breakable walls 2", gfx_sheet_ptr_index: 4, palette_list_ptr_index: 4, sprite_ptr_index: 4},
  {pointer: 0x020693A0, desc: "Breakable walls 3", gfx_sheet_ptr_index: 0, palette_list_ptr_index: 0, sprite_ptr_index: 0},
  {pointer: 0x020693A0, desc: "Breakable walls 4", gfx_sheet_ptr_index: 5, palette_list_ptr_index: 5, sprite_ptr_index: 5},
  {pointer: 0x020693A0, desc: "Breakable walls 5", gfx_sheet_ptr_index: 6, palette_list_ptr_index: 6, sprite_ptr_index: 6},
  {pointer: 0x020693A0, desc: "Breakable walls 6", gfx_sheet_ptr_index: 2, palette_list_ptr_index: 2, sprite_ptr_index: 2},
  {pointer: 0x020693A0, desc: "Breakable walls 7", gfx_sheet_ptr_index: 7, palette_list_ptr_index: 7, sprite_ptr_index: 7},
  {pointer: 0x020693A0, desc: "Breakable walls 8", gfx_sheet_ptr_index: 3, palette_list_ptr_index: 3, sprite_ptr_index: 3},
  
  {pointer: 0x022D3DA0, desc: "Title screen graphics", overlay: 26},
  {pointer: 0x022D3DB0, desc: "Title screen options", overlay: 26},
  {pointer: 0x022CA6C0, desc: "Select data menu", overlay: 25},
  {pointer: 0x022CEF90, desc: "Name entry menu", overlay: 25},
  {pointer: 0x022CF380, desc: "Co-op mode start menu", overlay: 25},
  {pointer: 0x022D1584, desc: "Co-op mode end menu", overlay: 25},
  {pointer: 0x02050D9C, desc: "Info screen", one_dimensional_mode: true},
  {pointer: 0x020322C0, desc: "Pause menu", one_dimensional_mode: true},
  {pointer: 0x02033AE8, desc: "Equip menu", one_dimensional_mode: true},
  
  {pointer: 0x022D045C, desc: "Brauner inside mirror portrait", overlay: 55},
  {pointer: 0x022D0438, desc: "Brauner curse beast", overlay: 55},
]

CANDLE_SPRITE = COMMON_SPRITE
MONEY_SPRITE = COMMON_SPRITE

TEXT_LIST_START_OFFSET = 0x02215410
TEXT_RANGE = (0..0x738)
TEXT_REGIONS = {
  "Character Names" => (0..0xB),
  "Item Names" => (0xC..0x15B),
  "Item Descriptions" => (0x15C..0x2AB),
  "Enemy Names" => (0x2AC..0x346),
  "Enemy Descriptions" => (0x347..0x3E1),
  "Skill Names" => (0x3E2..0x44D),
  "Skill Descriptions" => (0x44E..0x4B9),
  "Music Names (Unused)" => (0x4BA..0x4D6),
  "System" => (0x4D7..0x50F),
  "Menus 1" => (0x510..0x5ED),
  "Music Names" => (0x5EE..0x611),
  "Language Names" => (0x612..0x616),
  "Quest Names" => (0x617..0x63B),
  "Quest Descriptions" => (0x63C..0x660),
  "Menus 2" => (0x661..0x6AD),
  "Events" => (0x6AE..0x737),
  "Debug" => (0x738..0x738)
}
STRING_DATABASE_START_OFFSET = 0x02219040
STRING_DATABASE_ORIGINAL_END_OFFSET = 0x02225A4B # for overlay 2. overlay 1 ends at 02224785
STRING_DATABASE_ALLOWABLE_END_OFFSET = STRING_DATABASE_ORIGINAL_END_OFFSET

# Note: the below are not actually where the original game stores the indexes. All three of those are at 02051F88 (since all three are the same: 00). The three addresses below are free space reused for the purpose of allowing the three values to be different.
NEW_GAME_STARTING_AREA_INDEX_OFFSET = 0x020B3E48
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x020B3E50
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x020B3E54
NEW_GAME_STARTING_X_POS_OFFSET = 0x022150C0
NEW_GAME_STARTING_Y_POS_OFFSET = 0x022150C4

FAKE_TRANSITION_ROOMS = [0x020DC754] # This room is marked as a transition room, but it's not actually.

ITEM_ICONS_PALETTE_POINTER = 0x022B58D0

ITEM_TYPES = [
  {
    name: "Consumables",
    list_pointer: 0x020D6F60,
    count: 96,
    format: CONSUMABLE_FORMAT # length: 12
  },
  {
    name: "Weapons",
    list_pointer: 0x020D7950,
    count: 73,
    format: WEAPON_FORMAT # length: 32
  },
  {
    name: "Body Armor",
    list_pointer: 0x020D73E0,
    count: 58,
    format: ARMOR_FORMAT # length: 24
  },
  {
    name: "Head Armor",
    list_pointer: 0x020D67E0,
    count: 38,
    format: ARMOR_FORMAT # length: 24
  },
  {
    name: "Leg Armor",
    list_pointer: 0x020D6528,
    count: 29,
    format: ARMOR_FORMAT # length: 24
  },
  {
    name: "Accessories",
    list_pointer: 0x020D6B70,
    count: 42,
    format: ARMOR_FORMAT # length: 24
  },
  {
    name: "Skills",
    list_pointer: 0x020D8538,
    count: 108,
    kind: :skill,
    format: SKILL_FORMAT # length: 24
  },
  {
    name: "Skills (extra data)",
    list_pointer: 0x020D8350,
    count: 81,
    kind: :skill,
    format: SKILL_EXTRA_DATA_FORMAT # length: 6
  },
]

PLAYER_LIST_POINTER = 0x02217F1C

NEW_OVERLAY_FREE_SPACE_START = 0x022FADE0
NEW_OVERLAY_FREE_SPACE_MAX_SIZE = 0x19000
ASSET_MEMORY_START_HARDCODED_LOCATION = 0x02094DA0

TEST_ROOM_SAVE_FILE_INDEX_LOCATION = 0x022D2A9C + 0x10
TEST_ROOM_AREA_INDEX_LOCATION      = 0x022D2A9C + 0x1C
TEST_ROOM_SECTOR_INDEX_LOCATION    = 0x022D2A9C + 0x24
TEST_ROOM_ROOM_INDEX_LOCATION      = 0x022D2A9C + 0x2C
TEST_ROOM_X_POS_LOCATION           = 0x022D2A9C + 0x54
TEST_ROOM_Y_POS_LOCATION           = 0x022D2A9C + 0x58

SHOP_ITEM_POOL_LIST = 0x020D4868
SHOP_POINT_ITEM_POOL = 0x020D48DC

FAKE_FREE_SPACES = [
  {path: "/ftc/overlay9_86", offset: 0x022EE1E0-0x022DA780, length: 4}, # Used by object 78
  {path: "/ftc/overlay9_91", offset: 0x022F9520-0x022DA780, length: 4}, # Used by object 54
  {path: "/ftc/overlay9_92", offset: 0x022F85A0-0x022DA780, length: 4}, # Used by object 55
  {path: "/ftc/overlay9_99", offset: 0x022ED000-0x022DA780, length: 0x98}, # Used by object 63
  {path: "/ftc/overlay9_100", offset: 0x022F4CC0-0x022DA780, length: 4}, # Used by object 64
  {path: "/ftc/overlay9_102", offset: 0x022FADC0-0x022DA780, length: 4}, # Used by object 56
  {path: "/ftc/overlay9_103", offset: 0x022F6D00-0x022DA780, length: 4}, # Used by object 57
  {path: "/ftc/overlay9_109", offset: 0x022E8320-0x022DA780, length: 0x14}, # Used by objects 50 and 94
  {path: "/ftc/overlay9_110", offset: 0x022E45A0-0x022DA780, length: 8}, # Used by object 51
  {path: "/ftc/overlay9_111", offset: 0x022EA560-0x022DA780, length: 4}, # Used by object 52
  {path: "/ftc/overlay9_112", offset: 0x022E4A80-0x022DA780, length: 0x14}, # Used by objects 53 and 66
  
  {path: "/ftc/overlay9_80", offset: 0x022F0EE0-0x022DA780, length: 0x40}, # Used by an unused room's layer list
  {path: "/ftc/overlay9_80", offset: 0x022F0EA0-0x022DA780, length: 0x40}, # Used by an unused room's layer list
  {path: "/ftc/overlay9_82", offset: 0x022ECFA0-0x022DA780, length: 0x40}, # Used by an unused room's layer list
  {path: "/ftc/overlay9_82", offset: 0x022ECF60-0x022DA780, length: 0x40}, # Used by an unused room's layer list
  {path: "/ftc/overlay9_82", offset: 0x022ECF20-0x022DA780, length: 0x40}, # Used by an unused room's layer list
  {path: "/ftc/overlay9_82", offset: 0x022ECEE0-0x022DA780, length: 0x40}, # Used by an unused room's layer list
  {path: "/ftc/overlay9_85", offset: 0x022F86C0-0x022DA780, length: 0x40}, # Used by an unused room's layer list
  {path: "/ftc/overlay9_86", offset: 0x022EE224-0x022DA780, length: 0x40}, # Used by an unused room's layer list
  {path: "/ftc/overlay9_86", offset: 0x022EE1E4-0x022DA780, length: 0x40}, # Used by an unused room's layer list
]

QUEST_LIST_POINTER = 0x020D4580

MENU_BG_LAYER_INFOS = [
  # TODO
]

FONTS = [
  {
    font_path: "/font/LD937728.DAT",
    char_width: 8,
    char_height: 8,
  },
  {
    font_path: "/font/LD937714.DAT",
    char_width: 16,
    char_height: 12,
  },
]
