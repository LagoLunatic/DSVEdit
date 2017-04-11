
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
  5 => "???",
  6 => "Entity hider",
  7 => "Font loader",
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
  #"Item Names" => (0xC..0xD9),
  #"Item Descriptions" => (0xDA..0x1A7),
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

SPECIAL_OBJECT_IDS = (0..0x75)
SPECIAL_OBJECT_CREATE_CODE_LIST = 0x084F0DF8
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x084F0ED8

PICKUP_SUBTYPES_FOR_ITEMS = (0x02..0x04) # TODO
PICKUP_SUBTYPES_FOR_SKILLS = (0x05..0xFF) # TODO
SOUL_FORMAT = [
  # length: 16
  [4, "Code"],
  [2, "Unknown 1"],
  [2, "Mana"],
  [1, "Unknown 2"],
  [1, "Unknown 3"],
  [2, "Unknown 4"],
  [2, "Effects", :bitfield],
  [2, "Unknown 6"],
]
ITEM_TYPES = [
  {
    name: "Souls",
    list_pointer: 0x080E15A8,
    count: 0x37,
    kind: :skill,
    format: SOUL_FORMAT # length: 16
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
}

OVERLAY_FILE_FOR_ENEMY_AI = {}
REUSED_ENEMY_INFO = {}
ENEMY_FILES_TO_LOAD_LIST = nil
BEST_SPRITE_FRAME_FOR_ENEMY = {
  0x00 => 0x03,
  0x01 => 0x06,
  0x06 => 0x11,
}

OVERLAY_FILE_FOR_SPECIAL_OBJECT = {}
REUSED_SPECIAL_OBJECT_INFO = {}
SPECIAL_OBJECT_FILES_TO_LOAD_LIST = nil
BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT = {}

