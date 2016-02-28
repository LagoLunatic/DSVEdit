
GAME = "por"
LONG_GAME_NAME = "Portrait of Ruin"

AREA_LIST_RAM_START_OFFSET = 0x020DF36C

EXTRACT_EXTRA_ROOM_INFO = Proc.new do |last_4_bytes_of_room_metadata|
  number_of_doors    = (last_4_bytes_of_room_metadata & 0b00000000_00000000_00000000_01111111)
  room_xpos_on_map   = (last_4_bytes_of_room_metadata & 0b00000000_00000000_00011111_10000000) >> 7
 #unknown_1          = (last_4_bytes_of_room_metadata & 0b00000000_00000000_00100000_00000000) >> 13
  room_ypos_on_map   = (last_4_bytes_of_room_metadata & 0b00000000_00001111_11000000_00000000) >> 14
 #unknown_2          = (last_4_bytes_of_room_metadata & 0b00000000_00010000_00000000_00000000) >> 20
  palette_page_index = (last_4_bytes_of_room_metadata & 0b00001111_10000000_00000000_00000000) >> 23
  [number_of_doors, room_xpos_on_map, room_ypos_on_map, palette_page_index]
end

# Overlays 78 to 116. Missing: 116
AREA_INDEX_TO_OVERLAY_INDEX = {
  0 => { # castle
     0 => 78,
     1 => 79, # entrance
     2 => 80,
     3 => 81,
     4 => 82,
     5 => 83,
     6 => 84,
     7 => 85,
     8 => 86,
     9 => 87,
    10 => 88, # master's keep
    11 => 89,
    12 => 90,
  },
  1 => { # city of haze
    0 => 93,
    1 => 94,
    2 => 95,
  },
  2 => {
    0 => 104,
    1 => 105,
    2 => 106,
  },
  3 => {
    0 => 91,
    1 => 92,
  },
  4 => {
    0 => 102,
    1 => 103,
  },
  5 => {
    0 => 96,
    1 => 97,
    2 => 98,
  },
  6 => {
    0 => 107,
    1 => 108,
  },
  7 => {
    0 => 99,
    1 => 100,
    2 => 101,
  },
  8 => {
    0 => 109,
    1 => 110,
    2 => 111,
    3 => 112,
  },
  9 => {
    0 => 113,
  },
  10 => {
    0 => 114,
    1 => 114,
    2 => 114,
  },
  11 => {
    0 => 115,
  },
  12 => {
    0 => 117,
  },
  13 => {
    0 => 118, # 118 is loaded into a different place in ram than all the other room overlays. 84 seems to be the one loaded into the normal ram slot, but that one isn't needed. This is probably related to this area being unused.
  },
}

AREA_INDEX_TO_AREA_NAME = {
   0 => "Dracula's Castle",
   1 => "City of Haze",
   2 => "13th Street",
   3 => "Sandy Grave",
   4 => "Forgotten City",
   5 => "Nation of Fools",
   6 => "Burnt Paradise",
   7 => "Forest of Doom",
   8 => "Dark Academy",
   9 => "Nest of Evil",
  10 => "Boss Rush",
  11 => "Lost Gallery",
  12 => "Epilogue",
  13 => "Unused Boss Rush",
}

SECTOR_INDEX_TO_SECTOR_NAME = {
  0 => {
     0 => "Entrance",
     1 => "Entrance",
     2 => "Buried Chamber",
     3 => "Great Stairway",
     4 => "Great Stairway",
     5 => "Great Stairway",
     6 => "Great Stairway",
     7 => "Tower of Death",
     8 => "Tower of Death",
     9 => "The Throne Room",
    10 => "Master's Keep",
    11 => "Master's Keep",
    12 => "Master's Keep",
  },
}

CONSTANT_OVERLAYS = [0, 5, 6, 7, 8]

INVALID_ROOMS = [0x020E5AD0, 0x020E62E0, 0x020E6300, 0x020E5BA0, 0x020E6320, 0x020E6610, 0x020E7388, 0x020E7780, 0x020E7850]

MAP_TILE_METADATA_LIST_START_OFFSET = 0x020DF3E4
MAP_TILE_LINE_DATA_LIST_START_OFFSET = 0x020DF420
MAP_LENGTH_DATA_START_OFFSET = 0x020BF914

