
GAME = "dos"
REGION = :usa
LONG_GAME_NAME = "Dawn of Sorrow"

AREA_LIST_RAM_START_OFFSET = 0x02006FC4 # Technically not a list, this points to code that has the the area hard coded, since DoS only has one area.

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

ENTITY_TYPE_DESCRIPTIONS = {
  0 => "Nothing",
  1 => "Enemy",
  2 => "Special object",
  3 => "Candle",
  4 => "Pickup",
  5 => "???",
  6 => "Entity hider",
  7 => "Font loader",
}

CONSTANT_OVERLAYS = [0, 1, 2, 3, 4, 5]

ROOM_OVERLAYS = (6..22)
MAX_ALLOWABLE_ROOM_OVERLAY_SIZE = 152864

MAP_TILE_METADATA_LIST_START_OFFSET = nil
MAP_TILE_METADATA_START_OFFSET = 0x0207708C
MAP_TILE_LINE_DATA_LIST_START_OFFSET = nil
MAP_TILE_LINE_DATA_START_OFFSET = 0x02076AAC
MAP_LENGTH_DATA_START_OFFSET = nil
MAP_NUMBER_OF_TILES = 3008
MAP_SECRET_DOOR_LIST_START_OFFSET = nil
MAP_SECRET_DOOR_DATA_START_OFFSET = 0x02076408
ABYSS_MAP_TILE_METADATA_START_OFFSET = 0x020788F4
ABYSS_MAP_TILE_LINE_DATA_START_OFFSET = 0x02078810
ABYSS_MAP_NUMBER_OF_TILES = 448
ABYSS_MAP_SECRET_DOOR_DATA_START_OFFSET = 0x0207880C

