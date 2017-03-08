
# This file is loaded after the USA constants file. It only needs to specify things that are different from the USA version.

REGION = :jp

# Overlays in the Japanese version of OoE are shifted down by 1 compared to the US version.
# This is because the US version uses overlay 0 for English text and overlay 1 for French text, but the Japanese version only has one text overlay: overlay 0.
# So we need to shift all overlay ids down by 1 (except for 0).

# Overlays 39 to 84.
AREA_INDEX_TO_OVERLAY_INDEX = AREA_INDEX_TO_OVERLAY_INDEX.map do |area_index, old_hash|
  new_hash = old_hash.map do |sector_index, overlay|
    [sector_index, overlay-1]
  end.to_h
  [area_index, new_hash]
end.to_h

CONSTANT_OVERLAYS = CONSTANT_OVERLAYS.map{|overlay| overlay-1}

# Overlays 23 to 37 are used for enemies.
OVERLAY_FILE_FOR_ENEMY_AI = OVERLAY_FILE_FOR_ENEMY_AI.map do |enemy_id, overlay|
  if overlay.is_a?(Array)
    [enemy_id, overlay.map{|overlay| overlay-1}]
  else
    [enemy_id, overlay-1]
  end
end.to_h

OVERLAY_FILE_FOR_SPECIAL_OBJECT = OVERLAY_FILE_FOR_SPECIAL_OBJECT.map do |object_id, overlay|
  if overlay.is_a?(Array)
    [object_id, overlay.map{|overlay| overlay-1}]
  else
    [object_id, overlay-1]
  end
end.to_h

AREA_LIST_RAM_START_OFFSET = 0x020D8FC4

MAP_TILE_METADATA_LIST_START_OFFSET = 0x020D906C
MAP_TILE_LINE_DATA_LIST_START_OFFSET = 0x020D90C0
MAP_LENGTH_DATA_START_OFFSET = 0x020B6174
MAP_SECRET_DOOR_LIST_START_OFFSET = 0x020D8F24

AREA_MUSIC_LIST_START_OFFSET = 0x020D75D8
SECTOR_MUSIC_LIST_START_OFFSET = 0x020D7554

LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET = 0x020DA694
LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET = 0x020EE3B3

ENEMY_DNA_RAM_START_OFFSET = 0x020B63D4

REUSED_ENEMY_INFO[0x23] = {init_code: 0x022502A0, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1} # black fomor -> white fomor
REUSED_ENEMY_INFO[0x34] = {init_code: 0x0228CF30, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0} # automaton zx26
REUSED_ENEMY_INFO[0x48] = {init_code: 0x0224E15C, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1} # ghoul -> zombie
REUSED_ENEMY_INFO[0x4C] = {init_code: 0x0228B8B0, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0} # black panther -> ladycat
REUSED_ENEMY_INFO[0x5D] = {init_code: 0x02241CC8, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0} # bugbear
REUSED_ENEMY_INFO[0x5F] = {init_code: 0x0228CF30, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0} # automaton zx27
REUSED_ENEMY_INFO[0x62] = {init_code: 0x02206F84, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1, sprite_ptr_index: 1} # mad snatcher -> mad butcher
ENEMY_FILES_TO_LOAD_LIST = 0x020F31C8

SPECIAL_OBJECT_CREATE_CODE_LIST = 0x020F40C0
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x020F42F4
REUSED_SPECIAL_OBJECT_INFO[0x01] = {sprite: 0x020C4E94, gfx_files: [0x020B87F8, 0x020B8804, 0x020B8810, 0x020B881C, 0x020B8828, 0x020B8840, 0x020B8888, 0x020B8894], palette: 0x020C8EC0} # magnes point
REUSED_SPECIAL_OBJECT_INFO[0x02] = {init_code: 0x022B6A60} # destructible
#  0x16 => {init_code: 0x0221A408, palette_offset: 1}, # red chest
#  0x17 => {init_code: 0x0221A408, palette_offset: 2}, # blue chest
REUSED_SPECIAL_OBJECT_INFO[0x2E] = {sprite: 0x020C4E94, gfx_files: [0x020B87F8, 0x020B8804, 0x020B8810, 0x020B881C, 0x020B8828, 0x020B8840, 0x020B8888, 0x020B8894], palette: 0x020C8EC0} # wooden door
#  0x36 => {init_code:         -1}, # transition room hider TODO
REUSED_SPECIAL_OBJECT_INFO[0x4B] = {sprite: 0x020C4E94, gfx_files: [0x020B87F8, 0x020B8804, 0x020B8810, 0x020B881C, 0x020B8828, 0x020B8840, 0x020B8888, 0x020B8894], palette: 0x020C8EC0} # boss door
#  0x55 => {sprite: 0x021DCAC0, gfx_files: [0x020B838C, 0x020B8398, 0x020B83A4, 0x020B83B0, 0x020B83BC, 0x020B83C8, 0x020B83D4, 0x020B83E0, 0x020B83EC, 0x020B83F8, 0x020B8404, 0x020B8410, 0x020B841C, 0x020B8428], palette: 0x020D73D0}, # area titles

