
GAME = "ooe"
REGION = :jp
LONG_GAME_NAME = "Order of Ecclesia"

AREA_LIST_RAM_START_OFFSET = 0x020D8FC4

# Overlays 39 to 84.
AREA_INDEX_TO_OVERLAY_INDEX = {
  0 => { 
    0 => 64,
    1 => 65,
    2 => 67,
    3 => 68,
    4 => 69,
    5 => 70,
    6 => 71,
    7 => 72,
    8 => 75,
    9 => 76,
    10 =>73,
    11 => 74,
    12 => 66,
  },     
  1 => { 
    0 => 39,
    1 => 40,
  },     
  2 => { 
    0 => 41,
  },     
  3 => { 
    0 => 42,
  },     
  4 => { 
    0 => 43,
  },     
  5 => { 
    0 => 44,
  },     
  6 => { 
    0 => 45,
    1 => 46,
  },     
  7 => { 
    0 => 47,
    1 => 48,
  },     
  8 => { 
    0 => 49,
    1 => 50,
    2 => 51,
  },     
  9 => { 
    0 => 52,
  },     
  10 => {
    0 => 53,
    1 => 54,
  },     
  11 => {
    0 => 55,
    1 => 56,
  },     
  12 => {
    0 => 57,
  },     
  13 => {
    0 => 58,
  },     
  14 => {
    0 => 59,
  },     
  15 => {
    0 => 60,
  },     
  16 => {
    0 => 61,
    1 => 62,
  },     
  17 => {
    0 => 63,
  },     
  18 => {
    0 => 77,
    1 => 78,
  },     
  19 => {
    0 => 79,
    1 => 80,
    2 => 81,
    3 => 82,
    4 => 83,
    5 => 84,
  }
}

CONSTANT_OVERLAYS = [18, 21]

MAP_TILE_METADATA_LIST_START_OFFSET = 0x020D906C
MAP_TILE_LINE_DATA_LIST_START_OFFSET = 0x020D90C0
MAP_LENGTH_DATA_START_OFFSET = 0x020B6174
MAP_SECRET_DOOR_LIST_START_OFFSET = 0x020D8F24

AREA_MUSIC_LIST_START_OFFSET = 0x020D75D8
SECTOR_MUSIC_LIST_START_OFFSET = 0x020D7554

LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET = 0x020DA694
LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET = 0x020EE3B3
LIST_OF_FILE_RAM_LOCATIONS_ENTRY_LENGTH = 0x20

ENEMY_DNA_RAM_START_OFFSET = 0x020B63D4

# Overlays 23 to 37 are used for enemies.
OVERLAY_FILE_FOR_ENEMY_AI = {
  0x16 => 37, # the creature
  0x3C => 37, # owl
  0x41 => 37, # owl knight
  0x4E => 37, # draculina
  0x5E => 37, # spectral sword
  0x66 => 35, # final knight
  0x67 => 28, # jiang shi
  0x6C => 23, # arthroverta
  0x6D => 29, # brachyura
  0x6E => 25, # maneater
  0x6F => 26, # rusalka
  0x70 => 31, # goliath
  0x71 => 32, # gravedorcus
  0x72 => 35, # albus
  0x73 => 36, # barlowe
  0x74 => 27, # wallman
  0x75 => 34, # blackmore
  0x76 => 30, # eligor
  0x77 => 24, # death
  0x78 => [33, 74], # dracula. His palette is actually stored in one of the area overlays (75) instead of his enemy overlay (34).
}
#REUSED_ENEMY_INFO = {
#  0x23 => {init_code: 0x022505AC, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1}, # black fomor -> white fomor
#  0x30 => {init_code:        nil, gfx_sheet_ptr_index: 0, palette_offset: 3, palette_list_ptr_index: 0}, # ladycat
#  0x34 => {init_code: 0x0228D23C, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # automaton zx26
#  0x48 => {init_code: 0x0224E468, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1}, # ghoul -> zombie
#  0x4C => {init_code: 0x0228BBBC, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # black panther -> ladycat
#  0x50 => {init_code:        nil, gfx_sheet_ptr_index: 0, palette_offset: 1, palette_list_ptr_index: 0}, # polkir
#  0x54 => {init_code:        nil, gfx_sheet_ptr_index: 0, palette_offset: 3, palette_list_ptr_index: 0}, # gurkha master
#  0x5D => {init_code: 0x02241FD4, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # bugbear
#  0x5F => {init_code: 0x0228D23C, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # automaton zx27
#  0x61 => {palette_offset: 2}, # gorgon head -> medusa head
#  0x62 => {init_code: 0x02207208, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # mad snatcher -> mad butcher
#  0x69 => {palette_offset: 9}, # weapon master
#  0x6A => {palette_offset: 0xC}, # weapon master
#}