MAP_FILL_COLOR = [160, 120, 88, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [0, 0, 248, 255]
MAP_SECRET_FILL_COLOR = [0, 128, 0, 255]
MAP_ENTRANCE_FILL_COLOR = [0, 0, 0, 0] # Area entrances don't exist in DoS.
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [16, 216, 32, 255]
MAP_DOOR_CENTER_PIXEL_COLOR = MAP_DOOR_COLOR
MAP_SECRET_DOOR_COLOR = [248, 248, 0, 255]

AREA_MUSIC_LIST_START_OFFSET = nil
SECTOR_MUSIC_LIST_START_OFFSET = 0x0209A634
AVAILABLE_BGM_POOL_START_OFFSET = nil
SONG_INDEX_TO_TEXT_INDEX = [
  0x3B1,
  0x3B2,
  0x3A7,
  0x3A8,
  0x3AF,
  0x3A9,
  0x3AC,
  0x396,
  0x3A5,
  0x3A6,
  0x3AD,
  0x397,
  0x398,
  0x399,
  0x39A,
  0x39B,
  0x39C,
  0x39D,
  0x39E,
  0x39F,
  0x3A0,
  0x3A1,
  0x3A2,
  0x3A3,
  0x3A4,
  0x3B0,
  0x3AA,
  0x3AB,
  "Ambience",
  0x3AE,
]

LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET = 0x0208CC6C
LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET = 0x0209A0C3
LIST_OF_FILE_RAM_LOCATIONS_ENTRY_LENGTH = 0x28

COLOR_OFFSETS_PER_256_PALETTE_INDEX = 16

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
  [4, "Weaknesses", :bitfield],
  [4, "Resistances", :bitfield],
]
ENEMY_DNA_BITFIELD_ATTRIBUTES = {
  "Weaknesses" => [
    "Strike",
    "Stab",
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
    "Stab",
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
    "Backstab",
    "Resistance 16",
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
}

# Overlays 23 to 40 used for enemies.
OVERLAY_FILE_FOR_ENEMY_AI = {
  # Enemies not listed here use one of the constant overlays like 0.
  0x0E => 28, # golem
  0x12 => 27, # manticore
  0x19 => 32, # catoblepas
  0x22 => 28, # treant
  0x25 => 24, # great armor
  0x2F => 31, # devil
  0x4D => 32, # gorgon
  0x51 => 27, # musshusu
  0x5B => 31, # flame demon
  0x5D => 31, # arc demon
  0x61 => 24, # final guard
  0x64 => 28, # iron golem
  0x65 => 30, # flying armor
  0x66 => 23, # balore
  0x67 => 29, # malphas
  0x68 => 40, # dmitrii
  0x69 => 25, # dario
  0x6A => 25, # puppet master
  0x6B => 26, # rahab
  0x6C => 36, # gergoth
  0x6D => 33, # zephyr
  0x6E => 37, # bat company
  0x6F => 35, # paranoia
  0x71 => 34, # death
  0x72 => 39, # abaddon
  0x73 => 38, # menace
}

REUSED_ENEMY_INFO = {
  # Enemies that had parts of them reused from another enemy.
  # init_code: The init code of the original enemy. This is where to look for gfx/palette/sprite data, not the reused enemy's init code.
  # gfx_sheet_ptr_index: The reused enemy uses a different gfx sheet than the original enemy. This value is which one to use.
  # palette_offset: The reused enemy uses different palettes than the original, but they're still in the same list of palettes. This is the offset of the new palette in the list.
  # palette_list_ptr_index: The reused enemy uses a completely different palette list from the original. This value is which one to use.
  0x1A => {init_code: 0x0223266C, gfx_sheet_ptr_index: 0, palette_offset: 2, palette_list_ptr_index: 0}, # ghoul and zombie
  0x4D => {init_code:        nil, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 1}, # gorgon and catoblepas
  0x54 => {init_code: 0x02270704, gfx_sheet_ptr_index: 0, palette_offset: 1, palette_list_ptr_index: 0, sprite_ptr_index: 1}, # erinys and valkyrie
  0x5C => {init_code: 0x02288FBC, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0}, # tanjelly and slime
  0x5B => {init_code: 0x022FF9F0, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # flame demon and devil
  0x5D => {init_code:        nil, gfx_sheet_ptr_index: 2, palette_offset: 0, palette_list_ptr_index: 2, sprite_ptr_index: 2}, # arc demon and devil
}

BEST_SPRITE_FRAME_FOR_ENEMY = {
  # Enemies not listed here default to frame 0.
  0x00 =>   8, # zombie
  0x05 =>  38, # peeping eye
  0x09 =>  17, # spin devil
  0x0E =>  19, # golem
  0x10 =>   7, # une
  0x12 =>  78, # manticore
  0x15 =>  14, # mandragora
  0x17 =>  13, # skeleton farmer
  0x19 =>  36, # catoblepas
  0x1A =>   8, # ghoul
  0x1B =>  17, # corpseweed
  0x22 =>  15, # treant
  0x23 =>  17, # amalaric sniper
  0x25 =>  20, # great armor
  0x26 =>  27, # killer doll
  0x29 =>   5, # witch
  0x2B =>   8, # lilith
  0x2C =>   3, # killer clown
  0x2E =>   6, # fleaman
  0x30 =>  37, # guillotiner
  0x31 =>  17, # draghignazzo
  0x36 =>  27, # wakwak tree
  0x3C =>  10, # larva
  0x3D =>   4, # heart eater
  0x40 =>   2, # medusa head
  0x43 =>   1, # mimic
  0x4A =>  39, # bugbear
  0x4C =>  42, # bone ark
  0x4D =>  36, # gorgon
  0x4E =>  10, # alura une
  0x4F =>   6, # great axe armor
  0x53 =>   5, # dead warrior
  0x55 =>   9, # succubus
  0x56 =>  16, # ripper
  0x5C =>  11, # tanjelly
  0x61 =>  20, # final guard
  0x62 =>  31, # malacoda
  0x63 =>   1, # alastor
  0x64 =>  15, # iron golem
  0x65 =>   6, # flying armor
  0x66 =>   5, # balore
  0x6B => 113, # rahab
  0x6C =>  16, # gergoth
  0x6E =>   5, # bat company
  0x6F =>  23, # paranoia
  0x71 =>  22, # death
  0x73 =>  31, # menace
  0x74 =>  22, # soma
}

ENEMY_FILES_TO_LOAD_LIST = 0x0208CA90

SPECIAL_OBJECT_IDS = (0..0x75)
SPECIAL_OBJECT_CREATE_CODE_LIST = 0x0222C714
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x0222C8F0
OVERLAY_FILE_FOR_SPECIAL_OBJECT = {
  0x2E => 25
}
REUSED_SPECIAL_OBJECT_INFO = {
  0x00 => {sprite: 0x0229EAD8, gfx_wrapper: 0x02079EAC, palette: 0x022B9B04}, # ice block
  0x01 => {init_code: 0x0222BAB8, ignore_files_to_load: true}, # destructible
  0x02 => {init_code:         -1},
  0x03 => {init_code:         -1},
  0x04 => {init_code:         -1},
  0x05 => {init_code:         -1},
  0x06 => {sprite: 0x0229A9FC, gfx_files: [0x022CA4B8, 0x022CA4C4, 0x022CA4D0, 0x022CA4DC, 0x022CA4E8, 0x022CA4F4], palette: 0x022C141C}, # area titles
  0x09 => {init_code: 0x0222BD04}, # chair
  0x0B => {init_code:         -1},
  0x11 => {init_code:         -1},
  0x1D => {sprite: 0x0229EAD8, gfx_wrapper: 0x02079EAC, palette: 0x022B9B04}, # wooden door
  0x22 => {init_code:         -1},
  0x25 => {sprite: 0x0229EAD8, gfx_wrapper: 0x02079EAC, palette: 0x022B9B04}, # boss door
  0x26 => {init_code: 0x021A8FC8}, # slot machine
  0x27 => {init_code: 0x021A8434}, # condemned tower gate
  0x29 => {init_code: 0x021A7FC4}, # dark chapel gate
  0x2A => {init_code: 0x021A7B44}, # flood gate
  0x2E => {init_code: 0x02304B98}, # iron maiden
  0x2F => {init_code:         -1},
  0x36 => {init_code:         -1},
  0x38 => {init_code:         -1},
  0x41 => {init_code:         -1},
  0x4C => {init_code:         -1},
  0x47 => {init_code: 0x0222CC10}, # hammer shopkeeper
  0x48 => {init_code: 0x0222CC00}, # yoko shopkeeper
  0x4A => {init_code:         -1},
  0x4F => {init_code: 0x0222CBE0}, # mina event actor
  0x50 => {init_code: 0x0222CC10}, # hammer event actor
  0x51 => {init_code: 0x0222CBF0}, # arikado event actor
  0x52 => {init_code: 0x0222CC20}, # julius event actor
  0x53 => {init_code: 0x0222CC30}, # celia event actor
  0x54 => {init_code: 0x0222CC40}, # dario event actor
  0x55 => {init_code: 0x0222CC50}, # dmitrii event actor
  0x5B => {init_code: 0x0222CC60}, # alucard event actor
  0x5D => {init_code:         -1},
  0x5E => {init_code:         -1},
  0x5F => {init_code:         -1},
  0x60 => {init_code:         -1},
  0x61 => {init_code:         -1},
  0x62 => {init_code:         -1},
  0x63 => {init_code:         -1},
  0x64 => {init_code:         -1},
  0x65 => {init_code:         -1},
  0x66 => {init_code:         -1},
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
}
BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT = {
  0x01 => 0x0F,
  0x0C => 0x01,
  0x0D => 0x17,
  0x0F => 0x04,
  0x16 =>   -1,
  0x18 => 0x11,
  0x1A => 0x03,
  0x1D => 0xED,
  0x25 => 0xDF,
  0x26 => 0x06,
  0x28 => 0x01,
  0x30 => 0x06,
  0x3A => 0x08,
  0x3B => 0x06,
  0x3D => 0x01,
  0x3E => 0x01,
  0x59 => 0x0A,
  0x5B => 0x10,
  0x5C =>   -1,
}
SPECIAL_OBJECT_FILES_TO_LOAD_LIST = 0x0209B88C

WEAPON_GFX_LIST_START = 0x0222EE24
SKILL_GFX_LIST_START = 0x0222E9D4

OTHER_SPRITES = [
  {desc: "Common", sprite: 0x0229EAD8, gfx_wrapper: 0x02079EAC, palette: 0x022B9B04},
  
  {pointer: 0x0222E474, desc: "Soma player"},
  {pointer: 0x0222E4CC, desc: "Julius player"},
  {pointer: 0x0222E524, desc: "Yoko player"},
  {pointer: 0x0222E57C, desc: "Alucard player"},
  
  {pointer: 0x0222BAAC, desc: "Destructibles 0"},
  {pointer: 0x0222BAB8, desc: "Destructibles 1"},
  {pointer: 0x0222BAC4, desc: "Destructibles 2"},
  {pointer: 0x0222BAD0, desc: "Destructibles 3"},
  {pointer: 0x0222BADC, desc: "Destructibles 4"},
  {pointer: 0x0222BAE8, desc: "Destructibles 5"},
  {pointer: 0x0222BAF4, desc: "Destructibles 6"},
  {pointer: 0x0222BB00, desc: "Destructibles 7"},
  {pointer: 0x0222BB0C, desc: "Destructibles 8"},
  {pointer: 0x0222BD04, desc: "Chair 1"},
  {pointer: 0x0222BD10, desc: "Chair 2"},
  {pointer: 0x0222BD1C, desc: "Chair 3"},
  {pointer: 0x0222BD28, desc: "Chair 4"},
  
  {pointer: 0x0203D4A0, desc: "Nintendo splash screen"},
  {pointer: 0x0203D564, desc: "Konami splash screen"},
  {pointer: 0x0203D8A8, desc: "Main menu"},
  {pointer: 0x0203DAB0, desc: "Castlevania logo"},
  {pointer: 0x0203ED3C, desc: "Credits"},
  {pointer: 0x0203ED58, desc: "Characters used during credits"},
  {pointer: 0x0203ED70, desc: "BGs used during credits"},
  {pointer: 0x0203F410, desc: "Game over screen"},
  {pointer: 0x02046714, desc: "Name signing screen"},
  {pointer: 0x02046ACC, desc: "File select menu"},
  {pointer: 0x020489A4, desc: "Choose course - unused?"},
  {pointer: 0x02049078, desc: "Enemy set mode menu"},
  {pointer: 0x0204908C, desc: "Enemy set retry/complete"},
  {pointer: 0x020490A0, desc: "Wi-fi menu"},
]

OVERLAY_FILES_WITH_SPRITE_DATA = [2]

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
TEXT_REGIONS_OVERLAYS = {
  "Character Names" => 0,
  "Item Names" => 0,
  "Item Descriptions" => 0,
  "Enemy Names" => 0,
  "Enemy Descriptions" => 0,
  "Soul Names" => 0,
  "Soul Descriptions" => 0,
  "Area Names" => 0,
  "Music Names" => 0,
  "Misc" => 0,
  "Menus" => 0,
  "Library" => 0,
  "Events" => 0
}
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
  0x04 => (0x00..0x3C), # armor
}
ITEM_GLOBAL_ID_RANGE = (1..0xCE)
SOUL_GLOBAL_ID_RANGE = (0..0x7A)

PICKUP_SUBTYPES_FOR_ITEMS = (0x02..0x04)
PICKUP_SUBTYPES_FOR_SKILLS = (0x05..0xFF)

NEW_GAME_STARTING_AREA_INDEX_OFFSET = nil
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x0202FB84
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x0202FB90

TRANSITION_ROOM_LIST_POINTER = 0x0208AD8C
FAKE_TRANSITION_ROOMS = []

ITEM_ICONS_PALETTE_POINTER = 0x022C4684
EXTRACT_ICON_INDEX_AND_PALETTE_INDEX = Proc.new do |icon_data|
  icon_index    = (icon_data & 0b00000000_11111111)
  palette_index = (icon_data & 0b11111111_00000000) >> 8
  [icon_index, palette_index]
end
PACK_ICON_INDEX_AND_PALETTE_INDEX = Proc.new do |icon_index, palette_index|
  icon_data  = icon_index
  icon_data |= palette_index << 8
  icon_data
end

ITEM_TYPES = [
  {
    name: "Consumables",
    list_pointer: 0x0209BA68,
    count: 66,
    format: [
      # length: 16
      [2, "Item ID"],
      [2, "Icon"],
      [4, "Price"],
      [1, "Type"],
      [1, "Unknown 1"],
      [2, "Var A"],
      [4, "Unused"],
    ]
  },
  {
    name: "Weapons",
    list_pointer: 0x0209C34C,
    count: 79,
    format: [
      # length: 28
      [2, "Item ID"],
      [2, "Icon"],
      [4, "Price"],
      [1, "Swing Anim"],
      [1, "Unknown 1"],
      [1, "Attack"],
      [1, "Defense"],
      [1, "Strength"],
      [1, "Constitution"],
      [1, "Intelligence"],
      [1, "Luck"],
      [4, "Effects", :bitfield],
      [1, "Sprite"],
      [1, "Super Anim"],
      [2, "Unknown 4"],
      [2, "Swing Modifiers", :bitfield],
      [2, "Swing Sound"],
    ]
  },
  {
    name: "Armor",
    list_pointer: 0x0209BE88,
    count: 61,
    format: [
      # length: 20
      [2, "Item ID"],
      [2, "Icon"],
      [4, "Price"],
      [1, "Type"],
      [1, "Unknown 1"],
      [1, "Attack"],
      [1, "Defense"],
      [1, "Strength"],
      [1, "Constitution"],
      [1, "Intelligence"],
      [1, "Luck"],
      [4, "Resistances", :bitfield],
    ]
  },
  {
    name: "Souls",
    list_pointer: 0x0209D190,
    count: 123,
    is_skill: true,
    format: [
      # length: 28
      [4, "Code"],
      [2, "Sprite"],
      [1, "Type"],
      [1, "Input flags", :bitfield],
      [2, "Soul Scaling"],
      [2, "Mana cost"],
      [2, "Attack"],
      [2, "Unknown 3"],
      [4, "Effects", :bitfield],
      [4, "Unwanted States"],
      [2, "Var A"],
      [2, "Var B"],
    ]
  },
]

ITEM_BITFIELD_ATTRIBUTES = {
  "Resistances" => [
    "Strike",
    "Stab",
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
    "Stab",
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
    "Effect 18",
    "Effect 19",
    "Effect 20",
    "Effect 21",
    "Effect 22",
    "Effect 23",
    "Effect 24",
    "Effect 25",
    "Effect 26",
    "Effect 27",
    "Effect 28",
    "Effect 29",
    "Effect 30",
    "Effect 31",
    "Effect 32",
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
  "Input flags" => [
    "Unknown 1",
    "Unknown 2",
    "Unknown 3",
    "Unknown 4",
    "Hold R",
    "Hold R (2)",
    "Hold R (3)",
    "Hold R (4)",
  ]
}

ITEM_POOLS_LIST_POINTER = nil
ITEM_POOL_INDEXES_FOR_AREAS_LIST_POINTER = nil
NUMBER_OF_ITEM_POOLS = 0
