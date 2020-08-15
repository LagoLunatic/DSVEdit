
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

ROOM_OVERLAYS = (ROOM_OVERLAYS.begin-1..ROOM_OVERLAYS.end-1)

AREAS_OVERLAY = AREAS_OVERLAY-1
MAPS_OVERLAY = MAPS_OVERLAY-1

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
MAP_SIZES_LIST_START_OFFSET = 0x020B619C
MAP_DRAW_OFFSETS_LIST_START_OFFSET = 0x020D8EC8
MAP_SECRET_DOOR_LIST_START_OFFSET = 0x020D8F24
MAP_ROW_WIDTHS_LIST_START_OFFSET = 0x020D9114

AREA_MUSIC_LIST_START_OFFSET = 0x020D75D8
SECTOR_MUSIC_LIST_START_OFFSET = 0x020D7554
SONG_INDEX_TO_TEXT_INDEX = [
  "Silence",
  0x602,
  0x603,
  0x604,
  0x605,
  0x606,
  0x607,
  0x608,
  0x609,
  0x60A,
  0x60B,
  0x60C,
  0x60D,
  "Ambience",
  0x60E,
  0x60F,
  0x610,
  0x611,
  0x612,
  0x613,
  0x614,
  0x615,
  0x616,
  0x617,
  0x618,
  0x619,
  0x61A,
  0x61B,
  0x61C,
  0x61D,
  0x61E,
  0x61F,
  0x620,
  0x621,
  0x622,
  0x623,
  0x624,
  0x625,
  0x626,
  0x627,
  0x628,
  0x629,
  0x62A,
  0x62B,
  0x62C,
  0x62D,
  0x62E,
  0x62F,
  0x630,
  0x631,
  "Suspicions",
  "Welcome to Legend (Alt?)",
  "The Beginning",
  0x632,
  0x633,
  0x634,
  0x635,
  0x636,
  0x637,
  0x638,
  0x639,
  0x63A,
]

ASSET_LIST_START = 0x020DA694
ASSET_LIST_END = 0x020EE3B3

ENEMY_DNA_RAM_START_OFFSET = 0x020B63D4

REUSED_ENEMY_INFO[0x23] = {init_code: 0x022502A0, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1} # black fomor -> white fomor
REUSED_ENEMY_INFO[0x34] = {init_code: 0x0228CF30, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0} # automaton zx26
REUSED_ENEMY_INFO[0x48] = {init_code: 0x0224E15C, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1} # ghoul -> zombie
REUSED_ENEMY_INFO[0x4C] = {init_code: 0x0228B8B0, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0} # black panther -> ladycat
REUSED_ENEMY_INFO[0x5D] = {init_code: 0x02241CC8, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0} # bugbear
REUSED_ENEMY_INFO[0x5F] = {init_code: 0x0228CF30, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0} # automaton zx27
REUSED_ENEMY_INFO[0x62] = {init_code: 0x02206F84, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1, sprite_ptr_index: 1} # mad snatcher -> mad butcher
ENEMY_FILES_TO_LOAD_LIST = 0x020F31C8

COMMON_SPRITE = {desc: "Common", sprite: 0x020C4E94, gfx_files: [0x020B87F8, 0x020B8804, 0x020B8810, 0x020B881C, 0x020B8828, 0x020B8840, 0x020B8888, 0x020B8894], palette: 0x020C8EC0}

SPECIAL_OBJECT_CREATE_CODE_LIST = 0x020F40C0
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x020F42F4
REUSED_SPECIAL_OBJECT_INFO[0x01] = COMMON_SPRITE # magnes point
REUSED_SPECIAL_OBJECT_INFO[0x02] = {init_code: 0x022B6A60} # destructible
REUSED_SPECIAL_OBJECT_INFO[0x16] = {init_code: 0x0221A158, palette_offset: 1} # red chest
REUSED_SPECIAL_OBJECT_INFO[0x17] = {init_code: 0x0221A158, palette_offset: 2} # blue chest
REUSED_SPECIAL_OBJECT_INFO[0x2B] = COMMON_SPRITE # area exit
REUSED_SPECIAL_OBJECT_INFO[0x2D] = COMMON_SPRITE # wygol wooden door
REUSED_SPECIAL_OBJECT_INFO[0x2E] = COMMON_SPRITE # wooden door
REUSED_SPECIAL_OBJECT_INFO[0x4B] = COMMON_SPRITE # boss door
REUSED_SPECIAL_OBJECT_INFO[0x4D] = COMMON_SPRITE # ecclesia wooden door
REUSED_SPECIAL_OBJECT_INFO[0x55] = {sprite: 0x021DC6E0, gfx_files: [0x020B8354, 0x020B8360, 0x020B836C, 0x020B8378, 0x020B8384, 0x020B8390, 0x020B839C, 0x020B83A8, 0x020B83B4, 0x020B83C0, 0x020B83CC, 0x020B83D8, 0x020B83E4, 0x020B83F0], palette: 0x020D723C} # area titles
REUSED_SPECIAL_OBJECT_INFO[0x5C] = {sprite: 0x021DC954, gfx_files: [0x020BA370], palette: 0x020D158C} # breakable wall

