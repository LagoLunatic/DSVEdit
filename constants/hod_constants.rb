
GAME = "hod"
REGION = :usa
LONG_GAME_NAME = "Harmony of Dissonance"

AREA_LIST_RAM_START_OFFSET = 0x08001EC8 # Technically not a list, this points to code that has the the area hard coded, since HoD only has one area.

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
     12 => nil,
     13 => nil,
     14 => nil,
     15 => nil,
     16 => nil,
     17 => nil,
     18 => nil,
     19 => nil,
     20 => nil,
  }
}

AREAS_OVERLAY = nil

AREA_INDEX_TO_AREA_NAME = {
   0 => "Dracula's Castle"
}

SECTOR_INDEX_TO_SECTOR_NAME = {
   0 => {
      0 => "Entrance A",
      1 => "Entrance B",
      2 => "Marble Corridor & Room of Illusion A",
      3 => "Marble Corridor & Room of Illusion B",
      4 => "Shrine of the Apostates & The Wailing Way A",
      5 => "Shrine of the Apostates & The Wailing Way B",
      6 => "Castle Top Floor A",
      7 => "Castle Top Floor B",
      8 => "Skeleton Cave A",
      9 => "Skeleton Cave B",
     10 => "Luminous Cavern A",
     11 => "Luminous Cavern B",
     12 => "Aqueduct of Dragons A",
     13 => "Aqueduct of Dragons B",
     14 => "Sky Walkway & Chapel of Dissonance A",
     15 => "Sky Walkway & Chapel of Dissonance B",
     16 => "Clock Tower A",
     17 => "Clock Tower B",
     18 => "Castle Treasury A",
     19 => "Castle Treasury B",
     20 => "Boss Rush",
  }
}

HARDCODED_BOSSRUSH_ROOM_IDS = [
  0x084AFB74,
  0x084B0230,
  0x084B0304,
  0x084AFE1C,
  0x084AFF84,
]

NOTHING_ENTITY_TYPE = nil
ENEMY_ENTITY_TYPE = 0
SPECIAL_OBJECT_ENTITY_TYPE = 1
CANDLE_ENTITY_TYPE = 2
PICKUP_ENTITY_TYPE = 3

ENTITY_TYPE_DESCRIPTIONS = {
  # TODO
  0 => "Enemy",
  1 => "Special object",
  2 => "Candle",
  3 => "Pickup",
}

ENEMY_IDS = (0x00..0xF9).to_a
COMMON_ENEMY_IDS = (0x00..0x60).to_a # TODO
BOSS_IDS = (0x61..0x63).to_a # TODO

BOSS_DOOR_SUBTYPE = 0 # TODO
BOSS_ID_TO_BOSS_INDEX = { # TODO
}

WOODEN_DOOR_SUBTYPE = 0 # TODO

AREA_NAME_SUBTYPE = nil

SAVE_POINT_SUBTYPE = 0 # TODO

COLOR_OFFSETS_PER_256_PALETTE_INDEX = 16

ENEMY_DNA_RAM_START_OFFSET = 0x080C7E38
ENEMY_DNA_FORMAT = [
  # length: 36
  [4, "Create Code"],
  [4, "Update Code"],
  [1, "Drop 1"],
  [1, "Drop 1 Type"], # e.g. 1=money, 3=item, 5=rare item??
  [1, "Drop 2"],
  [1, "Drop 2 Type"],
  [2, "HP"],
  [2, "EXP"],
  [1, "Level"],
  [1, "Defense?"],
  [1, "Unknown 2"],
  [1, "Unknown 3"],
  [2, "Attack"],
  [1, "Unknown 4"],
  [1, "Unknown 5"],
  [1, "Unknown 6"],
  [1, "Unknown 7"],
  [1, "Unknown 8"],
  [1, "Unknown 9"],
  [1, "Unknown 10"],
  [1, "Unknown 11"],
  [1, "Unknown 12"],
  [1, "Unknown 13"],
  [1, "Resistances", :bitfield],
  [1, "Weaknesses", :bitfield],
  [1, "Unknown 14"],
  [1, "Unknown 15"],
]
ENEMY_DNA_BITFIELD_ATTRIBUTES = {
  "Weaknesses" => [
    "Fire",
    "Ice",
    "Thunder",
    "Wind",
    "Weakness 5",
    "Weakness 6",
    "Weakness 7",
    "Weakness 8",
  ],
  "Resistances" => [
    "Fire",
    "Ice",
    "Thunder",
    "Wind",
    "Resistance 5",
    "Resistance 6",
    "Resistance 7",
    "Resistance 8",
  ],
}

