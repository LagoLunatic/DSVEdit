
GAME = "por"
LONG_GAME_NAME = "Portrait of Ruin"

AREA_LIST_RAM_START_OFFSET = 0x020DF36C

EXTRACT_EXTRA_ROOM_INFO = Proc.new do |last_4_bytes_of_room_metadata|
  number_of_doors    = (last_4_bytes_of_room_metadata & 0b00000000_00000000_00000000_01111111)
  room_xpos_on_map   = (last_4_bytes_of_room_metadata & 0b00000000_00000000_00011111_10000000) >> 7
 #unknown_1          = (last_4_bytes_of_room_metadata & 0b00000000_00000000_00100000_00000000) >> 13
  room_ypos_on_map   = (last_4_bytes_of_room_metadata & 0b00000000_00001111_11000000_00000000) >> 14
 #unknown_2          = (last_4_bytes_of_room_metadata & 0b00000000_00010000_00000000_00000000) >> 20
  palette_page_index = (last_4_bytes_of_room_metadata & 0b00001111_10000000_00000000_00000000) >> 23
  [number_of_doors, room_xpos_on_map, room_ypos_on_map, palette_page_index]
end

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

CONSTANT_OVERLAYS = [0, 5, 6, 7, 8]

INVALID_ROOMS = [0x020E5AD0, 0x020E62E0, 0x020E6300, 0x020E5BA0, 0x020E6320, 0x020E6610, 0x020E7388, 0x020E7780, 0x020E7850]

MAP_TILE_METADATA_LIST_START_OFFSET = 0x020DF3E4
MAP_TILE_LINE_DATA_LIST_START_OFFSET = 0x020DF420
MAP_LENGTH_DATA_START_OFFSET = 0x020BF914

MAP_FILL_COLOR = [160, 64, 128, 255]
MAP_SAVE_FILL_COLOR = [248, 0, 0, 255]
MAP_WARP_FILL_COLOR = [0, 0, 248, 255]
MAP_SECRET_FILL_COLOR = [0, 128, 0, 255]
MAP_ENTRANCE_FILL_COLOR = [248, 128, 0, 255]
MAP_LINE_COLOR = [248, 248, 248, 255]
MAP_DOOR_COLOR = [216, 216, 216, 255]
MAP_DOOR_CENTER_PIXEL_COLOR = [0, 0, 0, 0]

RAM_START_FOR_ROOM_OVERLAYS = 0x022E8820
RAM_END_FOR_ROOM_OVERLAYS = 0x022E8820 + 132736
ARM9_LENGTH = 1_039_288
LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET = 0xD1AFC
LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET = 0xE315B
LIST_OF_FILE_RAM_LOCATIONS_ENTRY_LENGTH = 32

OVERLAY_RAM_INFO_START_OFFSET = 0x101C00
OVERLAY_ROM_INFO_START_OFFSET = 0x67FE00

ENTITY_BLOCK_START_OFFSET = 0x3798D8
ENTITY_BLOCK_END_OFFSET   = 0x6344D1 # guess

ENEMY_DNA_RAM_START_OFFSET = 0x020BE568
ENEMY_DNA_LENGTH = 32
ENEMY_DNA_FORMAT = [
  [4, "Init AI"],
  [4, "Running AI"],
  [2, "Item 1"],
  [2, "Item 2"],
  [1, "Unknown 1"],
  [1, "SP"],
  [2, "HP"],
  [2, "EXP"],
  [1, "Unknown 2"],
  [1, "Attack"],
  [1, "Defense"],
  [1, "Unknown 3"],
  [1, "Item 1 Chance"],
  [1, "Item 2 Chance"],
  [2, "Weaknesses", :bitfield],
  [2, "Unknown 4"],
  [2, "Resistances", :bitfield],
  [2, "Unknown 5"],
]
ENEMY_DNA_BITFIELD_ATTRIBUTES = {
  "Weaknesses" => [
    "Strike",
    "Whip",
    "Slash",
    "Fire",
    "Ice",
    "Electric",
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
  ],
  "Resistances" => [
    "Strike",
    "Whip",
    "Slash",
    "Fire",
    "Ice",
    "Electric",
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
  ],
}