ENEMY_FILES_TO_LOAD_LIST = 0x020F31C8

SPECIAL_OBJECT_CREATE_CODE_LIST = 0x020F40C0
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x020F42F4
OVERLAY_FILE_FOR_SPECIAL_OBJECT = {
  0x25 => 61,
  0x27 => 50,
  0x38 => 45,
  0x3A => 45,
  0x3B => 54,
  0x3D => 68,
  0x40 => 77,
  0x43 => 64,
  0x44 => 67,
  0x45 => 54,
  0x47 => 56,
  0x48 => 56,
  0x49 => 56,
  0x4A => 56,
  0x4C => 51,
  0x4E => 41,
  0x4F => 62,
  0x50 => 75,
  0x51 => 76,
  0x53 => 71,
  0x54 => 59,
  0x57 => 71,
  0x58 => 40,
  0x59 => 65,
  0x5A => 45,
  0x5B => 45,
  0x5D => 83,
  0x60 => 41,
  0x66 => 77,
}
#REUSED_SPECIAL_OBJECT_INFO = {
#  0x00 => {init_code:         -1},
#  0x01 => {sprite: 0x020C4E24, gfx_files: [0x020B8788, 0x020B8794, 0x020B87A0, 0x020B87AC, 0x020B87B8, 0x020B87D0, 0x020B8818, 0x020B8824], palette: 0x020C8E50}, # magnes point
#  0x02 => {init_code: 0x022B6E98}, # destructible
#  0x03 => {init_code:         -1},
#  0x16 => {init_code: 0x0221A408, palette_offset: 1}, # red chest
#  0x17 => {init_code: 0x0221A408, palette_offset: 2}, # blue chest
#  0x1A => {init_code:         -1},
#  0x1B => {init_code:         -1},
#  0x1C => {init_code:         -1},
#  0x22 => {init_code:         -1}, # movement slowing area
#  0x24 => {init_code:         -1}, # timed boss door opener
#  0x2A => {init_code:         -1}, # moving platform waypoint
#  0x2E => {sprite: 0x020C4E24, gfx_files: [0x020B8788, 0x020B8794, 0x020B87A0, 0x020B87AC, 0x020B87B8, 0x020B87D0, 0x020B8818, 0x020B8824], palette: 0x020C8E50}, # wooden door
#  0x35 => {init_code:         -1},
#  0x36 => {init_code:         -1}, # transition room hider TODO
#  0x4B => {sprite: 0x020C4E24, gfx_files: [0x020B8788, 0x020B8794, 0x020B87A0, 0x020B87AC, 0x020B87B8, 0x020B87D0, 0x020B8818, 0x020B8824], palette: 0x020C8E50}, # boss door
#  0x55 => {sprite: 0x021DCAC0, gfx_files: [0x020B838C, 0x020B8398, 0x020B83A4, 0x020B83B0, 0x020B83BC, 0x020B83C8, 0x020B83D4, 0x020B83E0, 0x020B83EC, 0x020B83F8, 0x020B8404, 0x020B8410, 0x020B841C, 0x020B8428], palette: 0x020D73D0}, # area titles
#  0x5C => {init_code:         -1}, # breakable wall TODO
#  0x62 => {init_code:         -1},
#  0x63 => {init_code:         -1},
#  0x64 => {init_code:         -1},
#  0x65 => {init_code:         -1},
#  0x67 => {init_code:         -1},
#  0x68 => {init_code:         -1},
#  0x69 => {init_code:         -1},
#  0x6A => {init_code:         -1},
#  0x6B => {init_code:         -1},
#  0x6C => {init_code:         -1},
#  0x6D => {init_code:         -1},
#  0x6E => {init_code:         -1},
#  0x6F => {init_code:         -1},
#  0x70 => {init_code:         -1},
#  0x71 => {init_code:         -1},
#  0x72 => {init_code:         -1},
#  0x73 => {init_code:         -1},
#  0x74 => {init_code:         -1},
#  0x75 => {init_code:         -1},
#  0x76 => {init_code:         -1},
#  0x77 => {init_code:         -1},
#  0x78 => {init_code:         -1},
#  0x79 => {init_code:         -1},
#  0x7A => {init_code:         -1},
#  0x7B => {init_code:         -1},
#  0x7C => {init_code:         -1},
#  0x7D => {init_code:         -1},
#  0x7E => {init_code:         -1},
#  0x7F => {init_code:         -1},
#  0x80 => {init_code:         -1},
#  0x81 => {init_code:         -1},
#  0x82 => {init_code:         -1},
#  0x83 => {init_code:         -1},
#  0x84 => {init_code:         -1},
#  0x85 => {init_code:         -1},
#  0x86 => {init_code:         -1},
#  0x88 => {init_code:         -1},
#  0x89 => {init_code:         -1},
#  0x8A => {init_code:         -1},
#  0x8B => {init_code:         -1},
#  0x8C => {init_code:         -1},
#}