SPECIAL_OBJECT_FILES_TO_LOAD_LIST = 0x020F3DF0

SKILL_GFX_LIST_START = 0x020D9C34

OTHER_SPRITES = [
  {desc: "Common", sprite: 0x020C4E94, gfx_files: [0x020B87F8, 0x020B8804, 0x020B8810, 0x020B881C, 0x020B8828, 0x020B8840, 0x020B8888, 0x020B8894], palette: 0x020C8EC0},
  {desc: "Explosion", sprite: 0x021DCC4C, gfx_files: [0x020B88A0], palette: 0x020C8EC0},
  
  {pointer: 0x020D939C, desc: "Shanoa player"},
  {pointer: 0x020D93F8, desc: "Arma Felix player"},
  {pointer: 0x020D9454, desc: "Arma Chiroptera player"},
  {pointer: 0x020D94B0, desc: "Arma Machina player"},
  {pointer: 0x020D950C, desc: "Albus player"},
  
  #{desc: "Albus event actor", sprite: 0x021DCCC4, palette: 0x020D4F3C, gfx_wrapper: 0x022A5CCC},
  #{desc: "Barlowe event actor", sprite: 0x021DCCC0, palette: 0x020D4F60, gfx_wrapper: 0x022A5CD4},
  #{desc: "Nikolai event actor", sprite: 0x021DCCBC, palette: 0x020D4FC4, gfx_wrapper: 0x022A5CE4},
  #{desc: "Jacob event actor", sprite: 0x021DCCB8, palette: 0x020D4FE8, gfx_wrapper: 0x022A5CF4},
  #{desc: "Abram event actor", sprite: 0x021DCCB4, palette: 0x020D500C, gfx_wrapper: 0x022A5D0C},
  #{desc: "Laura event actor", sprite: 0x021DCCB0, palette: 0x020D5030, gfx_wrapper: 0x022A5D14},
  #{desc: "Eugen event actor", sprite: 0x021DCCAC, palette: 0x020D5054, gfx_wrapper: 0x022A5D24},
  #{desc: "Aeon event actor", sprite: 0x021DCCA8, palette: 0x020D5078, gfx_wrapper: 0x022A5CB4},
  #{desc: "Marcel event actor", sprite: 0x021DCCA4, palette: 0x020D509C, gfx_wrapper: 0x022A5CC4},
  #{desc: "George event actor", sprite: 0x021DCCA0, palette: 0x020D50C0, gfx_wrapper: 0x022A5CDC},
  #{desc: "Serge event actor", sprite: 0x021DCC9C, palette: 0x020D50E4, gfx_wrapper: 0x022A5CFC},
  #{desc: "Anna event actor", sprite: 0x021DCC98, palette: 0x020D5108, gfx_wrapper: 0x022A5D1C},
  #{desc: "Monica event actor", sprite: 0x021DCC94, palette: 0x020D512C, gfx_wrapper: 0x022A5CBC},
  #{desc: "Irina event actor", sprite: 0x021DCC90, palette: 0x020D5150, gfx_wrapper: 0x022A5CEC},
  #{desc: "Daniela event actor", sprite: 0x021DCC8C, palette: 0x020D5174, gfx_wrapper: 0x022A5D2C},
  #{desc: "Dracula event actor", sprite: 0x021DCAC8, palette: 0x022CEA40, gfx_wrapper: 0x022A5D04, overlay: 75},
  
  {pointer: 0x022B6970, desc: "Glyph statue"},
  {pointer: 0x022B6984, desc: "Destructibles 0"},
  {pointer: 0x022B6998, desc: "Destructibles 1"},
  {pointer: 0x022B69AC, desc: "Destructibles 2"},
  {pointer: 0x022B69C0, desc: "Destructibles 3"},
  {pointer: 0x022B69D4, desc: "Destructibles 4"},
  {pointer: 0x022B69E8, desc: "Destructibles 5"},
  {pointer: 0x022B69FC, desc: "Destructibles 6"},
  {pointer: 0x022B6A10, desc: "Destructibles 7"},
  {pointer: 0x022B6A24, desc: "Destructibles 8"},
  {pointer: 0x022B6A38, desc: "Destructibles 9"},
  {pointer: 0x022B6A4C, desc: "Destructibles 10"},
  {pointer: 0x022B6A60, desc: "Destructibles 11"},
  {pointer: 0x022B6A74, desc: "Destructibles 12"},
  
  {desc: "Breakable walls 0", sprite: 0x021DC96C, gfx_files: [0x020BA328], palette: 0x020D0FB4},
  {desc: "Breakable walls 1", sprite: 0x021DC968, gfx_files: [0x020BA334], palette: 0x020D1138},
  {desc: "Breakable walls 2", sprite: 0x021DC964, gfx_files: [0x020BA340], palette: 0x020D127C},
  {desc: "Breakable walls 3", sprite: 0x021DC960, gfx_files: [0x020BA34C], palette: 0x020D12E0},
  {desc: "Breakable walls 4", sprite: 0x021DC960, gfx_files: [0x020BA34C], palette: 0x020D12E0},
  {desc: "Breakable walls 5", sprite: 0x021DC95C, gfx_files: [0x020BA358], palette: 0x020D1444},
  {desc: "Breakable walls 6", sprite: 0x021DC95C, gfx_files: [0x020BA358], palette: 0x020D1444},
  {desc: "Breakable walls 7", sprite: 0x021DC958, gfx_files: [0x020BA364], palette: 0x020D14C8},
  {desc: "Breakable walls 8", sprite: 0x021DC954, gfx_files: [0x020BA370], palette: 0x020D158C},
]

