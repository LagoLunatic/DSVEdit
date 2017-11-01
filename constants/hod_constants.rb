
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
      2 => "Marble Corridor A",
      3 => "Marble Corridor B",
      4 => "The Wailing Way A",
      5 => "The Wailing Way B",
      6 => "Castle Top Floor A",
      7 => "Castle Top Floor B",
      8 => "Skeleton Cave A",
      9 => "Skeleton Cave B",
     10 => "Luminous Cavern A",
     11 => "Luminous Cavern B",
     12 => "Aqueduct of Dragons A",
     13 => "Aqueduct of Dragons B",
     14 => "Chapel of Dissonance A",
     15 => "Chapel of Dissonance B",
     16 => "Clock Tower A",
     17 => "Clock Tower B",
     18 => "Castle Treasury A",
     19 => "Castle Treasury B",
  }
}

HARDCODED_BOSSRUSH_ROOM_IDS = [
  # TODO
]

ENTITY_TYPE_DESCRIPTIONS = {
  # TODO
  0 => "Nothing",
  1 => "Enemy",
  2 => "Special object",
  3 => "Candle",
  4 => "Pickup",
  5 => "Hard mode pickup",
  6 => "All-souls-found pickup",
}

ENEMY_IDS = (0x00..0x70).to_a
COMMON_ENEMY_IDS = (0x00..0x6F).to_a # TODO
BOSS_IDS = (0x70..0x70).to_a # TODO

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
TEXT_RANGE = (0..0x24E)
TEXT_REGIONS = {
  "Character Names" => (0..0x9),
  "Events" => (0xA..0x21),
  "Item Names" => (0x22..0xF6),
  "Item Descriptions" => (0xF7..0x1CB),
  "Enemy Names" => (0x1CC..0x22F),
  "Misc" => (0x230..0x24E),
}
TEXT_REGIONS_OVERLAYS = {
  "Character Names" => nil,
  "Events" => nil,
  "Item Names" => nil,
  "Item Descriptions" => nil,
  "Enemy Names" => nil,
  "Misc" => nil,
}
STRING_DATABASE_START_OFFSET = nil # TODO
STRING_DATABASE_ORIGINAL_END_OFFSET = nil # TODO
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

SPECIAL_OBJECT_IDS = (0..0) # TODO
SPECIAL_OBJECT_CREATE_CODE_LIST = nil # TODO
SPECIAL_OBJECT_UPDATE_CODE_LIST = nil # TODO

ITEM_LOCAL_ID_RANGES = {
   # TODO
}
ITEM_GLOBAL_ID_RANGE = (0..0) # TODO
SKILL_GLOBAL_ID_RANGE = (0..0) # TODO
SKILL_LOCAL_ID_RANGE = nil
PICKUP_GLOBAL_ID_RANGE = (0..0) # TODO

PICKUP_SUBTYPES_FOR_ITEMS = (0..0) # TODO
PICKUP_SUBTYPES_FOR_SKILLS = (0..0) # TODO

NEW_GAME_STARTING_AREA_INDEX_OFFSET = nil
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = nil # TODO
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = nil # TODO

ITEM_ICONS_PALETTE_POINTER = 0x08124104
GLYPH_ICONS_PALETTE_POINTER = nil
ITEM_ICONS_GFX_POINTERS = [0x080E8A04, 0x080EAA08, 0x080ECA0C, 0x080EEA10]

CONSUMABLE_FORMAT = [
  # length: 16
  [2, "Item ID"],
  [2, "Icon"],
  [1, "Unknown 1"],
  [1, "Unknown 2"],
  [1, "Unknown 3"],
  [1, "Unknown 4"],
  [1, "Unknown 5"],
  [1, "Unknown 6"],
  [1, "Unknown 7"],
  [1, "Unknown 8"],
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
  # length: 20
  [2, "Item ID"],
  [2, "Icon"],
  [1, "Type?"],
  [1, "Unknown 2"],
  [1, "Strength"],
  [1, "Defense"],
  [1, "Intelligence"],
  [1, "Luck"],
  [1, "resist?"],
  [1, "Unknown 8"],
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
  ],
  "Resistances" => [
    "Fire",
    "Ice",
    "Thunder",
    "Wind",
    "Unknown 5",
    "Unknown 6",
    "Unknown 7",
    "Unknown 8",
  ],
}