MAP_FILL_COLOR = [160, 64, 128, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [0, 0, 248, 255]
MAP_SECRET_FILL_COLOR = [0, 128, 0, 255]
MAP_ENTRANCE_FILL_COLOR = [248, 128, 0, 255]
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [216, 216, 216, 255]
MAP_DOOR_CENTER_PIXEL_COLOR = [0, 0, 0, 0]

RAM_START_FOR_ROOM_OVERLAYS = 0x022E8820
RAM_END_FOR_ROOM_OVERLAYS = 0x022E8820 + 132736
ARM9_LENGTH = 1_039_288
LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET = 0xD1AFC
LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET = 0xE315B
LIST_OF_FILE_RAM_LOCATIONS_ENTRY_LENGTH = 32

OVERLAY_RAM_INFO_START_OFFSET = 0x101C00
OVERLAY_ROM_INFO_START_OFFSET = 0x67FE00

ENTITY_BLOCK_START_OFFSET = 0x3798D8
ENTITY_BLOCK_END_OFFSET   = 0x6344D1 # guess

ENEMY_DNA_RAM_START_OFFSET = 0x020BE568
ENEMY_DNA_LENGTH = 32
ENEMY_DNA_FORMAT = [
  [4, "Init AI"],
  [4, "Running AI"],
  [2, "Item 1"],
  [2, "Item 2"],
  [1, "Unknown 1"],
  [1, "SP"],
  [2, "HP"],
  [2, "EXP"],
  [1, "Unknown 2"],
  [1, "Attack"],
  [1, "Defense"],
  [1, "Unknown 3"],
  [1, "Item 1 Chance"],
  [1, "Item 2 Chance"],
  [2, "Weaknesses", :bitfield],
  [2, "Unknown 4"],
  [2, "Resistances", :bitfield],
  [2, "Unknown 5"],
]
ENEMY_DNA_BITFIELD_ATTRIBUTES = {
  "Weaknesses" => [
    "Clubs",
    "Spears",
    "Swords",
    "Fire",
    "Water",
    "Lightning",
    "Dark",
    "Holy",
    "Poison",
    "Curse",
    "Earth",
    "Weakness 12",
    "Weakness 13",
    "Weakness 14",
    "Weakness 15",
    "Weakness 16",
  ],
  "Resistances" => [
    "Clubs",
    "Spears",
    "Swords",
    "Fire",
    "Water",
    "Lightning",
    "Dark",
    "Holy",
    "Poison",
    "Curse",
    "Earth",
    "Resistance 12",
    "Time Stop",
    "Resistance 14",
    "Resistance 15",
    "Resistance 16",
  ],
}

STRING_LIST_START_OFFSET = 0x0221BA50
STRING_RANGE = (0..0x748)
STRING_REGIONS = {
  "Character Names" => (0..0xB),
  "Item Names" => (0xC..0x15B),
  "Item Descriptions" => (0x15C..0x2AB),
  "Enemy Names" => (0x2AC..0x348),
  "Enemy Descriptions" => (0x349..0x3E5),
  "Skill Names" => (0x3E6..0x451),
  "Skill Descriptions" => (0x452..0x4BD),
  "Area Names (Unused)" => (0x4BE..0x4C9),
  "Music Names (Unused)" => (0x4CA..0x4E6),
  "Misc" => (0x4E7..0x51F),
  "Menus" => (0x520..0x6BD),
  "Events" => (0x6BE..0x747),
  "Debug" => (0x748..0x748)
}
STRING_REGIONS_OVERLAYS = {
  "Character Names" => 2,
  "Item Names" => 1,
  "Item Descriptions" => 1,
  "Enemy Names" => 1,
  "Enemy Descriptions" => 1,
  "Skill Names" => 1,
  "Skill Descriptions" => 1,
  "Area Names (Unused)" => 1,
  "Music Names (Unused)" => 1,
  "Misc" => 1,
  "Menus" => 1,
  "Events" => 2,
  "Debug" => 1
}

ENTITY_TYPE_FOR_PICKUPS = 0x04

ENEMY_IDS = (0x00..0x9A)
COMMON_ENEMY_IDS = (0x00..0x80).to_a
BOSS_IDS = (0x81..0x9A).to_a
VERY_LARGE_ENEMIES = [0x64, 0x13, 0x79, 0x78, 0x45, 0x25, 0x21, 0x52, 0x2C, 0x7D, 0x7A, 0x22, 0x15] # alura une, andras, flame demon, iron golem, treant, dragon zombie, great armor, final guard, amphisbaena, alastor, demon, catoblepas, golem

ITEM_ID_RANGES = {
  0x02 => (0x00..0x5F), # consumable
  0x03 => (0x01..0x48), # weapon
  0x04 => (0x01..0x39), # body
  0x05 => (0x01..0x25), # head
  0x06 => (0x01..0x1C), # feet
  0x07 => (0x01..0x29), # misc
}

ITEM_BYTE_7_RANGE_FOR_DEFENSIVE_EQUIPMENT = (0x04..0x07)

ITEM_BYTE_7_VALUE_FOR_SKILLS_AND_PASSIVES = 0x08

ITEM_BYTE_11_RANGE_FOR_SKILLS = (0x01..0x5B)
ITEM_BYTE_11_RANGE_FOR_PASSIVES = (0x5C..0x6B) # aka relics in PoR.

# Note: the below are not actually where the original game stores the indexes. All three of those are at 02051F88 (since all three are the same: 00). The three addresses below are free space reused for the purpose of allowing the three values to be different.
NEW_GAME_STARTING_AREA_INDEX_OFFSET = 0x020BFC00
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x020BFC08
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x020BFC0C
