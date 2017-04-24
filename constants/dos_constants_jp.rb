
REGION = :jp

MAP_TILE_METADATA_START_OFFSET = 0x02077088
MAP_TILE_LINE_DATA_START_OFFSET = 0x02076AA8
MAP_SECRET_DOOR_DATA_START_OFFSET = 0x02076404
ABYSS_MAP_TILE_METADATA_START_OFFSET = 0x020788F0
ABYSS_MAP_TILE_LINE_DATA_START_OFFSET = 0x0207880C
ABYSS_MAP_SECRET_DOOR_DATA_START_OFFSET = 0x02078808

SECTOR_MUSIC_LIST_START_OFFSET = 0x0209A544

LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET = 0x0208CC6C
LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET = 0x02099FD3

ENEMY_DNA_RAM_START_OFFSET = 0x02078CA8

REUSED_ENEMY_INFO[0x1A] = {init_code: 0x0223170C, gfx_sheet_ptr_index: 0, palette_offset: 2, palette_list_ptr_index: 0} # ghoul and zombie
REUSED_ENEMY_INFO[0x54] = {init_code: 0x0226F79C, gfx_sheet_ptr_index: 0, palette_offset: 1, palette_list_ptr_index: 0, sprite_ptr_index: 1} # erinys and valkyrie
REUSED_ENEMY_INFO[0x5C] = {init_code: 0x02288054, gfx_sheet_ptr_index: 0, palette_offset: 0, palette_list_ptr_index: 0} # tanjelly and slime
REUSED_ENEMY_INFO[0x5B] = {init_code: 0x022FEA30, gfx_sheet_ptr_index: 1, palette_offset: 0, palette_list_ptr_index: 1, sprite_ptr_index: 1} # flame demon and devil

SPECIAL_OBJECT_CREATE_CODE_LIST = 0x0222B7B4
SPECIAL_OBJECT_UPDATE_CODE_LIST = 0x0222B990
REUSED_SPECIAL_OBJECT_INFO[0x00] = {sprite: 0x0229DB78, gfx_wrapper: 0x02079EA8, palette: 0x022B8BA4} # ice block
REUSED_SPECIAL_OBJECT_INFO[0x01] = {init_code: 0x0222AB58, ignore_files_to_load: true} # destructible
REUSED_SPECIAL_OBJECT_INFO[0x06] = {sprite: 0x02299A9C, gfx_files: [0x022C9534, 0x022C9540, 0x022C954C, 0x022C9558, 0x022C9564, 0x022C9570], palette: 0x022C04BC} # area titles
REUSED_SPECIAL_OBJECT_INFO[0x09] = {init_code: 0x0222ADA4} # chair
REUSED_SPECIAL_OBJECT_INFO[0x1D] = {sprite: 0x0229DB78, gfx_wrapper: 0x02079EA8, palette: 0x022B8BA4} # wooden door
REUSED_SPECIAL_OBJECT_INFO[0x25] = {sprite: 0x0229DB78, gfx_wrapper: 0x02079EA8, palette: 0x022B8BA4} # boss door
REUSED_SPECIAL_OBJECT_INFO[0x26] = {init_code: 0x021A9048} # slot machine
REUSED_SPECIAL_OBJECT_INFO[0x27] = {init_code: 0x021A84B4} # condemned tower gate
REUSED_SPECIAL_OBJECT_INFO[0x29] = {init_code: 0x021A8044} # dark chapel gate
REUSED_SPECIAL_OBJECT_INFO[0x2A] = {init_code: 0x021A7BC4} # flood gate
REUSED_SPECIAL_OBJECT_INFO[0x2E] = {init_code: 0x02303BD8} # iron maiden
REUSED_SPECIAL_OBJECT_INFO[0x47] = {init_code: 0x0222BCC0} # hammer shopkeeper
REUSED_SPECIAL_OBJECT_INFO[0x48] = {init_code: 0x0222BCB0} # yoko shopkeeper
REUSED_SPECIAL_OBJECT_INFO[0x4F] = {init_code: 0x0222BC90} # mina event actor
REUSED_SPECIAL_OBJECT_INFO[0x50] = {init_code: 0x0222BCC0} # hammer event actor
REUSED_SPECIAL_OBJECT_INFO[0x51] = {init_code: 0x0222BCA0} # arikado event actor
REUSED_SPECIAL_OBJECT_INFO[0x52] = {init_code: 0x0222BCD0} # julius event actor
REUSED_SPECIAL_OBJECT_INFO[0x53] = {init_code: 0x0222BCE0} # celia event actor
REUSED_SPECIAL_OBJECT_INFO[0x54] = {init_code: 0x0222BCF0} # dario event actor
REUSED_SPECIAL_OBJECT_INFO[0x55] = {init_code: 0x0222BD00} # dmitrii event actor
REUSED_SPECIAL_OBJECT_INFO[0x5B] = {init_code: 0x0222BD10} # alucard event actor
SPECIAL_OBJECT_FILES_TO_LOAD_LIST = 0x0209B79C