TEXT_LIST_START_OFFSET = 0x08495500
TEXT_RANGE = (0..0x2AA)
TEXT_REGIONS = {
  "Character Names" => (0..0x9),
  "Events" => (0xA..0x21),
  "Item Names" => (0x22..0xF6),
  "Item Descriptions" => (0xF7..0x1CB),
  "Enemy Names" => (0x1CC..0x248),
  "Menus" => (0x249..0x28B),
  "Music Names" => (0x28C..0x2AA),
}
TEXT_REGIONS_OVERLAYS = {
  "Character Names" => nil,
  "Events" => nil,
  "Item Names" => nil,
  "Item Descriptions" => nil,
  "Enemy Names" => nil,
  "Menus" => nil,
  "Music Names" => nil,
}
STRING_DATABASE_START_OFFSET = 0x080CA25C
STRING_DATABASE_ORIGINAL_END_OFFSET = 0x080DAD92
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
SHIFT_JIS_MAPPING_LIST = 0x080C5508

SPECIAL_OBJECT_IDS = (0..0x31)
SPECIAL_OBJECT_CREATE_CODE_LIST = 0x08494EA4
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x08494F6C

ITEM_LOCAL_ID_RANGES = {
  0x03 => (0x00..0x1A), # consumable
  0x04 => (0x00..0x08), # weapon
  0x05 => (0x00..0x7F), # armor
  0x06 => (0x00..0x04), # spellbook
  0x07 => (0x00..0x1F), # relic
  0x08 => (0x00..0x1E), # armor
}
ITEM_GLOBAL_ID_RANGE = (0..0xD4)
SKILL_GLOBAL_ID_RANGE = (0..0) # TODO
SKILL_LOCAL_ID_RANGE = nil
PICKUP_GLOBAL_ID_RANGE = (0..0xD4)

PICKUP_SUBTYPES_FOR_ITEMS = (3..8)
PICKUP_SUBTYPES_FOR_SKILLS = (0..0) # TODO

NEW_GAME_STARTING_AREA_INDEX_OFFSET = nil
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = nil
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = nil
NEW_GAME_STARTING_ROOM_POINTER_OFFSET = 0x08003BC0

ITEM_ICONS_PALETTE_POINTER = 0x08124104
GLYPH_ICONS_PALETTE_POINTER = nil
ITEM_ICONS_GFX_POINTERS = [0x080E8A04, 0x080EAA08, 0x080ECA0C, 0x080EEA10]

