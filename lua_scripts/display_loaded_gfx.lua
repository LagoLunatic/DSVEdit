
-- currently supports: US DoS, US PoR

identifier = memory.readword(0x0200000E)
if identifier == 0xFDE3 then -- US DoS
  ASSET_LIST_START = 0x0208CC6C
  ASSET_LIST_END = 0x0209A0C3
  ASSET_LIST_ENTRY_SIZE = 0x28
  
  LOADED_GFX_ASSETS_LIST_START = 0x020C7460
  LOADED_GFX_ASSETS_LIST_END = 0x020C76DF
  
  LOADED_GFX_ASSET_OFFSET_TO_INDEX_OF_PARENT = 0x04
  LOADED_GFX_ASSET_OFFSET_TO_GFX_LOAD_TYPE = 0x0A
  LOADED_GFX_ASSET_OFFSET_TO_UNK_NUM = 0x0D
  LOADED_GFX_ASSET_OFFSET_TO_DATA_PTR = 0x10
elseif identifier == 0x94BA then -- US PoR
  ASSET_LIST_START = 0x020CDAFC
  ASSET_LIST_END = 0x020DF15B
  ASSET_LIST_ENTRY_SIZE = 0x20
  
  LOADED_GFX_ASSETS_LIST_START = 0x020FB204
  LOADED_GFX_ASSETS_LIST_END = 0x020FB483
  
  LOADED_GFX_ASSET_OFFSET_TO_INDEX_OF_PARENT = 0x00
  LOADED_GFX_ASSET_OFFSET_TO_GFX_LOAD_TYPE = 0x06 -- unsure
  LOADED_GFX_ASSET_OFFSET_TO_UNK_NUM = 0x09
  LOADED_GFX_ASSET_OFFSET_TO_DATA_PTR = 0x0C
else
  -- C73B for US OoE
  -- 62F2 for JP DoS
  -- 446B for JP PoR
  -- EC90 for JP OoE
  print("Error: Unsupported game")
  return
end

asset_ptr_to_asset_filename = {}
entry_ptr = ASSET_LIST_START
i = 0
while entry_ptr < ASSET_LIST_END do
  asset_index = i
  asset_ptr = memory.readdwordsigned(entry_ptr+0x00)
  asset_filename = ""
  chars = {}
  for i, byte in ipairs(memory.readbyterange(entry_ptr+0x06, 0x1A)) do
    if byte == 0 then
      break
    end
    asset_filename = asset_filename .. string.char(byte)
  end
  if asset_ptr ~= 0 then
    asset_ptr_to_asset_filename[asset_ptr] = asset_filename
  end
  
  entry_ptr = entry_ptr + ASSET_LIST_ENTRY_SIZE
  i = i + 1
end

local function display_hitboxes()
  entry_ptr = LOADED_GFX_ASSETS_LIST_START
  i = 0
  gfx_lists_by_index = {}
  while entry_ptr < LOADED_GFX_ASSETS_LIST_END do
    index_of_parent_entry = memory.readdwordsigned(entry_ptr+LOADED_GFX_ASSET_OFFSET_TO_INDEX_OF_PARENT)
    gfx_load_type = memory.readbytesigned(entry_ptr+LOADED_GFX_ASSET_OFFSET_TO_GFX_LOAD_TYPE)
    unk_num = memory.readbytesigned(entry_ptr+LOADED_GFX_ASSET_OFFSET_TO_UNK_NUM)
    data_ptr = memory.readdwordsigned(entry_ptr+LOADED_GFX_ASSET_OFFSET_TO_DATA_PTR)
    
    if index_of_parent_entry == -1 then
      display_str = "(empty)"
    elseif index_of_parent_entry ~= i then
      num_entries_up_to_parent = (i - index_of_parent_entry)
      if gfx_lists_by_index[index_of_parent_entry] == nil then
        -- todo ?????
        display_str = string.format("(^%d)", num_entries_up_to_parent)
      else
        gfx_asset_ptr = gfx_lists_by_index[index_of_parent_entry][num_entries_up_to_parent]
        display_str = "^ " .. asset_ptr_to_asset_filename[gfx_asset_ptr]
      end
    elseif gfx_load_type == 0 then -- Single GFX
      display_str = asset_ptr_to_asset_filename[data_ptr]
    elseif gfx_load_type == 1 then -- Multi GFX list loaded simultaneously
      num_gfx_pages_in_list = memory.readbytesigned(data_ptr+0x02)
      gfx_list_ptr = memory.readdwordsigned(data_ptr+0x04)
      list_entry_index = 0
      gfx_lists_by_index[i] = {}
      while list_entry_index < num_gfx_pages_in_list do
        gfx_asset_ptr = memory.readdwordsigned(gfx_list_ptr + list_entry_index*4)
        gfx_lists_by_index[i][list_entry_index] = gfx_asset_ptr
        list_entry_index = list_entry_index + 1
      end
      
      --display_str = string.format("List: %08X", data_ptr)
      first_gfx_asset_ptr = gfx_lists_by_index[i][0]
      display_str = string.format("V " .. asset_ptr_to_asset_filename[first_gfx_asset_ptr])
    else
      -- todo handle player gfx that swap out somehow
      display_str = string.format("Unknown: %08X", data_ptr)
    end
    display_str = display_str .. " " .. unk_num -- string.format(" %d", unk_num)
    
    x = math.floor(i / 16) * 126
    y = 1 + (i%16)*10
    gui.text(x, y, display_str)
    
    entry_ptr = entry_ptr + 0x14
    i = i + 1
  end
end

gui.register(display_hitboxes)