SPECIAL_OBJECT_FILES_TO_LOAD_LIST = 0x020F3DF0

WEAPON_GFX_LIST_START = 0x020D9C34

OTHER_SPRITES = [
#  {desc: "Common", sprite: 0x020C4E24, gfx_files: [0x020B8788, 0x020B8794, 0x020B87A0, 0x020B87AC, 0x020B87B8, 0x020B87D0, 0x020B8818, 0x020B8824], palette: 0x020C8E50},
#  
#  {pointer: 0x020EED5C, desc: "Shanoa player"},
#  {pointer: 0x020EEDB8, desc: "Arma Felix player"},
#  {pointer: 0x020EEE14, desc: "Arma Chiroptera player"},
#  {pointer: 0x020EEE70, desc: "Arma Machina player"},
#  {pointer: 0x020EEECC, desc: "Albus player"},
#  
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
]

TEXT_LIST_START_OFFSET = 0x021FDDA0
TEXT_RANGE = (0..0x764)
TEXT_REGIONS = {
  "Character Names" => (0..0x15),
  "Item Names" => (0x16..0x177),
  "Item Descriptions" => (0x178..0x2D9),
  "Enemy Names" => (0x2DA..0x352),
  "Enemy Descriptions" => (0x353..0x3CB),
  "Misc" => (0x3CC..0x407),
  "Menus" => (0x408..0x65F),
  "Events" => (0x660..0x764)
}
TEXT_REGIONS_OVERLAYS = {
  "Character Names" => 0,
  "Item Names" => 0,
  "Item Descriptions" => 0,
  "Enemy Names" => 0,
  "Enemy Descriptions" => 0,
  "Misc" => 0,
  "Menus" => 0,
  "Events" => 0
}
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

