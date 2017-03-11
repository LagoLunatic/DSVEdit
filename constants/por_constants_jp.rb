
# This file is loaded after the USA constants file. It only needs to specify things that are different from the USA version.

REGION = :jp

AREA_LIST_RAM_START_OFFSET = 0x020D3B78

MAX_ALLOWABLE_ROOM_OVERLAY_SIZE = 132672

#INVALID_ROOMS = [0x020E5AD0, 0x020E62E0, 0x020E6300, 0x020E5BA0, 0x020E6320, 0x020E6610, 0x020E7388, 0x020E7780, 0x020E7850]

MAP_TILE_METADATA_LIST_START_OFFSET = 0x020D3BF0
MAP_TILE_LINE_DATA_LIST_START_OFFSET = 0x020D3C2C
MAP_LENGTH_DATA_START_OFFSET = 0x020B3B58
MAP_SECRET_DOOR_LIST_START_OFFSET = 0x020D3B00

AREA_MUSIC_LIST_START_OFFSET = 0x020D416C
SECTOR_MUSIC_LIST_START_OFFSET = 0x020D417C
AVAILABLE_BGM_POOL_START_OFFSET = 0x020D4A40
# sound test data at: 022D3DFC
SONG_INDEX_TO_TEXT_INDEX = [ # TODO
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

LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET = 0x020C237C
LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET = 0x020D399B

ENEMY_DNA_RAM_START_OFFSET = 0x020B27AC

#REUSED_ENEMY_INFO = {
#  0x31 => {palette_offset: 2}, # lilith
#  0x46 => {init_code: 0x02297320, palette_offset: 3}, # red axe armor -> axe armor
#  0x4E => {init_code: 0x022D7930}, # flame demon
#  0x54 => {palette_offset: 1}, # ghoul and zombie
#  0x58 => {init_code: 0x022744DC, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1}, # buster armor -> crossbow armor
#  0x5C => {init_code: 0x022D7918, palette_list_ptr_index: 1},
#  0x5E => {init_code: 0x02259EE4}, # tanjelly -> slime
#  0x63 => {init_code: 0x022630F8}, # vice beetle -> spittle bone
#  0x72 => {init_code: 0x022D7900, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # poison worm -> sand worm
#  0x79 => {init_code: 0x02297320, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # double axe armor -> axe armor
#  0x7A => {init_code: 0x022D7930, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # demon
#  0x7E => {palette_offset: 1}, # golden skeleton and skeleton
#  0x98 => {init_code: 0x0221E954} # whip's memory. for some reason his pointers are off in some random place not near his init code.
#}
RICHTERS_LIST_OF_GFX_POINTERS = 0x02217DD8

ENEMY_FILES_TO_LOAD_LIST = 0x020C210C

SPECIAL_OBJECT_CREATE_CODE_LIST = 0x02217288
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x02217598
#REUSED_SPECIAL_OBJECT_INFO = {
#  0x00 => {init_code: 0x020F4B6C},
#  0x01 => {init_code: 0x020F4B6C},
#  0x1A => {init_code: 0x020F4E84}, # portrait
#  0x22 => {sprite: 0x022B36E8, gfx_wrapper: 0x020BFF24, palette: 0x022B7660},
#  0x76 => {init_code: 0x020F4E90}, # portrait
#  0x82 => {sprite: 0x022B36E8, gfx_wrapper: 0x020BFF24, palette: 0x022B7660},
#  0x86 => {init_code: 0x020F4E84}, # portrait
#  0x87 => {init_code: 0x020F4E90}, # portrait
#  0xB6 => {init_code: 0x0221B9C0},
#  0xB7 => {init_code: 0x0221B9D0},
#  0xB8 => {init_code: 0x0221B9E0},
#  0xB9 => {init_code: 0x0221B9F0},
#  0xBA => {init_code: 0x0221BA00},
#  0xBB => {init_code: 0x0221BA10},
#  0xBC => {init_code: 0x0221BA20},
#  0xBD => {init_code: 0x0221BA30},
#  0xBE => {init_code: 0x0221BA40},
#}
SPECIAL_OBJECT_FILES_TO_LOAD_LIST = 0x020D6218

WEAPON_GFX_LIST_START = 0x02218A98
SKILL_GFX_LIST_START = 0x022186A0

#OTHER_SPRITES = [
#  {desc: "Common", sprite: 0x022B36E8, gfx_wrapper: 0x020BFF24, palette: 0x022B7660},
#  
#  {pointer: 0x0221E7F4, desc: "Jonathan player"},
#  {pointer: 0x0221E84C, desc: "Charlotte player"},
#  {pointer: 0x0221E8A4, desc: "Stella player"},
#  {pointer: 0x0221E8FC, desc: "Loretta player"},
#  {pointer: 0x0221E950, desc: "Richter player"},
#  {pointer: 0x0221E9AC, desc: "Maria player"},
#  {pointer: 0x0221EA04, desc: "Old Axe Armor player"},
#  
#  {pointer: 0x020F4B58, desc: "Destructibles 0"},
#  {pointer: 0x020F4B6C, desc: "Destructibles 1"},
#  {pointer: 0x020F4B80, desc: "Destructibles 2"},
#  {pointer: 0x020F4B94, desc: "Destructibles 3"},
#  {pointer: 0x020F4BA8, desc: "Destructibles 4"},
#  {pointer: 0x020F4BBC, desc: "Destructibles 5"},
#  {pointer: 0x020F4BD0, desc: "Destructibles 6"},
#  {pointer: 0x020F4BE4, desc: "Destructibles 7"},
#  {pointer: 0x020F4BF8, desc: "Destructibles 8"},
#  {pointer: 0x020F4C0C, desc: "Destructibles 9"},
#  {pointer: 0x020F4C20, desc: "Destructibles 10"},
#  {pointer: 0x020F4C34, desc: "Destructibles 11"},
#  {pointer: 0x020F4C48, desc: "Destructibles 12"},
#  {pointer: 0x020F4C5C, desc: "Destructibles 13"},
#  {pointer: 0x020F4C70, desc: "Destructibles 14"},
#  {pointer: 0x020F4C84, desc: "Destructibles 15"},
#  {pointer: 0x020F4E84, desc: "Portrait frame 0"},
#  {pointer: 0x020F4E90, desc: "Portrait frame 1"},
#  {pointer: 0x020F4E9C, desc: "Portrait painting 0"},
#  {pointer: 0x020F4EA8, desc: "Portrait painting 1"},
#  {pointer: 0x020F4EB4, desc: "Portrait painting ???"}, # broken
#  {pointer: 0x020F4EC0, desc: "Portrait painting 3"},
#  
#  {pointer: 0x0206E4C8, desc: "Breakable walls 1", gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1},
#  {pointer: 0x0206E4C8, desc: "Breakable walls 2", gfx_sheet_ptr_index: 4, palette_list_ptr_index: 4, sprite_ptr_index: 4},
#  {pointer: 0x0206E4C8, desc: "Breakable walls 3", gfx_sheet_ptr_index: 0, palette_list_ptr_index: 0, sprite_ptr_index: 0},
#  {pointer: 0x0206E4C8, desc: "Breakable walls 4", gfx_sheet_ptr_index: 5, palette_list_ptr_index: 5, sprite_ptr_index: 5},
#  {pointer: 0x0206E4C8, desc: "Breakable walls 5", gfx_sheet_ptr_index: 6, palette_list_ptr_index: 6, sprite_ptr_index: 6},
#  {pointer: 0x0206E4C8, desc: "Breakable walls 6", gfx_sheet_ptr_index: 2, palette_list_ptr_index: 2, sprite_ptr_index: 2},
#  {pointer: 0x0206E4C8, desc: "Breakable walls 7", gfx_sheet_ptr_index: 7, palette_list_ptr_index: 7, sprite_ptr_index: 7},
#  {pointer: 0x0206E4C8, desc: "Breakable walls 8", gfx_sheet_ptr_index: 3, palette_list_ptr_index: 3, sprite_ptr_index: 3},
#  
#  {pointer: 0x022E0700, desc: "Title screen graphics", overlay: 26},
#  {pointer: 0x022E0710, desc: "Title screen options", overlay: 26},
#  {pointer: 0x022DA15C, desc: "Select data menu", overlay: 25},
#  {pointer: 0x022DAAE0, desc: "Name entry menu", overlay: 25},
#  {pointer: 0x022DEE20, desc: "Co-op mode start menu", overlay: 25},
#  {pointer: 0x022DC9AC, desc: "Co-op mode end menu", overlay: 25},
#  {pointer: 0x0203BCBC, desc: "Equip menu", one_dimensional_mode: true},
#  
#  {pointer: 0x022D7CBC, desc: "Brauner inside mirror portrait", overlay: 55},
#  {pointer: 0x022D7C98, desc: "Brauner curse beast", overlay: 55},
#]
#
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
  "Misc" => (0x4D7..0x50F),
  "Menus" => (0x510..0x6AD),
  "Events" => (0x6AE..0x737),
  "Debug" => (0x738..0x738)
}
#STRING_DATABASE_START_OFFSET = 0x0221F680
#STRING_DATABASE_ORIGINAL_END_OFFSET = 0x0222C835
#STRING_DATABASE_ALLOWABLE_END_OFFSET = STRING_DATABASE_ORIGINAL_END_OFFSET

## Note: the below are not actually where the original game stores the indexes. All three of those are at 02051F88 (since all three are the same: 00). The three addresses below are free space reused for the purpose of allowing the three values to be different.
#NEW_GAME_STARTING_AREA_INDEX_OFFSET = 0x020BFC00
#NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x020BFC08
#NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x020BFC0C

#FAKE_TRANSITION_ROOMS = [0x020E7F18] # This room is marked as a transition room, but it's not actually.

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
    list_pointer: 0x020D6528,
    count: 42,
    format: ARMOR_FORMAT # length: 24
  },
  {
    name: "Skills",
    list_pointer: 0x020D8538,
    count: 108,
    is_skill: true,
    format: SKILL_FORMAT # length: 24
  },
]