OVERLAY_FILE_FOR_ENEMY_AI = {}
REUSED_ENEMY_INFO = {
}
ENEMY_FILES_TO_LOAD_LIST = nil
BEST_SPRITE_FRAME_FOR_ENEMY = {
}
BEST_SPRITE_OFFSET_FOR_ENEMY = {}

COMMON_SPRITE = {} # TODO

OVERLAY_FILE_FOR_SPECIAL_OBJECT = {}
REUSED_SPECIAL_OBJECT_INFO = {
}
SPECIAL_OBJECT_FILES_TO_LOAD_LIST = nil
BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT = {
}
BEST_SPRITE_OFFSET_FOR_SPECIAL_OBJECT = {}

OTHER_SPRITES = [
  COMMON_SPRITE,
]

CANDLE_FRAME_IN_COMMON_SPRITE = nil # TODO
MONEY_FRAME_IN_COMMON_SPRITE = nil # TODO
CANDLE_SPRITE = nil # TODO
MONEY_SPRITE = nil # TODO

WEAPON_GFX_LIST_START = nil # TODO
WEAPON_GFX_COUNT = nil # TODO
WEAPON_SPRITES_LIST_START = nil # TODO
WEAPON_PALETTE_LIST = nil # TODO

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

WARP_ROOM_LIST_START = nil # TODO
WARP_ROOM_COUNT = nil # TODO

MAP_FILL_COLOR = [0, 0, 224, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [248, 128, 0, 255]
MAP_SECRET_FILL_COLOR = [0, 128, 0, 255]
MAP_ENTRANCE_FILL_COLOR = [248, 248, 8, 255]#[0, 196, 0, 255]#[216, 64, 216, 255] # Rooms that warp you between castles. Note that some of these are only in one castle or the other?
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [0, 200, 200, 255]
MAP_DOOR_CENTER_PIXEL_COLOR = MAP_DOOR_COLOR
MAP_SECRET_DOOR_COLOR = [248, 248, 0, 255]

AREA_MUSIC_LIST_START_OFFSET = nil
SECTOR_MUSIC_LIST_START_OFFSET = nil # TODO
AVAILABLE_BGM_POOL_START_OFFSET = nil
SONG_INDEX_TO_TEXT_INDEX = [
  # TODO
]

NEW_OVERLAY_ID = nil
NEW_OVERLAY_FREE_SPACE_START = nil
NEW_OVERLAY_FREE_SPACE_END = nil
NEW_OVERLAY_FREE_SPACE_SIZE = nil

ROM_FREE_SPACE_START = 0x69D400
ROM_FREE_SPACE_SIZE = 0x162C00

TEST_ROOM_SAVE_FILE_INDEX_LOCATION = nil # TODO
TEST_ROOM_AREA_INDEX_LOCATION      = nil
TEST_ROOM_SECTOR_INDEX_LOCATION    = nil # TODO
TEST_ROOM_ROOM_INDEX_LOCATION      = nil # TODO
TEST_ROOM_X_POS_LOCATION           = nil # TODO
TEST_ROOM_Y_POS_LOCATION           = nil # TODO
TEST_ROOM_OVERLAY = nil

SHOP_ITEM_POOL_LIST = nil # TODO
SHOP_ITEM_POOL_COUNT = nil # TODO

FAKE_FREE_SPACES = []

MAGIC_SEAL_COUNT = 0
MAGIC_SEAL_LIST_START = nil
MAGIC_SEAL_FOR_BOSS_LIST_START = nil