SPECIAL_OBJECT_FILES_TO_LOAD_LIST = 0x020F3DF0

SKILL_GFX_LIST_START = 0x020D9C34
MELEE_GLYPH_CODE_POINTERS = [0x020793D4, 0x020A7EFC, 0x020A82EC, 0x020A82FC, 0x020A830C]

OTHER_SPRITES = [
  COMMON_SPRITE,
  {desc: "Explosion", sprite: 0x021DCC4C, gfx_files: [0x020B88A0], palette: 0x020C8EC0},
  
  {pointer: 0x020D939C, desc: "Shanoa player"},
  {pointer: 0x020D93F8, desc: "Arma Felix player"},
  {pointer: 0x020D9454, desc: "Arma Chiroptera player"},
  {pointer: 0x020D94B0, desc: "Arma Machina player"},
  {pointer: 0x020D950C, desc: "Albus player"},
  
  {desc: "Albus event actor", sprite: 0x021DC8E4, palette: 0x020D4FAC, gfx_wrapper: 0x022A588C},
  {desc: "Barlowe event actor", sprite: 0x021DC8E0, palette: 0x020D4FD0, gfx_wrapper: 0x022A5894},
  {desc: "Nikolai event actor", sprite: 0x021DC8DC, palette: 0x020D5034, gfx_wrapper: 0x022A58A4},
  {desc: "Jacob event actor", sprite: 0x021DC8D8, palette: 0x020D5058, gfx_wrapper: 0x022A58B4},
  {desc: "Abram event actor", sprite: 0x021DC8D4, palette: 0x020D507C, gfx_wrapper: 0x022A58CC},
  {desc: "Laura event actor", sprite: 0x021DC8D0, palette: 0x020D50A0, gfx_wrapper: 0x022A58D4},
  {desc: "Eugen event actor", sprite: 0x021DC8CC, palette: 0x020D50C4, gfx_wrapper: 0x022A58E4},
  {desc: "Aeon event actor", sprite: 0x021DC8C8, palette: 0x020D50E8, gfx_wrapper: 0x022A5874},
  {desc: "Marcel event actor", sprite: 0x021DC8C4, palette: 0x020D510C, gfx_wrapper: 0x022A5884},
  {desc: "George event actor", sprite: 0x021DC8C0, palette: 0x020D5130, gfx_wrapper: 0x022A589C},
  {desc: "Serge event actor", sprite: 0x021DC8BC, palette: 0x020D5154, gfx_wrapper: 0x022A58BC},
  {desc: "Anna event actor", sprite: 0x021DC8B8, palette: 0x020D5178, gfx_wrapper: 0x022A58DC},
  {desc: "Monica event actor", sprite: 0x021DC8B4, palette: 0x020D519C, gfx_wrapper: 0x022A587C},
  {desc: "Irina event actor", sprite: 0x021DC8B0, palette: 0x020D51C0, gfx_wrapper: 0x022A58AC},
  {desc: "Daniela event actor", sprite: 0x021DC8AC, palette: 0x020D51E4, gfx_wrapper: 0x022A58EC},
  {desc: "Dracula event actor", sprite: 0x021DC6E8, palette: 0x022CE604, gfx_wrapper: 0x022A58C4, overlay: 75-1},
  
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
  
  {pointer: 0x022196D0, desc: "Title screen 1", overlay: 20-1},
  {pointer: 0x022196E8, desc: "Title screen 2", overlay: 20-1},
  {pointer: 0x02219700, desc: "Title screen 3", overlay: 20-1},
  {desc: "Main menu", gfx_files: [0x020BA508, 0x020BA514, 0x020BA520, 0x020BA55C, 0x020BA5B0, 0x020BA604, 0x020BA658, 0x020BA6AC, 0x020BA6D0, 0x020BA6DC], sprite: 0x021DC91C, palette: 0x020D1BF4},
  {desc: "Pause menu", gfx_files: [0x020BA478, 0x020BA484, 0x020BA490, 0x020BA49C, 0x020BA4F0, 0x020BA4FC], sprite: 0x021DC920, palette: 0x020D19F0},
  
  {desc: "Map", sprite: 0x020C55AC, gfx_files: [0x020BA7FC], palette: 0x020D2420, one_dimensional_mode: true},
  
  {desc: "World Map", sprite: 0x021DC918, gfx_files: [0x020BA6E8, 0x020BA6F4, 0x020BA700, 0x020BA70C, 0x020BA718, 0x020BA724, 0x020BA730], palette: 0x020D1EF8},
]

CANDLE_SPRITE = COMMON_SPRITE
MONEY_SPRITE = COMMON_SPRITE

