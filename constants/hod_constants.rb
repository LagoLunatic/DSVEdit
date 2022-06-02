
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
     20 => "Hardcoded rooms",
  }
}

HARDCODED_ROOM_IDS = [
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
  0 => "Enemy",
  1 => "Special object",
  2 => "Candle",
  3 => "Pickup",
}

ENEMY_IDS = (0x00..0xF9).to_a
COMMON_ENEMY_IDS = (0x00..0x60).to_a # TODO
BOSS_IDS = (0x61..0x63).to_a # TODO

BOSS_DOOR_SUBTYPE = 0x06
BOSS_ID_TO_BOSS_INDEX = { # TODO
}

WOODEN_DOOR_SUBTYPE = 0x05

AREA_NAME_SUBTYPE = nil

SAVE_POINT_SUBTYPE = 0x00

COLOR_OFFSETS_PER_256_PALETTE_INDEX = 16

ENEMY_DNA_RAM_START_OFFSET = 0x080C7E38
ENEMY_DNA_FORMAT = [
  # length: 0x24
  [4, "Create Code"],
  [4, "Update Code"],
  [1, "Drop 1"],
  [1, "Drop 1 Type"],
  [1, "Drop 2"],
  [1, "Drop 2 Type"],
  [2, "HP"],
  [2, "EXP"],
  [1, "Level"],
  [1, "Defense?"],
  [1, "Drop 1 Chance"],
  [1, "Drop 2 Chance"],
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

EVENT_CREATE_CODE_LIST_START = 0x084B173C
EVENT_UPDATE_CODE_LIST_START = 0x084B178C

ITEM_LOCAL_ID_RANGES = {
  0x03 => (0x00..0x1A), # consumable
  0x04 => (0x00..0x08), # weapon
  0x05 => (0x00..0x7F), # armor
  0x06 => (0x00..0x04), # spellbook
  0x07 => (0x00..0x1F), # relic
  0x08 => (0x00..0x1E), # armor
}
ITEM_GLOBAL_ID_RANGE = (0..0xD4)
SKILL_GLOBAL_ID_RANGE = (0..-1) # Empty, skills don't have IDs in HoD.
SKILL_LOCAL_ID_RANGE = nil
PICKUP_GLOBAL_ID_RANGE = (0..0xD4)

PICKUP_SUBTYPES_FOR_ITEMS = (3..8)
PICKUP_SUBTYPES_FOR_SKILLS = (0..-1) # Empty, skills don't have IDs in HoD.

NEW_GAME_STARTING_AREA_INDEX_OFFSET = nil
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = nil
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = nil
NEW_GAME_STARTING_ROOM_POINTER_OFFSET = 0x08003BC0

ITEM_ICONS_PALETTE_POINTER = 0x08124104
GLYPH_ICONS_PALETTE_POINTER = nil
ITEM_ICONS_GFX_POINTERS = [0x080E8A04, 0x080EAA08, 0x080ECA0C, 0x080EEA10]

CONSUMABLE_FORMAT = [
  # length: 0xC
  [2, "Item ID"],
  [2, "Icon"],
  [1, "Type"],
  [1, "Unknown 1"],
  [2, "Var A"],
  [4, "Unknown 2"],
]
WEAPON_FORMAT = [
  # length: 0xC
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
  # length: 0xC
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
    format: CONSUMABLE_FORMAT # length 0xC
  },
  {
    name: "Weapons",
    list_pointer: 0x084B25F4,
    count: 0x9,
    format: WEAPON_FORMAT # length 0xC
  },
  {
    name: "Armor",
    list_pointer: 0x084B2660,
    count: 0x80,
    format: ARMOR_FORMAT # length 0xC
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
    count: 0xC,
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
  0x05 => {hod_anim_list_ptr: 0x084B2040, hod_anim_list_count: 12}, # skeleton
  0x0E => {hod_anim_list_ptr: 0x084B1FFC, hod_anim_list_count: 6}, # rock armor
  0x10 => {init_code: 0x08051DE0, palette_offset: 2, hod_anim_list_ptr: 0x084B19AC, hod_anim_list_count: 12}, # lizard man -> master lizard
  0x13 => {hod_anim_list_ptr: 0x084B18F4, hod_anim_list_count: 7}, # skeleton blaze
  0x14 => {hod_anim_list_ptr: 0x084B17F8, hod_anim_list_count: 6}, # big skeleton
  0x1C => {hod_anim_list_ptr: 0x084B2294, hod_anim_list_count: 6}, # skeleton ape
  0x1D => {init_code: 0x08096DD0, palette_offset: 6}, # gate guarder -> living armor
  0x1E => {hod_anim_list_ptr: 0x084B1910, hod_anim_list_count: 7}, # golem
  0x1F => {hod_anim_list_ptr: 0x084B1A30, hod_anim_list_count: 0x21}, # skull knight
  0x20 => {init_code: 0x080596FC}, # tiny devil, use solo GFX instead of pazuzu GFX
  0x21 => {update_code: 0x080AD368}, # scarecrow
  0x24 => {hod_anim_list_ptr: 0x084B1894, hod_anim_list_count: 18}, # axe armor
  0x25 => {gfx_files: [0x0811BCD0], sprite: 0x08149C94}, # witch
  0x27 => {init_code: 0x08092A04, palette_offset: 1, hod_anim_list_ptr: 0x084B1FFC, hod_anim_list_count: 6}, # bomber armor -> rock armor
  0x2B => {hod_anim_list_ptr: 0x084B1860, hod_anim_list_count: 13}, # bone archer
  0x2E => {hod_anim_list_ptr: 0x084B1810, hod_anim_list_count: 9}, # devil
  0x2F => {hod_anim_list_ptr: 0x084B193C, hod_anim_list_count: 4}, # merman
  0x30 => {hod_anim_list_ptr: 0x084B194C, hod_anim_list_count: 6}, # fishman
  0x32 => {init_code: 0x0805A8DC}, # ruler sword lv2
  0x33 => {hod_anim_ptrs: [ # feather demon (animations are hardcoded across a bunch of different state functions)
    # Animations for Feather Demon hardcoded across 0xB different functions in list 0x080DF934.
    0x080DF960,
    0x080DF96C,
    0x080DF998,
    0x080DF9A8,
    0x080DF9B8,
    0x080DF9F0,
    0x080DFA04,
    0x080DFA10,
    0x080DFA20,
    # Animations for Feather Demon's feathers in list 0x084B1A20 (4 entries in the list but the first is a duplicate).
    0x080DFA9C,
    0x080DFAB0,
    0x080DFAC4,
  ]},
  0x34 => {init_code: 0x08096DD0}, # guardian armor -> living armor
  0x35 => {init_code: 0x08096EF0}, # boomerang armor -> living armor
  0x36 => {hod_anim_list_ptr: 0x084B1964, hod_anim_list_count: 8}, # giant merman
  0x39 => {update_code: 0x080AB318}, # gold medusa -> medusa
  0x3A => {hod_anim_list_ptr: 0x084B19DC, hod_anim_list_count: 8}, # mimic
  0x3B => {hod_anim_ptrs: [ # white dragon lv3
    0x080DF4C0,
    0x080DF4D4,
    0x080DF4E8,
    0x080DF4FC,
    0x080DF510,
  ]},
  0x3C => {update_code: 0x080A8504}, # skeleton mirror -> bone soldier
  0x3D => {palette_offset: 1}, # O
  0x3E => {hod_anim_list_ptr: 0x084B184C, hod_anim_list_count: 5}, # harpy (note: first entry is a duplicate)
  0x3F => {init_code: 0x080417AC, update_code: 0x08041988, palette_offset: 1, hod_anim_list_ptr: 0x084B1894, hod_anim_list_count: 0x12}, # axe armor lv2 -> axe armor
  # TODO: fix animations for enemies 0x40+
  0x41 => {init_code: 0x08096DD0, palette_offset: 8}, # bronze guarder -> living armor
  0x43 => {gfx_files: [0x08123680, 0x08123688]}, # legion (saint)
  0x46 => {palette_offset: 2}, # bone liquid
  0x47 => {init_code: 0x0805A8DC}, # ruler sword lv3
  0x48 => {init_code: 0x08051DE0, palette_offset: 1}, # poison lizard -> master lizard
  0x49 => {palette_offset: 1, gfx_files: [0x0811BE10, 0x0811BE18]}, # pazuzu
  0x4C => {init_code: 0x08043EB0, palette: 0x08125250, gfx_sheet_ptr_index: 1, sprite_ptr_index: 1}, # blaze master -> skeleton blaze
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
  0x63 => {gfx_files: [0x081236F0, 0x081236F8], palette_offset: 1}, # dracula wraith 2
  0x64 => {init_code: 0x0803A694}, # fleaman from ceiling
  0x65 => {init_code: 0x080596B4}, # tiny devil from ceiling
  0x66 => {init_code: -1},
  0x67 => {init_code: -1},
  0x68 => {init_code: -1},
  0x69 => {init_code: -1},
  0x6A => {init_code: -1},
  0x6B => {palette_offset: 2},
  0x6C => {sprite: 0x0812CE34, gfx_files: [0x080E89FC], palette: 0x08124104, palette_offset: 1},
  0x6D => {gfx_files: [0x0811BE00, 0x0811BE08], palette_offset: 2}, # pazuzu (breaks through wall)
  0x6E => {palette_offset: 9}, # skeleton mirror (in mirror)
  0x6F => {init_code: 0x08096DD0}, # revenge armor (spawns talos) -> living armor
  0x70 => {init_code: 0x080535A0}, # slime (comes from pipe)
  0x71 => {palette_offset: 3},
  0x72 => {init_code: -1},
  0x73 => {init_code: -1},
  0x74 => {init_code: -1},
  0x75 => {init_code: -1},
  0x76 => {init_code: -1},
  0x77 => {init_code: 0x080936A8}, # talos (chase) -> talos
  0x79 => {init_code: 0x08096DD0}, # revenge armor -> living armor
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
  0x6C => 0x47, # candle
  0x6F => 0x10, # revenge armor (spawns talos)
  0x77 => 0x10, # talos (chase)
  0x79 => 0x10, # revenge armor
}
BEST_SPRITE_OFFSET_FOR_ENEMY = {
  0x71 => {y: -0x20},
}
# Need to copy the data for the normal Juste mode enemy IDs over to the Maxim mode enemy IDs.
(0x00..0x7C).each do |enemy_id|
  REUSED_ENEMY_INFO[enemy_id+0x7D] = REUSED_ENEMY_INFO[enemy_id]
  BEST_SPRITE_FRAME_FOR_ENEMY[enemy_id+0x7D] = BEST_SPRITE_FRAME_FOR_ENEMY[enemy_id]
  BEST_SPRITE_OFFSET_FOR_ENEMY[enemy_id+0x7D] = BEST_SPRITE_OFFSET_FOR_ENEMY[enemy_id]
end

COMMON_SPRITE = {desc: "Common",
  sprite: 0x0812CE34,
  gfx_files: [0x080E89FC], palette: 0x08124104, palette_offset: 1,
  hod_anim_ptrs: [0x080DF52C]
}

OVERLAY_FILE_FOR_SPECIAL_OBJECT = {}
REUSED_SPECIAL_OBJECT_INFO = {
  0x01 => {palette_offset: 2}, # warp point
  0x02 => {init_code: 0x0801C320}, # teleporter
  0x03 => {palette_offset: 1}, # wall in save room
  0x04 => {init_code: -1}, # sets a flag
  0x05 => {init_code: 0x0801C950}, # wooden door
  0x06 => {init_code: 0x0801D088, palette_offset: 1},
  0x07 => {init_code: -1}, # light in dark rooms
  0x08 => {init_code: 0x08078030, sprite_ptr_index: 1},
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
  0x28 => {init_code: 0x0802FC68}, # lydie
  0x2A => {init_code: 0x080246D8, palette: 0x0812613C}, # furniture
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
  
  {desc: "Juste player", init_code: 0x080E1FFC, hod_anim_list_ptr: 0x084B1AD0, hod_anim_list_count: 0x34},
  {desc: "Simon player", init_code: 0x080E202C, hod_anim_list_ptr: 0x084B1BA0, hod_anim_list_count: 0x34, palette_offset: 1},
  {desc: "Maxim player", init_code: 0x080E205C, hod_anim_list_ptr: 0x084B1C70, hod_anim_list_count: 0x34},
  
  {desc: "Candle 0", gfx_files: [0x0811BD98], palette: 0x08125BB0, palette_offset: 0, sprite: 0x081548B4},
  {desc: "Candle 1", gfx_files: [0x0811BDA0], palette: 0x08125BB0, palette_offset: 1, sprite: 0x08154A88},
  {desc: "Candle 2", gfx_files: [0x0811BDA8], palette: 0x08125BB0, palette_offset: 2, sprite: 0x08154C08},
  {desc: "Candle 3", gfx_files: [0x0811BDB0], palette: 0x08125BB0, palette_offset: 3, sprite: 0x08154D7C},
  {desc: "Candle 4", gfx_files: [0x0811BDB8], palette: 0x08125CD4, palette_offset: 0, sprite: 0x08154ECC},
  {desc: "Candle 5", gfx_files: [0x0811BDC0], palette: 0x08125CF8, palette_offset: 0, sprite: 0x0815501C},
  {desc: "Candle 6", gfx_files: [0x0811BDC8], palette: 0x08125D1C, palette_offset: 0, sprite: 0x08155250},
  {desc: "Candle 7", gfx_files: [0x0811BDD0], palette: 0x08125BB0, palette_offset: 7, sprite: 0x08155484},
  {desc: "Candle 8", gfx_files: [0x0811BDD8], palette: 0x08125D40, palette_offset: 0, sprite: 0x081556AC},
  
  {desc: "Area names", gfx_files: [0x0811BBC0, 0x0811BB90, 0x0811BB68, 0x0811BBB0, 0x0811BB70, 0x0811BB78, 0x0811BB60, 0x0811BB88, 0x0811BBA8, 0x0811BBA0, 0x0811BB98, 0x0811BBB8, 0x0811BB80], palette: 0x08124D14, no_sprite: true},
  {desc: "Skull door", init_code: 0x0801C980},
  {desc: "Clock tower in BG", init_code: 0x08026B34},
  {desc: "Giant Merman spin", init_code: 0x0804B220},
  {desc: "Lift to center of castle", init_code: 0x08022134},
  
  {desc: "Prologue Moon", sprite: 0x0815A698, gfx_wrapper: 0x080C4168, palette: 0x081272F4, palette_offset: 1},
  {desc: "Game over screen text", sprite: 0x08149508, gfx_wrapper: 0x0811BCB8, palette: 0x0815D7E8, palette_offset: 4},
  
  {desc: "Event 00", init_code: 0x0802D0E0},
  {desc: "Event 01", init_code: 0x0802EFF0},
  {desc: "Event 02", init_code: 0x0802D3A4},
  {desc: "Event 03", init_code: 0x0802EEE0},
  {desc: "Event 04", init_code: 0x0802D7E8},
  {desc: "Event 05", init_code: 0x0802F1F8},
  {desc: "Event 06", init_code: 0x0802DA38},
  {desc: "Event 07", init_code: 0x0802DCB8},
  {desc: "Event 08", init_code: 0x0802F428},
  {desc: "Event 09", init_code: 0x0802F788},
  {desc: "Event 0A", init_code: 0x0802DE8C},
  {desc: "Event 0B", init_code: 0x0802E10C},
  {desc: "Event 0C", init_code: 0x0802E34C},
  {desc: "Event 0D", init_code: 0x0802E98C},
  {desc: "Event 0E", init_code: 0x0802E558},
  {desc: "Event 0F", init_code: 0x080301DC},
  {desc: "Event 10", init_code: 0x0802FC68, gfx_wrapper: 0x080DC964},#0x080301DC},
  {desc: "Event 11", init_code: 0x08030210},
  {desc: "Event 12", init_code: 0x0802EBB4},
  {desc: "Event 13", init_code: 0x080302C0},
  
  # maxim's gfx list: 080DC964
  # maxim's duplicate gfx list?: 080E0570
  # skill gfx...? list: 080E2940
]

CANDLE_FRAME_IN_COMMON_SPRITE = 0x47
MONEY_FRAME_IN_COMMON_SPRITE = nil
CANDLE_SPRITE = COMMON_SPRITE
MONEY_SPRITE = nil

WEAPON_GFX_LIST_START = nil
WEAPON_GFX_COUNT = 0
WEAPON_SPRITES_LIST_START = nil
WEAPON_PALETTE_LIST = nil
SKILL_GFX_LIST_START = 0x080E2944
SKILL_GFX_COUNT = 0x24
SKILL_GFX_PALETTE_POINTER = 0x08124104 # TODO need to set palette index for each spell
SKILL_GFX_HARDCODED_SPRITE_POINTERS = {
  0x00 => 0x08132F9C,
  0x01 => 0x081332A8,
  0x02 => 0x08133404,
  0x03 => 0x08133470,
  0x04 => 0x08133764,
  0x05 => 0x08133998,
  0x06 => 0x08133AAC,
  0x07 => 0x08133C8C,
  0x08 => 0x08134274,
  0x09 => 0x0812CE34,
  0x0A => 0x0812CE34,
  0x0B => 0x08134274,
  0x0C => 0x081344A8,
  0x0D => 0x08134574,
  0x0E => 0x081346DC,
  0x0F => 0x0813485C,
  0x10 => 0x08134CB8,
  0x11 => 0x0813512C,
  0x12 => 0x08135438,
  0x13 => 0x08135798,
  0x14 => 0x081359E4,
  0x15 => 0x08135ED0,
  0x16 => 0x0812CE34,
  0x17 => 0x08135ED0,
  0x18 => 0x08136518,
  0x19 => 0x08136734,
  0x1A => 0x08136AA0,
  # TODO 1B+ just have placeholder sprites set here
  0x1B => 0x081332A8,
  0x1C => 0x081332A8,
  0x1D => 0x081332A8,
  0x1E => 0x08157E30, # sprite is correct, but gfx isn't...?
  0x1F => 0x081332A8,
  0x20 => 0x081332A8,
  0x21 => 0x081332A8,
  0x22 => 0x081332A8,
  0x23 => 0x081332A8,
}

BUTTON_AND_WALL_GFX_LIST_START = 0x084B096C

MAP_TILE_METADATA_LIST_START_OFFSET = nil
MAP_TILE_METADATA_START_OFFSET = 0x080DAD94
MAP_TILE_LINE_DATA_LIST_START_OFFSET = nil
MAP_TILE_LINE_DATA_START_OFFSET = 0x080DC194
MAP_LENGTH_DATA_START_OFFSET = nil
MAP_NUMBER_OF_TILES = 2560
MAP_SECRET_DOOR_LIST_START_OFFSET = nil
MAP_SECRET_DOOR_DATA_START_OFFSET = 0x080DC694
MAP_SECRET_ROOM_DATA_START_OFFSET = nil
MAP_DRAW_X_OFFSET_LOCATION = nil
MAP_DRAW_Y_OFFSET_LOCATION = nil
ABYSS_MAP_TILE_METADATA_START_OFFSET = nil
ABYSS_MAP_TILE_LINE_DATA_START_OFFSET = nil
ABYSS_MAP_NUMBER_OF_TILES = nil
ABYSS_MAP_SECRET_DOOR_DATA_START_OFFSET = nil
ABYSS_MAP_DRAW_X_OFFSET_LOCATION = nil
ABYSS_MAP_DRAW_Y_OFFSET_LOCATION = nil

WARP_ROOM_LIST_POINTER_HARDCODED_LOCATIONS = [0x08009BD0]
WARP_ROOM_LAST_INDEX_HARDCODED_LOCATIONS = [] # HoD doesn't seem to hardcode how many warp rooms there are, just checks the null end marker in the list

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

PLAYER_LIST_POINTER = 0x080E1FFC
PLAYER_COUNT = 3
PLAYER_NAMES = [
  "Juste",
  "Simon",
  "Maxim",
]
PLAYER_LIST_FORMAT = [
  # length: 0x30
  [4, "GFX list pointer"],
  [4, "Palette pointer"],
  [2, "Palette index"],
  [2, "Unknown 2"],
  [4, "Sprite pointer"],
  [4, "Animations pointer"],
  [4, "Banned moves pointer"],
  [4, "Movement params pointer"],
  [4, "Anim palette indexes ptr"],
  [4, "Unknown 7"],
  [4, "Sound effects pointer"],
  [4, "Misc bitfield", :bitfield],
  [4, "Starting subweapon"],
]
PLAYER_BITFIELD_ATTRIBUTES = {
  "Misc bitfield" => [
    "Can use Healing Spell (No subweapon + Summoning Tome)",
    "Can use Knife",
    "Can use Axe",
    "Can use Cross",
    "Can use Holy Water",
    "Can use Holy Book",
    "Can use Sacred Fist",
    "Can use Shuriken",
    "Unknown 9",
    "Unknown 10",
    "Unknown 11",
    "Unknown 12",
    "Unknown 13",
    "Unknown 14",
    "Unknown 15",
    "Unknown 16",
    "Dangling whip visible / can charge whip",
    "Has trails",
    "Can turn in mid-air",
    "Taken damage numbers visible",
    "Creates dust clouds",
    "Vulnerable to status effects",
    "Blue attack effects",
    "Unknown 24", # Set for Maxim, but doesn't seem to be read in the code
    "Juste's Axe/Cross/Holy Water", # Disables the changes for Simon's version of these 3 subweapons
    "Interrupt attack anim on land",
    "Unknown 27",
    "Unknown 28",
    "Unknown 29",
    "Unknown 30",
    "Unknown 31",
    "Unknown 32",
  ]
}

PLAYER_MOVEMENT_PARAMS_LIST_POINTER = 0x080E1C00
PLAYER_MOVEMENT_PARAMS_FORMAT = [
  # length: 0xAC
  [4, "Walking X Velocity"],
  [4, "Unknown 2"],
  [4, "Quick Dash X Force"],
  [4, "Quick Dash X Deceleration"],
  [4, "Unknown 5"], # 0806E132 0806E262 x vel
  [4, "Unknown 6"],
  [4, "Unknown 7"], # 0806E8BA x vel
  [4, "Unknown 8"], # 0806E8E8 y vel
  [4, "Unknown 9"], # 0806E8EE y accel
  [4, "Sliding Horizontally X Velocity"],
  [4, "Sliding Sloped X Velocity"],
  [4, "Unknown 12"],
  [4, "Unknown 13"],
  [4, "Damaged on Ground X Velocity"],
  [4, "Damaged on Ground X Deceleration"],
  [4, "Unknown 16"], # 0806DC2E x vel
  [4, "Unknown 17"], # 0806DC36 x accel
  [4, "Damaged in Air X Velocity"],
  [4, "Damaged in Air Y Velocity"],
  [4, "Unknown 20"], # 0806DE38 0806DF98 x accel
  [4, "Unknown 21"], # 0806DDBA 0806DF7E y vel
  [4, "Unknown 22"], # 0806DFC8 y accel
  [4, "X Velocity During Ascent"],
  [4, "X Velocity During Descent"],
  [4, "Walking X Deceleration"],
  [4, "X Deceleration in Air"],
  [4, "Unknown 27"], # 0806C35E x vel
  [4, "High Jump Y Force"],
  [4, "High Jump Y Acceleration"],
  [4, "Unknown 30"],
  [4, "First Jump Y Force"],
  [4, "Air Jump Y Force"],
  [4, "Unknown 33"], # 08071FC6 y accel
  [4, "Unknown 34"], # 0806F49E y vel
  [4, "Y Acceleration During Ascent"], # 0806DE46 y accel during a jump? (gravity?)
  [4, "Y Acceleration During Descent"], # 0806C71A 0806E47A falling y accel? ONLY falling off an edge or smth though, not descending from a jump?
  [4, "Maximum Y Velocity"],
  [4, "Jumpkicking X Velocity"],
  [4, "Jumpkicking Y Velocity"],
  [4, "Unknown 40"], # 080714A0 y vel
  [4, "Unknown 41"], # 080714A8 y accel
  [4, "Unknown 42"], # 080714FE y vel
  [4, "Maximum Number of Jumps"],
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
TEST_ROOM_SCREEN_X_POS_LOCATION    = 0x08002164
TEST_ROOM_SCREEN_Y_POS_LOCATION    = 0x08002168
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

MENU_BG_LAYER_INFOS = [
  {
    name: "Pause screen",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x08166874,
  },
  {
    name: "Equip",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x08166124,
  },
  {
    name: "Item use",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x081661B4,
  },
  {
    name: "Spell book select",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x08166364,
  },
  {
    name: "Relics",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x081662D4,
  },
  {
    name: "Button config",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x08166244,
  },
  {
    name: "Secret info",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x081667E4,
  },
  {
    name: "Bestiary list",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x081663F4,
  },
  {
    name: "Bestiary entry",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x08166514,
  },
  {
    name: "Collectibles",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x081665A4,
  },
  {
    name: "Shop",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x08166904,
  },
  {
    name: "Shop buy menu",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x08166994,
  },
  {
    name: "Shop sell menu",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x08166484,
  },
  {
    name: "Konami logo",
    gfx_file_pointers:      [0x0815CD98],
    palette_list_pointer:   0x0815D3D8,
    layer_metadata_pointer: 0x08163974,
  },
  {
    name: "Licensed by Nintendo",
    gfx_file_pointers:      [0x0815CDA0, 0x0815CDA8, 0x0815CDB0],
    palette_list_pointer:   0x0815D3FC,
    layer_metadata_pointer: 0x08163A94,
  },
  {
    name: "Title screen 1",
    gfx_file_pointers:      [0x0815CDA0, 0x0815CDA8, 0x0815CDB0],
    palette_list_pointer:   0x0815D3FC,
    layer_metadata_pointer: 0x08163A04,
  },
  {
    name: "Title screen 2",
    gfx_file_pointers:      [0x0815CDA0, 0x0815CDA8, 0x0815CDB0],
    palette_list_pointer:   0x0815D3FC,
    layer_metadata_pointer: 0x08163BA4,
  },
  {
    name: "Title screen background (blue)",
    gfx_file_pointers:      [0x0815CDA0, 0x0815CDA8, 0x0815CDB0],
    palette_list_pointer:   0x0815D3FC,
    layer_metadata_pointer: 0x08163DC4,
  },
  {
    name: "Title screen background (red)",
    gfx_file_pointers:      [0x0815CDA0, 0x0815CDA8, 0x0815CDB0],
    palette_list_pointer:   0x0815D3FC,
    layer_metadata_pointer: 0x08163CB4,
  },
  {
    name: "Game start 1",
    gfx_file_pointers:      [0x0815CDB8, 0x0815CDC0],
    palette_list_pointer:   0x0815D5A0,
    layer_metadata_pointer: 0x08163EE4,
  },
  {
    name: "Game start 2",
    gfx_file_pointers:      [0x0815CDB8, 0x0815CDC0],
    palette_list_pointer:   0x0815D5A0,
    layer_metadata_pointer: 0x08163E54,
  },
  {
    name: "Select data 1",
    gfx_file_pointers:      [0x0815CDB8, 0x0815CDC0],
    palette_list_pointer:   0x0815D5A0,
    layer_metadata_pointer: 0x08163F74,
  },
  {
    name: "Select data 2 / Delete data 2",
    gfx_file_pointers:      [0x0815CDB8, 0x0815CDC0],
    palette_list_pointer:   0x0815D5A0,
    layer_metadata_pointer: 0x081641B4,
  },
  {
    name: "Copy data 1",
    gfx_file_pointers:      [0x0815CDB8, 0x0815CDC0],
    palette_list_pointer:   0x0815D5A0,
    layer_metadata_pointer: 0x08164094,
  },
  {
    name: "Copy data 2",
    gfx_file_pointers:      [0x0815CDB8, 0x0815CDC0],
    palette_list_pointer:   0x0815D5A0,
    layer_metadata_pointer: 0x08164244,
  },
  {
    name: "Delete data 1",
    gfx_file_pointers:      [0x0815CDB8, 0x0815CDC0],
    palette_list_pointer:   0x0815D5A0,
    layer_metadata_pointer: 0x08164124,
  },
  {
    name: "Name entry / Change name",
    gfx_file_pointers:      [0x0815CDB8, 0x0815CDC0],
    palette_list_pointer:   0x0815D5A0,
    layer_metadata_pointer: 0x08164004,
  },
  {
    name: "Boss rush menu 1",
    gfx_file_pointers:      [0x0815CDC8, 0x0811AB04],
    palette_list_pointer:   0x0815D744,
    layer_metadata_pointer: 0x08164514,
  },
  {
    name: "Boss rush menu 2",
    gfx_file_pointers:      [0x0815CDC8, 0x0811AB04],
    palette_list_pointer:   0x0815D744,
    layer_metadata_pointer: 0x08164484,
  },
  {
    name: "Boss rush menu 3",
    gfx_file_pointers:      [0x0815CDC8, 0x0811AB04],
    palette_list_pointer:   0x0815D744,
    layer_metadata_pointer: 0x08164364,
  },
  {
    name: "Boss rush score (easy)",
    gfx_file_pointers:      [0x0815CDC8, 0x0811AB04],
    palette_list_pointer:   0x0815D744,
    layer_metadata_pointer: 0x081642D4,
  },
  {
    name: "Boss rush score (normal)",
    gfx_file_pointers:      [0x0815CDC8, 0x0811AB04],
    palette_list_pointer:   0x0815D744,
    layer_metadata_pointer: 0x08164634,
  },
  {
    name: "Boss rush score (hard)",
    gfx_file_pointers:      [0x0815CDC8, 0x0811AB04],
    palette_list_pointer:   0x0815D744,
    layer_metadata_pointer: 0x081645A4,
  },
  {
    name: "Boss rush retry",
    gfx_file_pointers:      [0x0815CDC8, 0x0811AB04],
    palette_list_pointer:   0x0815D744,
    layer_metadata_pointer: 0x081646C4,
  },
  {
    name: "Boss rush menu background",
    gfx_file_pointers:      [0x0815CDC8, 0x0811AB04],
    palette_list_pointer:   0x0815D744,
    layer_metadata_pointer: 0x081643F4,
  },
  {
    name: "Hard boss rush end screen 1",
    gfx_file_pointers:      [0x0815D3D0],
    palette_list_pointer:   0x08163750,
    layer_metadata_pointer: 0x0819CC04,
  },
  {
    name: "Hard boss rush end screen 2",
    gfx_file_pointers:      [0x0815D3D0],
    palette_list_pointer:   0x08163750,
    layer_metadata_pointer: 0x0819CB74,
  },
  {
    name: "Hard boss rush end screen text",
    gfx_file_pointers:      [0x0815D3D0],
    palette_list_pointer:   0x08163750,
    layer_metadata_pointer: 0x0819CAE4,
  },
  {
    name: "Sound mode (unused)",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x08166754,
  },
  {
    name: "BGM test",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x08166634,
  },
  {
    name: "Sound effect test (unused)",
    gfx_file_pointers:      [0x0815CE40, 0x0815CE48],
    palette_list_pointer:   0x0815E104,
    layer_metadata_pointer: 0x081666C4,
  },
  {
    name: "Prologue 1",
    gfx_file_pointers:      [0x0815D3C0, 0x0815D3C8],
    palette_list_pointer:   0x081635AC,
    layer_metadata_pointer: 0x0819C8B4,
  },
  {
    name: "Prologue 2",
    gfx_file_pointers:      [0x0815D3C0, 0x0815D3C8],
    palette_list_pointer:   0x081635AC,
    layer_metadata_pointer: 0x0819C9C4,
  },
  {
    name: "Prologue 3",
    gfx_file_pointers:      [0x0815D3C0, 0x0815D3C8],
    palette_list_pointer:   0x081635AC,
    layer_metadata_pointer: 0x0819CA54,
  },
  {
    name: "HUD",
    gfx_file_pointers:      [0x0815CDF0],
    palette_list_pointer:   0x0815D8B0,
    layer_metadata_pointer: 0x08164C94,
  },
  {
    name: "Game over screen background",
    gfx_file_pointers:      [0x0815CDD0, 0x0815CDD8, 0x0815CDE0],
    palette_list_pointer:   0x0815D7E8,
    layer_metadata_pointer: 0x08164754,
  },
  {
    name: "Game over screen ring",
    gfx_file_pointers:      [0x0815CDD0, 0x0815CDD8, 0x0815CDE0],
    palette_list_pointer:   0x0815D7E8,
    layer_metadata_pointer: 0x08164874,
  },
  {
    name: "Game over screen ring reflection",
    gfx_file_pointers:      [0x0815CDD0, 0x0815CDD8, 0x0815CDE0],
    palette_list_pointer:   0x0815D7E8,
    layer_metadata_pointer: 0x081647E4,
  },
  {
    name: "Credits",
    gfx_file_pointers:      [0x0815CDE8],
    palette_list_pointer:   0x0815D88C,
    layer_metadata_pointer: 0x08164C04,
  },
  {
    name: "Portrait 00 (Merchant)",
    gfx_file_pointers:      [0x0815D0A0],
    palette_list_pointer:   0x081601F8,
    layer_metadata_pointer: 0x08181B84,
  },
  {
    name: "Portrait 01 (Juste)",
    gfx_file_pointers:      [0x0815CE50],
    palette_list_pointer:   0x0815E2A8,
    layer_metadata_pointer: 0x08166A24,
  },
  {
    name: "Portrait 02 (Maxim)",
    gfx_file_pointers:      [0x0815D0B8],
    palette_list_pointer:   0x08160264,
    layer_metadata_pointer: 0x08181D34,
  },
  {
    name: "Portrait 03 (Angry Maxim)",
    gfx_file_pointers:      [0x0815D0C0],
    palette_list_pointer:   0x08160288,
    layer_metadata_pointer: 0x08181DC4,
  },
  {
    name: "Portrait 04 (Death)",
    gfx_file_pointers:      [0x0815D0A8],
    palette_list_pointer:   0x0816021C,
    layer_metadata_pointer: 0x08181C14,
  },
  {
    name: "Portrait 05 (Lydie)",
    gfx_file_pointers:      [0x0815D0B0],
    palette_list_pointer:   0x08160240,
    layer_metadata_pointer: 0x08181CA4,
  },
  {
    name: "Portrait 06 (Dracula Wraith)",
    gfx_file_pointers:      [0x0815D0C8],
    palette_list_pointer:   0x081602AC,
    layer_metadata_pointer: 0x08181E54,
  },
]

FONTS = [
  {
    font_address: 0x08496316,
    font_data_size: 0x2912,
    char_width: 8,
    char_height: 12,
  },
]

ENTITY_SET_ANIMATION_FUNC_PTR = 0x080134F4
