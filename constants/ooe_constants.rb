
GAME = "ooe"
REGION = :usa
LONG_GAME_NAME = "Order of Ecclesia"

AREA_LIST_RAM_START_OFFSET = 0x020ECDDC

# Overlays 40 to 85.
AREA_INDEX_TO_OVERLAY_INDEX = {
  0 => {
    0 => 65,
    1 => 66,
    2 => 68,
    3 => 69,
    4 => 70,
    5 => 71,
    6 => 72,
    7 => 73,
    8 => 76,
    9 => 77,
    10 => 74,
    11 => 75,
    12 => 67,
  },
  1 => {
    0 => 40,
    1 => 41,
  },
  2 => {
    0 => 42,
  },
  3 => {
    0 => 43,
  },
  4 => {
    0 => 44,
  },
  5 => {
    0 => 45,
  },
  6 => {
    0 => 46,
    1 => 47,
  },
  7 => {
    0 => 48,
    1 => 49,
  },
  8 => {
    0 => 50,
    1 => 51,
    2 => 52,
  },
  9 => {
    0 => 53,
  },
  10 => {
    0 => 54,
    1 => 55,
  },
  11 => {
    0 => 56,
    1 => 57,
  },
  12 => {
    0 => 58,
  },
  13 => {
    0 => 59,
  },
  14 => {
    0 => 60,
  },
  15 => {
    0 => 61,
  },
  16 => {
    0 => 62,
    1 => 63,
  },
  17 => {
    0 => 64,
  },
  18 => {
    0 => 78,
    1 => 79,
  },
  19 => {
    0 => 80,
    1 => 81,
    2 => 82,
    3 => 83,
    4 => 84,
    5 => 85,
  }
}

AREA_INDEX_TO_AREA_NAME = {
   0 => "Dracula's Castle",
   1 => "Wygol Village",
   2 => "Ecclesia",
   3 => "Training Hall",
   4 => "Ruvas Forest",
   5 => "Argila Swamp",
   6 => "Kalidus Channel",
   7 => "Somnus Reef",
   8 => "Minera Prison Island",
   9 => "Lighthouse",
  10 => "Tymeo Mountains",
  11 => "Tristis Pass",
  12 => "Large Cavern",
  13 => "Giant's Dwelling",
  14 => "Mystery Manor",
  15 => "Misty Forest Road",
  16 => "Oblivion Ridge",
  17 => "Skeleton Cave",
  18 => "Monastery",
  19 => "Epilogue & Boss Rush Mode & Practice Mode"
}

SECTOR_INDEX_TO_SECTOR_NAME = {
  0 => {
     0 => "Castle Entrance",
     1 => "Castle Entrance",
     2 => "Underground Labyrinth",
     3 => "Library",
     4 => "Library (Kitchen)",
     5 => "Barracks",
     6 => "Mechanical Tower",
     7 => "Mechanical Tower",
     8 => "Arms Depot",
     9 => "Forsaken Cloister",
    10 => "Final Approach",
    11 => "Final Approach",
    12 => "Castle Entrance",
  },
}

ENTITY_TYPE_DESCRIPTIONS = {
  0 => "Nothing",
  1 => "Enemy",
  2 => "Special object",
  3 => "Candle",
  4 => "Pickup",
  5 => "???",
  6 => "???",
  7 => "Hidden pickup",
  8 => "Entity hider",
  9 => "???",
}

CONSTANT_OVERLAYS = [22]

ROOM_OVERLAYS = (40..85)
MAX_ALLOWABLE_ROOM_OVERLAY_SIZE = 168384

AREAS_OVERLAY = 19
MAPS_OVERLAY = 19

MAP_TILE_METADATA_LIST_START_OFFSET = 0x020ECE84
MAP_TILE_LINE_DATA_LIST_START_OFFSET = 0x020ECED8
MAP_LENGTH_DATA_START_OFFSET = 0x020B61C0
MAP_SIZES_LIST_START_OFFSET = 0x020B61E8
MAP_DRAW_OFFSETS_LIST_START_OFFSET = 0x020ECCE0
MAP_SECRET_DOOR_LIST_START_OFFSET = 0x020ECD3C
MAP_ROW_WIDTHS_LIST_START_OFFSET = 0x020ECF2C
MAP_MAX_NUM_WARPS = 8

AREA_MUSIC_LIST_START_OFFSET = 0x020D79D8
SECTOR_MUSIC_LIST_START_OFFSET = 0x020D7954
AVAILABLE_BGM_POOL_START_OFFSET = nil
SONG_INDEX_TO_TEXT_INDEX = [
  "Silence",
  0x5E4,
  0x5E5,
  0x5E6,
  0x5E7,
  0x5E8,
  0x5E9,
  0x5EA,
  0x5EB,
  0x5EC,
  0x5ED,
  0x5EE,
  0x5EF,
  "Ambience",
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
  0x5FD,
  0x5FE,
  0x5FF,
  0x600,
  0x601,
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
  0x60E,
  0x60F,
  0x610,
  0x611,
  0x612,
  0x613,
  "Suspicions",
  "Welcome to Legend (Alt?)",
  "The Beginning",
  0x614,
  0x615,
  0x616,
  0x617,
  0x618,
  0x619,
  0x61A,
  0x61B,
  0x61C,
]

