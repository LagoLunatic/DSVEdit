
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
GLYPH_GLOBAL_ID_RANGE = (0..0x50)

ENEMY_IDS = (0x00..0x78)
COMMON_ENEMY_IDS = (0x00..0x6A).to_a
BOSS_IDS = (0x6B..0x78).to_a
VERY_LARGE_ENEMIES = []

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
    "Weakness 16",
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

TEXT_LIST_START_OFFSET = 0x021FACC0
TEXT_RANGE = (0..0x764)
TEXT_REGIONS = {
  "Character Names" => (0..0x15),
  "Glyph & Item Names" => (0x16..0x177),
  "Glyph & Item Descriptions" => (0x178..0x2D9),
  "Enemy Names" => (0x2DA..0x352),
  "Enemy Descriptions" => (0x353..0x3CB),
  "Misc" => (0x3CC..0x407),
  "Menus" => (0x408..0x65F),
  "Events" => (0x660..0x764)
}
TEXT_REGIONS_OVERLAYS = {
  "Character Names" => 0,
  "Glyph & Item Names" => 0,
  "Glyph & Item Descriptions" => 0,
  "Enemy Names" => 0,
  "Enemy Descriptions" => 0,
  "Misc" => 0,
  "Menus" => 0,
  "Events" => 0
}

ENTITY_TYPE_FOR_PICKUPS = 0x02

NEW_GAME_STARTING_AREA_INDEX_OFFSET = 0x020AC14C
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x020AC154
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x020AC15C

NEW_GAME_STARTING_TOP_SCREEN_TYPE_OFFSET = 0x02214F68