TEXT_LIST_START_OFFSET = 0x021FDDA0
TEXT_RANGE = (0..0x781)
TEXT_REGIONS = {
  "Character Names" => (0..0x15),
  "Item Names" => (0x16..0x177),
  "Item Descriptions" => (0x178..0x2D9),
  "Enemy Names" => (0x2DA..0x352),
  "Enemy Descriptions" => (0x353..0x3CB),
  "Music Names (Unused)" => (0x3CC..0x3E8),
  "System" => (0x3E9..0x424),
  "Menus 1" => (0x425..0x551),
  "Quest Names" => (0x552..0x575),
  "Menus 2" => (0x576..0x584),
  "Term List" => (0x585..0x5BE),
  "Area Names" => (0x5BF..0x5DE),
  "Quest Descriptions" => (0x5DF..0x601),
  "Music Names" => (0x602..0x63A),
  "Menus 3" => (0x63B..0x67C),
  "Events" => (0x67D..0x781)
}
TEXT_REGIONS_OVERLAYS = {
  "Character Names" => 0,
  "Item Names" => 0,
  "Item Descriptions" => 0,
  "Enemy Names" => 0,
  "Enemy Descriptions" => 0,
  "Music Names (Unused)" => 0,
  "System" => 0,
  "Menus 1" => 0,
  "Quest Names" => 0,
  "Menus 2" => 0,
  "Term List" => 0,
  "Area Names" => 0,
  "Quest Descriptions" => 0,
  "Music Names" => 0,
  "Menus 3" => 0,
  "Events" => 0
}
STRING_DATABASE_START_OFFSET = 0x021DCEA0
STRING_DATABASE_ORIGINAL_END_OFFSET = 0x021FDD88
STRING_DATABASE_ALLOWABLE_END_OFFSET = STRING_DATABASE_ORIGINAL_END_OFFSET

NAMES_FOR_UNNAMED_SKILLS = {}

NEW_GAME_STARTING_AREA_INDEX_OFFSET = 0x020ABFF0
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x020ABFF8
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x020AC000
NEW_GAME_STARTING_X_POS_OFFSET = 0x020D7640
NEW_GAME_STARTING_Y_POS_OFFSET = 0x020D7644

FAKE_TRANSITION_ROOMS = [0x022ADF68, 0x022A7A38]

ITEM_ICONS_PALETTE_POINTER = 0x020D17EC
GLYPH_ICONS_PALETTE_POINTER = 0x020C98C4

ITEM_TYPES = [
  {
    name: "Arm Glyphs",
    list_pointer: 0x020F14D8,
    count: 55,
    kind: :skill,
    format: ARM_GLYPH_FORMAT
  },
  {
    name: "Back Glyphs",
    list_pointer: 0x020F039C,
    count: 25,
    kind: :skill,
    format: BACK_GLYPH_FORMAT
  },
  {
    name: "Glyph Unions",
    list_pointer: 0x020F0C34,
    count: 31,
    kind: :skill,
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

PLAYER_LIST_POINTER = 0x020D939C

NEW_OVERLAY_ID = 85
NEW_OVERLAY_FREE_SPACE_START = 0x022EAD60
NEW_OVERLAY_FREE_SPACE_MAX_SIZE = 0x32000
ASSET_MEMORY_START_HARDCODED_LOCATION = 0x02007354

TEST_ROOM_SAVE_FILE_INDEX_LOCATION = 0x022130E8 + 0x10
TEST_ROOM_AREA_INDEX_LOCATION      = 0x022130E8 + 0x30
TEST_ROOM_SECTOR_INDEX_LOCATION    = 0x022130E8 + 0x38
TEST_ROOM_ROOM_INDEX_LOCATION      = 0x022130E8 + 0x40
TEST_ROOM_X_POS_LOCATION           = 0x022130E8 + 0xA0
TEST_ROOM_Y_POS_LOCATION           = 0x022130E8 + 0xA4
TEST_ROOM_OVERLAY = TEST_ROOM_OVERLAY-1

SHOP_ITEM_POOL_LIST = 0x02222634
SHOP_HARDCODED_ITEM_POOLS = [
  {
    requirement: nil,
    items: {
      0x021FFFA4 => :arm_shifted_immediate,
      0x021FFFB0 => :arm_shifted_immediate,
      0x021FFFBC => :arm_shifted_immediate,
      0x021FFFC8 => :arm_shifted_immediate,
      0x021FFFD4 => :arm_shifted_immediate,
      0x02200144 => :word, # loaded by 0x021FFFE0
      0x021FFFEC => :arm_shifted_immediate,
    }
  },
  {
    requirement: 0x0220001C,
    items: {
      0x02200148 => :word, # loaded by 0x02200028 and 0x02200000
      0x02200150 => :word, # loaded by 0x02200034
      0x02200154 => :word, # loaded by 0x02200040
    }
  },
  {
    requirement: 0x02200070,
    items: {
      0x02200158 => :word, # loaded by 0x0220007C and 0x02200054
      0x02200088 => :arm_shifted_immediate,
      0x0220015C => :word, # loaded by 0x02200094
    }
  },
]

FAKE_FREE_SPACES = [
  {path: "/ftc/overlay9_45", offset: 0x022E467C-0x022C1BA0, length: 0xC0}, # Used by object 5A
  {path: "/ftc/overlay9_52", offset: 0x022CD480-0x022C1BA0, length: 0xC}, # Used by object 28 (really 9 bytes are used, but I round it up to be safe)
]

QUEST_LIST_POINTER = 0x020DA2C0

MENU_BG_LAYER_INFOS = [
  # TODO
]
