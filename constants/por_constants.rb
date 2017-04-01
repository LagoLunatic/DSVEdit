
GAME = "por"
REGION = :usa
LONG_GAME_NAME = "Portrait of Ruin"

AREA_LIST_RAM_START_OFFSET = 0x020DF36C

# Overlays 78 to 118. Missing: 116
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

ENTITY_TYPE_DESCRIPTIONS = {
  0 => "Nothing",
  1 => "Enemy",
  2 => "Special object",
  3 => "Candle",
  4 => "Pickup",
  5 => "???",
  6 => "All-quests-complete pickup",
  7 => "Hidden pickup",
  8 => "Entity hider",
  9 => "Font loader",
}

CONSTANT_OVERLAYS = [0, 5, 6, 7, 8]

ROOM_OVERLAYS = (78..117)
MAX_ALLOWABLE_ROOM_OVERLAY_SIZE = 132736

MAP_TILE_METADATA_LIST_START_OFFSET = 0x020DF3E4
MAP_TILE_LINE_DATA_LIST_START_OFFSET = 0x020DF420
MAP_LENGTH_DATA_START_OFFSET = 0x020BF914
MAP_SECRET_DOOR_LIST_START_OFFSET = 0x020DF2F4

MAP_FILL_COLOR = [160, 64, 128, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [0, 0, 248, 255]
MAP_SECRET_FILL_COLOR = [0, 128, 0, 255]
MAP_ENTRANCE_FILL_COLOR = [248, 128, 0, 255]
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [216, 216, 216, 255]
MAP_DOOR_CENTER_PIXEL_COLOR = [0, 0, 0, 0]
MAP_SECRET_DOOR_COLOR = [248, 248, 0, 255]

AREA_MUSIC_LIST_START_OFFSET = 0x020DF2A4
SECTOR_MUSIC_LIST_START_OFFSET = 0x020DF2B4
AVAILABLE_BGM_POOL_START_OFFSET = 0x020E0204
SONG_INDEX_TO_TEXT_INDEX = [
  "Silence",
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
  0x60E,
  0x614,
  0x60D,
  0x60F,
  0x611,
  0x612,
  0x613,
  0x620,
  0x615,
  0x610,
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
  0x621,
]

LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET = 0x020CDAFC
LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET = 0x020DF15B
LIST_OF_FILE_RAM_LOCATIONS_ENTRY_LENGTH = 0x20

COLOR_OFFSETS_PER_256_PALETTE_INDEX = 256

ENEMY_DNA_RAM_START_OFFSET = 0x020BE568
ENEMY_DNA_FORMAT = [
  # length: 32
  [4, "Init AI"],
  [4, "Running AI"],
  [2, "Item 1"],
  [2, "Item 2"],
  [1, "Petrified Palette"],
  [1, "SP"],
  [2, "HP"],
  [2, "EXP"],
  [1, "Unknown 2"],
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
    "Whip",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Dark",
    "Holy",
    "Poison",
    "Curse",
    "Stone",
    "Weakness 12",
    "Weakness 13",
    "Weakness 14",
    "Weakness 15",
    "Made of flesh",
    "Weakness 17",
    "Weakness 18",
    "Weakness 19",
    "Weakness 20",
    "Weakness 21",
    "Weakness 22",
    "Weakness 23",
    "Weakness 24",
    "Weakness 25",
    "Weakness 26",
    "Weakness 27",
    "Weakness 28",
    "Weakness 29",
    "Weakness 30",
    "Weakness 31",
    "Weakness 32",
  ],
  "Resistances" => [
    "Strike",
    "Whip",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Dark",
    "Holy",
    "Poison",
    "Curse",
    "Stone",
    "Resistance 12",
    "Time Stop",
    "Resistance 14",
    "Resistance 15",
    "Resistance 16",
    "Resistance 17",
    "Resistance 18",
    "Resistance 19",
    "Resistance 20",
    "Resistance 21",
    "Resistance 22",
    "Resistance 23",
    "Resistance 24",
    "Resistance 25",
    "Projectile Deflect",
    "Resistance 27",
    "Resistance 28",
    "Resistance 29",
    "Resistance 30",
    "Resistance 31",
    "Resistance 32",
  ],
}