CONSUMABLE_FORMAT = [
  # length: 12
  [2, "Item ID"],
  [2, "Icon"],
  [1, "Type"],
  [1, "Unknown 1"],
  [2, "Var A"],
  [4, "Unknown 2"],
]
WEAPON_FORMAT = [
  # length: 12
  [2, "Item ID"],
  [2, "Icon"],
  [2, "special effects?"],
  [1, "Strength"],
  [1, "Defense"],
  [1, "Intelligence"],
  [1, "Luck"],
  [2, "Effects", :bitfield],
]
ARMOR_FORMAT = [
  # length: 12
  [2, "Item ID"],
  [2, "Icon"],
  [1, "Type"],
  [1, "Unknown 1"],
  [1, "Strength"],
  [1, "Defense"],
  [1, "Intelligence"],
  [1, "Luck"],
  [2, "Resistances", :bitfield],
]
SPELLBOOK_FORMAT = [
  # length: 4
  [2, "Item ID"],
  [2, "Icon"],
]
RELIC_FORMAT = [
  # length: 4
  [2, "Item ID"],
  [2, "Icon"],
]
FURNITURE_FORMAT = [
  # length: 4
  [2, "Item ID"],
  [2, "Icon"],
]
SUBWEAPON_FORMAT = [
  # length: 0xC
  [1, "Max at once"],
  [1, "Heart cost"],
  [1, "Num entities created"],
  [1, "Unknown"],
  [4, "Create Code"],
  [4, "Update Code"],
]
SPELL_FORMAT = [
  # length: 0xC
  [4, "Code"],
  [1, "Cast animation"],
  [1, "Unknown"],
  [2, "Mana cost"],
  [2, "Heart cost"],
  [2, "GFX Index"],
]
ITEM_TYPES = [
  {
    name: "Consumables",
    list_pointer: 0x084B24A4,
    count: 0x1C,
    format: CONSUMABLE_FORMAT # length 12
  },
  {
    name: "Weapons",
    list_pointer: 0x084B25F4,
    count: 0x9,
    format: WEAPON_FORMAT # length 12
  },
  {
    name: "Armor",
    list_pointer: 0x084B2660,
    count: 0x80,
    format: ARMOR_FORMAT # length 12
  },
  {
    name: "Spellbooks",
    list_pointer: 0x084B2C60,
    count: 0x5,
    format: SPELLBOOK_FORMAT # length 4
  },
  {
    name: "Relics",
    list_pointer: 0x084B2C74,
    count: 0x20,
    format: RELIC_FORMAT # length 4
  },
  {
    name: "Furniture",
    list_pointer: 0x084B2CA4,
    count: 0x1F,
    format: FURNITURE_FORMAT # length 4
  },
  {
    name: "Subweapons",
    list_pointer: 0x080E2308,
    count: 0x10,
    kind: :subweapon,
    format: SUBWEAPON_FORMAT # length 0xC
  },
  {
    name: "Spells",
    list_pointer: 0x080E29D4,
    count: 0x30,
    kind: :skill,
    format: SPELL_FORMAT # length 0xC
  },
]
ITEM_BITFIELD_ATTRIBUTES = {
  "Effects" => [
    "Fire",
    "Ice",
    "Thunder",
    "Wind",
    "Unknown 5",
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
  ],
  "Resistances" => [
    "Poison",
    "Curse",
    "Stone",
    "Fire",
    "Ice",
    "Thunder",
    "Wind",
    "Unknown 8",
    "Unknown 9",
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
  0x03 => {palette_offset: 1}, # medusa head
  0x09 => {gfx_files: [0x080E895C, 0x080E8964]}, # giant bat
  0x10 => {init_code: 0x08051DE0, palette_offset: 2}, # lizard man -> master lizard
  0x1D => {init_code: 0x08096DD0, palette_offset: 6}, # gate guarder -> living armor
  0x25 => {gfx_files: [0x0811BCD0], sprite: 0x08149C94}, # witch
  0x27 => {init_code: 0x08092A04, palette_offset: 1}, # bomber armor -> rock armor
  0x32 => {init_code: 0x0805A8DC}, # ruler sword lv2
  0x34 => {init_code: 0x08096DD0}, # guardian armor -> living armor
  0x35 => {init_code: 0x08096EF0}, # boomerang armor -> living armor
  0x3D => {palette_offset: 1}, # O
  0x3F => {init_code: 0x080417AC, palette_offset: 1}, #  axe armor lv2 -> axe armor
  0x41 => {init_code: 0x08096DD0, palette_offset: 8}, # bronze guarder -> living armor
  0x43 => {gfx_files: [0x08123680, 0x08123688]}, # legion (saint)
  0x46 => {palette_offset: 2}, # bone liquid
  0x47 => {init_code: 0x0805A8DC}, # ruler sword lv3
  0x48 => {init_code: 0x08051DE0, palette_offset: 1}, # poison lizard -> master lizard
  0x49 => {palette_offset: 1}, # pazuzu
  0x4C => {init_code: 0x08043EB0, palette: 0x08125250}, # blaze master -> skeleton blaze
  0x4F => {init_code: 0x0809B1AC}, # skeleton glass -> skeleton
  0x51 => {init_code: 0x08096EB8}, # hammer-hammer -> living armor
  0x52 => {init_code: 0x08038AFC, palette_offset: 1}, # disc armor lv2 -> disc armor
  0x53 => {init_code: 0x080A3A1C}, # minotaur lv2 -> minotaur
  0x54 => {gfx_files: [0x08123690, 0x08123698]}, # legion (corpse)
  0x58 => {init_code: 0x080467EC, gfx_files: [0x0811BCD8], sprite: 0x0814A0D8, palette_offset: 1}, # pixie -> witch
  0x59 => {init_code: 0x0804FE60, palette_offset: 1}, # sylph -> siren
  0x5C => {init_code: 0x0809B168}, # clear bone -> skeleton
  0x5D => {gfx_files: [0x0811BCC0, 0x080E8944]},
  0x5F => {init_code: 0x08096F28}, # pike master -> living armor
  # TODO 63 dracula wraith 2 glitchy
  0x6D => {palette_offset: 2}, # pazuzu (breaks through wall)
  0x77 => {init_code: 0x080936A8}, # talos (chase) -> talos
  0x79 => {init_code: 0x08096DD0}, # revenge armor -> living armor
  # TODO: 64+
}
ENEMY_FILES_TO_LOAD_LIST = nil
BEST_SPRITE_FRAME_FOR_ENEMY = {
  0x01 => 0x12, # tiny slime
  0x02 => 0x04, # slime
  0x06 => 0x08, # fleaman
  0x07 => 0x0B, # bone soldier
  0x09 => 0x08, # giant bat
  0x0A => 0x04, # ghost
  0x0E => 0x05, # rock armor
  0x0F => 0x03, # white dragon lv2
  0x11 => 0x10, # living armor
  0x16 => 0x26, # peeping eye
  0x17 => 0x10, # skeleton flail
  0x1A => 0x03, # skeleton rib
  0x1B => 0x05, # bone thrower
  0x1D => 0x10, # gate guarder
  0x1F => 0x71, # skull knight
  0x21 => 0x01, # scarecrow
  0x22 => 0x1E, # skeleton spider
  0x25 => 0x0A, # witch
  0x27 => 0x0C, # bomber armor
  0x29 => 0x17, # balloon
  0x2A => 0x18, # big balloon
  0x33 => 0x04, # feather demon
  0x34 => 0x0A, # guardian armor
  0x35 => 0x10, # boomerang armor
  0x3A => 0x10, # mimic
  0x3B => 0x06, # white dragon lv3
  0x3C => 0x0B, # skeleton mirror
  0x3D => 0x03, # O
  0x3F => 0x06, # axe armor lv2
  0x41 => 0x10, # bronze guarder
  0x40 => 0x0A, # specter
  0x43 => 0x29, # legion (saint)
  0x49 => 0x0C, # pazuzu
  0x4D => 0x1F, # arthro skeleton
  0x4E => 0x13, # rare ghost
  0x51 => 0x10, # hammer-hammer
  0x53 => 0x58, # minotaur lv2
  0x55 => 0x10, # talos
  0x58 => 0x0A, # pixie
  0x5E => 0x07, # simon wraith
  0x5F => 0x10, # pike master
  0x77 => 0x10, # talos (chase)
  0x79 => 0x10, # revenge armor
  # TODO: 64+
}
BEST_SPRITE_OFFSET_FOR_ENEMY = {}

COMMON_SPRITE = {desc: "Common", sprite: 0x0812CE34, gfx_files: [0x080E89FC], palette: 0x08124104, palette_offset: 1}

OVERLAY_FILE_FOR_SPECIAL_OBJECT = {}
REUSED_SPECIAL_OBJECT_INFO = {
  0x01 => {palette_offset: 2}, # warp point
  0x03 => {palette_offset: 1}, # wall in save room
  0x04 => {init_code: -1}, # sets a flag
  0x05 => {init_code: 0x0801C950}, # wooden door
  0x06 => {init_code: 0x0801D088, palette_offset: 1},
  0x07 => {init_code: -1}, # light in dark rooms
  0x0B => {palette_offset: 8},
  0x0C => {palette_offset: 8}, # note: 0x0C's crate is created at 0812F5D0
  0x0D => {palette_offset: 4},
  0x11 => {init_code: -1}, # cogs
  0x13 => {palette_offset: 1},
  0x14 => {palette_offset: 2},
  0x15 => {init_code: -1}, # machine
  0x16 => {palette_offset: 2}, # hittable cog
  0x18 => {palette_offset: 3}, # small spinning gear
  0x1B => {init_code: -1}, # lightning
  0x1D => {init_code: 0x080213E0, palette_offset: 5}, # ball race
  0x20 => {init_code: -1}, # giant axe
  0x21 => {palette_offset: 3}, # giant crocomire skull and logs
  0x22 => {init_code: -1}, # giant skull
  0x23 => {init_code: 0x08022FA1}, # giant rock and logs -> giant crocomire skull and logs
  0x24 => {init_code: -1}, # water
  0x25 => {init_code: -1}, # spikes
  0x26 => {init_code: -1}, # event
  0x27 => {init_code: -1}, # drawbridge
  0x2F => {gfx_files: [0x081236B8]},
  0x31 => {init_code: -1},
}
SPECIAL_OBJECT_FILES_TO_LOAD_LIST = nil
BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT = {
  0x03 => 0x01,
  0x05 => 0x01,
  0x06 => 0x52,
  0x09 => 0x01,
  0x0B => 0x08,
  0x0C => 0x05,
  0x12 => 0x08,
  0x14 => 0x06,
  0x19 => 0x03,
}
BEST_SPRITE_OFFSET_FOR_SPECIAL_OBJECT = {}

OTHER_SPRITES = [
  COMMON_SPRITE,
  
  {desc: "Juste player", init_code: 0x080E1FFC},
  
  {desc: "Candle 0", gfx_files: [0x0811BD98], palette: 0x08125BB0, palette_offset: 0, sprite: 0x081548B4},
  {desc: "Candle 1", gfx_files: [0x0811BDA0], palette: 0x08125BB0, palette_offset: 1, sprite: 0x08154A88},
  {desc: "Candle 2", gfx_files: [0x0811BDA8], palette: 0x08125BB0, palette_offset: 2, sprite: 0x08154C08},
  {desc: "Candle 3", gfx_files: [0x0811BDB0], palette: 0x08125BB0, palette_offset: 3, sprite: 0x08154D7C},
  {desc: "Candle 4", gfx_files: [0x0811BDB8], palette: 0x08125CD4, palette_offset: 0, sprite: 0x08154ECC},
  {desc: "Candle 5", gfx_files: [0x0811BDC0], palette: 0x08125CF8, palette_offset: 0, sprite: 0x0815501C},
  {desc: "Candle 6", gfx_files: [0x0811BDC8], palette: 0x08125D1C, palette_offset: 0, sprite: 0x08155250},
  {desc: "Candle 7", gfx_files: [0x0811BDD0], palette: 0x08125BB0, palette_offset: 7, sprite: 0x08155484},
  {desc: "Candle 8", gfx_files: [0x0811BDD8], palette: 0x08125D40, palette_offset: 0, sprite: 0x081556AC},
  
  # maxim's gfx list: 080DC964
  # maxim's duplicate gfx list?: 080E0570
  # skill gfx...? list: 080E2940
]

CANDLE_FRAME_IN_COMMON_SPRITE = 0x47
MONEY_FRAME_IN_COMMON_SPRITE = nil # TODO
CANDLE_SPRITE = COMMON_SPRITE
MONEY_SPRITE = nil # TODO

WEAPON_GFX_LIST_START = nil
WEAPON_GFX_COUNT = 0
WEAPON_SPRITES_LIST_START = nil
WEAPON_PALETTE_LIST = nil
SKILL_GFX_LIST_START = nil # TODO
SKILL_GFX_COUNT = 0 # TODO

MAP_TILE_METADATA_LIST_START_OFFSET = nil
MAP_TILE_METADATA_START_OFFSET = 0x080DAD94
MAP_TILE_LINE_DATA_LIST_START_OFFSET = nil
MAP_TILE_LINE_DATA_START_OFFSET = 0x080DC194
MAP_LENGTH_DATA_START_OFFSET = nil
MAP_NUMBER_OF_TILES = 2560
MAP_SECRET_DOOR_LIST_START_OFFSET = nil
MAP_SECRET_DOOR_DATA_START_OFFSET = nil # TODO (does HoD even have secret doors?)
ABYSS_MAP_TILE_METADATA_START_OFFSET = nil
ABYSS_MAP_TILE_LINE_DATA_START_OFFSET = nil
ABYSS_MAP_NUMBER_OF_TILES = nil
ABYSS_MAP_SECRET_DOOR_DATA_START_OFFSET = nil

WARP_ROOM_LIST_START = 0x0849507C
WARP_ROOM_COUNT = 7

MAP_FILL_COLOR = [0, 0, 224, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [248, 128, 0, 255]
MAP_CASTLE_B_WARP_FILL_COLOR = [0, 196, 0, 255]
MAP_BOTH_CASTLES_WARP_FILL_COLOR = [248, 248, 8, 255]
MAP_SECRET_FILL_COLOR = [0, 128, 0, 255]
MAP_ENTRANCE_FILL_COLOR = [0, 0, 0, 0] # Area entrances don't exist in HoD.
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [0, 200, 200, 255]
MAP_DOOR_CENTER_PIXEL_COLOR = MAP_DOOR_COLOR
MAP_SECRET_DOOR_COLOR = [248, 248, 0, 255]

AREA_MUSIC_LIST_START_OFFSET = nil
SECTOR_MUSIC_LIST_START_OFFSET = 0x084950DC
AVAILABLE_BGM_POOL_START_OFFSET = nil
SONG_INDEX_TO_TEXT_INDEX = [
  "(No change)",
  0x28C,
  0x28D,
  0x28E,
  0x28F,
  0x290,
  0x291,
  0x292,
  0x293,
  0x294,
  0x295,
  0x296,
  0x297,
  0x298,
  0x299,
  0x29A,
  0x29B,
  0x29C,
  0x29D,
  0x29E,
  0x29F,
  0x2A0,
  0x2A1,
  0x2A2,
  0x2A3,
  0x2A4,
  0x2A5,
  0x2A6,
  0x2A7,
  0x2A8,
  0x2A9,
  0x2AA,
]
HOD_UNIQUE_SECTOR_NAMES_FOR_MUSIC = [
  "Entrance A",
  "Entrance B",
  "Marble Corridor A",
  "Marble Corridor B",
  "Shrine of the Apostates A",
  "Shrine of the Apostates B",
  "Castle Top Floor A",
  "Castle Top Floor B",
  "Skeleton Cave A",
  "Skeleton Cave B",
  "Luminous Cavern A",
  "Luminous Cavern B",
  "Aqueduct of Dragons A",
  "Aqueduct of Dragons B",
  "Sky Walkway A",
  "Sky Walkway B",
  "Clock Tower A",
  "Clock Tower B",
  "Castle Treasury A",
  "Castle Treasury B",
  "Room of Illusion A",
  "Room of Illusion B",
  "The Wailing Way A",
  "The Wailing Way B",
  "Chapel of Dissonance A",
  "Chapel of Dissonance B",
]

NEW_OVERLAY_ID = nil
NEW_OVERLAY_FREE_SPACE_START = nil
NEW_OVERLAY_FREE_SPACE_MAX_SIZE = nil
ASSET_MEMORY_START_HARDCODED_LOCATION = nil

ROM_FREE_SPACE_START = 0x69D400
ROM_FREE_SPACE_SIZE = 0x162C00

TEST_ROOM_SAVE_FILE_INDEX_LOCATION = 0x0800213A
TEST_ROOM_AREA_INDEX_LOCATION      = nil
TEST_ROOM_SECTOR_INDEX_LOCATION    = nil
TEST_ROOM_ROOM_INDEX_LOCATION      = nil
TEST_ROOM_X_POS_LOCATION           = 0x080E2120
TEST_ROOM_Y_POS_LOCATION           = 0x080E2122
TEST_ROOM_POINTER_LOCATION         = 0x0800214C
TEST_ROOM_OVERLAY = nil

SHOP_ITEM_POOL_LIST = 0x084B1714
SHOP_ITEM_POOL_COUNT = 0xA
SHOP_ALLOWABLE_ITEMS_LIST = 0x084B15C0
SHOP_NUM_ALLOWABLE_ITEMS = 0x2D

FAKE_FREE_SPACES = []

MAGIC_SEAL_COUNT = 0
MAGIC_SEAL_LIST_START = nil
MAGIC_SEAL_FOR_BOSS_LIST_START = nil
