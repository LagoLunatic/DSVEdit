
GAME = "ooe"
LONG_GAME_NAME = "Order of Ecclesia"

AREA_LIST_RAM_START_OFFSET = 0x020ECDDC

EXTRACT_EXTRA_ROOM_INFO = Proc.new do |last_4_bytes_of_room_metadata|
  number_of_doors    = (last_4_bytes_of_room_metadata & 0b00000000_00000000_00000000_01111111)
  room_xpos_on_map   = (last_4_bytes_of_room_metadata & 0b00000000_00000000_00111111_10000000) >> 7
  room_ypos_on_map   = (last_4_bytes_of_room_metadata & 0b00000000_00011111_11000000_00000000) >> 14
  palette_page_index = (last_4_bytes_of_room_metadata & 0b00001111_10000000_00000000_00000000) >> 23
  [number_of_doors, room_xpos_on_map, room_ypos_on_map, palette_page_index]
end

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
   3 => "Training Chamber",
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
     4 => "Library",
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

CONSTANT_OVERLAYS = [19, 22]

INVALID_ROOMS = []

MAP_TILE_METADATA_LIST_START_OFFSET = 0x020ECE84
MAP_TILE_LINE_DATA_LIST_START_OFFSET = 0x020ECED8
MAP_LENGTH_DATA_START_OFFSET = 0x020B61C0

AREA_MUSIC_LIST_START_OFFSET = 0x020D79D8
SECTOR_MUSIC_LIST_START_OFFSET = 0x020D7954

