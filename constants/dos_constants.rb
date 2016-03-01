
GAME = "dos"
LONG_GAME_NAME = "Dawn of Sorrow"

AREA_LIST_RAM_START_OFFSET = 0x02006FC4 # Technically not a list, this points to code that has the the area hard coded, since DoS only has one area.

EXTRACT_EXTRA_ROOM_INFO = Proc.new do |last_4_bytes_of_room_metadata|
  number_of_doors    = (last_4_bytes_of_room_metadata & 0b00000000_00000000_11111111_11111111)
  room_xpos_on_map   = (last_4_bytes_of_room_metadata & 0b00000000_00111111_00000000_00000000) >> 16
  room_ypos_on_map   = (last_4_bytes_of_room_metadata & 0b00011111_10000000_00000000_00000000) >> 23
 #unknown_1          = (last_4_bytes_of_room_metadata & 0b00100000_00000000_00000000_00000000) >> 29
  palette_page_index = 0 # always 0 in dos, and so not stored in these 4 bytes
  [number_of_doors, room_xpos_on_map, room_ypos_on_map, palette_page_index]
end

# Overlays 6 to 22.
AREA_INDEX_TO_OVERLAY_INDEX = {
   0 => {
     0 => 14, # lost village
     1 => 11, # demon guest house
     2 =>  6, # wizardry lab
     3 => 16, # garden of madness
     4 =>  8, # dark chapel
     5 =>  7, # condemned tower and mine of judgement
     6 => 17, # subterranean hell
     7 => 15, # silenced ruins
     8 =>  9, # clock tower
     9 => 10, # the pinnacle
    10 => 12, # menace's room
    11 => 13, # the abyss
    12 => 18, # prologue area (in town)
    13 => 19, # epilogue area (overlooking castle)
    14 => 20, # boss rush
    15 => 21, # enemy set mode
    16 => 22, # final room of julius mode where you fight soma
   }
}

AREA_INDEX_TO_AREA_NAME = {
   0 => "Dracula's Castle"
}

SECTOR_INDEX_TO_SECTOR_NAME = {
   0 => {
     0 => "The Lost Village",
     1 => "Demon Guest House",
     2 => "Wizardry Lab",
     3 => "Garden of Madness",
     4 => "The Dark Chapel",
     5 => "Condemned Tower & Mine of Judgment",
     6 => "Subterranean Hell",
     7 => "Silenced Ruins",
     8 => "Cursed Clock Tower",
     9 => "The Pinnacle",
    10 => "Menace",
    11 => "The Abyss",
    12 => "Prologue",
    13 => "Epilogue",
    14 => "Boss Rush",
    15 => "Enemy Set Mode",
    16 => "Throne Room",
  }
}

CONSTANT_OVERLAYS = [0, 1, 2, 3, 4, 5]

INVALID_ROOMS = []

MAP_TILE_METADATA_LIST_START_OFFSET = nil
MAP_TILE_METADATA_START_OFFSET = 0x0207708C
MAP_TILE_LINE_DATA_LIST_START_OFFSET = nil
MAP_TILE_LINE_DATA_START_OFFSET = 0x02076AAC
MAP_LENGTH_DATA_START_OFFSET = nil
ABYSS_MAP_TILE_METADATA_START_OFFSET = 0x020788F4
ABYSS_MAP_TILE_LINE_DATA_START_OFFSET = 0x02078810