WEAPON_GFX_LIST_START = 0x0222DED4
SKILL_GFX_LIST_START = 0x0222DA84

OTHER_SPRITES = [
  {desc: "Common", sprite: 0x0229DB78, gfx_wrapper: 0x02079EA8, palette: 0x022B8BA4},
  
  {pointer: 0x0222D524, desc: "Soma player"},
  {pointer: 0x0222D57C, desc: "Julius player"},
  {pointer: 0x0222D5D4, desc: "Yoko player"},
  {pointer: 0x0222D62C, desc: "Alucard player"},
  
  {pointer: 0x0222AB4C, desc: "Destructibles 0"},
  {pointer: 0x0222AB58, desc: "Destructibles 1"},
  {pointer: 0x0222AB64, desc: "Destructibles 2"},
  {pointer: 0x0222AB70, desc: "Destructibles 3"},
  {pointer: 0x0222AB7C, desc: "Destructibles 4"},
  {pointer: 0x0222AB88, desc: "Destructibles 5"},
  {pointer: 0x0222AB94, desc: "Destructibles 6"},
  {pointer: 0x0222ABA0, desc: "Destructibles 7"},
  {pointer: 0x0222ABAC, desc: "Destructibles 8"},
  {pointer: 0x0222ADA4, desc: "Chair 1"},
  {pointer: 0x0222ADB0, desc: "Chair 2"},
  {pointer: 0x0222ADBC, desc: "Chair 3"},
  {pointer: 0x0222ADC8, desc: "Chair 4"},
  
#  {pointer: 0x0203D4A0, desc: "Nintendo splash screen"}, # Does not exist in the Japanese version
  {pointer: 0x0203D584, desc: "Konami splash screen"},
  {pointer: 0x0203D8C8, desc: "Main menu"},
  {pointer: 0x0203DAD0, desc: "Castlevania logo"},
  {pointer: 0x0203ED54, desc: "Credits"},
  {pointer: 0x0203ED78, desc: "Characters used during credits"},
  {pointer: 0x0203ED80, desc: "BGs used during credits"},
  {pointer: 0x0203F430, desc: "Game over screen"},
  {pointer: 0x02046734, desc: "Name signing screen"},
  {pointer: 0x02046AEC, desc: "File select menu"},
  {pointer: 0x020489C4, desc: "Choose course - unused?"},
  {pointer: 0x02049098, desc: "Enemy set mode menu"},
  {pointer: 0x020490AC, desc: "Enemy set retry/complete"},
  {pointer: 0x020490C0, desc: "Wi-fi menu"},
]

CANDLE_SPRITE = OTHER_SPRITES[0]
MONEY_SPRITE = OTHER_SPRITES[0]

TEXT_LIST_START_OFFSET = 0x0222E3B0
STRING_DATABASE_START_OFFSET = 0x0221803C
STRING_DATABASE_ORIGINAL_END_OFFSET = 0x0222A962
STRING_DATABASE_ALLOWABLE_END_OFFSET = STRING_DATABASE_ORIGINAL_END_OFFSET

NAMES_FOR_UNNAMED_SKILLS = {}

NEW_GAME_STARTING_SECTOR_INDEX_OFFSET = 0x0202FC20
NEW_GAME_STARTING_ROOM_INDEX_OFFSET = 0x0202FC2C

ITEM_ICONS_PALETTE_POINTER = 0x022C3724

ITEM_TYPES = [
  {
    name: "Consumables",
    list_pointer: 0x0209B978,
    count: 66,
    format: CONSUMABLE_FORMAT # length: 16
  },
  {
    name: "Weapons",
    list_pointer: 0x0209C25C,
    count: 79,
    format: WEAPON_FORMAT # length: 28
  },
  {
    name: "Armor",
    list_pointer: 0x0209BD98,
    count: 61,
    format: ARMOR_FORMAT # length: 20
  },
  {
    name: "Souls",
    list_pointer: 0x0209D0A0,
    count: 123,
    kind: :skill,
    format: SOUL_FORMAT # length: 28
  },
  {
    name: "Souls (extra data)",
    list_pointer: 0x0209D034,
    count: 53,
    kind: :skill,
    format: SOUL_EXTRA_DATA_FORMAT # length: 2
  },
]

PLAYER_LIST_POINTER = 0x0222D524

TEST_ROOM_SAVE_FILE_INDEX_LOCATION = 0x0203E534 + 0x0C
TEST_ROOM_AREA_INDEX_LOCATION      = nil
TEST_ROOM_SECTOR_INDEX_LOCATION    = 0x0203E534 + 0x2C
TEST_ROOM_ROOM_INDEX_LOCATION      = 0x0203E534 + 0x34
TEST_ROOM_X_POS_LOCATION           = 0x0203E534 + 0x60
TEST_ROOM_Y_POS_LOCATION           = 0x0203E534 + 0x64
TEST_ROOM_OVERLAY = nil