MAP_FILL_COLOR = [160, 64, 128, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [0, 0, 248, 255]
MAP_SECRET_FILL_COLOR = [0, 128, 0, 255]
MAP_ENTRANCE_FILL_COLOR = [248, 128, 0, 255]
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [216, 216, 216, 255]
MAP_DOOR_CENTER_PIXEL_COLOR = [0, 0, 0, 0]

RAM_START_FOR_ROOM_OVERLAYS = 0x022C1FE0
RAM_END_FOR_ROOM_OVERLAYS = 0x022C1FE0 + 168384
ARM9_LENGTH = 1_044_004
LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET = 0xDCCEC
LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET = 0xF0A0B
LIST_OF_FILE_RAM_LOCATIONS_ENTRY_LENGTH = 32

OVERLAY_RAM_INFO_START_OFFSET = 0x103000
OVERLAY_ROM_INFO_START_OFFSET = 0x588000

ITEM_GLOBAL_ID_RANGE = (0x70..0x162) # includes relics
GLYPH_GLOBAL_ID_RANGE = (2..0x50)

ENEMY_IDS = (0x00..0x78)
COMMON_ENEMY_IDS = (0x00..0x6A).to_a
BOSS_IDS = (0x6B..0x78).to_a
RANDOMIZABLE_BOSS_IDS = BOSS_IDS - [0x76] # remove eligor, he needs his own huge room

BOSS_DOOR_SUBTYPE = 0x4B
BOSS_ID_TO_BOSS_DOOR_VAR_B = {
  0x6B => 0x02, # giant skeleton
  0x6C => 0x01, # arthroverta
  0x6D => 0x03, # brachyura
  0x6E => 0x04, # man eater
  0x6F => 0x05, # rusalka
  0x70 => 0x06, # goliath
  0x71 => 0x07, # gravedorcus
  0x72 => 0x08, # albus
  0x73 => 0x09, # barlowe
  0x74 => 0x0A, # wallman
  0x75 => 0x0B, # blackmore
  0x76 => 0x0C, # eligor
  0x77 => 0x0D, # death
  0x78 => 0x0F, # dracula
}

ENEMY_DNA_RAM_START_OFFSET = 0x020B6364
ENEMY_DNA_LENGTH = 36
ENEMY_DNA_FORMAT = [
  [4, "Init AI"],
  [4, "Running AI"],
  [2, "Item 1"],
  [2, "Item 2"],
  [1, "Unknown 1"],
  [1, "Unknown 2"],
  [2, "HP"],
  [2, "EXP"],
  [2, "Unknown 3"],
  [2, "Glyph"],
  [1, "Glyph Chance"],
  [1, "Attack"],
  [1, "Unknown 4"],
  [1, "Unknown 5"],
  [1, "Item 1 Chance"],
  [1, "Item 2 Chance"],
  [2, "Weaknesses", :bitfield],
  [2, "Unknown 6"],
  [2, "Resistances", :bitfield],
  [2, "Unknown 7"],
]
ENEMY_DNA_BITFIELD_ATTRIBUTES = {
  "Weaknesses" => [
    "Strike",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Light",
    "Dark",
    "Poison",
    "Curse",
    "Stone",
    "Weakness 11",
    "Weakness 12",
    "Weakness 13",
    "Weakness 14",
    "Weakness 15",
    "Made of flesh",
  ],
  "Resistances" => [
    "Strike",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Light",
    "Dark",
    "Poison",
    "Curse",
    "Stone",
    "Resistance 11",
    "Resistance 12",
    "Resistance 13",
    "Resistance 14",
    "Resistance 15",
    "Resistance 16",
  ],
}

# Overlays 24 to 38 are used for enemies.
OVERLAY_FILE_FOR_ENEMY_AI = {
   22 => 38, # the creature
   60 => 38, # owl
   65 => 38, # owl knight
   78 => 38, # draculina
   94 => 38, # spectral sword
  102 => 36, # final knight
  103 => 29, # jiang shi
  108 => 24, # arthroverta
  109 => 30, # brachyura
  110 => 26, # maneater
  111 => 27, # rusalka
  112 => 32, # goliath
  113 => 33, # gravedorcus
  114 => 36, # albus
  115 => 37, # barlowe
  116 => 28, # wallman
  117 => 35, # blackmore
  118 => 31, # eligor
  119 => 25, # death
  120 => [34, 75], # dracula. His palette is actually stored in one of the area overlays (75) instead of his enemy overlay (34).
}
REUSED_ENEMY_INFO = {
  35 => {init_code: 0x022505AC, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1}, # black fomor -> white fomor
  48 => {init_code:        nil, gfx_sheet_ptr_index: 0, palette_offset: 3, palette_list_ptr_index: 0}, # ladycat
  52 => {init_code: 0x0228D23C, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # automaton zx26
  72 => {init_code: 0x0224E468, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1}, # ghoul -> zombie
  76 => {init_code: 0x0228BBBC, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # black panther -> ladycat
  80 => {init_code:        nil, gfx_sheet_ptr_index: 0, palette_offset: 1, palette_list_ptr_index: 0}, # polkir
  84 => {init_code:        nil, gfx_sheet_ptr_index: 0, palette_offset: 3, palette_list_ptr_index: 0}, # gurkha master
  93 => {init_code: 0x02241FD4, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # bugbear
  95 => {init_code: 0x0228D23C, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # automaton zx27
}
BEST_SPRITE_FRAME_FOR_ENEMY = {
    7 =>  36, # nominon
    9 =>   7, # une
   14 =>   8, # invisible man
   17 =>  30, # demon
   21 =>  16, # forneus
   22 => 107, # the creature
   23 =>   3, # black crow
   24 =>   7, # skull spider
   26 =>  30, # sea demon
   30 =>  30, # fire demon
   36 =>  90, # enkidu
   41 =>  16, # skeleton rex
   44 =>   5, # lorelai
   49 =>  15, # ectoplasm
   51 =>  21, # miss murder
   53 =>  23, # skeleton beast
   54 =>  20, # balloon
   59 =>  30, # thunder demon
   63 =>  14, # mandragora
   65 =>  15, # owl knight
   71 =>   6, # flea man
   73 =>  38, # peeping eye
   80 =>  36, # polkir
   84 =>  20, # gurkha master
   85 =>  20, # red smasher
   91 =>  74, # rebuild
   93 =>  39, # bugbear
   95 =>   1, # automaton zx27
   96 =>   2, # medusa head
   97 =>   2, # gorgon head
  100 =>  29, # king skeleton
  104 =>  30, # demon lord
  105 =>  20, # double hammer
  106 =>  20, # weapon master
  107 =>   6, # giant skeleton
  108 =>   3, # arthroverta
  109 =>  64, # brachyura
  110 =>   7, # maneater
  112 =>  74, # goliath
  116 =>  29, # wallman
  120 =>  56, # dracula
}

TEXT_LIST_START_OFFSET = 0x021FACC0
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
STRING_DATABASE_START_OFFSET = 0x021DD280
STRING_DATABASE_ORIGINAL_END_OFFSET = 0x021FACBC
STRING_DATABASE_ALLOWABLE_END_OFFSET = 0x021FFDA0

NEW_GAME_STARTING_AREA_INDEX_OFFSET = 0x020AC14C
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x020AC154
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x020AC15C

NEW_GAME_STARTING_TOP_SCREEN_TYPE_OFFSET = 0x02214F68

TRANSITION_ROOM_LIST_POINTER = nil
FAKE_TRANSITION_ROOMS = [0x022AE3A8, 0x022A7E78]

armor_format = [
  [2, "Item ID"],
  [1, "Icon"],
  [1, "Palette"],
  [4, "Price"],
  [1, "Unknown 1"],
  [1, "Unknown 2"],
  [1, "Defense"],
  [1, "Strength"],
  [1, "Constitution"],
  [1, "Intelligence"],
  [1, "Mind"],
  [1, "Luck"],
  [1, "Unknown 3"],
  [1, "Unknown 4"],
  [1, "Unknown 5"],
  [1, "Unknown 6"],
]
ITEM_TYPES = [
  {
    name: "Arm Glyphs",
    list_pointer: 0x020F0A08,
    count: 55,
    format: [
      [2, "Item ID"],
      [2, "Attack"],
      [4, "Code Pointer"],
      [1, "GFX"],
      [1, "Unknown 2"],
      [1, "Unknown 3"],
      [1, "Mana"],
      [4, "Unknown 4"],
      [4, "Unknown 5"],
      [2, "Icon"],
      [1, "bitf"],
      [1, "Unknown 6"],
      [1, "Unknown 7"],
      [1, "Unknown 8"],
      [1, "Unknown 9"],
      [1, "Delay"],
      [1, "SFX"],
      [1, "Unknown 11"],
      [1, "Unknown 12"],
      [1, "Unknown 13"],
    ]
  },
  {
    name: "Back Glyphs",
    list_pointer: 0x020EF8CC,
    count: 25,
    format: [
      [2, "Item ID"],
      [2, "Unknown 1"],
      [4, "Code Pointer"],
      [1, "GFX"],
      [1, "Unknown 2"],
      [1, "Unknown 3"],
      [1, "Mana"],
      [4, "Unknown 4"],
      [4, "Unknown 5"],
      [2, "Icon"],
      [1, "bitf?"],
      [1, "Unknown 6"],
      [1, "Unknown 7"],
      [1, "Unknown 8"],
      [1, "Unknown 9"],
      [1, "Unknown 10"],
    ]
  },
  {
    name: "Relics",
    list_pointer: 0x020EF4C4,
    count: 6,
    format: [
      [2, "Item ID"],
      [1, "Unknown 1"],
      [1, "Unknown 2"],
      [4, "Unknown 3"],
      [4, "Unknown 4"],
    ]
  },
  {
    name: "Consumables",
    list_pointer: 0x020F04C8,
    count: 112,
    format: [
      [2, "Item ID"],
      [1, "Icon"],
      [1, "Palette"],
      [4, "Price"],
      [1, "Type"],
      [1, "Unknown 1"],
      [2, "Var A"],
    ]
  },
  {
    name: "Body Armor",
    list_pointer: 0x020EF6B0,
    count: 27,
    format: armor_format
  },
  {
    name: "Head Armor",
    list_pointer: 0x020EFB88,
    count: 36,
    format: armor_format
  },
  {
    name: "Accessories",
    list_pointer: 0x020EFE58,
    count: 39,
    format: armor_format
  },
  {
    name: "Leg Armor",
    list_pointer: 0x020EF50C,
    count: 21,
    format: armor_format
  },
  {
    name: "Weapons",
    list_pointer: 0x020EF48C,
    count: 2,
    format: [
      [2, "Item ID"],
      [2, "Icon"],
      [4, "Price"],
      [1, "unk"],
      [1, "Attack"],
      [1, "Defense"],
      [1, "Strength"],
      [1, "Constitution"],
      [1, "Intelligence"],
      [1, "Mind"],
      [1, "Luck"],
      [2, "Effects", :bitfield],
      [1, "unk1"],
      [2, "unk2"],
      [1, "gfx?"],
      [2, "unk3"],
      [2, "Swing Modifiers", :bitfield],
      [2, "unk4"],
    ]
  },
]

ITEM_BITFIELD_ATTRIBUTES = {
  "Effects" => [
    "Effect 1",
    "Effect 2",
    "constant dmg?",
    "Effect 4",
    "Effect 5",
    "Electric",
    "Effect 7",
    "Holy",
    "Poison",
    "Curse",
    "Petrify",
    "Effect 12",
    "Effect 13",
    "Effect 14",
    "Effect 15",
    "Effect 16",
  ],
  "Swing Modifiers" => [
    "No interrupt on land",
    "Weapon floats in place",
    "Modifier 3",
    "Player can move",
    "Modifier 5",
    "Modifier 6",
    "Transparent weapon",
    "Shaky weapon",
    "No interrupt on anim end",
    "Modifier 10",
    "Modifier 11",
    "Modifier 12",
    "Modifier 13",
    "Modifier 14",
    "Modifier 15",
    "Modifier 16",
  ],
}
