
GAME = "por"
LONG_GAME_NAME = "Portrait of Ruin"

#AREA_LIST_START_OFFSET = 0x0E7A5C

MAJOR_AREA_LIST_START_OFFSET = 0x0E336C

GET_LIST_OF_MAJOR_AREAS = Proc.new do |rom, converter|
  i = 0
  major_areas = []
  while true
    major_area_pointer = rom[0x0E336C+i*4, 4].unpack("V*").first
    break if major_area_pointer == 0
    major_areas << converter.ram_to_rom(major_area_pointer) #- 0x2000000 + 0x4000
    i += 1
  end
  major_areas
end

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
  0 => {
     0 => "01 - Entrance",
     1 => "01 - Entrance",
     2 => "03 - Buried Chamber",
     3 => "04 - Great Stairway",
     4 => "04 - Great Stairway",
     5 => "04 - Great Stairway",
     6 => "04 - Great Stairway",
     7 => "07 - Tower of Death",
     8 => "07 - Tower of Death",
     9 => "16 - The Throne Room",
    10 => "09 - Master's Keep",
    11 => "09 - Master's Keep",
    12 => "09 - Master's Keep",
  },
  1 => "02 - City of Haze",
  2 => "13 - 13th Street",
  3 => "05 - Sandy Grave",
  4 => "11 - Forgotten City",
  5 => "06 - Nation of Fools",
  6 => "12 - Burnt Paradise",
  7 => "08 - Forest of Doom",
  8 => "10 - Dark Academy",
  9 => "14 - Nest of Evil",
  10 => "15 - Boss Rush",
  11 => "Lost Gallery",
  12 => "Epilogue",
  13 => "Unused Boss Rush",
}

CONSTANT_OVERLAYS = []

INVALID_ROOMS = [0x020E5AD0, 0x020E62E0, 0x020E6300, 0x020E5BA0, 0x020E6320, 0x020E6610, 0x020E7388, 0x020E7780, 0x020E7850]

MAP_TILE_METADATA_LIST_START_OFFSET = 0x020DF3E4
MAP_TILE_LINE_DATA_LIST_START_OFFSET = 0x020DF420
MAP_LENGTH_DATA_START_OFFSET = 0x020BF914

MAP_FILL_COLOR = [160, 64, 128, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [0, 0, 248, 255]
MAP_ENTRANCE_FILL_COLOR = [248, 128, 0, 255]
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [216, 216, 216, 255]

RAM_START_FOR_ROOM_OVERLAYS = 0x022E8820
RAM_END_FOR_ROOM_OVERLAYS = 0x022E8820 + 132736
ARM9_LENGTH = 1_039_288
FILENAMES_IN_BC_FOLDER_START_OFFSET = 0x678E93
FILES_IN_BC_FOLDER_ROM_OFFSETS_LIST_START = 0x6801B8
BC_FOLDER_START_OFFSET = 0xD1AFC
BC_FOLDER_END_OFFSET = 0xD6DDB
BC_FOLDER_FILE_LENGTH = 32

OVERLAY_RAM_INFO_START_OFFSET = 0x101C00
OVERLAY_ROM_INFO_START_OFFSET = 0x67FE00

ENTITY_BLOCK_START_OFFSET = 0x3798D8
ENTITY_BLOCK_END_OFFSET   = 0x6344D1 # guess

ENEMY_IDS = (0x00..0x80).to_a
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