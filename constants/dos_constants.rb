
GAME = "dos"
LONG_GAME_NAME = "Dawn of Sorrow"

MAJOR_AREA_LIST_START_OFFSET = 0x00AFC4 # Technically not a list, this points to code that has the the major area hard coded, since DoS only has one major area.

#AREA_LIST_START_OFFSET = 0x08ED44

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
   0 => {
     0 => "00 - The Lost Village",
     1 => "01 - Demon Guest House",
     2 => "02 - Wizardry Lab",
     3 => "03 - Garden of Madness",
     4 => "04 - The Dark Chapel",
     5 => "05 - Condemned Tower & Mine of Judgment",
     6 => "06 - Subterranean Hell",
     7 => "07 - Silenced Ruins",
     8 => "08 - Cursed Clock Tower",
     9 => "09 - The Pinnacle",
    10 => "10 - Menace",
    11 => "11 - The Abyss",
    12 => "12 - Prologue",
    13 => "13 - Epilogue",
    14 => "14 - Boss Rush",
    15 => "15 - Enemy Set Mode",
    16 => "16 - Throne Room",
  }
}

CONSTANT_OVERLAYS = []

INVALID_ROOMS = []

MAP_TILE_METADATA_LIST_START_OFFSET = nil
MAP_TILE_METADATA_START_OFFSET = 0x0207708C
MAP_TILE_LINE_DATA_LIST_START_OFFSET = nil
MAP_TILE_LINE_DATA_START_OFFSET = 0x02076AAC
MAP_LENGTH_DATA_START_OFFSET = nil

MAP_FILL_COLOR = [160, 120, 88, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [0, 0, 248, 255]
MAP_ENTRANCE_FILL_COLOR = [0, 0, 0, 0] # Area entrances don't exist in DoS.
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [16, 216, 32, 255]

RAM_START_FOR_ROOM_OVERLAYS = 0x022DA4A0
RAM_END_FOR_ROOM_OVERLAYS = 0x022DA4A0 + 152864
ARM9_LENGTH = 813976
FILENAMES_IN_BC_FOLDER_START_OFFSET = 0x3DA676
FILES_IN_BC_FOLDER_ROM_OFFSETS_LIST_START = 0x3DEB50
BC_FOLDER_START_OFFSET = 0x90C6C
BC_FOLDER_END_OFFSET = 0x94483
BC_FOLDER_FILE_LENGTH = 40

OVERLAY_RAM_INFO_START_OFFSET = 0x0CAC00
OVERLAY_ROM_INFO_START_OFFSET = 0x3DEA00

ENTITY_BLOCK_START_OFFSET = 0x0A4B9C
ENTITY_BLOCK_END_OFFSET   = 0x0C3D9C

ENEMY_DNA_START_OFFSET = 0x07CCAC

COMMON_ENEMY_IDS = (0x00..0x64).to_a
BOSS_IDS = (0x65..0x73).to_a # regular game bosses end at 0x73 (menace), 0x74 is soma that you fight in julius mode (and 0x75 is his second form, dracula).
VERY_LARGE_ENEMIES = [0x64, 0x60, 0x25, 0x5D, 0x63, 0x0E, 0x61, 0x5B, 0x2F, 0x22] # iron golem, stolas, great armor, arc demon, alastor, golem, final guard, flame demon, devil, treant

ITEM_ID_RANGES = {
  0x02 => (0x00..0x41), # consumable
  0x03 => (0x01..0x4E), # weapon
  0x04 => (0x00..0x3D), # body armor
}

ITEM_BYTE_7_RANGE_FOR_DEFENSIVE_EQUIPMENT = (0x04..0x04)

ITEM_BYTE_7_VALUE_FOR_SKILLS_AND_PASSIVES = 0x05

ITEM_BYTE_11_RANGE_FOR_SKILLS = (0x00..0x73)
ITEM_BYTE_11_RANGE_FOR_PASSIVES = (0x74..0x7A) # aka ability souls in DoS.