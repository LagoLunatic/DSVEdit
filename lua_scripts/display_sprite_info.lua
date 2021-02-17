
identifier = memory.readword(0x0200000E)
if identifier == 0xFDE3 then -- US DoS
  entity_list_start = 0x020CA3F0
  entity_list_end = 0x020F6DEF
  entity_size = 0x2A0
  entity_screen_position_field_offset = 0x20
  entity_position_field_offset = 0x2C
  entity_sprite_info_field_offset = 0x68
  entity_anim_index_field_offset = 0x9C
  entity_frame_index_field_offset = 0x74
  
  ASSET_LIST_START = 0x0208CC6C
  ASSET_LIST_END = 0x0209A0C3
  
  sprite_info_list_start = 0x020C6260

  screen_x_ptr = 0x020F7070
  screen_y_ptr = 0x020F7074
  
  game_state_location = 0x020C07E8
elseif identifier == 0x94BA then -- US PoR
  entity_list_start = 0x020FC500
  entity_list_end = 0x0211173F
  entity_size = 0x160
  entity_screen_position_field_offset = 0x24
  entity_position_field_offset = 0x30
  entity_sprite_info_field_offset = 0x6C
  entity_anim_index_field_offset = 0x7C
  entity_frame_index_field_offset = 0x84
  
  ASSET_LIST_START = 0x020CDAFC
  ASSET_LIST_END = 0x020DF15B
  
  sprite_info_list_start = 0x020FA200

  screen_x_ptr = 0x021119FC
  screen_y_ptr = 0x02111A00
  
  game_state_location = 0x020F6284
elseif identifier == 0xC73B then -- US OoE
  entity_list_start = 0x021092A0
  entity_list_end = 0x0211DF5F
  entity_size = 0x160
  entity_screen_position_field_offset = 0x24
  entity_position_field_offset = 0x30
  entity_sprite_info_field_offset = 0x6C
  entity_anim_index_field_offset = 0x7C
  entity_frame_index_field_offset = 0x84
  
  ASSET_LIST_START = 0x020D8CEC
  ASSET_LIST_END = 0x020ECA0B
  
  sprite_info_list_start = 0x0211E0C0

  screen_x_ptr = 0x021000BC
  screen_y_ptr = 0x021000C0
  
  game_state_location = 0x0211D723 -- hack, that's not really the game state location. might be at 0x021516D0 but that doesn't work perfectly
else
  -- 62F2 for JP DoS
  -- 446B for JP PoR
  -- EC90 for JP OoE
  print("Error: Unsupported game")
  return
end

asset_ptr_to_asset_filename = {}
entry_ptr = ASSET_LIST_START
sprite_asset_ptrs = {}
i = 0
while entry_ptr < ASSET_LIST_END do
  asset_index = i
  asset_ptr = memory.readdwordsigned(entry_ptr+0x00)
  asset_type = memory.readwordsigned(entry_ptr+0x04)
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
  
  if asset_type == 4 then
    table.insert(sprite_asset_ptrs, asset_ptr)
  end
  
  entry_ptr = entry_ptr + 0x28
  i = i + 1
end

local function display_sprite_info()
  if memory.readbyte(game_state_location) ~= 2 then
    -- Not ingame
    return
  end
  
  entity_ptr = entity_list_start
  entity_index = 0
  
  screen_x = memory.readdwordsigned(screen_x_ptr)/0x1000
  screen_y = memory.readdwordsigned(screen_y_ptr)/0x1000
  
  while entity_ptr < entity_list_end do
    entity_code_pointer = memory.readdword(entity_ptr)
    if entity_code_pointer ~= 0 then
      x_pos = memory.readdword(entity_ptr+entity_screen_position_field_offset+0)/0x1000
      y_pos = memory.readdword(entity_ptr+entity_screen_position_field_offset+4)/0x1000
      z_pos = memory.readdword(entity_ptr+entity_screen_position_field_offset+8)/0x1000
      entity_sprite_info_index = memory.readword(entity_ptr+entity_sprite_info_field_offset)
      entity_anim_index = memory.readword(entity_ptr+entity_anim_index_field_offset)
      entity_frame_index = memory.readword(entity_ptr+entity_frame_index_field_offset)
      
      sprite_info_ptr = sprite_info_list_start + entity_sprite_info_index*0x10
      gfx_index = memory.readdword(sprite_info_ptr+0x8)
      sprite_data_ptr = memory.readdword(sprite_info_ptr+0xC)
      
      sprite_asset_ptr = nil
      for i, possible_sprite_asset_ptr in ipairs(sprite_asset_ptrs) do
        possible_sprite_data_ptr = memory.readdword(possible_sprite_asset_ptr)
        if sprite_data_ptr == possible_sprite_data_ptr then
          sprite_asset_ptr = possible_sprite_asset_ptr
          break
        end
      end
      
      if sprite_asset_ptr == nil then
        sprite_name = string.format("%08X", sprite_data_ptr)
      elseif asset_ptr_to_asset_filename[sprite_asset_ptr] ~= nil then
        sprite_name = asset_ptr_to_asset_filename[sprite_asset_ptr]
      else
        sprite_name = string.format("Unknown: %08X", sprite_data_ptr)
      end
      
      gui.text(x_pos, y_pos-20, string.format("%08X", entity_ptr))
      gui.text(x_pos, y_pos-10, sprite_name)
      gui.text(x_pos, y_pos, string.format("%04X", entity_frame_index))
    end
    
    entity_ptr = entity_ptr + entity_size
    entity_index = entity_index + 1
  end
end

gui.register(display_sprite_info)