MAP_FILL_COLOR = [160, 64, 128, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [0, 0, 248, 255]
MAP_SECRET_FILL_COLOR = [0, 128, 0, 255]
MAP_ENTRANCE_FILL_COLOR = [248, 128, 0, 255]
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [216, 216, 216, 255]
MAP_DOOR_CENTER_PIXEL_COLOR = [0, 0, 0, 0]
MAP_SECRET_DOOR_COLOR = [248, 248, 0, 255]

ASSET_LIST_START = 0x020D8CEC
ASSET_LIST_END = 0x020ECA0B
ASSET_LIST_ENTRY_LENGTH = 0x20

COLOR_OFFSETS_PER_256_PALETTE_INDEX = 256

ITEM_LOCAL_ID_RANGES = {}
ITEM_GLOBAL_ID_RANGE = (0x6F..0x161) # includes relics
SKILL_GLOBAL_ID_RANGE = (0..0x6E)
SKILL_LOCAL_ID_RANGE = (0..0x6E)
PICKUP_GLOBAL_ID_RANGE = (0..0x161)

PICKUP_SUBTYPES_FOR_ITEMS = (0xFF..0xFF)
PICKUP_SUBTYPES_FOR_SKILLS = (0x02..0x04)

ENEMY_IDS = (0x00..0x78).to_a
COMMON_ENEMY_IDS = (0x00..0x6A).to_a - [0x67]
BOSS_IDS = [0x67] + (0x6B..0x78).to_a

BOSS_DOOR_SUBTYPE = 0x4B
BOSS_ID_TO_BOSS_INDEX = {
  0x6B => 0x02, # Giant Skeleton
  0x6C => 0x01, # Arthroverta
  0x6D => 0x03, # Brachyura
  0x6E => 0x04, # Maneater
  0x6F => 0x05, # Rusalka
  0x70 => 0x06, # Goliath
  0x71 => 0x07, # Gravedorcus
  0x72 => 0x08, # Albus
  0x73 => 0x09, # Barlowe
  0x74 => 0x0A, # Wallman
  0x75 => 0x0B, # Blackmore
  0x76 => 0x0C, # Eligor
  0x77 => 0x0D, # Death
  0x78 => 0x0F, # Dracula
}

WOODEN_DOOR_SUBTYPE = 0x2E

AREA_NAME_SUBTYPE = 0x55

SAVE_POINT_SUBTYPE = 0x46
WARP_POINT_SUBTYPE = 0x34

ENEMY_DNA_RAM_START_OFFSET = 0x020B6364
ENEMY_DNA_FORMAT = [
  # length: 36
  [4, "Create Code"],
  [4, "Update Code"],
  [2, "Item 1"],
  [2, "Item 2"],
  [1, "Petrified Palette"],
  [1, "AP"],
  [2, "HP"],
  [2, "EXP"],
  [1, "Blood Color"],
  [1, "Unknown 3"],
  [2, "Glyph"],
  [1, "Glyph Chance"],
  [1, "Attack"],
  [1, "Physical Defense"],
  [1, "Magical Defense"],
  [1, "Item 1 Chance"],
  [1, "Item 2 Chance"],
  [4, "Weaknesses", :bitfield],
  [4, "Resistances", :bitfield],
]
ENEMY_DNA_BITFIELD_ATTRIBUTES = {
  "Weaknesses" => [
    "Strike",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Holy",
    "Dark",
    "Unknown 8",
    "Poison",
    "Curse",
    "Stone",
    "Torpor",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Made of flesh",
    "Unknown 17",
    "Unknown 18",
    "Unknown 19",
    "Unknown 20",
    "Unknown 21",
    "Unknown 22",
    "Unknown 23",
    "Unknown 24",
    "Unknown 25",
    "Arm glyphs",
    "Glyph unions",
    "Unknown 28",
    "Unknown 29",
    "Unknown 30",
    "Unknown 31",
    "Unknown 32",
  ],
  "Resistances" => [
    "Strike",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Holy",
    "Dark",
    "Unknown 8",
    "Poison",
    "Curse",
    "Stone",
    "Unknown 12",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
    "Unknown 17",
    "Unknown 18",
    "Unknown 19",
    "Unknown 20",
    "Unknown 21",
    "Unknown 22",
    "Unknown 23",
    "Unknown 24",
    "Unknown 25",
    "Unknown 26",
    "Unknown 27",
    "Unknown 28",
    "Unknown 29",
    "Unknown 30",
    "Unknown 31",
    "Don't load GFX",
  ],
}

# Overlays 24 to 38 are used for enemies.
OVERLAY_FILE_FOR_ENEMY_AI = {
  0x16 => 38, # the creature
  0x3C => 38, # owl
  0x41 => 38, # owl knight
  0x4E => 38, # draculina
  0x5E => 38, # spectral sword
  0x66 => 36, # final knight
  0x67 => 29, # jiang shi
  0x6C => 24, # arthroverta
  0x6D => 30, # brachyura
  0x6E => 26, # maneater
  0x6F => 27, # rusalka
  0x70 => 32, # goliath
  0x71 => 33, # gravedorcus
  0x72 => 36, # albus
  0x73 => 37, # barlowe
  0x74 => 28, # wallman
  0x75 => 35, # blackmore
  0x76 => 31, # eligor
  0x77 => 25, # death
  0x78 => [34, 75], # dracula. His palette is actually stored in one of the area overlays (75) instead of his enemy overlay (34).
}
REUSED_ENEMY_INFO = {
  0x23 => {init_code: 0x022505AC, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1}, # black fomor -> white fomor
  0x30 => {init_code:        nil, gfx_sheet_ptr_index: 0, palette_offset: 3, palette_list_ptr_index: 0}, # ladycat
  0x34 => {init_code: 0x0228D23C, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # automaton zx26
  0x48 => {init_code: 0x0224E468, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1}, # ghoul -> zombie
  0x4C => {init_code: 0x0228BBBC, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # black panther -> ladycat
  0x50 => {init_code:        nil, gfx_sheet_ptr_index: 0, palette_offset: 1, palette_list_ptr_index: 0}, # polkir
  0x54 => {init_code:        nil, gfx_sheet_ptr_index: 0, palette_offset: 3, palette_list_ptr_index: 0}, # gurkha master
  0x5D => {init_code: 0x02241FD4, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # bugbear
  0x5F => {init_code: 0x0228D23C, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # automaton zx27
  0x61 => {palette_offset: 2}, # gorgon head -> medusa head
  0x62 => {init_code: 0x02207208, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # mad snatcher -> mad butcher
  0x65 => {palette_offset: 1}, # winged skeleton -> winged guard
  0x69 => {palette_offset: 9}, # double hammer
  0x6A => {palette_offset: 0xC}, # weapon master
}
BEST_SPRITE_FRAME_FOR_ENEMY = {
  0x07 => 0x24, # nominon
  0x09 => 0x07, # une
  0x0E => 0x08, # invisible man
  0x11 => 0x1E, # demon
  0x15 => 0x10, # forneus
  0x16 => 0x6B, # the creature
  0x17 => 0x03, # black crow
  0x18 => 0x07, # skull spider
  0x1A => 0x1E, # sea demon
  0x1C => 0x04, # nightmare
  0x1E => 0x1E, # fire demon
  0x24 => 0x5A, # enkidu
  0x29 => 0x10, # skeleton rex
  0x2C => 0x05, # lorelai
  0x31 => 0x0F, # ectoplasm
  0x33 => 0x15, # miss murder
  0x35 => 0x17, # skeleton beast
  0x36 => 0x14, # balloon
  0x3B => 0x1E, # thunder demon
  0x3F => 0x0E, # mandragora
  0x41 => 0x0F, # owl knight
  0x47 => 0x06, # flea man
  0x49 => 0x26, # peeping eye
  0x4D => 0x07, # mimic
  0x50 => 0x24, # polkir
  0x54 => 0x14, # gurkha master
  0x55 => 0x14, # red smasher
  0x5A => 0x14, # hammer shaker
  0x5B => 0x4A, # rebuild
  0x5D => 0x27, # bugbear
  0x5F => 0x01, # automaton zx27
  0x60 => 0x02, # medusa head
  0x61 => 0x02, # gorgon head
  0x63 => 0x01, # great knight
  0x64 => 0x1D, # king skeleton
  0x66 => 0x01, # final knight
  0x68 => 0x1E, # demon lord
  0x69 => 0x14, # double hammer
  0x6A => 0x14, # weapon master
  0x6B => 0x06, # giant skeleton
  0x6C => 0x03, # arthroverta
  0x6D => 0x40, # brachyura
  0x6E => 0x07, # maneater
  0x70 => 0x4A, # goliath
  0x74 => 0x1D, # wallman
  0x75 => 0x1E, # blackmore
  0x77 => 0x17, # death
  0x78 => 0x38, # dracula
}
BEST_SPRITE_OFFSET_FOR_ENEMY = {
  0x54 => {x: -0x40, y: -0x80},
  0x55 => {x: -0x40, y: -0x80},
  0x5A => {x: -0x40, y: -0x80},
  0x69 => {x: -0x40, y: -0x80},
  0x6A => {x: -0x40, y: -0x80},
}

ENEMY_FILES_TO_LOAD_LIST = 0x020F2814

COMMON_SPRITE = {desc: "Common", sprite: 0x020C4E24, gfx_files: [0x020B8788, 0x020B8794, 0x020B87A0, 0x020B87AC, 0x020B87B8, 0x020B87D0, 0x020B8818, 0x020B8824], palette: 0x020C8E50}

SPECIAL_OBJECT_IDS = (0..0x8C)
SPECIAL_OBJECT_CREATE_CODE_LIST = 0x020F370C
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x020F3940
OVERLAY_FILE_FOR_SPECIAL_OBJECT = {
  0x18 => 71,
  0x19 => 57,
  0x1F => 68,
  0x23 => 43,
  0x25 => 62,
  0x27 => 51,
  0x28 => 53,
  0x2C => 41,
  0x2D => 40,
  0x2F => 53,
  0x38 => 46,
  0x3A => 46,
  0x3B => 55,
  0x3D => 69,
  0x40 => 78,
  0x43 => 65,
  0x44 => 68,
  0x45 => 55,
  0x47 => 57,
  0x48 => 57,
  0x49 => 57,
  0x4A => 57,
  0x4C => 52,
  0x4D => 42,
  0x4E => 42,
  0x4F => 63,
  0x50 => 76,
  0x51 => 77,
  0x53 => 72,
  0x54 => 60,
  0x57 => 72,
  0x58 => 41,
  0x59 => 66,
  0x5A => 46,
  0x5B => 46,
  0x5D => 84,
  0x60 => 42,
  0x61 => 42,
  0x62 => 42,
  0x63 => 42,
  0x64 => 42,
  0x65 => 42,
  0x66 => 78,
  0x67 => 41,
  0x68 => 41,
  0x69 => 51,
  0x6A => 42,
  0x6B => 53,
  0x6C => 64,
  0x6D => 64,
  0x6E => 41,
  0x6F => 59,
  0x70 => 42,
  0x71 => 62,
  0x72 => 62,
  0x73 => 42,
  0x74 => 60,
  0x75 => 60,
  0x76 => 60,
  0x77 => 42,
  0x78 => 42,
  0x79 => 60,
  0x7A => 42,
  0x7E => 67,
  0x7F => 67,
  0x85 => 75,
  0x86 => 75,
}
REUSED_SPECIAL_OBJECT_INFO = {
  0x00 => {init_code:         -1},
  0x01 => COMMON_SPRITE, # magnes point
  0x02 => {init_code: 0x022B6E98}, # destructible
  0x03 => {init_code:         -1},
  0x06 => {init_code:         -1},
  0x09 => {init_code: 0x02216CB4},
  0x0A => {init_code: 0x02216CB4},
  0x16 => {init_code: 0x0221A408, palette_offset: 1}, # red chest
  0x17 => {init_code: 0x0221A408, palette_offset: 2}, # blue chest
  0x18 => {init_code:         -1},
  0x19 => {init_code:         -1},
  0x1A => {init_code:         -1},
  0x1B => {init_code:         -1},
  0x1C => {init_code:         -1},
  0x22 => {init_code:         -1}, # movement slowing area
  0x23 => {init_code:         -1}, # volaticus blocker
  0x24 => {init_code:         -1}, # timed boss door opener
  0x2A => {init_code:         -1}, # moving platform waypoint
  0x2B => COMMON_SPRITE, # area exit
  0x2D => COMMON_SPRITE, # wygol wooden door
  0x2E => COMMON_SPRITE, # wooden door
  0x35 => {init_code:         -1},
  0x36 => {init_code:         -1}, # transition room hider TODO
  0x3A => {init_code:         -1},
  0x3E => {init_code:         -1},
  0x4B => COMMON_SPRITE, # boss door
  0x4D => COMMON_SPRITE, # ecclesia wooden door
  0x54 => {init_code:         -1},
  0x55 => {sprite: 0x021DCAC0, gfx_files: [0x020B838C, 0x020B8398, 0x020B83A4, 0x020B83B0, 0x020B83BC, 0x020B83C8, 0x020B83D4, 0x020B83E0, 0x020B83EC, 0x020B83F8, 0x020B8404, 0x020B8410, 0x020B841C, 0x020B8428], palette: 0x020D73D0}, # area titles
  0x5C => {sprite: 0x021DCD34, gfx_files: [0x020BA300], palette: 0x020D151C}, # breakable wall
  0x62 => {init_code:         -1},
  0x63 => {init_code:         -1},
  0x64 => {init_code:         -1},
  0x65 => {init_code:         -1},
  0x67 => {init_code:         -1},
  0x68 => {init_code:         -1},
  0x69 => {init_code:         -1},
  0x6A => {init_code:         -1},
  0x6B => {init_code:         -1},
  0x6C => {init_code:         -1},
  0x6D => {init_code:         -1},
  0x6E => {init_code:         -1},
  0x6F => {init_code:         -1},
  0x70 => {init_code:         -1},
  0x71 => {init_code:         -1},
  0x72 => {init_code:         -1},
  0x73 => {init_code:         -1},
  0x74 => {init_code:         -1},
  0x75 => {init_code:         -1},
  0x76 => {init_code:         -1},
  0x77 => {init_code:         -1},
  0x78 => {init_code:         -1},
  0x79 => {init_code:         -1},
  0x7A => {init_code:         -1},
  0x7B => {init_code:         -1},
  0x7C => {init_code:         -1},
  0x7D => {init_code:         -1},
  0x7E => {init_code:         -1},
  0x7F => {init_code:         -1},
  0x80 => {init_code:         -1},
  0x81 => {init_code:         -1},
  0x82 => {init_code:         -1},
  0x83 => {init_code:         -1},
  0x84 => {init_code:         -1},
  0x85 => {init_code:         -1},
  0x86 => {init_code:         -1},
  0x88 => {init_code:         -1},
  0x89 => {init_code:         -1},
  0x8A => {init_code:         -1},
  0x8B => {init_code:         -1},
  0x8C => {init_code:         -1},
}
BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT = {
  0x01 => 0x153,
  0x07 => 0x04,
  0x08 => 0x3B,
  0x09 =>   -1,
  0x0A => 0x1B,
  0x16 => 0x05,
  0x17 => 0x05,
  0x1D =>   -1,
  0x25 => 0x02,
  0x28 => 0x06,
  0x2B => 0x135,
  0x2D => 0xED,
  0x2E => 0xED,
  0x38 =>   -1,
  0x3D =>   -1,
  0x3F => 0x01,
  0x42 => 0x02,
  0x4B => 0xDF,
  0x4D => 0xED,
  0x4E => 0x09,
  0x57 =>   -1,
  0x58 =>   -1,
  0x59 => 0x01,
  0x5B => 0x02,
  0x60 => 0x06,
  0x61 =>   -1,
  0x66 =>   -1,
  0x87 =>   -1,
}
BEST_SPRITE_OFFSET_FOR_SPECIAL_OBJECT = {
  0x07 => {x: 4, y: -24},
  0x14 => {x: 8, y: 8},
  0x2E => {x: 8},
  0x4B => {x: 8},
  0x4D => {x: 8},
  0x4E => {x: 8, y: -32},
}
SPECIAL_OBJECT_FILES_TO_LOAD_LIST = 0x020F343C

WEAPON_GFX_LIST_START = nil
WEAPON_GFX_COUNT = 0
WEAPON_SPRITES_LIST_START = nil
WEAPON_PALETTE_LIST = nil
SKILL_GFX_LIST_START = 0x020F3BC0
SKILL_GFX_COUNT = 0x59
MELEE_GLYPH_CODE_POINTERS = [0x02070890, 0x020A6C68, 0x020A7058, 0x020A7068, 0x020A7078]

OTHER_SPRITES = [
  COMMON_SPRITE,
  {desc: "Explosion", sprite: 0x021DD02C, gfx_files: [0x020B8830], palette: 0x020C8E50},
  
  {pointer: 0x020EED5C, desc: "Shanoa player"},
  {pointer: 0x020EEDB8, desc: "Arma Felix player"},
  {pointer: 0x020EEE14, desc: "Arma Chiroptera player"},
  {pointer: 0x020EEE70, desc: "Arma Machina player"},
  {pointer: 0x020EEECC, desc: "Albus player", sprite: 0x021DCAEC},
  
  {desc: "Albus event actor", sprite: 0x021DCCC4, palette: 0x020D4F3C, gfx_wrapper: 0x022A5CCC},
  {desc: "Barlowe event actor", sprite: 0x021DCCC0, palette: 0x020D4F60, gfx_wrapper: 0x022A5CD4},
  {desc: "Nikolai event actor", sprite: 0x021DCCBC, palette: 0x020D4FC4, gfx_wrapper: 0x022A5CE4},
  {desc: "Jacob event actor", sprite: 0x021DCCB8, palette: 0x020D4FE8, gfx_wrapper: 0x022A5CF4},
  {desc: "Abram event actor", sprite: 0x021DCCB4, palette: 0x020D500C, gfx_wrapper: 0x022A5D0C},
  {desc: "Laura event actor", sprite: 0x021DCCB0, palette: 0x020D5030, gfx_wrapper: 0x022A5D14},
  {desc: "Eugen event actor", sprite: 0x021DCCAC, palette: 0x020D5054, gfx_wrapper: 0x022A5D24},
  {desc: "Aeon event actor", sprite: 0x021DCCA8, palette: 0x020D5078, gfx_wrapper: 0x022A5CB4},
  {desc: "Marcel event actor", sprite: 0x021DCCA4, palette: 0x020D509C, gfx_wrapper: 0x022A5CC4},
  {desc: "George event actor", sprite: 0x021DCCA0, palette: 0x020D50C0, gfx_wrapper: 0x022A5CDC},
  {desc: "Serge event actor", sprite: 0x021DCC9C, palette: 0x020D50E4, gfx_wrapper: 0x022A5CFC},
  {desc: "Anna event actor", sprite: 0x021DCC98, palette: 0x020D5108, gfx_wrapper: 0x022A5D1C},
  {desc: "Monica event actor", sprite: 0x021DCC94, palette: 0x020D512C, gfx_wrapper: 0x022A5CBC},
  {desc: "Irina event actor", sprite: 0x021DCC90, palette: 0x020D5150, gfx_wrapper: 0x022A5CEC},
  {desc: "Daniela event actor", sprite: 0x021DCC8C, palette: 0x020D5174, gfx_wrapper: 0x022A5D2C},
  {desc: "Dracula event actor", sprite: 0x021DCAC8, palette: 0x022CEA40, gfx_wrapper: 0x022A5D04, overlay: 75},
  
  {pointer: 0x022B6DA8, desc: "Glyph statue"},
  {pointer: 0x022B6DBC, desc: "Destructibles 0"},
  {pointer: 0x022B6DD0, desc: "Destructibles 1"},
  {pointer: 0x022B6DE4, desc: "Destructibles 2"},
  {pointer: 0x022B6DF8, desc: "Destructibles 3"},
  {pointer: 0x022B6E0C, desc: "Destructibles 4"},
  {pointer: 0x022B6E20, desc: "Destructibles 5"},
  {pointer: 0x022B6E34, desc: "Destructibles 6"},
  {pointer: 0x022B6E48, desc: "Destructibles 7"},
  {pointer: 0x022B6E5C, desc: "Destructibles 8"},
  {pointer: 0x022B6E70, desc: "Destructibles 9"},
  {pointer: 0x022B6E84, desc: "Destructibles 10"},
  {pointer: 0x022B6E98, desc: "Destructibles 11"},
  {pointer: 0x022B6EAC, desc: "Destructibles 12"},
  
  {desc: "Breakable walls 0", sprite: 0x021DCD4C, gfx_files: [0x020BA2B8], palette: 0x020D0F44},
  {desc: "Breakable walls 1", sprite: 0x021DCD48, gfx_files: [0x020BA2C4], palette: 0x020D10C8},
  {desc: "Breakable walls 2", sprite: 0x021DCD44, gfx_files: [0x020BA2D0], palette: 0x020D120C},
  {desc: "Breakable walls 3", sprite: 0x021DCD40, gfx_files: [0x020BA2DC], palette: 0x020D1270},
  {desc: "Breakable walls 4", sprite: 0x021DCD40, gfx_files: [0x020BA2DC], palette: 0x020D1270},
  {desc: "Breakable walls 5", sprite: 0x021DCD3C, gfx_files: [0x020BA2E8], palette: 0x020D13D4},
  {desc: "Breakable walls 6", sprite: 0x021DCD3C, gfx_files: [0x020BA2E8], palette: 0x020D13D4},
  {desc: "Breakable walls 7", sprite: 0x021DCD38, gfx_files: [0x020BA2F4], palette: 0x020D1458},
  {desc: "Breakable walls 8", sprite: 0x021DCD34, gfx_files: [0x020BA300], palette: 0x020D151C},
  
  {pointer: 0x0221BBB0, desc: "Title screen 1", overlay: 20},
  {pointer: 0x0221BBC8, desc: "Title screen 2 Japanese", overlay: 20},
  {pointer: 0x0221BBC8, desc: "Title screen 2 English", gfx_files: [0x020BED2C, 0x020BED38, 0x020BED44, 0x020BED50, 0x020BED5C, 0x020BED68, 0x020BED74, 0x020BED80, 0x020BEDD4, 0x020BEDE0], overlay: 20},
  {pointer: 0x0221BBE0, desc: "Title screen 3", overlay: 20},
  {desc: "Main menus", gfx_files: [0x020BA498, 0x020BA4A4, 0x020BA4B0, 0x020BA4EC, 0x020BA540, 0x020BA594, 0x020BA5E8, 0x020BA63C, 0x020BA660, 0x020BA66C], sprite: 0x021DCCFC, palette: 0x020D1B84},
  {desc: "Pause menus", gfx_files: [0x020BA408, 0x020BA414, 0x020BA420, 0x020BA42C, 0x020BA480, 0x020BA48C], sprite: 0x021DCD00, palette: 0x020D1980},
  
  {desc: "Map", sprite: 0x020C553C, palette: 0x020D23B0, gfx_files: [0x020BA78C], one_dimensional_mode: true},
  {desc: "Wygol Map", sprite: 0x020BFA2C, palette: 0x20D3C10, gfx_files: [0x020BEC90, 0x020BEC9C], one_dimensional_mode: true},
  {desc: "World Map", sprite: 0x021DCCF8, palette: 0x020D1E88, gfx_files: [
    0x020BA678, 0x020BA684, 0x020BA690, 0x020BA69C, 0x020BA6A8, 0x020BA6B4, 0x020BA6C0
  ]},
  
  {desc: "Prologue background", sprite: 0x021DCAE4, palette: 0x020D6D38, gfx_wrapper: 0x02217D90},
  
  {desc: "Credits background", sprite: 0x021DCAD8, palette: 0x020D6F60, gfx_wrapper: 0x02217D4C},
  {desc: "Credits text", sprite: 0x021DCAE0, palette: 0x020D6F3C, gfx_file_names: [
    "/sc2/f_enr00.dat",
    "/sc2/f_enr01.dat",
    "/sc2/f_enr02.dat",
    "/sc2/f_enr03.dat",
    "/sc2/f_enr04.dat",
    "/sc2/f_enr05.dat",
    "/sc2/f_enr06.dat",
    "/sc2/f_enr07.dat",
    "/sc2/f_enr08.dat",
    "/sc2/f_enr09.dat",
    "/sc2/f_enr0a.dat",
    "/sc2/f_enr0b.dat",
    "/sc2/f_enr0c.dat",
    "/sc2/f_enr0d.dat",
    "/sc2/f_enr0e.dat",
    "/sc2/f_enr0f.dat",
    "/sc2/f_enr10.dat",
    "/sc2/f_enr11.dat",
    "/sc2/f_enr12.dat",
    "/sc2/f_enr13.dat",
    "/sc2/f_enr14.dat",
    "/sc2/f_enr15.dat",
    "/sc2/f_enr16.dat",
    "/sc2/f_enr17.dat",
  ]},
  
  {desc: "HUD", sprite: 0x021DCD04, palette: 0x020D177C, gfx_file_names: ["/sc/f_gauge.dat"]},
  
  {desc: "Bestiary enemies 00-03", sprite: 0x020F4608, palette: 0x020D2B90, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist00.dat"]},
  {desc: "Bestiary enemies 04-07", sprite: 0x020F4608, palette: 0x020D2C14, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist01.dat"]},
  {desc: "Bestiary enemies 08-0B", sprite: 0x020F4608, palette: 0x020D2C98, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist02.dat"]},
  {desc: "Bestiary enemies 0C-0F", sprite: 0x020F4608, palette: 0x020D2D1C, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist03.dat"]},
  {desc: "Bestiary enemies 10-13", sprite: 0x020F4608, palette: 0x020D2DA0, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist04.dat"]},
  {desc: "Bestiary enemies 14-17", sprite: 0x020F4608, palette: 0x020D2E24, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist05.dat"]},
  {desc: "Bestiary enemies 18-1B", sprite: 0x020F4608, palette: 0x020D2EA8, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist06.dat"]},
  {desc: "Bestiary enemies 1C-1F", sprite: 0x020F4608, palette: 0x020D2F2C, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist07.dat"]},
  {desc: "Bestiary enemies 20-23", sprite: 0x020F4608, palette: 0x020D2FB0, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist08.dat"]},
  {desc: "Bestiary enemies 24-27", sprite: 0x020F4608, palette: 0x020D3034, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist09.dat"]},
  {desc: "Bestiary enemies 28-2B", sprite: 0x020F4608, palette: 0x020D30B8, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist0a.dat"]},
  {desc: "Bestiary enemies 2C-2F", sprite: 0x020F4608, palette: 0x020D313C, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist0b.dat"]},
  {desc: "Bestiary enemies 30-33", sprite: 0x020F4608, palette: 0x020D31C0, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist0c.dat"]},
  {desc: "Bestiary enemies 34-37", sprite: 0x020F4608, palette: 0x020D3244, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist0d.dat"]},
  {desc: "Bestiary enemies 38-3B", sprite: 0x020F4608, palette: 0x020D32C8, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist0e.dat"]},
  {desc: "Bestiary enemies 3C-3F", sprite: 0x020F4608, palette: 0x020D334C, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist0f.dat"]},
  {desc: "Bestiary enemies 40-43", sprite: 0x020F4608, palette: 0x020D33D0, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist10.dat"]},
  {desc: "Bestiary enemies 44-47", sprite: 0x020F4608, palette: 0x020D3454, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist11.dat"]},
  {desc: "Bestiary enemies 48-4B", sprite: 0x020F4608, palette: 0x020D34D8, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist12.dat"]},
  {desc: "Bestiary enemies 4C-4F", sprite: 0x020F4608, palette: 0x020D355C, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist13.dat"]},
  {desc: "Bestiary enemies 50-53", sprite: 0x020F4608, palette: 0x020D35E0, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist14.dat"]},
  {desc: "Bestiary enemies 54-57", sprite: 0x020F4608, palette: 0x020D3664, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist15.dat"]},
  {desc: "Bestiary enemies 58-5B", sprite: 0x020F4608, palette: 0x020D36E8, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist16.dat"]},
  {desc: "Bestiary enemies 5C-5F", sprite: 0x020F4608, palette: 0x020D376C, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist17.dat"]},
  {desc: "Bestiary enemies 60-63", sprite: 0x020F4608, palette: 0x020D37F0, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist18.dat"]},
  {desc: "Bestiary enemies 64-67", sprite: 0x020F4608, palette: 0x020D3874, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist19.dat"]},
  {desc: "Bestiary enemies 68-6B", sprite: 0x020F4608, palette: 0x020D38F8, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist1a.dat"]},
  {desc: "Bestiary enemies 6C-6F", sprite: 0x020F4608, palette: 0x020D397C, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist1b.dat"]},
  {desc: "Bestiary enemies 70-73", sprite: 0x020F4608, palette: 0x020D3A00, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist1c.dat"]},
  {desc: "Bestiary enemies 74-77", sprite: 0x020F4608, palette: 0x020D3A84, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist1d.dat"]},
  {desc: "Bestiary enemy 78", sprite: 0x020F4608, palette: 0x020D3B08, one_dimensional_mode: true, gfx_file_names: ["/sc/f_elist1e.dat"]},
  
  {desc: "Face portraits 00-04 (Shanoa)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x12, gfx_file_names: [
    "/sc/f_fsha00.dat",
    "/sc/f_fsha01.dat",
    "/sc/f_fsha02.dat",
    "/sc/f_fsha03.dat",
    "/sc/f_fsha04.dat",
  ]},
  {desc: "Face portraits 05-09 (Albus)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x03, gfx_file_names: [
    "/sc/f_falb00.dat",
    "/sc/f_falb01.dat",
    "/sc/f_falb02.dat",
    "/sc/f_falb03.dat",
    "/sc/f_falb04.dat",
  ]},
  {desc: "Face portraits 0A-0C (Barlowe)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x05, gfx_file_names: [
    "/sc/f_fbar00.dat",
    "/sc/f_fbar01.dat",
    "/sc/f_fbar02.dat",
  ]},
  {desc: "Face portrait 0D (Nikolai)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x10, gfx_file_names: [
    "/sc/f_fnic00.dat",
  ]},
  {desc: "Face portrait 0E (Jacob)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x0C, gfx_file_names: [
    "/sc/f_fjak00.dat",
  ]},
  {desc: "Face portrait 0F (Abram)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x02, gfx_file_names: [
    "/sc/f_fabr00.dat",
  ]},
  {desc: "Face portrait 10 (Laura)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x0D, gfx_file_names: [
    "/sc/f_flol00.dat",
  ]},
  {desc: "Face portrait 11 (Eugen)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x09, gfx_file_names: [
    "/sc/f_feug00.dat",
  ]},
  {desc: "Face portrait 12 (Aeon)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x0B, gfx_file_names: [
    "/sc/f_fiwo00.dat",
  ]},
  {desc: "Face portrait 13 (Marcel)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x0E, gfx_file_names: [
    "/sc/f_fmar00.dat",
  ]},
  {desc: "Face portrait 14 (George)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x0A, gfx_file_names: [
    "/sc/f_fgeo00.dat",
  ]},
  {desc: "Face portrait 15 (Serge)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x11, gfx_file_names: [
    "/sc/f_fser00.dat",
  ]},
  {desc: "Face portrait 16 (Anna)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x04, gfx_file_names: [
    "/sc/f_fann00.dat",
  ]},
  {desc: "Face portrait 17 (Monica)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x0F, gfx_file_names: [
    "/sc/f_fmon00.dat",
  ]},
  {desc: "Face portrait 18 (Irina)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x08, gfx_file_names: [
    "/sc/f_fele00.dat",
  ]},
  {desc: "Face portrait 19 (Daniela)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x06, gfx_file_names: [
    "/sc/f_fdan00.dat",
  ]},
  {desc: "Face portraits 1A-1B (Dracula)", no_sprite: true, palette: 0x021FFDA0, overlay: 0x07, gfx_file_names: [
    "/sc/f_fdra00.dat",
    "/sc/f_fdra01.dat",
  ]},
]

CANDLE_FRAME_IN_COMMON_SPRITE = 0xDB
MONEY_FRAME_IN_COMMON_SPRITE = 0xEF
CANDLE_SPRITE = COMMON_SPRITE
MONEY_SPRITE = COMMON_SPRITE

OVERLAY_FILES_WITH_SPRITE_DATA = []

TEXT_LIST_START_OFFSET = 0x021FACC0 # 0x021FE000 for French text.
TEXT_RANGE = (0..0x764)
TEXT_REGIONS = {
  "Character Names" => (0..0x15),
  "Item Names" => (0x16..0x177),
  "Item Descriptions" => (0x178..0x2D9),
  "Enemy Names" => (0x2DA..0x352),
  "Enemy Descriptions" => (0x353..0x3CB),
  "System" => (0x3CC..0x407),
  "Menus 1" => (0x408..0x533),
  "Quest Names" => (0x534..0x557),
  "Menus 2" => (0x558..0x566),
  "Term List" => (0x567..0x5A0),
  "Area Names" => (0x5A1..0x5C0),
  "Quest Descriptions" => (0x5C1..0x5E3),
  "Music Names" => (0x5E4..0x61C),
  "Menus 3" => (0x61D..0x65F),
  "Events" => (0x660..0x764)
}
TEXT_REGIONS_OVERLAYS = {
  # French text uses overlay 1 instead of 0.
  "Character Names" => 0,
  "Item Names" => 0,
  "Item Descriptions" => 0,
  "Enemy Names" => 0,
  "Enemy Descriptions" => 0,
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
STRING_DATABASE_START_OFFSET = 0x021DD280
STRING_DATABASE_ORIGINAL_END_OFFSET = 0x021FACBC
STRING_DATABASE_ALLOWABLE_END_OFFSET = 0x021FFDA0
TEXT_COLOR_NAMES = {
  0x00 => "TRANSPARENT",
  0x01 => "WHITE",
  0x02 => "BLACK",
  0x03 => "GREY",
  0x04 => "PINK",
  0x05 => "BROWN",
  0x06 => "AZURE",
  0x07 => "YELLOW",
  0x08 => "RED",
  0x09 => "ORANGE",
  0x0A => "LIGHTYELLOW",
  0x0B => "GREEN",
  0x0C => "AQUA",
  0x0D => "BLUE",
  0x0E => "PURPLE",
  0x0F => "WHITE2",
}

NAMES_FOR_UNNAMED_SKILLS = {
  0x33 => "Cat Tackle",
  0x34 => "Cat Tail",
  0x35 => "Bat Throw",
  0x36 => "Bat Kick",
}

NEW_GAME_STARTING_AREA_INDEX_OFFSET = 0x020AC14C
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x020AC154
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x020AC15C
NEW_GAME_STARTING_X_POS_OFFSET = 0x020D7FB4
NEW_GAME_STARTING_Y_POS_OFFSET = 0x020D7FB8

FAKE_TRANSITION_ROOMS = [0x022AE3A8, 0x022A7E78]

ITEM_ICONS_PALETTE_POINTER = 0x020D177C
GLYPH_ICONS_PALETTE_POINTER = 0x020C9854
ITEM_ICONS_GFX_POINTERS = nil

ARM_GLYPH_FORMAT = [
  # length: 32
  [2, "Item ID"],
  [2, "DMG multiplier"],
  [4, "Code"],
  [1, "Sprite"],
  [1, "?/Swings/Union"],
  [1, "Max at once"],
  [1, "Mana cost"],
  [4, "Effects", :bitfield],
  [4, "Unwanted States", :bitfield],
  [2, "Icon"],
  [2, "Swing Modifiers", :bitfield],
  [2, "Var A"],
  [1, "IFrames"],
  [1, "Delay"],
  [4, "Swing Sound"],
]
BACK_GLYPH_FORMAT = [
  # length: 28
  [2, "Item ID"],
  [2, "DMG multiplier"],
  [4, "Code"],
  [1, "Sprite"],
  [1, "Unknown 2"],
  [1, "Max at once"],
  [1, "Mana cost"],
  [4, "Effects", :bitfield],
  [4, "Unwanted States", :bitfield],
  [2, "Icon"],
  [2, "Var A"],
  [4, "Unknown 5"],
]
GLYPH_UNION_FORMAT = [
  # length: 28
  [2, "Item ID"],
  [2, "DMG multiplier"],
  [4, "Code"],
  [1, "Sprite"],
  [1, "?/Swings"],
  [1, "Max at once"],
  [1, "Heart cost"],
  [4, "Effects", :bitfield],
  [4, "Unwanted States", :bitfield],
  [2, "Icon"],
  [2, "Swing Modifiers", :bitfield],
  [2, "Swing Anim"],
  [1, "IFrames"],
  [1, "Unknown 9"],
]
RELIC_FORMAT = [
  # length: 12
  [2, "Item ID"],
  [2, "Icon"],
  [4, "Unknown 1"],
  [4, "Unknown 2"],
]
CONSUMABLE_FORMAT = [
  # length: 12
  [2, "Item ID"],
  [2, "Icon"],
  [4, "Price"],
  [1, "Type"],
  [1, "Unknown 1"],
  [2, "Var A"],
]
ARMOR_FORMAT = [
  # length: 20
  [2, "Item ID"],
  [2, "Icon"],
  [4, "Price"],
  [1, "Type"],
  [1, "Unknown 1"],
  [1, "Defense"],
  [1, "Strength"],
  [1, "Constitution"],
  [1, "Intelligence"],
  [1, "Mind"],
  [1, "Luck"],
  [4, "Resistances", :bitfield],
]
WEAPON_FORMAT = [
  # length: 28
  [2, "Item ID"],
  [2, "Icon"],
  [4, "Price"],
  [1, "Unknown 1"],
  [1, "Attack"],
  [1, "Defense"],
  [1, "Strength"],
  [1, "Constitution"],
  [1, "Intelligence"],
  [1, "Mind"],
  [1, "Luck"],
  [4, "Effects", :bitfield],
  [1, "GFX"],
  [1, "Palette"],
  [2, "Unknown 4"],
  [2, "Swing Modifiers", :bitfield],
  [2, "Unknown 5"],
]

ITEM_TYPES = [
  {
    name: "Arm Glyphs",
    list_pointer: 0x020F0A08,
    count: 55,
    kind: :skill,
    format: ARM_GLYPH_FORMAT
  },
  {
    name: "Back Glyphs",
    list_pointer: 0x020EF8CC,
    count: 25,
    kind: :skill,
    format: BACK_GLYPH_FORMAT
  },
  {
    name: "Glyph Unions",
    list_pointer: 0x020F0164,
    count: 31,
    kind: :skill,
    format: GLYPH_UNION_FORMAT
  },
  {
    name: "Relics",
    list_pointer: 0x020EF4C4,
    count: 6,
    format: RELIC_FORMAT
  },
  {
    name: "Consumables",
    list_pointer: 0x020F04C8,
    count: 112,
    format: CONSUMABLE_FORMAT
  },
  {
    name: "Body Armor",
    list_pointer: 0x020EF6B0,
    count: 27,
    format: ARMOR_FORMAT
  },
  {
    name: "Head Armor",
    list_pointer: 0x020EFB88,
    count: 36,
    format: ARMOR_FORMAT
  },
  {
    name: "Leg Armor",
    list_pointer: 0x020EF50C,
    count: 21,
    format: ARMOR_FORMAT
  },
  {
    name: "Accessories",
    list_pointer: 0x020EFE58,
    count: 39,
    format: ARMOR_FORMAT
  },
  {
    name: "Weapons (Unused)",
    list_pointer: 0x020EF48C,
    count: 2,
    format: WEAPON_FORMAT
  },
]

ITEM_BITFIELD_ATTRIBUTES = {
  "Resistances" => [
    "Strike",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Holy",
    "Dark",
    "Unknown 8",
    "Poison",
    "Curse",
    "Stone",
    "Unknown 12",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
    "Unknown 17",
    "Unknown 18",
    "Unknown 19",
    "Unknown 20",
    "Unknown 21",
    "Unknown 22",
    "Unknown 23",
    "Unknown 24",
    "Unknown 25",
    "(Enemy-used) Arm glyphs",
    "Unknown 27",
    "Unknown 28",
    "Unknown 29",
    "Unknown 30",
    "Unknown 31",
    "Unknown 32",
  ],
  "Effects" => [
    "Strike",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Holy",
    "Dark",
    "Unknown 8",
    "Poison",
    "Curse",
    "Stone",
    "Torpor",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
    "Unknown 17",
    "Shield",
    "Unknown 19",
    "Unknown 20",
    "Unknown 21",
    "Unknown 22",
    "Unknown 23",
    "Unknown 24",
    "Unknown 25",
    "Is an arm glyph",
    "Is a glyph union",
    "Can destroy Blood Skeletons",
    "Unknown 29",
    "Unknown 30",
    "Unknown 31",
    "Unknown 32",
  ],
  "Unwanted States" => [
    "Moving",
    "Moving forward",
    "Facing left",
    "Crouching",
    "In air",
    "Double jumping",
    "Unknown 7",
    "Jumpkick bounce",
    "Ceiling above head (jump/crouch in small space)",
    "On jump-through platform",
    "Ceiling above head (crouch in small space)",
    "Taking damage in the air",
    "Ceiling above head (standing)",
    "Backdashing",
    "Jumpkicking",
    "Swinging melee weapon",
    "Using Y-button arm glyph",
    "Using X-button arm glyph",
    "Using back glyph",
    "Using glyph union",
    "Sliding",
    "Jumpkicking",
    "Taking damage",
    "Unknown 24",
    "Dying",
    "Unknown 26",
    "Unknown 27",
    "Unknown 28",
    "Unknown 29",
    "Unknown 30",
    "Unknown 31",
    "Unknown 32",
  ],
  "Swing Modifiers" => [
    "No interrupt player anim on land",
    "Weapon floats in corner of room",
    "Unknown 3",
    "Unknown 4",
    "No trail gradual fadeout",
    "Unknown 6",
    "No transparent slash trail",
    "Unknown 8",
    "Unknown 9",
    "Unknown 10",
    "Unknown 11",
    "Unknown 12",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
  ],
}

ITEM_POOLS_LIST_POINTER = 0x02223B20
ITEM_POOL_INDEXES_FOR_AREAS_LIST_POINTER = 0x02223B08
NUMBER_OF_ITEM_POOLS = 0xB

PLAYER_LIST_POINTER = 0x020EED5C
PLAYER_COUNT = 5
PLAYER_NAMES = [
  "Shanoa",
  "Arma Felix",
  "Arma Chiroptera",
  "Arma Machina",
  "Albus",
]
PLAYER_LIST_FORMAT = [
  # length: 92
  [4, "GFX list pointer"],
  [4, "Sprite pointer"],
  [4, "Palette pointer"],
  [4, "State anims ptr"],
  [2, "GFX asset index"],
  [2, "Sprite asset index"],
  [4, "Walking speed"],
  [4, "Jump force"],
  [4, "Double jump force"],
  [4, "Slide force"],
  [4, "Actions", :bitfield],
  [4, "??? bitfield", :bitfield],
  [4, "Backdash force"],
  [4, "Backdash friction"],
  [2, "Backdash duration"],
  [2, "Unknown 14"],
  [4, "Damage types", :bitfield],
  [4, "Unknown 16"],
  [2, "Sprite Y offset"],
  [2, "Outline color index"],
  [2, "Outline color"],
  [2, "Unknown 19"],
  [4, "Unknown 20"],
  [4, "Hitbox pointer"],
  [2, "Height"],
  [2, "Face icon frame"],
  [4, "Swing anims (Y)"],
  [4, "Swing anims (X)"],
]
PLAYER_BITFIELD_ATTRIBUTES = {
  "Actions" => [
    "Can slide",
    "Can use weapons",
    "Unknown 3",
    "Unknown 4",
    "Unknown 5",
    "Can jumpkick",
    "Can superjump",
    "Can slidejump",
    "Unknown 9",
    "Unknown 10",
    "Unknown 11",
    "Unknown 12",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
    "Unknown 17",
    "Unknown 18",
    "Can absorb glyphs",
    "Unknown 20",
    "Unknown 21",
    "Can up-pose",
    "Unknown 23",
    "Unknown 24",
    "Unknown 25",
    "Unknown 26",
    "Unknown 27",
    "Unknown 28",
    "Unknown 29",
    "Unknown 30",
    "Unknown 31",
    "Unknown 32",
  ],
  "??? bitfield" => [
    "Horizontal flip",
    "Can smash head",
    "Unknown 3",
    "Unknown 4",
    "Is female",
    "No interrupt dbl jump",
    "Unknown 7",
    "Unknown 8",
    "Unknown 9",
    "Unknown 10",
    "Unknown 11",
    "Unknown 12",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
    "Unknown 17",
    "Unknown 18",
    "Unknown 19",
    "Unknown 20",
    "Unknown 21",
    "Unknown 22",
    "Unknown 23",
    "Unknown 24",
    "Unknown 25",
    "Unknown 26",
    "Unknown 27",
    "Unknown 28",
    "Unknown 29",
    "Unknown 30",
    "Unknown 31",
    "Unknown 32",
  ],
  "Damage types" => [
    "Strike",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Holy",
    "Dark",
    "Unknown 8",
    "Poison",
    "Curse",
    "Stone",
    "Unknown 12",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
    "Unknown 17",
    "Take half damage & Reflect projectiles",
    "Can be hit",
    "Unknown 20",
    "Unknown 21",
    "Unknown 22",
    "Unknown 23",
    "Unknown 24",
    "Unknown 25",
    "Unknown 26",
    "Unknown 27",
    "Unknown 28",
    "Unknown 29",
    "Unknown 30",
    "Unknown 31",
    "Unknown 32",
  ],
}

NEW_OVERLAY_ID = 86
NEW_OVERLAY_FREE_SPACE_START = 0x022EB1A0
NEW_OVERLAY_FREE_SPACE_MAX_SIZE = 0x32000
ASSET_MEMORY_START_HARDCODED_LOCATION = 0x02007354

TEST_ROOM_SAVE_FILE_INDEX_LOCATION = 0x02213308
TEST_ROOM_AREA_INDEX_LOCATION      = 0x02213328
TEST_ROOM_SECTOR_INDEX_LOCATION    = 0x02213330
TEST_ROOM_ROOM_INDEX_LOCATION      = 0x02213338
TEST_ROOM_X_POS_LOCATION           = 0x02213398
TEST_ROOM_Y_POS_LOCATION           = 0x0221339C
TEST_ROOM_OVERLAY = 20

SHOP_ITEM_POOL_LIST = 0x022228D4
SHOP_ITEM_POOL_COUNT = 0x24
SHOP_HARDCODED_ITEM_POOL_COUNT = 3
SHOP_HARDCODED_ITEM_POOLS = [
  {
    requirement: nil,
    items: {
      0x02200184 => :arm_shifted_immediate,
      0x02200190 => :arm_shifted_immediate,
      0x0220019C => :arm_shifted_immediate,
      0x022001A8 => :arm_shifted_immediate,
      0x022001B4 => :arm_shifted_immediate,
      0x02200324 => :word, # loaded by 0x022001C0
      0x022001CC => :arm_shifted_immediate,
    }
  },
  {
    requirement: 0x022001FC,
    items: {
      0x02200328 => :word, # loaded by 0x02200208 and 0x022001E0
      0x02200330 => :word, # loaded by 0x02200214
      0x02200334 => :word, # loaded by 0x02200220
    }
  },
  {
    requirement: 0x02200250,
    items: {
      0x02200338 => :word, # loaded by 0x0220025C and 0x02200234
      0x02200268 => :arm_shifted_immediate,
      0x0220033C => :word, # loaded by 0x02200274
    }
  },
]

FAKE_FREE_SPACES = [
  {path: "/ftc/overlay9_46", offset: 0x022E4ABC-0x022C1FE0, length: 0xC0}, # Used by object 5A
  {path: "/ftc/overlay9_53", offset: 0x022CD8C0-0x022C1FE0, length: 0xC}, # Used by object 28 (really 9 bytes are used, but I round it up to be safe)
]

MAGIC_SEAL_COUNT = 0
MAGIC_SEAL_LIST_START = nil
MAGIC_SEAL_FOR_BOSS_LIST_START = nil

NUM_PLAYER_ANIM_STATES = 0x50
PLAYER_ANIM_STATE_NAMES = [
  "Idle",
  "Starting to hold up",
  "Holding up",
  "Starting to walk",
  "Turning around",
  "Walking",
  "Stopping",
  "Landing while moving",
  "Starting to crouch",
  "Crouching",
  "Standing up",
  "Jumping straight up",
  "Jumping diagonally",
  "Double jumping",
  "Superjumping",
  "Smashing head",
  "",
  "",
  "Flying",
  "Falling",
  "Landing from small height",
  "Landing from medium height",
  "Hard landing straight down",
  "Hard landing diagonally",
  "Swimming",
  "Submerged underwater without Serpent Scale",
  "Turning around while swimming",
  "Pushing",
  "Swinging melee weapon with Y-button hand",
  "Crouching and swinging melee weapon with Y-button hand",
  "In air and swinging melee weapon with Y-button hand",
  "Swinging melee weapon with X-button hand",
  "Crouching and swinging melee weapon with X-button hand",
  "In air and swinging melee weapon with X-button hand",
  "Using throwing glyph with Y-button hand",
  "Crouching and using throwing glyph with Y-button hand",
  "In air and using throwing glyph with Y-button hand",
  "Using throwing glyph with X-button hand",
  "Crouching and using throwing glyph with X-button hand",
  "In air and using throwing glyph with X-button hand",
  "Arms outstretched in front using magic",
  "Charging Acerbatus (boss Albus only)",
  "Firing Acerbatus (boss Albus only)",
  "",
  "Backdashing",
  "Sliding on flat ground",
  "Sliding on slope",
  "Slidejumping",
  "Jumpkicking straight down",
  "Jumpkicking diagonally down",
  "Taking damage while standing/walking",
  "Taking damage while backdashing",
  "Taking damage while crouching",
  "Taking damage in air from the front",
  "Taking damage in air from behind",
  "Petrified 1",
  "Petrified 2",
  "Grabbed",
  "",
  "Dying in air",
  "Dying on ground",
  "Waking up 1",
  "Lowering head",
  "Raising head",
  "Entering fighting pose 1",
  "Entering fighting pose 2",
  "",
  "",
  "Waking up 2",
  "",
  "",
  "Starting to flame kick",
  "Flame kicking",
  "Landing from flame kicking (boss Albus only)",
  "",
  "",
  "",
  "",
  "",
  "",
]

QUEST_LIST_POINTER = 0x020F58B0
QUEST_COUNT = 0x24
QUEST_LIST_FORMAT = [
  # length: 0x10
  [2, "Reward"],
  [2, "Unused 1"],
  [4, "Requirements Pointer"],
  [1, "Quest Modifiers", :bitfield],
  [1, "Unused 2"],
  [2, "Unused 3"],
  [4, "Unused 4"],
]
QUEST_BITFIELD_ATTRIBUTES = {
  "Quest Modifiers" => [
    "Reward is gold",
    "Unknown 1",
    "Is a kill quest",
    "Unknown 3",
    "Unused 4",
    "Unused 5",
    "Unused 6",
    "Unused 7",
  ],
}

MENU_BG_LAYER_INFOS = [
  # TODO
]
