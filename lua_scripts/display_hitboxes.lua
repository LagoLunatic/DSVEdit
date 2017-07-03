
-- Renders all currently active hitboxes, with the color depending on the type of hitbox.

identifier = memory.readword(0x0200000E)
if identifier == 0xFDE3 then -- US DoS
  entity_list_start = 0x020CA3F0
  entity_list_end = 0x020F6DEF
  entity_size = 0x2A0
  
  hitbox_list_start = 0x0210AF18

  screen_x_ptr = 0x020F7070
  screen_y_ptr = 0x020F7074
  
  game_state_location = 0x020C07E8
elseif identifier == 0x94BA then -- US PoR
  entity_list_start = 0x020FC500
  entity_list_end = 0x0211173F
  entity_size = 0x160
  
  hitbox_list_start = 0x0213291C

  screen_x_ptr = 0x021119FC
  screen_y_ptr = 0x02111A00
  
  game_state_location = 0x020F6284
elseif identifier == 0xC73B then -- US OoE
  entity_list_start = 0x021092A0
  entity_list_end = 0x0211DF5F
  entity_size = 0x160
  
  hitbox_list_start = 0x02128BDC

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

local function display_hitboxes()
  if memory.readbyte(game_state_location) ~= 2 then
    -- Not ingame
    return
  end
  
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
        
        if htype == 0 then -- Deleted hitbox, or hitbox used for something else, like letting the player stand on an enemy's back.
          -- White.
          fillcolor = "#FFFFFF3F"
          linecolor = "#FFFFFFFF"
        elseif htype == 1 then -- Can deal damage but not take it.
          -- Blue.
          fillcolor = "#0000FF3F"
          linecolor = "#0000FFFF"
        elseif htype == 2 then -- Can take damage from player.
          -- Yellow.
          fillcolor = "#FFFF003F"
          linecolor = "#FFFF00FF"
        elseif htype == 3 then -- Can take damage from player, can deal damage to player.
          -- Red.
          fillcolor = "#FF00003F"
          linecolor = "#FF0000FF"
        elseif htype == 4 then -- Can't deal or take damage.
          -- Purple.
          fillcolor = "#FF00FF3F"
          linecolor = "#FF00FFFF"
        elseif htype == 6 then -- Can take damage from enemies.
          -- Green.
          fillcolor = "#00FF003F"
          linecolor = "#00FF00FF"
        else
          print("Unknown hitbox type " .. htype .. " at " .. string.format("%08X", hitbox_ptr))
          fillcolor = "#0000003F"
          linecolor = "#000000FF"
        end
        
        left = left-screen_x
        top = top-screen_y
        right = right-screen_x
        bottom = bottom-screen_y
        
        -- Negative y pos is interpreted as on the top screen by Desmume.
        top = math.max(top, 0)
        
        if bottom >= 0 then
          gui.drawbox(left, top, right, bottom, fillcolor, linecolor)
        end
      end
    end
    
    entity_ptr = entity_ptr + entity_size
  end
end

gui.register(display_hitboxes)
