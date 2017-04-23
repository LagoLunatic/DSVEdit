
GAME = "aos"
REGION = :usa
LONG_GAME_NAME = "Aria of Sorrow"

AREA_LIST_RAM_START_OFFSET = 0x08001990 # Technically not a list, this points to code that has the the area hard coded, since AoS only has one area.

AREA_INDEX_TO_OVERLAY_INDEX = {
  0 => {
     0 => nil,
     1 => nil,
     2 => nil,
     3 => nil,
     4 => nil,
     5 => nil,
     6 => nil,
     7 => nil,
     8 => nil,
     9 => nil,
    10 => nil,
    11 => nil,
  }
}

AREAS_OVERLAY = nil

AREA_INDEX_TO_AREA_NAME = {
   0 => "Dracula's Castle"
}

SECTOR_INDEX_TO_SECTOR_NAME = {
   0 => {
     0 => "Castle Corridor",
     1 => "Chapel",
     2 => "Study",
     3 => "Dance Hall",
     4 => "Inner Quarters",
     5 => "Floating Garden",
     6 => "Clock Tower",
     7 => "Underground Reservoir",
     8 => "The Arena",
     9 => "Top Floor",
    10 => "Forbidden Area",
    11 => "Chaotic Realm",
  }
}

ENTITY_TYPE_DESCRIPTIONS = {
  0 => "Nothing",
  1 => "Enemy",
  2 => "Special object",
  3 => "Candle",
  4 => "Pickup",
  5 => "Hard mode pickup",
  6 => "All-souls-found pickup",
}

ENEMY_IDS = (0x00..0x70)
COMMON_ENEMY_IDS = (0x00..0x69).to_a
BOSS_IDS = (0x6A..0x70).to_a
FINAL_BOSS_IDS = (0x70..0x70).to_a
RANDOMIZABLE_BOSS_IDS = BOSS_IDS - FINAL_BOSS_IDS
ENEMY_DNA_RAM_START_OFFSET = 0x080E9644
ENEMY_DNA_FORMAT = [
  # length: 36
  [4, "Init AI"],
  [4, "Running AI"],
  [2, "Unknown 1"],
  [2, "Unknown 2"],
  [2, "HP"],
  [2, "MP"],
  [2, "EXP"],
  [1, "Soul Rarity??"],
  [1, "Attack"],
  [1, "Defense"],
  [1, "Unknown 7"],
  [1, "Unknown 8"],
  [1, "Soul Type"],
  [1, "Soul"],
  [1, "Unknown 11"],
  [2, "Weaknesses", :bitfield],
  [2, "Resistances", :bitfield],
  [2, "Unknown 12"],
  [2, "Unknown 13"],
  [2, "Unknown 14"],
]
ENEMY_DNA_BITFIELD_ATTRIBUTES = {
  "Weaknesses" => [
    "Slash",
    "Flame",
    "Water",
    "Thunder",
    "Dark",
    "Holy",
    "Poison",
    "Curse",
    "Stone",
    "Weakness 10",
    "Weakness 11",
    "Weakness 12",
    "Weakness 13",
    "Weakness 14",
    "Weakness 15",
    "Weakness 16",
  ],
  "Resistances" => [
    "Slash",
    "Flame",
    "Water",
    "Thunder",
    "Dark",
    "Holy",
    "Poison",
    "Curse",
    "Stone",
    "Resistance 10",
    "Resistance 11",
    "Resistance 12",
    "Resistance 13",
    "Resistance 14",
    "Resistance 15",
    "Resistance 16",
  ],
}