# Overlays 25 and 43 to 77 used for enemies.
OVERLAY_FILE_FOR_ENEMY_AI = {
  # Enemies not listed here use one of the constant overlays like 0.
  0x13 => 72, # andras
  0x15 => 76, # golem
  0x21 => 44, # great armor
  0x22 => 48, # catoblepas
  0x25 => 68, # dragon zombie
  0x2A => 69, # sand worm
  0x2C => 62, # amphisbaena
  0x2D => 54, # elgiza
  0x45 => 45, # treant
  0x4E => 47, # flame demon
  0x51 => 46, # malphas
  0x52 => 44, # final guard
  0x55 => 71, # ruler's sword
  0x5A => 77, # amalaric sniper
  0x5C => 48, # gorgon
  0x64 => 73, # alura une
  0x72 => 69, # poison worm
  0x78 => 45, # iron golem
  0x7A => 47, # demon
  0x7D => 75, # alastor
  0x81 => 43, # balore
  0x82 => 50, # gergoth
  0x83 => 49, # zephyr
  0x84 => 67, # aguni
  0x85 => 51, # abaddon
  0x87 => 70, # fake trevor
  0x88 => 70, # fake grant
  0x89 => 70, # fake sypha
  0x8A => 58, # dullahan
  0x8B => 53, # behemoth
  0x8C => 56, # keremet
  0x8D => 74, # astarte
  0x8E => 52, # legion
  0x8F => 59, # dagon
  0x90 => 64, # death
  0x91 => 63, # stella/loretta
  0x92 => 63, # stella/loretta
  0x93 => 55, # brauner
  0x94 => 60, # the creature
  0x95 => 57, # werewolf
  0x96 => 61, # medusa
  0x97 => 66, # mummy man
  0x98 => 25, # whip's memory
  0x99 => 64, # dracula
  0x9A => 65, # true dracula
}
REUSED_ENEMY_INFO = {
  0x31 => {palette_offset: 2}, # lilith
  0x46 => {init_code: 0x02297320, palette_offset: 3}, # red axe armor -> axe armor
  0x4E => {init_code: 0x022D7930}, # flame demon
  0x54 => {palette_offset: 1}, # ghoul and zombie
  0x58 => {init_code: 0x022744DC, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1}, # buster armor -> crossbow armor
  0x5C => {init_code: 0x022D7918, palette_list_ptr_index: 1}, # gorgon -> catoblepas
  0x5E => {init_code: 0x02259EE4}, # tanjelly -> slime
  0x63 => {init_code: 0x022630F8}, # vice beetle -> spittle bone
  0x72 => {init_code: 0x022D7900, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # poison worm -> sand worm
  0x79 => {init_code: 0x02297320, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # double axe armor -> axe armor
  0x7A => {init_code: 0x022D7930, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # demon
  0x7E => {palette_offset: 1}, # golden skeleton and skeleton
  0x98 => {init_code: 0x0221E954} # whip's memory. for some reason his pointers are off in some random place not near his init code.
}
RICHTERS_LIST_OF_GFX_POINTERS = 0x0221E6B0
BEST_SPRITE_FRAME_FOR_ENEMY = {
  0x00 => 0x1A, # zombie
  0x0B => 0x07, # une
  0x0E => 0x10, # forneus
  0x11 => 0x1A, # wight
  0x14 => 0x08, # invisible man
  0x17 => 0x02, # mimic
  0x1A => 0x33, # spittle bone
  0x1B => 0x06, # ghost
  0x1E => 0x0F, # ectoplasm
  0x20 => 0x06, # fleaman
  0x21 => 0x14, # great armor
  0x22 => 0x24, # catoblepas
  0x25 => 0x5F, # dragon zombie
  0x26 => 0x03, # killer clown
  0x28 => 0x04, # hanged bones
  0x29 => 0x11, # flying skull
  0x2D => 0x27, # elgiza
  0x30 => 0x01, # crossbow armor
  0x31 => 0x12, # lilith
  0x32 => 0x01, # skeleton flail
  0x37 => 0x11, # corpseweed
  0x38 => 0x02, # medusa head
  0x3D => 0x0A, # blue crow
  0x3E => 0x0F, # frog
  0x3F => 0x1B, # killer doll
  0x40 => 0x02, # killer bee
  0x41 => 0x03, # dogether
  0x42 => 0x1F, # bee hive
  0x43 => 0x1B, # moldy corpse
  0x45 => 0x0F, # treant
  0x4C => 0x11, # spin devil
  0x4D => 0x12, # succubus
  0x52 => 0x14, # final guard
  0x53 => 0x1B, # glasya labolas
  0x54 => 0x1A, # ghoul
  0x56 => 0x05, # witch
  0x57 => 0x1A, # skeleton tree
  0x58 => 0x01, # buster armor
  0x5C => 0x24, # gorgon
  0x5E => 0x0B, # tanjelly
  0x5F => 0x05, # dead warrior
  0x63 => 0x44, # vice beetle
  0x64 => 0x0A, # alura une
  0x67 => 0x0E, # mandragora
  0x68 => 0x1B, # wakwak tree
  0x69 => 0x25, # guillotiner
  0x6A => 0x01, # nyx
  0x71 => 0x0B, # ripper
  0x74 => 0x2D, # demon head
  0x76 => 0x1A, # ghoul king
  0x77 => 0x16, # vapula
  0x78 => 0x0F, # iron golem
  0x7B => 0x2A, # bone ark
  0x7C => 0x0D, # skeleton farmer
  0x7D => 0x01, # alastor
  0x80 => 0x18, # amducias
  0x81 => 0x05, # balore
  0x82 => 0x10, # gergoth
  0x8A => 0x5E, # dullahan
  0x8B => 0x35, # behemoth
  0x8C => 0x5B, # keremet
  0x8D => 0x1B, # astarte
  0x90 => 0x19, # death
  0x96 => 0x36, # medusa
  0x9A => 0x09, # true dracula
}

ENEMY_FILES_TO_LOAD_LIST = 0x020CD88C

SPECIAL_OBJECT_IDS = (0..0xBE)
SPECIAL_OBJECT_CREATE_CODE_LIST = 0x0221D908
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x0221DC18
OVERLAY_FILE_FOR_SPECIAL_OBJECT = {
  0x1C => 78,
  0x21 => 92,
  0x25 => 93,
  0x28 => 104,
  0x2E => 86,
  0x2F => 101,
  0x30 => 111,
  0x31 => 94,
  0x32 => 91,
  0x39 => 86,
  0x3A => 79,
  0x40 => 81,
  0x46 => 85,
  0x48 => 86,
  0x4A => 85,
  0x4E => 79,
  0x50 => 109,
  0x51 => 110,
  0x52 => 111,
  0x53 => 112,
  0x54 => 91,
  0x55 => 92,
  0x56 => 102,
  0x57 => 103,
  0x61 => 93,
  0x62 => 91,
  0x63 => 99,
  0x64 => 100,
  0x65 => 111,
  0x66 => 112,
  0x7E => 86,
  0x7F => 93,
  0x84 => 99,
  0x8B => 102,
  0x8E => 98,
  0x8F => 89,
  0x94 => 109,
}
REUSED_SPECIAL_OBJECT_INFO = {
  0x00 => {init_code: 0x020F4B6C},
  0x01 => {init_code: 0x020F4B6C},
  0x02 => {init_code:         -1},
  0x03 => {init_code:         -1},
  0x06 => {init_code:         -1},
  0x16 => {init_code:         -1},
  0x1A => {init_code: 0x020F4E84}, # portrait
  0x1B => {init_code:         -1},
  0x22 => {sprite: 0x022B36E8, gfx_wrapper: 0x020BFF24, palette: 0x022B7660},
  0x23 => {init_code:         -1},
  0x24 => {init_code:         -1},
  0x42 => {init_code:         -1},
  0x61 => {init_code:         -1},
  0x62 => {init_code:         -1},
  0x63 => {init_code:         -1},
  0x64 => {init_code:         -1},
  0x65 => {init_code:         -1},
  0x66 => {init_code:         -1},
  0x67 => {init_code:         -1},
  0x76 => {init_code: 0x020F4E90}, # portrait
  0x82 => {sprite: 0x022B36E8, gfx_wrapper: 0x020BFF24, palette: 0x022B7660},
  0x86 => {init_code: 0x020F4E84}, # portrait
  0x87 => {init_code: 0x020F4E90}, # portrait
  0x8B => {init_code:         -1},
  0x94 => {init_code:         -1},
  0x95 => {init_code:         -1},
  0x96 => {init_code:         -1},
  0x97 => {init_code:         -1},
  0x98 => {init_code:         -1},
  0x99 => {init_code:         -1},
  0x9A => {init_code:         -1},
  0x9B => {init_code:         -1},
  0x9C => {init_code:         -1},
  0x9D => {init_code:         -1},
  0x9E => {init_code:         -1},
  0x9F => {init_code:         -1},
  0xA0 => {init_code:         -1},
  0xA1 => {init_code:         -1},
  0xA2 => {init_code:         -1},
  0xA3 => {init_code:         -1},
  0xA4 => {init_code:         -1},
  0xA5 => {init_code:         -1},
  0xA6 => {init_code:         -1},
  0xA7 => {init_code:         -1},
  0xA8 => {init_code:         -1},
  0xA9 => {init_code:         -1},
  0xAA => {init_code:         -1},
  0xAB => {init_code:         -1},
  0xAC => {init_code:         -1},
  0xAD => {init_code:         -1},
  0xAE => {init_code:         -1},
  0xAF => {init_code:         -1},
  0xB0 => {init_code:         -1},
  0xB1 => {init_code:         -1},
  0xB2 => {init_code:         -1},
  0xB3 => {init_code:         -1},
  0xB4 => {init_code:         -1},
  0xB5 => {init_code:         -1},
  0xB6 => {init_code: 0x0221B9C0},
  0xB7 => {init_code: 0x0221B9D0},
  0xB8 => {init_code: 0x0221B9E0},
  0xB9 => {init_code: 0x0221B9F0},
  0xBA => {init_code: 0x0221BA00},
  0xBB => {init_code: 0x0221BA10},
  0xBC => {init_code: 0x0221BA20},
  0xBD => {init_code: 0x0221BA30},
  0xBE => {init_code: 0x0221BA40},
}
BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT = {
  0x01 => 0x0F,
  0x17 =>   -1,
  0x18 =>   -1,
  0x19 =>   -1,
  0x1C => 0x19,
  0x22 => 0xDF,
  0x25 => 0x0E,
  0x27 =>   -1,
  0x29 =>   -1,
  0x2A =>   -1,
  0x2B =>   -1,
  0x2F => 0x01,
  0x32 => 0x09,
  0x33 => 0x08,
  0x39 => 0x01,
  0x43 => 0x0A,
  0x45 =>   -1,
  0x49 =>   -1,
  0x4D => 0x02,
  0x58 => 0x01,
  0x59 => 0x03,
  0x5B => 0x03,
  0x5F => 0x02,
  0x6A => 0x02,
  0x6B => 0x04,
  0x79 => 0x07,
  0x7A => 0x07,
  0x82 => 0xED,
}
SPECIAL_OBJECT_FILES_TO_LOAD_LIST = 0x020E19DC

WEAPON_GFX_LIST_START = 0x0221F110
SKILL_GFX_LIST_START = 0x0221ED18

OTHER_SPRITES = [
  {desc: "Common", sprite: 0x022B36E8, gfx_wrapper: 0x020BFF24, palette: 0x022B7660},
  
  {pointer: 0x0221E7F4, desc: "Jonathan player"},
  {pointer: 0x0221E84C, desc: "Charlotte player"},
  {pointer: 0x0221E8A4, desc: "Stella player"},
  {pointer: 0x0221E8FC, desc: "Loretta player"},
  {pointer: 0x0221E950, desc: "Richter player"},
  {pointer: 0x0221E9AC, desc: "Maria player"},
  {pointer: 0x0221EA04, desc: "Old Axe Armor player"},
  
  {pointer: 0x020F4B58, desc: "Destructibles 0"},
  {pointer: 0x020F4B6C, desc: "Destructibles 1"},
  {pointer: 0x020F4B80, desc: "Destructibles 2"},
  {pointer: 0x020F4B94, desc: "Destructibles 3"},
  {pointer: 0x020F4BA8, desc: "Destructibles 4"},
  {pointer: 0x020F4BBC, desc: "Destructibles 5"},
  {pointer: 0x020F4BD0, desc: "Destructibles 6"},
  {pointer: 0x020F4BE4, desc: "Destructibles 7"},
  {pointer: 0x020F4BF8, desc: "Destructibles 8"},
  {pointer: 0x020F4C0C, desc: "Destructibles 9"},
  {pointer: 0x020F4C20, desc: "Destructibles 10"},
  {pointer: 0x020F4C34, desc: "Destructibles 11"},
  {pointer: 0x020F4C48, desc: "Destructibles 12"},
  {pointer: 0x020F4C5C, desc: "Destructibles 13"},
  {pointer: 0x020F4C70, desc: "Destructibles 14"},
  {pointer: 0x020F4C84, desc: "Destructibles 15"},
  {pointer: 0x020F4E84, desc: "Portrait frame 0"},
  {pointer: 0x020F4E90, desc: "Portrait frame 1"},
  {pointer: 0x020F4E9C, desc: "Portrait painting 0"},
  {pointer: 0x020F4EA8, desc: "Portrait painting 1"},
  {pointer: 0x020F4EB4, desc: "Portrait painting ???"}, # broken
  {pointer: 0x020F4EC0, desc: "Portrait painting 3"},
  
  {pointer: 0x0206E4C8, desc: "Breakable walls 1", gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1},
  {pointer: 0x0206E4C8, desc: "Breakable walls 2", gfx_sheet_ptr_index: 4, palette_list_ptr_index: 4, sprite_ptr_index: 4},
  {pointer: 0x0206E4C8, desc: "Breakable walls 3", gfx_sheet_ptr_index: 0, palette_list_ptr_index: 0, sprite_ptr_index: 0},
  {pointer: 0x0206E4C8, desc: "Breakable walls 4", gfx_sheet_ptr_index: 5, palette_list_ptr_index: 5, sprite_ptr_index: 5},
  {pointer: 0x0206E4C8, desc: "Breakable walls 5", gfx_sheet_ptr_index: 6, palette_list_ptr_index: 6, sprite_ptr_index: 6},
  {pointer: 0x0206E4C8, desc: "Breakable walls 6", gfx_sheet_ptr_index: 2, palette_list_ptr_index: 2, sprite_ptr_index: 2},
  {pointer: 0x0206E4C8, desc: "Breakable walls 7", gfx_sheet_ptr_index: 7, palette_list_ptr_index: 7, sprite_ptr_index: 7},
  {pointer: 0x0206E4C8, desc: "Breakable walls 8", gfx_sheet_ptr_index: 3, palette_list_ptr_index: 3, sprite_ptr_index: 3},
  
  {pointer: 0x022E0700, desc: "Title screen graphics", overlay: 26},
  {pointer: 0x022E0710, desc: "Title screen options", overlay: 26},
  {pointer: 0x022DA15C, desc: "Select data menu", overlay: 25},
  {pointer: 0x022DAAE0, desc: "Name entry menu", overlay: 25},
  {pointer: 0x022DEE20, desc: "Co-op mode start menu", overlay: 25},
  {pointer: 0x022DC9AC, desc: "Co-op mode end menu", overlay: 25},
  {pointer: 0x0203BCBC, desc: "Equip menu", one_dimensional_mode: true},
  
  {pointer: 0x022D7CBC, desc: "Brauner inside mirror portrait", overlay: 55},
  {pointer: 0x022D7C98, desc: "Brauner curse beast", overlay: 55},
]

OVERLAY_FILES_WITH_SPRITE_DATA = [5, 6]

TEXT_LIST_START_OFFSET = 0x0221BA50
TEXT_RANGE = (0..0x748)
TEXT_REGIONS = {
  "Character Names" => (0..0xB),
  "Item Names" => (0xC..0x15B),
  "Item Descriptions" => (0x15C..0x2AB),
  "Enemy Names" => (0x2AC..0x348),
  "Enemy Descriptions" => (0x349..0x3E5),
  "Skill Names" => (0x3E6..0x451),
  "Skill Descriptions" => (0x452..0x4BD),
  "Music Names (Unused)" => (0x4BE..0x4E6),
  "Misc" => (0x4E7..0x51F),
  "Menus" => (0x520..0x6BD),
  "Events" => (0x6BE..0x747),
  "Debug" => (0x748..0x748)
}
TEXT_REGIONS_OVERLAYS = {
  "Character Names" => 2,
  "Item Names" => 1,
  "Item Descriptions" => 1,
  "Enemy Names" => 1,
  "Enemy Descriptions" => 1,
  "Skill Names" => 1,
  "Skill Descriptions" => 1,
  "Music Names (Unused)" => 1,
  "Misc" => 1,
  "Menus" => 1,
  "Events" => 2,
  "Debug" => 1
}
STRING_DATABASE_START_OFFSET = 0x0221F680
STRING_DATABASE_ORIGINAL_END_OFFSET = 0x0222C835 # for overlay 1. overlay 2 ends at 0222B34C
STRING_DATABASE_ALLOWABLE_END_OFFSET = STRING_DATABASE_ORIGINAL_END_OFFSET
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

ENEMY_IDS = (0x00..0x9A)
COMMON_ENEMY_IDS = (0x00..0x80).to_a
BOSS_IDS = (0x81..0x9A).to_a
FINAL_BOSS_IDS = []
RANDOMIZABLE_BOSS_IDS = BOSS_IDS - FINAL_BOSS_IDS

BOSS_DOOR_SUBTYPE = 0x22
BOSS_ID_TO_BOSS_DOOR_VAR_B = {
  0x86 => 0x19,
  0x8A => 0x01,
  0x8B => 0x02,
  0x8C => 0x04,
  0x8D => 0x07,
  #0x8E => 0x, # legion
  0x8F => 0x06,
  0x90 => 0x10,
  0x91 => 0x0D,
  0x92 => 0x0E,
  #0x93 => 0x, # brauner
  0x94 => 0x09,
  0x95 => 0x08,
  0x96 => 0x0B,
  0x97 => 0x0A,
  #0x98 => 0x, # whips memory
  0x99 => 0x11,
  0x9A => 0x11,
}

ITEM_LOCAL_ID_RANGES = {
  0x02 => (0x00..0x5F), # consumable
  0x03 => (0x01..0x48), # weapon
  0x04 => (0x01..0x39), # body
  0x05 => (0x01..0x25), # head
  0x06 => (0x01..0x1C), # feet
  0x07 => (0x01..0x29), # misc
}
ITEM_GLOBAL_ID_RANGE = (0x01..0x1BB) # regular items end at 150. skills end at 1AB. 1BB is including relics.
SKILL_GLOBAL_ID_RANGE = (0x01..0x6B)

PICKUP_SUBTYPES_FOR_ITEMS = (0x02..0x07)
PICKUP_SUBTYPES_FOR_SKILLS = (0x08..0xFF)

# Note: the below are not actually where the original game stores the indexes. All three of those are at 02051F88 (since all three are the same: 00). The three addresses below are free space reused for the purpose of allowing the three values to be different.
NEW_GAME_STARTING_AREA_INDEX_OFFSET = 0x020BFC00
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x020BFC08
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x020BFC0C

TRANSITION_ROOM_LIST_POINTER = nil
FAKE_TRANSITION_ROOMS = [0x020E7F18] # This room is marked as a transition room, but it's not actually.

ITEM_ICONS_PALETTE_POINTER = 0x022C2B14
EXTRACT_ICON_INDEX_AND_PALETTE_INDEX = Proc.new do |icon_data|
  icon_index    = (icon_data & 0b00000111_11111111)
  palette_index = (icon_data & 0b11111000_00000000) >> 11
  [icon_index, palette_index]
end
PACK_ICON_INDEX_AND_PALETTE_INDEX = Proc.new do |icon_index, palette_index|
  icon_data  = icon_index
  icon_data |= palette_index << 11
  icon_data
end

CONSUMABLE_FORMAT = [
  # length: 12
  [2, "Item ID"],
  [2, "Icon"],
  [4, "Price"],
  [1, "Type"],
  [1, "Unknown 1"],
  [2, "Var A"],
]
WEAPON_FORMAT = [
  # length: 32
  [2, "Item ID"],
  [2, "Icon"],
  [4, "Price"],
  [1, "Swing Anim"],
  [1, "Graphical Effect"],
  [1, "Equippable by", :bitfield],
  [1, "Attack"],
  [1, "Defense"],
  [1, "Strength"],
  [1, "Constitution"],
  [1, "Intelligence"],
  [1, "Mind"],
  [1, "Luck"],
  [1, "Unknown 2"],
  [1, "Unknown 3"],
  [4, "Effects", :bitfield],
  [1, "Sprite"],
  [1, "Crit type/Palette"],
  [1, "IFrames"],
  [1, "Unknown 5"],
  [2, "Swing Modifiers", :bitfield],
  [2, "Swing Sound"],
]
ARMOR_FORMAT = [
  # length: 24
  [2, "Item ID"],
  [2, "Icon"],
  [4, "Price"],
  [1, "Type"],
  [1, "Unknown 1"],
  [1, "Equippable by", :bitfield],
  [1, "Attack"],
  [1, "Defense"],
  [1, "Strength"],
  [1, "Constitution"],
  [1, "Intelligence"],
  [1, "Mind"],
  [1, "Luck"],
  [1, "Unknown 2"],
  [1, "Unknown 3"],
  [4, "Resistances", :bitfield],
]
SKILL_FORMAT = [
  # length: 24
  [4, "Code"],
  [1, "Sprite"],
  [1, "Type"],
  [1, "Unknown 1"],
  [1, "Unknown 2"],
  [2, "Mana cost"],
  [2, "DMG multiplier"],
  [4, "Effects", :bitfield],
  [4, "Unwanted States", :bitfield],
  [2, "Var A"],
  [2, "Var B"],
]
SKILL_EXTRA_DATA_FORMAT = [
  # length: 6
  [2, "Max at once/Spell charge"],
  [2, "SP to Master"],
  [2, "Unknown 1"],
]
ITEM_TYPES = [
  {
    name: "Consumables",
    list_pointer: 0x020E2724,
    count: 96,
    format: CONSUMABLE_FORMAT # length: 12
  },
  {
    name: "Weapons",
    list_pointer: 0x020E3114,
    count: 73,
    format: WEAPON_FORMAT # length: 32
  },
  {
    name: "Body Armor",
    list_pointer: 0x020E2BA4,
    count: 58,
    format: ARMOR_FORMAT # length: 24
  },
  {
    name: "Head Armor",
    list_pointer: 0x020E1FA4,
    count: 38,
    format: ARMOR_FORMAT # length: 24
  },
  {
    name: "Leg Armor",
    list_pointer: 0x020E1CEC,
    count: 29,
    format: ARMOR_FORMAT # length: 24
  },
  {
    name: "Accessories",
    list_pointer: 0x020E2334,
    count: 42,
    format: ARMOR_FORMAT # length: 24
  },
  {
    name: "Skills",
    list_pointer: 0x020E3CFC,
    count: 108,
    kind: :skill,
    format: SKILL_FORMAT # length: 24
  },
  {
    name: "Skills (extra data)",
    list_pointer: 0x020E3B14,
    count: 81,
    kind: :skill,
    format: SKILL_EXTRA_DATA_FORMAT # length: 6
  },
]

ITEM_BITFIELD_ATTRIBUTES = {
  "Resistances" => [
    "Strike",
    "Whip",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Dark",
    "Holy",
    "Poison",
    "Curse",
    "Stone",
    "Resistance 12",
    "Resistance 13",
    "Resistance 14",
    "Resistance 15",
    "Resistance 16",
    "Resistance 17",
    "Resistance 18",
    "Resistance 19",
    "Resistance 20",
    "Resistance 21",
    "Resistance 22",
    "Resistance 23",
    "Resistance 24",
    "Resistance 25",
    "Resistance 26",
    "Resistance 27",
    "Resistance 28",
    "Resistance 29",
    "Resistance 30",
    "Resistance 31",
    "Resistance 32",
  ],
  "Effects" => [
    "Strike",
    "Whip",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Dark",
    "Holy",
    "Poison",
    "Curse",
    "Stone",
    "Effect 12",
    "Effect 13",
    "Effect 14",
    "Effect 15",
    "Effect 16",
    "Effect 17",
    "Reflect projectiles",
    "Effect 19",
    "Effect 20",
    "Effect 21",
    "Effect 22",
    "Effect 23",
    "Effect 24",
    "Effect 25",
    "Effect 26",
    "Magical",
    "Cures vampirism",
    "Effect 29",
    "Effect 30",
    "Effect 31",
    "Effect 32",
  ],
  "Unwanted States" => [
    "Moving",
    "Moving forward",
    "Facing left",
    "Crouching",
    "In air",
    "Double jumping",
    "Dying",
    "Jumpkick bounce",
    "Ceiling above head (jump/crouch in small space)",
    "On jump-through platform",
    "Ceiling above head (crouch in small space)",
    "Taking damage in the air",
    "Ceiling above head (standing)",
    "Jumpkicking/using subweapon",
    "Swinging melee weapon",
    "Using combo tech",
    "Using subweapon",
    "State 18",
    "State 19",
    "Backdashing",
    "Sliding",
    "Jumpkicking",
    "Taking damage",
    "State 24",
    "State 25",
    "State 26",
    "Pushing",
    "State 28",
    "State 29",
    "Shoulder jump",
    "State 31",
    "State 32",
  ],
  "Swing Modifiers" => [
    "No interrupt on land",
    "Weapon floats in place",
    "Modifier 3",
    "Player can move",
    "No Slash Trail",
    "Modifier 6",
    "Modifier 7",
    "Shaky weapon",
    "Modifier 9",
    "Modifier 10",
    "Modifier 11",
    "No interrupt on anim end",
    "No dangle",
    "Can whip diagonally",
    "Modifier 15",
    "Modifier 16",
  ],
  "Equippable by" => [
    "Jonathan",
    "Charlotte",
    "Unused 3",
    "Unused 4",
    "Unused 5",
    "Unused 6",
    "Unused 7",
    "Unused 8",
  ]
}

ITEM_POOLS_LIST_POINTER = nil
ITEM_POOL_INDEXES_FOR_AREAS_LIST_POINTER = nil
NUMBER_OF_ITEM_POOLS = 0

PLAYER_LIST_POINTER = 0x0221E7F4
PLAYER_COUNT = 7
PLAYER_NAMES = [
  "Jonathan",
  "Charlotte",
  "Stella",
  "Loretta",
  "Richter",
  "Maria",
  "Old Axe Armor",
]
PLAYER_LIST_FORMAT = [
  # length: 88
  [4, "GFX list pointer"],
  [4, "Sprite pointer"],
  [4, "Palette pointer"],
  [4, "State anims ptr"],
  [2, "GFX file index"],
  [2, "Sprite file index"],
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
  [4, "Combo tech ptr"],
  [2, "Sprite Y offset"],
  [2, "Unknown 17"],
  [2, "Unknown 18"],
  [2, "Unknown 19"],
  [4, "Unknown 20"],
  [4, "Hitbox pointer"],
  [2, "Height"],
  [2, "Face icon frame"],
  [4, "Swing anims ptr"],
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
    "Can whip diagonally",
    "Jonathan's voice",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
    "No gravity",
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
  "??? bitfield" => [
    "Horizontal flip",
    "Can smash head",
    "Is currently AI partner",
    "Can combo tech",
    "Is female",
    "Unknown 6",
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
    "Whip",
    "Slash",
    "Fire",
    "Ice",
    "Lightning",
    "Dark",
    "Holy",
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
