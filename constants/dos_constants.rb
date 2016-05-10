
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
    "Made of flesh",
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
    "Backstab",
    "Resistance 16",
  ],
}

# Overlays 23 to 40 used for enemies.
OVERLAY_FILE_FOR_ENEMY_AI = {
  # Enemies not listed here use one of the constant overlays like 0.
   14 => 28, # golem
   18 => 27, # manticore
   25 => 32, # catoblepas
   34 => 28, # treant
   37 => 24, # great armor
   47 => 31, # devil
   77 => 32, # gorgon
   81 => 27, # musshusu
   91 => 31, # flame demon
   93 => 31, # arc demon
   97 => 24, # final guard
  100 => 28, # iron golem
  101 => 30, # flying armor
  102 => 23, # balore
  103 => 29, # malphas
  104 => 40, # dmitrii
  105 => 25, # dario
  106 => 25, # puppet master
  107 => 26, # rahab
  108 => 36, # gergoth
  109 => 33, # zephyr
  110 => 37, # bat company
  111 => 35, # paranoia
  113 => 34, # death
  114 => 39, # abaddon
  115 => 38, # menace
}

REUSED_ENEMY_INFO = {
  # Enemies that had parts of them reused from another enemy.
  # init_code: The init code of the original enemy. This is where to look for gfx/palette/sprite data, not the reused enemy's init code.
  # gfx_sheet_ptr_index: The reused enemy uses a different gfx sheet than the original enemy. This value is which one to use.
  # palette_offset: The reused enemy uses different palettes than the original, but they're still in the same list of palettes. This is the offset of the new palette in the list.
  # palette_list_ptr_index: The reused enemy uses a completely different palette list from the original. This value is which one to use.
  26 => {init_code: 0x0223266C, gfx_sheet_ptr_index: 0, palette_offset: 2, palette_list_ptr_index: 0}, # ghoul and zombie
  84 => {init_code: 0x02270704, gfx_sheet_ptr_index: 0, palette_offset: 1, palette_list_ptr_index: 0}, # erinys and valkyrie
  92 => {init_code: 0x02288FBC, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # tanjelly and slime
  91 => {init_code: 0x022FF9F0, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1}, # flame demon and devil
  93 => {init_code: 0x022FF9F0, gfx_sheet_ptr_index: 2, palette_offset: 0, palette_list_ptr_index: 2}, # arc demon and devil
}

BEST_SPRITE_FRAME_FOR_ENEMY = {
  # Enemies not listed here default to frame 0.
    0 =>   8, # zombie
    5 =>  38, # peeping eye
    9 =>   7, # spin devil
   14 =>  19, # golem
   16 =>   7, # une
   18 =>  78, # manticore
   21 =>  14, # mandragora
   23 =>  13, # skeleton farmer
   26 =>   8, # ghoul
   27 =>  17, # corpseweed
   34 =>  15, # treant
   35 =>  17, # amalaric sniper
   37 =>  20, # great armor
   38 =>  27, # killer doll
   41 =>   5, # witch
   43 =>   8, # lilith
   44 =>   3, # killer clown
   46 =>   6, # fleaman
   48 =>  37, # guillotiner
   49 =>  17, # draghignazzo
   54 =>  27, # wakwak tree
   60 =>  10, # larva
   61 =>   4, # heart eater
   64 =>   2, # medusa head
   67 =>   1, # mimic
   74 =>  39, # bugbear
   76 =>  42, # bone ark
   78 =>  10, # alura une
   79 =>   6, # great axe armor
   83 =>   5, # dead warrior
   85 =>   9, # succubus
   86 =>  16, # ripper
   92 =>  11, # tanjelly
   97 =>  20, # final guard
   98 =>  31, # malacoda
   99 =>   1, # alastor
  100 =>  15, # iron golem
  101 =>   6, # flying armor
  102 =>   5, # balore
  107 => 113, # rahab
  108 =>  16, # gergoth
  110 =>   5, # bat company
  111 =>  23, # paranoia
  113 =>  22, # death
  115 =>  31, # menace
  116 =>  22, # soma
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
STRING_DATABASE_ORIGINAL_END_OFFSET = 0x0222B8CA
STRING_DATABASE_ALLOWABLE_END_OFFSET = STRING_DATABASE_ORIGINAL_END_OFFSET

NAMES_FOR_UNNAMED_SKILLS = {
  0x2E => "Bat Form",
  0x2F => "Holy Flame",
  0x30 => "Blue Splash",
  0x31 => "Holy Lightning",
  0x32 => "Cross",
  0x33 => "Holy Water",
  0x34 => "Grand Cross",
}

ENEMY_IDS = (0x00..0x75)
COMMON_ENEMY_IDS = (0x00..0x64).to_a
BOSS_IDS = (0x65..0x75).to_a
FINAL_BOSS_IDS = (0x73..0x75).to_a
RANDOMIZABLE_BOSS_IDS = BOSS_IDS - FINAL_BOSS_IDS

BOSS_DOOR_SUBTYPE = 0x25
BOSS_ID_TO_BOSS_DOOR_VAR_B = {
  0x65 => 0x01,
  0x66 => 0x02,
  0x67 => 0x04,
  0x68 => 0x03,
  0x69 => 0x05,
  0x6A => 0x06,
  0x6B => 0x08,
  0x6C => 0x07,
  0x6D => 0x09,
  0x6E => 0x0A,
  0x6F => 0x0C,
  0x70 => 0x0B,
  0x71 => 0x0D,
  0x72 => 0x0F,
}

ITEM_LOCAL_ID_RANGES = {
  0x02 => (0x00..0x41), # consumable
  0x03 => (0x01..0x4E), # weapon
  0x04 => (0x00..0x3D), # body armor
}
ITEM_GLOBAL_ID_RANGE = (1..0xCE)
SOUL_GLOBAL_ID_RANGE = (0..0x7A)

ITEM_BYTE_7_RANGE_FOR_DEFENSIVE_EQUIPMENT = (0x04..0x04)

ITEM_BYTE_7_VALUE_FOR_SKILLS_AND_PASSIVES = 0x05

NEW_GAME_STARTING_AREA_INDEX_OFFSET = nil
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x0202FB84
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x0202FB90

TRANSITION_ROOM_LIST_POINTER = 0x0208AD8C
FAKE_TRANSITION_ROOMS = []

ITEM_TYPES = [
  {
    name: "Consumables",
    list_pointer: 0x0209BA68,
    count: 66,
    format: [
      [2, "Item ID"],
      [1, "Icon"],
      [1, "Palette"],
      [4, "Price"],
      [1, "Type"],
      [1, "Unknown 1"],
      [2, "Var A"],
      [4, "Unused"],
    ]
  },
  {
    name: "Body Armor",
    list_pointer: 0x0209BE88,
    count: 61,
    format: [
      [2, "Item ID"],
      [1, "Icon"],
      [1, "Palette"],
      [4, "Price"],
      [1, "Type"],
      [1, "Unknown 1"],
      [1, "Attack"],
      [1, "Defense"],
      [1, "Strength"],
      [1, "Constitution"],
      [1, "Intelligence"],
      [1, "Luck"],
      [2, "Resistances", :bitfield],
      [1, "Unknown 2"],
      [1, "Unknown 3"],
    ]
  },
  {
    name: "Weapons",
    list_pointer: 0x0209C34C,
    count: 79,
    format: [
      [2, "Item ID"],
      [1, "Icon"],
      [1, "Palette"],
      [4, "Price"],
      [1, "Swing Anim"],
      [1, "Unknown 1"],
      [1, "Attack"],
      [1, "Defense"],
      [1, "Strength"],
      [1, "Constitution"],
      [1, "Intelligence"],
      [1, "Luck"],
      [2, "Effects", :bitfield],
      [1, "Unknown 2"],
      [1, "Unknown 3"],
      [1, "Sprite"],
      [1, "Super Anim"],
      [2, "Unknown 4"],
      [2, "Swing Modifiers", :bitfield],
      [2, "Swing Sound"],
    ]
  }
]

ITEM_BITFIELD_ATTRIBUTES = {
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
    "Resistance 13",
    "Resistance 14",
    "Resistance 15",
    "Resistance 16",
  ],
  "Effects" => [
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