TEXT_LIST_START_OFFSET = 0x08506B38
TEXT_RANGE = (0..0xB4E)
TEXT_REGIONS = {
  "Character Names" => (0..0xA),
  "Item Names" => (0x5B..0xE2),
  "Item Descriptions" => (0x15C..0x1E3),
  "Enemy Names" => (0x25D..0x2CD),
  "Enemy Descriptions" => (0x2CE..0x293),
  "Soul Names" => (0xE3..0x15B),
  "Soul Descriptions" => (0x1E4..0x25C),
  #"Area Names" => (0x38A..0x395),
  #"Music Names" => (0x396..0x3B2),
  #"Misc" => (0x3B3..0x3D8),
  #"Menus" => (0x3D9..0x477),
  #"Library" => (0x478..0x4A5),
  #"Events" => (0x4A6..0xB4E)
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
STRING_DATABASE_START_OFFSET = nil
STRING_DATABASE_ORIGINAL_END_OFFSET = nil
STRING_DATABASE_ALLOWABLE_END_OFFSET = STRING_DATABASE_ORIGINAL_END_OFFSET
TEXT_COLOR_NAMES = {
  0x00 => "TRANSPARENT",
  0x01 => "WHITE",
  0x02 => "GREY",
  0x03 => "PINK",
  0x04 => "BROWN",
  0x05 => "AZURE",
  0x06 => "DARKBLUE",
  0x07 => "YELLOW",
  0x08 => "ORANGE",
  0x09 => "LIGHTGREEN",
  0x0A => "GREEN",
  0x0B => "BRIGHTPINK",
  0x0C => "PURPLE",
  0x0D => "BROWN2",
  0x0E => "BLACK",
  0x0F => "BLACK2",
}

SPECIAL_OBJECT_IDS = (0..0x37)
SPECIAL_OBJECT_CREATE_CODE_LIST = 0x084F0DF8
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x084F0ED8

ITEM_LOCAL_ID_RANGES = {
  0x02 => (0x00..0x1F), # consumable
  0x03 => (0x00..0x3A), # weapon
  0x04 => (0x00..0x2C), # armor
}
ITEM_GLOBAL_ID_RANGE = (0..0x87)
SKILL_GLOBAL_ID_RANGE = (0..0xFA)
SKILL_LOCAL_ID_RANGE = nil # souls in AoS are split into multiple different types.
PICKUP_GLOBAL_ID_RANGE = (0..0xFA)

PICKUP_SUBTYPES_FOR_ITEMS = (0x02..0x04) # TODO
PICKUP_SUBTYPES_FOR_SKILLS = (0x05..0xFF) # TODO

ITEM_ICONS_PALETTE_POINTER = 0x082099FC
GLYPH_ICONS_PALETTE_POINTER = nil
ITEM_ICONS_GFX_POINTERS = [0x081C5E00, 0x081C7E04, 0x081C9E08]

CONSUMABLE_FORMAT = [
  # length: 16
  [2, "Item ID"],
  [2, "Icon"],
  [4, "Price"],
  [1, "Type"],
  [1, "Unknown 1"],
  [2, "Var A"],
  [4, "Unused"],
]
WEAPON_FORMAT = [
  # length: 28
  [2, "Item ID"],
  [2, "Icon"],
  [4, "Price"],
  [1, "Attack Type"],
  [1, "Unknown 4"],
  [1, "Attack"],
  [1, "Defense"],
  [1, "Constitution"],
  [1, "Intelligence"],
  [1, "Mind"],
  [1, "Luck"],
  [2, "Effects", :bitfield],
  [1, "Sprite"],
  [1, "???"],
  [1, "Unknown 10"],
  [1, "Palette"],
  [1, "? anim??"],
  [1, "Unknown 12"],
  [4, "Unknown 13"],
]
ARMOR_FORMAT = [
  # length: 20
  [2, "Item ID"],
  [2, "Icon"],
  [4, "Price"],
  [1, "Type"],
  [1, "Unknown 4"],
  [1, "Attack"],
  [1, "Defense"],
  [1, "Constitution"],
  [1, "Intelligence"],
  [1, "Mind"],
  [1, "Luck"],
  [2, "Resistances", :bitfield],
  [1, "Unknown 8"],
  [1, "Unknown 9"],
]
RED_SOUL_FORMAT = [
  # length: 16
  [4, "Code"],
  [2, "Use anim"],
  [2, "Mana"],
  [1, "Unknown 2"],
  [1, "Unknown 3"],
  [2, "DMG multiplier"],
  [2, "Effects", :bitfield],
  [2, "Var A"],
]
BLUE_SOUL_FORMAT = [
  # length: 12
  [4, "Code"],
  [2, "Unknown 1"],
  [2, "Unknown 2"],
  [2, "Unknown 3"],
  [2, "Unknown 4"],
]
YELLOW_SOUL_FORMAT = [
  # length: 12
  [4, "Code"],
  [2, "Unknown 1"],
  [2, "Unknown 2"],
  [2, "Unknown 3"],
  [2, "Unknown 4"],
]
ITEM_TYPES = [
  {
    name: "Consumables",
    list_pointer: 0x08505B3C,
    count: 0x20,
    format: CONSUMABLE_FORMAT # length 16
  },
  {
    name: "Weapons",
    list_pointer: 0x08505D3C,
    count: 0x3B,
    format: WEAPON_FORMAT # length 28
  },
  {
    name: "Armor",
    list_pointer: 0x085063B0,
    count: 0x2D,
    format: ARMOR_FORMAT # length 20
  },
  {
    name: "Red Souls",
    list_pointer: 0x080E15A8,
    count: 0x37,
    kind: :skill,
    format: RED_SOUL_FORMAT # length: 16
  },
  {
    name: "Blue Souls",
    list_pointer: 0x080E1938,
    count: 0x19,
    kind: :skill,
    format: BLUE_SOUL_FORMAT # length: 12
  },
  {
    name: "Yellow Souls",
    list_pointer: 0x080E1B14,
    count: 0x23,
    kind: :skill,
    format: YELLOW_SOUL_FORMAT # length: 12
  },
]
ITEM_BITFIELD_ATTRIBUTES = {
  "Effects" => [
    "Slash",
    "Flame",
    "Water",
    "Thunder",
    "Dark",
    "Holy",
    "Poison",
    "Curse",
    "Stone",
    "Unknown 10",
    "Unknown 11",
    "Unknown 12",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
  ],
  "Resistances" => [
    "Slash",
    "Flame",
    "Water",
    "Thunder",
    "Dark",
    "Holy",
    "Poison",
    "Curse",
    "Stone",
    "Unknown 10",
    "Unknown 11",
    "Unknown 12",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
  ],
}

OVERLAY_FILE_FOR_ENEMY_AI = {}
REUSED_ENEMY_INFO = {
  0x07 => {init_code: 0x08070AC4}, # killer fish
  0x08 => {init_code: 0x081193DC}, # bone pillar
  0x0B => {init_code: 0x08077C40}, # white dragon
  0x0F => {init_code: 0x08075660, palette_offset: 1}, # siren -> harpy
  0x11 => {init_code: 0x08093178}, # durga -> curly
  0x13 => {init_code: 0x0807E2CC}, # giant ghost
  0x15 => {init_code: 0x080B0AD4}, # minotaur
  0x17 => {init_code: 0x0807A970}, # arachne
  0x1C => {init_code: 0x08089A50, palette_offset: 1}, # catoblepas
  0x21 => {init_code: 0x08098E00}, # creaking skull
  0x22 => {init_code: 0x08081128, palette_offset: 2, gfx_sheet_ptr_index: 1}, # wooden golem
  0x25 => {palette_offset: 1}, # lilith -> succubus
  0x2B => {palette_offset: 1}, # curly
  0x2D => {palette_offset: 1}, # red crow -> blue crow
  0x2E => {init_code: 0x080BBFF0}, # cockatrice
  0x30 => {init_code: 0x08091430, palette_offset: 2}, # devil
  0x35 => {init_code: 0x08081128, gfx_sheet_ptr_index: 1}, # golem
  0x36 => {init_code: 0x0807406C}, # manticore
  0x37 => {init_code: 0x080864A0, palette_offset: 1}, # gremlin => gargoyle
  0x3C => {init_code: 0x0808E024}, # great armor
  0x3E => {init_code: 0x080AD7F0}, # giant worm
  0x41 => {init_code: 0x081193EC}, # fish head
  0x43 => {init_code: 0x08087D24}, # triton
  0x45 => {init_code: 0x080AD1D0}, # big golem
  0x47 => {init_code: 0x080AD7F0, palette_offset: 1}, # poison worm
  0x48 => {init_code: 0x08091430}, # arc demon
  0x49 => {init_code: 0x080B7E80, sprite: 0x0824A334}, # cagnazzo
  0x4A => {palette_offset: 1}, # ripper
  0x4B => {init_code: 0x0807968C}, # werejaguar
  0x50 => {init_code: 0x08081128, palette_offset: 3}, # flesh golem TODO
  0x54 => {init_code: 0x0807968C, palette_offset: 1}, # weretiger
  0x58 => {init_code: 0x080B0AD4, palette_offset: 1}, # red minotaur
  0x5C => {init_code: 0x08098E00, palette_offset: 1}, # giant skeleton
  0x5D => {init_code: 0x080A1BEC}, # gladiator
  0x60 => {init_code: 0x08099430}, # mimic
  0x61 => {init_code: 0x0809C4E4}, # stolas
  0x62 => {init_code: 0x0806E714, palette_offset: 1}, # erinys -> valkyrie
  0x63 => {init_code: 0x080B7E80, palette_offset: 1, sprite: 0x0824A334}, # lubicant
  0x64 => {init_code: 0x080BBFF0, palette_offset: 1}, # basilisk
  0x65 => {init_code: 0x08081128, palette_offset: 1, gfx_sheet_ptr_index: 1}, # iron golem
  0x66 => {init_code: 0x08091430, palette_offset: 1}, # demon lord
  0x67 => {init_code: 0x0808E024, palette_offset: 1}, # final guard
  0x68 => {init_code: 0x08091430, palette_offset: 3}, # flame demon
  0x69 => {init_code: 0x0808E024, palette_offset: 2}, # shadow knight
}
ENEMY_FILES_TO_LOAD_LIST = nil
BEST_SPRITE_FRAME_FOR_ENEMY = {
  0x00 => 0x03,
  0x01 => 0x06,
  0x06 => 0x11,
  0x07 => 0x08,
  0x0E => 0x07,
  0x17 => 0x1D,
  0x21 => 0x16,
  0x22 => 0x01,
  0x30 => 0x05,
  0x36 => 0x03,
  0x3C => 0x0E,
  0x3D => 0x08,
  0x3E => 0x07,
  0x48 => 0x07,
  0x4D => 0x0A,
  0x50 => 0x10,
  0x51 => 0x09,
  0x5C => 0x16,
  0x60 => 0x0D,
  0x65 => 0x02,
  0x66 => 0x08,
  0x67 => 0x11,
  0x68 => 0x05,
  0x69 => 0x12,
}
BEST_SPRITE_OFFSET_FOR_ENEMY = {}

OVERLAY_FILE_FOR_SPECIAL_OBJECT = {}
REUSED_SPECIAL_OBJECT_INFO = {
  0x00 => {init_code: 0x0804D8F0}, # wooden door
  0x01 => {init_code: 0x08033254}, # pushable crate TODO: sprite file can't be found, gfx and palette are fine
  0x02 => {sprite: 0x0820ED60, gfx_wrapper: 0x081C15F4, palette: 0x082099FC, palette_offset: 2, unwrapped_gfx: true},
  0x05 => {sprite: 0x0820ED60, gfx_wrapper: 0x081C15F4, palette: 0x082099FC, palette_offset: 3, unwrapped_gfx: true},
  0x07 => {init_code:         -1},
  0x08 => {init_code: 0x08526004},
  0x09 => {init_code: 0x08526004},
  0x0C => {init_code:         -1},
  0x0E => {init_code: 0x08526214}, # destructible
  0x0F => {sprite: 0x0820ED60, gfx_wrapper: 0x081C15F4, palette: 0x082099FC, palette_offset: 3, unwrapped_gfx: true},
  0x12 => {init_code:         -1}, # multiple different background visuals
  0x1F => {init_code: 0x08055BE0, palette_offset: 2},
  0x20 => {init_code:         -1},
  0x29 => {init_code: 0x085264D0, palette_offset: 6},
  0x2A => {init_code: 0x085264D0, palette_offset: 6},
  0x2D => {palette_offset: 2},
  0x2E => {palette_offset: 5},
  0x34 => {palette_offset: 2},
}
SPECIAL_OBJECT_FILES_TO_LOAD_LIST = nil
BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT = {
  0x00 => 0x01,
  0x02 => 0x3F,
  0x05 => 0x7D,
  0x0F => 0x4A,
  0x1B => 0x02,
  0x1F => 0x0A,
  0x26 => 0x02,
  0x34 => 0x03,
}
BEST_SPRITE_OFFSET_FOR_SPECIAL_OBJECT = {}

OTHER_SPRITES = [
  {desc: "Common", sprite: 0x0820ED60, gfx_wrapper: 0x081C15F4, palette: 0x082099FC, palette_offset: 3, unwrapped_gfx: true},
  
  {desc: "Breakable walls 1", pointer: 0x08526004},
  {desc: "Breakable walls 2", pointer: 0x08526010},
  {desc: "Breakable walls 3", pointer: 0x0852601C},
  {desc: "Breakable walls 4", pointer: 0x08526028},
  {desc: "Breakable walls 5", pointer: 0x08526034},
  {desc: "Breakable walls 6", pointer: 0x08526040},
  {desc: "Breakable walls 7", pointer: 0x0852604C},
  {desc: "Breakable walls 8", pointer: 0x08526058},
  
  {desc: "Destructible 0", pointer: 0x08526214},
  {desc: "Destructible 1", pointer: 0x08526220},
  {desc: "Destructible 2", pointer: 0x0852622C},
  {desc: "Destructible 3", pointer: 0x08526238},
  {desc: "Destructible 4", pointer: 0x08526244},
  {desc: "Destructible 5", pointer: 0x08526250},
  {desc: "Destructible 6", pointer: 0x0852625C},
  {desc: "Destructible 7", pointer: 0x08526268},
  {desc: "Destructible 8", pointer: 0x08526274},
  {desc: "Destructible 9", pointer: 0x08526280},
  {desc: "Destructible A", pointer: 0x0852628C},
  {desc: "Destructible B", pointer: 0x08526298},
  {desc: "Destructible C", pointer: 0x085262A4},
  {desc: "Destructible D", pointer: 0x085262B0},
  
  {desc: "Background window", pointer: 0x085263A8},
  {desc: "Background rushing water", pointer: 0x085263C0},
  {desc: "Background moon", pointer: 0x085263D8},
  
  {desc: "unknown", pointer: 0x085264D0},
  {desc: "unknown", pointer: 0x085264E0},
  {desc: "unknown", pointer: 0x085264F0},
  {desc: "unknown", pointer: 0x08526500},
  {desc: "unknown", pointer: 0x08526510},
  {desc: "unknown", pointer: 0x08526520},
  {desc: "unknown", pointer: 0x08526530},
  {desc: "unknown", pointer: 0x08526540},
  {desc: "unknown", pointer: 0x08526550},
]

CANDLE_FRAME_IN_COMMON_SPRITE = 0x1E
MONEY_FRAME_IN_COMMON_SPRITE = 0x21
CANDLE_SPRITE = OTHER_SPRITES[0].merge(palette_offset: 3)
MONEY_SPRITE = OTHER_SPRITES[0].merge(palette_offset: 2)

WEAPON_GFX_LIST_START = 0x084F10C0
WEAPON_SPRITES_LIST_START = 0x084F117C
WEAPON_PALETTE_LIST = 0x082098B8

MAP_TILE_METADATA_LIST_START_OFFSET = nil
MAP_TILE_METADATA_START_OFFSET = 0x08116650
MAP_TILE_LINE_DATA_LIST_START_OFFSET = nil
MAP_TILE_LINE_DATA_START_OFFSET = 0x08117DD0
MAP_LENGTH_DATA_START_OFFSET = nil
MAP_NUMBER_OF_TILES = 3008
MAP_SECRET_DOOR_LIST_START_OFFSET = nil
MAP_SECRET_DOOR_DATA_START_OFFSET = nil # TODO
ABYSS_MAP_TILE_METADATA_START_OFFSET = nil
ABYSS_MAP_TILE_LINE_DATA_START_OFFSET = nil
ABYSS_MAP_NUMBER_OF_TILES = nil
ABYSS_MAP_SECRET_DOOR_DATA_START_OFFSET = nil

MAP_FILL_COLOR = [0, 0, 224, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [248, 248, 8, 255]
MAP_SECRET_FILL_COLOR = [0, 128, 0, 255]
MAP_ENTRANCE_FILL_COLOR = [0, 0, 0, 0] # Area entrances don't exist in AoS.
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [0, 200, 200, 255]
MAP_DOOR_CENTER_PIXEL_COLOR = MAP_DOOR_COLOR
MAP_SECRET_DOOR_COLOR = [248, 248, 0, 255]

NEW_OVERLAY_ID = nil
NEW_OVERLAY_FREE_SPACE_START = nil
NEW_OVERLAY_FREE_SPACE_END = nil
NEW_OVERLAY_FREE_SPACE_SIZE = nil

TEST_ROOM_SAVE_FILE_INDEX_LOCATION = 0x087FFFF0 # TODO
TEST_ROOM_AREA_INDEX_LOCATION      = nil
TEST_ROOM_SECTOR_INDEX_LOCATION    = 0x08002B5C
TEST_ROOM_ROOM_INDEX_LOCATION      = 0x08002B5E
TEST_ROOM_X_POS_LOCATION           = 0x087FFFF0
TEST_ROOM_Y_POS_LOCATION           = 0x087FFFF0
TEST_ROOM_OVERLAY = nil