MAP_FILL_COLOR = [160, 120, 88, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [0, 0, 248, 255]
MAP_SECRET_FILL_COLOR = [0, 128, 0, 255]
MAP_ENTRANCE_FILL_COLOR = [0, 0, 0, 0] # Area entrances don't exist in DoS.
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [16, 216, 32, 255]
MAP_DOOR_CENTER_PIXEL_COLOR = MAP_DOOR_COLOR

RAM_START_FOR_ROOM_OVERLAYS = 0x022DA4A0
RAM_END_FOR_ROOM_OVERLAYS = 0x022DA4A0 + 152864
ARM9_LENGTH = 813976
LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET = 0x90C6C
LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET = 0x9E0C3
LIST_OF_FILE_RAM_LOCATIONS_ENTRY_LENGTH = 40

OVERLAY_RAM_INFO_START_OFFSET = 0x0CAC00
OVERLAY_ROM_INFO_START_OFFSET = 0x3DEA00

ENTITY_BLOCK_START_OFFSET = 0x0A4B9C
ENTITY_BLOCK_END_OFFSET   = 0x0C3D9C

ENEMY_DNA_RAM_START_OFFSET = 0x02078CAC
ENEMY_DNA_LENGTH = 36
ENEMY_DNA_FORMAT = [
  [4, "Init AI"],
  [4, "Running AI"],
  [2, "Item 1"],
  [2, "Item 2"],
  [1, "Unknown 1"],
  [1, "Unknown 2"],
  [2, "HP"],
  [2, "MP"],
  [2, "EXP"],
  [1, "Soul Chance"],
  [1, "Attack"],
  [1, "Defense"],
  [1, "Item Chance"],
  [2, "Unknown 3"],
  [1, "Soul"],
  [1, "Unknown 4"],
  [2, "Weaknesses", :bitfield],
  [2, "Unknown 5"],
  [2, "Resistances", :bitfield],
  [2, "Unknown 6"],
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

TEXT_LIST_START_OFFSET = 0x0222F300
TEXT_RANGE = (0..0x50A)
TEXT_REGIONS = {
  "Character Names" => (0..0xB),
  "Item Names" => (0xC..0xD9),
  "Item Descriptions" => (0xDA..0x1A7),
  "Enemy Names" => (0x1A8..0x21D),
  "Enemy Descriptions" => (0x21E..0x293),
  "Soul Names" => (0x294..0x30E),
  "Soul Descriptions" => (0x30F..0x389),
  "Area Names" => (0x38A..0x395),
  "Music Names" => (0x396..0x3B2),
  "Misc" => (0x3B3..0x3D8),
  "Menus" => (0x3D9..0x477),
  "Library" => (0x478..0x4A5),
  "Events" => (0x4A6..0x50A)
}
TEXT_REGIONS_OVERLAYS = {}
STRING_DATABASE_START_OFFSET = 0x02217E14
STRING_DATABASE_END_OFFSET = 0x0222B8CA

ENTITY_TYPE_FOR_PICKUPS = 0x04

ENEMY_IDS = (0x00..0x75)
COMMON_ENEMY_IDS = (0x00..0x64).to_a
BOSS_IDS = (0x65..0x73).to_a # regular game bosses end at 0x73 (menace), 0x74 is soma that you fight in julius mode (and 0x75 is his second form, dracula).
VERY_LARGE_ENEMIES = [0x64, 0x60, 0x25, 0x5D, 0x63, 0x0E, 0x61, 0x5B, 0x2F, 0x22] # iron golem, stolas, great armor, arc demon, alastor, golem, final guard, flame demon, devil, treant

ITEM_LOCAL_ID_RANGES = {
  0x02 => (0x00..0x41), # consumable
  0x03 => (0x01..0x4E), # weapon
  0x04 => (0x00..0x3D), # body armor
}
ITEM_GLOBAL_ID_RANGE = (1..0xCE)
SOUL_GLOBAL_ID_RANGE = (0..0x7A)

ITEM_BYTE_7_RANGE_FOR_DEFENSIVE_EQUIPMENT = (0x04..0x04)

ITEM_BYTE_7_VALUE_FOR_SKILLS_AND_PASSIVES = 0x05

ITEM_BYTE_11_RANGE_FOR_SKILLS = (0x00..0x73)
ITEM_BYTE_11_RANGE_FOR_PASSIVES = (0x74..0x7A) # aka ability souls in DoS.

NEW_GAME_STARTING_AREA_INDEX_OFFSET = nil
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x0202FB84
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x0202FB90