TEXT_LIST_START_OFFSET = 0x021FDDA0
STRING_DATABASE_START_OFFSET = 0x021DCEA0
STRING_DATABASE_ORIGINAL_END_OFFSET = 0x021FDD88
STRING_DATABASE_ALLOWABLE_END_OFFSET = STRING_DATABASE_ORIGINAL_END_OFFSET

NAMES_FOR_UNNAMED_SKILLS = {}

NEW_GAME_STARTING_AREA_INDEX_OFFSET = 0x020ABFF0
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x020ABFF8
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x020AC000

#NEW_GAME_STARTING_TOP_SCREEN_TYPE_OFFSET = 0x02214F68 # TODO

FAKE_TRANSITION_ROOMS = [0x022ADF68, 0x022A7A38]

ITEM_ICONS_PALETTE_POINTER = 0x020D17EC
GLYPH_ICONS_PALETTE_POINTER = 0x020C98C4

ITEM_TYPES = [
  {
    name: "Arm Glyphs",
    list_pointer: 0x020F14D8,
    count: 55,
    is_skill: true,
    format: ARM_GLYPH_FORMAT
  },
  {
    name: "Back Glyphs",
    list_pointer: 0x020F039C,
    count: 25,
    is_skill: true,
    format: BACK_GLYPH_FORMAT
  },
  {
    name: "Glyph Unions",
    list_pointer: 0x020F0C34,
    count: 31,
    is_skill: true,
    format: GLYPH_UNION_FORMAT
  },
  {
    name: "Relics",
    list_pointer: 0x020EFF94,
    count: 6,
    format: RELIC_FORMAT
  },
  {
    name: "Consumables",
    list_pointer: 0x020F0F98,
    count: 112,
    format: CONSUMABLE_FORMAT
  },
  {
    name: "Body Armor",
    list_pointer: 0x020F0180,
    count: 27,
    format: ARMOR_FORMAT
  },
  {
    name: "Head Armor",
    list_pointer: 0x020F0658,
    count: 36,
    format: ARMOR_FORMAT
  },
  {
    name: "Leg Armor",
    list_pointer: 0x020EFFDC,
    count: 21,
    format: ARMOR_FORMAT
  },
  {
    name: "Accessories",
    list_pointer: 0x020F0928,
    count: 39,
    format: ARMOR_FORMAT
  },
  {
    name: "Weapons (Unused)",
    list_pointer: 0x020EFF5C,
    count: 2,
    format: WEAPON_FORMAT
  },
]

ITEM_POOLS_LIST_POINTER = 0x02223880
ITEM_POOL_INDEXES_FOR_AREAS_LIST_POINTER = 0x02223868