armor_format = [
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
  [2, "Resistances", :bitfield],
  [1, "Unknown 2"],
  [1, "Unknown 3"],
]
ITEM_TYPES = [
  {
    name: "Arm Glyphs",
    list_pointer: 0x020F14D8,
    count: 55,
    format: [
      # length: 32
      [2, "Item ID"],
      [2, "Attack"],
      [4, "Code Pointer"],
      [1, "Sprite"],
      [1, "Unknown 1"],
      [1, "Unknown 2"],
      [1, "Mana"],
      [4, "Effects", :bitfield],
      [4, "Unwanted States"],
      [2, "Icon"],
      [1, "Unknown 4"],
      [1, "Unknown 5"],
      [1, "Unknown 6"],
      [1, "Unknown 7"],
      [1, "Unknown 8"],
      [1, "Delay"],
      [1, "Swing Sound"],
      [1, "Unknown 9"],
      [1, "Unknown 10"],
      [1, "Unknown 11"],
    ]
  },
  {
    name: "Back Glyphs",
    list_pointer: 0x020F039C,
    count: 25,
    format: [
      # length: 28
      [2, "Item ID"],
      [2, "Unknown 1"],
      [4, "Code Pointer"],
      [1, "Sprite"],
      [1, "Unknown 2"],
      [1, "Unknown 3"],
      [1, "Mana"],
      [4, "Effects", :bitfield],
      [4, "Unwanted States"],
      [2, "Icon"],
      [2, "Var A"],
      [1, "Unknown 5"],
      [1, "Unknown 6"],
      [1, "Unknown 7"],
      [1, "Unknown 8"],
    ]
  },
  {
    name: "Glyph Unions",
    list_pointer: 0x020F0C34,
    count: 31,
    format: [
      # length: 28
      [2, "Item ID"],
      [2, "Attack"],
      [4, "Code Pointer"],
      [1, "Sprite"],
      [1, "Unknown 1"],
      [1, "Unknown 2"],
      [1, "Mana"],
      [4, "Effects", :bitfield],
      [4, "Unwanted States"],
      [2, "Icon"],
      [1, "Unknown 4"],
      [1, "Unknown 5"],
      [1, "Unknown 6"],
      [1, "Unknown 7"],
      [1, "Unknown 8"],
      [1, "Unknown 9"],
    ]
  },
  {
    name: "Relics",
    list_pointer: 0x020EFF94,
    count: 6,
    format: [
      # length: 12
      [2, "Item ID"],
      [2, "Icon"],
      [4, "Unknown 1"],
      [4, "Unknown 2"],
    ]
  },
  {
    name: "Consumables",
    list_pointer: 0x020F0F98,
    count: 112,
    format: [
      # length: 12
      [2, "Item ID"],
      [2, "Icon"],
      [4, "Price"],
      [1, "Type"],
      [1, "Unknown 1"],
      [2, "Var A"],
    ]
  },
  {
    name: "Body Armor",
    list_pointer: 0x020F0180,
    count: 27,
    format: armor_format # length: 20
  },
  {
    name: "Head Armor",
    list_pointer: 0x020F0658,
    count: 36,
    format: armor_format # length: 20
  },
  {
    name: "Leg Armor",
    list_pointer: 0x020EFFDC,
    count: 21,
    format: armor_format # length: 20
  },
  {
    name: "Accessories",
    list_pointer: 0x020F0928,
    count: 39,
    format: armor_format # length: 20
  },
  {
    name: "Weapons (Unused)",
    list_pointer: 0x020EFF5C,
    count: 2,
    format: [
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
      [2, "Effects", :bitfield],
      [1, "Unknown 2"],
      [1, "Unknown 3"],
      [1, "GFX"],
      [1, "Palette"],
      [2, "Unknown 4"],
      [2, "Swing Modifiers", :bitfield],
      [2, "Unknown 5"],
    ]
  },
]

ITEM_POOLS_LIST_POINTER = 0x02223880
ITEM_POOL_INDEXES_FOR_AREAS_LIST_POINTER = 0x02223868
NUMBER_OF_ITEM_POOLS = 0xB
