
-- Renders all currently active hitboxes, with the color depending on the type of hitbox.

game_id = memory.readdword(0x023FFE0C)
if game_id == 0x45564341 then -- ACVE, US DoS
  entity_list_start = 0x020CA3F0
  entity_list_end = 0x020F6DEF
  entity_size = 0x2A0
  
  hitbox_list_start = 0x0210AF18

  screen_x_ptr = 0x020F7070
  screen_y_ptr = 0x020F7074
elseif game_id == 0x45424341 then -- ACBE, US PoR
  entity_list_start = 0x020FC500
  entity_list_end = 0x0211173F
  entity_size = 0x160
  
  hitbox_list_start = 0x0213291C

  screen_x_ptr = 0x021119FC
  screen_y_ptr = 0x02111A00
elseif game_id == 0x45395259 then -- YR9E, US OoE
  entity_list_start = 0x021092A0
  entity_list_end = 0x0211DF5F
  entity_size = 0x160
  
  hitbox_list_start = 0x02128BDC

  screen_x_ptr = 0x021000BC
  screen_y_ptr = 0x021000C0
else
  print("Error: Unsupported game")
  return
end

local function display_weapon_hitboxes()
  entity_ptr = entity_list_start
  
  screen_x = memory.readdwordsigned(screen_x_ptr)/0x1000
  screen_y = memory.readdwordsigned(screen_y_ptr)/0x1000
  
  while entity_ptr < entity_list_end do
    entity_code_pointer = memory.readdword(entity_ptr)
    entity_hitbox_is_active = memory.readbyte(entity_ptr+0xA6)
    if entity_code_pointer ~= 0 and entity_hitbox_is_active ~= 0 then
      hitbox_index = memory.readbyte(entity_ptr+0xA7)
      
      for i=0,1 do
        hitbox_ptr = hitbox_list_start + hitbox_index*0x14 + i*0xA
        htype  = memory.readword(hitbox_ptr)
        left   = memory.readwordsigned(hitbox_ptr + 2)
        top    = memory.readwordsigned(hitbox_ptr + 4)
        right  = memory.readwordsigned(hitbox_ptr + 6)
        bottom = memory.readwordsigned(hitbox_ptr + 8)
        
        if htype == 0 then -- Deleted hitbox.
          -- We won't render these.
          fillcolor = 0xFFFFFF3F
          linecolor = 0xFFFFFFFF
        elseif htype == 1 then -- Can deal damage but not take it.
          -- Blue.
          fillcolor = 0x0000FF3F
          linecolor = 0x0000FFFF
        elseif htype == 2 then -- Can take damage from player.
          -- Yellow.
          fillcolor = 0xFFFF003F
          linecolor = 0xFFFF00FF
        elseif htype == 3 then -- Can take damage from player, can deal damage to player.
          -- Red.
          --print(string.format("%08X", entity_ptr))
          fillcolor = 0xFF00003F
          linecolor = 0xFF0000FF
        elseif htype == 4 then -- Can't deal or take damage.
          -- Purple.
          fillcolor = 0xFF00FF3F
          linecolor = 0xFF00FFFF
        elseif htype == 6 then -- Can take damage from enemies.
          -- Green.
          fillcolor = 0x00FF003F
          linecolor = 0x00FF00FF
        else
          print("Unknown hitbox type " .. htype .. " at " .. string.format("%08X", hitbox_ptr))
          fillcolor = 0x0000003F
          linecolor = 0x000000FF
        end
        
        left = left-screen_x
        top = top-screen_y
        right = right-screen_x
        bottom = bottom-screen_y
        
        -- Negative y pos is interpreted as on the top screen by Desmume.
        top = math.max(top, 0)
        
        if htype ~= 0 and bottom >= 0 then
          gui.drawbox(left, top, right, bottom, fillcolor, linecolor)
        end
      end
    end
    
    entity_ptr = entity_ptr + entity_size
  end
end

gui.register(display_weapon_hitboxes)