# Overlays 43 to 77 used for enemies.
OVERLAY_FILE_FOR_ENEMY_AI = {
  # Enemies not listed here use one of the constant overlays like 0.
   19 => 72, # andras
   21 => 76, # golem
   33 => 44, # great armor
   34 => 48, # catoblepas
   37 => 68, # dragon zombie
   42 => 69, # sand worm
   44 => 62, # amphisbaena
   45 => 54, # elgiza
   69 => 45, # treant
   78 => 47, # flame demon
   81 => 46, # malphas
   82 => 44, # final guard
   85 => 71, # ruler's sword
   90 => 77, # amalaric sniper
   92 => 48, # gorgon
  100 => 73, # alura une
  114 => 69, # poison worm
  120 => 45, # iron golem
  122 => 47, # demon
  125 => 75, # alastor
  129 => 43, # balore
  130 => 50, # gergoth
  131 => 49, # zephyr
  132 => 67, # aguni
  133 => 51, # abaddon
  135 => 70, # fake trevor
  136 => 70, # fake grant
  137 => 70, # fake sypha
  138 => 58, # dullahan
  139 => 53, # behemoth
  140 => 56, # keremet
  141 => 74, # astarte
  142 => 52, # legion
  143 => 59, # dagon
  144 => 64, # death
  145 => 63, # stella/loretta
  146 => 63, # stella/loretta
  147 => 55, # brauner
  148 => 60, # the creature
  149 => 57, # werewolf
  150 => 61, # medusa
  151 => 66, # mummy man
  152 => 25, # whip's memory
  153 => 64, # dracula
  154 => 65, # true dracula
}
REUSED_ENEMY_INFO = {
   #17 => {init_code: 0x0222D5DC, gfx_sheet_ptr_index: 0, palette_offset: 3, palette_list_ptr_index: 0}, # wight -> zombie
   49 => {palette_offset: 2}, # lilith
   70 => {init_code: 0x02297320, palette_offset: 3}, # red axe armor -> axe armor
   78 => {init_code: 0x022D7930}, # flame demon
   84 => {palette_offset: 1}, # ghoul and zombie
   88 => {init_code: 0x022744DC, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1}, # buster armor -> crossbow armor
   92 => {init_code: 0x022D7918, palette_list_ptr_index: 1},
   94 => {init_code: 0x02259EE4}, # tanjelly -> slime
   99 => {init_code: 0x022630F8}, # vice beetle -> spittle bone
  114 => {init_code: 0x022D7900, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # poison worm -> sand worm
  121 => {init_code: 0x02297320, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # double axe armor -> axe armor
  122 => {init_code: 0x022D7930, gfx_sheet_ptr_index: 1, palette_list_ptr_index: 1, sprite_ptr_index: 1}, # demon
  126 => {palette_offset: 1}, # golden skeleton and skeleton
}
BEST_SPRITE_FRAME_FOR_ENEMY = {
    0 =>  26, # zombie
   11 =>   7, # une
   14 =>  16, # forneus
   17 =>  26, # wight
   20 =>   8, # invisible man
   23 =>   2, # mimic
   26 =>  51, # spittle bone
   27 =>   6, # ghost
   30 =>  15, # ectoplasm
   32 =>   6, # fleaman
   33 =>  20, # great armor
   34 =>  36, # catoblepas
   37 =>  95, # dragon zombie
   38 =>   3, # killer clown
   40 =>   4, # hanged bones
   41 =>  17, # flying skull
   45 =>  39, # elgiza
   48 =>   1, # crossbow armor
   49 =>  18, # lilith
   50 =>   1, # skeleton flail
   55 =>  17, # corpseweed
   56 =>   2, # medusa head
   61 =>  10, # blue crow
   62 =>  15, # frog
   63 =>  27, # killer doll
   64 =>   2, # killer bee
   65 =>   3, # dogether
   66 =>  31, # bee hive
   67 =>  27, # moldy corpse
   69 =>  15, # treant
   76 =>  17, # spin devil
   77 =>  18, # succubus
   82 =>  20, # final guard
   83 =>  27, # glasya labolas
   84 =>  26, # ghoul
   86 =>   5, # witch
   87 =>   4, # skeleton tree
   88 =>   1, # buster armor
   92 =>  36, # gorgon
   94 =>  11, # tanjelly
   95 =>   5, # dead warrior
   99 =>  68, # vice beetle
  100 =>  10, # alura une
  103 =>  14, # mandragora
  104 =>  27, # wakwak tree
  105 =>  37, # guillotiner
  106 =>   1, # nyx
  113 =>  11, # ripper
  116 =>  45, # demon head
  118 =>  26, # ghoul king
  119 =>  22, # vapula
  120 =>  15, # iron golem
  123 =>  42, # bone ark
  124 =>  13, # skeleton farmer
  125 =>   1, # alastor
  128 =>  24, # amducias
  129 =>   5, # balore
  130 =>  16, # gergoth
  138 =>  94, # dullahan
  139 =>  53, # behemoth
  140 =>  91, # keremet
  141 =>  27, # astarte
  144 =>  25, # death
  150 =>  54, # medusa
}

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
  "Area Names (Unused)" => (0x4BE..0x4C9),
  "Music Names (Unused)" => (0x4CA..0x4E6),
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
  "Area Names (Unused)" => 1,
  "Music Names (Unused)" => 1,
  "Misc" => 1,
  "Menus" => 1,
  "Events" => 2,
  "Debug" => 1
}
STRING_DATABASE_START_OFFSET = 0x0221F680
STRING_DATABASE_END_OFFSET = 0x0222C835
STRING_DATABASE_ALLOWABLE_END_OFFSET = STRING_DATABASE_END_OFFSET

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
ITEM_GLOBAL_ID_RANGE = (1..0x1BB) # regular items end at 150. skills end at 1AB. 1BB is including relics.
SKILL_GLOBAL_ID_RANGE = (1..0x6B)

ITEM_BYTE_7_RANGE_FOR_DEFENSIVE_EQUIPMENT = (0x04..0x07)

ITEM_BYTE_7_VALUE_FOR_SKILLS_AND_PASSIVES = 0x08

# Note: the below are not actually where the original game stores the indexes. All three of those are at 02051F88 (since all three are the same: 00). The three addresses below are free space reused for the purpose of allowing the three values to be different.
NEW_GAME_STARTING_AREA_INDEX_OFFSET = 0x020BFC00
NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x020BFC08
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x020BFC0C

TRANSITION_ROOM_LIST_POINTER = nil
FAKE_TRANSITION_ROOMS = [0x020E7F18] # This room is marked as a transition room, but it's not actually.

armor_format = [
  [2, "Item ID"],
  [1, "Icon"],
  [1, "Palette"],
  [4, "Price"],
  [1, "Type"],
  [1, "Unknown 1"],
  [1, "Equippable by"],
  [1, "Attack"],
  [1, "Defense"],
  [1, "Strength"],
  [1, "Constitution"],
  [1, "Intelligence"],
  [1, "Mind"],
  [1, "Luck"],
  [1, "Unknown 2"],
  [1, "Unknown 3"],
  [2, "Resistances", :bitfield],
  [1, "Unknown 4"],
  [1, "Unknown 5"],
]
ITEM_TYPES = [
  {
    name: "Consumables",
    list_pointer: 0x020E2724,
    count: 96,
    format: [
      [2, "Item ID"],
      [1, "Icon"],
      [1, "Palette"],
      [4, "Price"],
      [1, "Type"],
      [1, "Unknown 1"],
      [2, "Var A"],
    ]
  },
  {
    name: "Weapons",
    list_pointer: 0x020E3114,
    count: 73,
    format: [
      [2, "Item ID"],
      [2, "Icon"],
      [4, "Price"],
      [1, "Swing Anim"],
      [1, "Graphical Effect"],
      [1, "Unknown 1"],
      [1, "Attack"],
      [1, "Defense"],
      [1, "Strength"],
      [1, "Constitution"],
      [1, "Intelligence"],
      [1, "Mind"],
      [1, "Luck"],
      [1, "Unknown 2"],
      [1, "Unknown 3"],
      [2, "Effects", :bitfield],
      [2, "Unknown 4"],
      [1, "Sprite"],
      [1, "Palette"],
      [2, "Unknown 5"],
      [2, "Swing Modifiers", :bitfield],
      [2, "Swing Sound"],
    ]
  },
  {
    name: "Body Armor",
    list_pointer: 0x020E2BA4,
    count: 58,
    format: armor_format
  },
  {
    name: "Head Armor",
    list_pointer: 0x020E1FA4,
    count: 38,
    format: armor_format
  },
  {
    name: "Leg Armor",
    list_pointer: 0x020E1CEC,
    count: 29,
    format: armor_format
  },
  {
    name: "Accessories",
    list_pointer: 0x020E2334,
    count: 42,
    format: armor_format
  },
]

ITEM_BITFIELD_ATTRIBUTES = {
  "Resistances" => [
    "Strike",
    "Whip",
    "Slash",
    "Fire",
    "Ice",
    "Electric",
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
  ],
  "Effects" => [
    "Strike",
    "Whip",
    "Slash",
    "Fire",
    "Ice",
    "Electric",
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
    "Modifier 14",
    "Modifier 15",
    "Modifier 16",
  ],
}
