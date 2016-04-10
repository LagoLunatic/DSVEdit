
class Game
  class InvalidGameError < StandardError ; end
  
  attr_reader :areas, :fs, :folder, :text_database, :rooms_by_metadata_pointer
  
  def initialize_from_folder(input_folder_path)
    header_path = File.join(input_folder_path, "ftc", "ndsheader.bin")
    unless File.file?(header_path)
      raise "Header file not present"
    end
    
    verify_game_and_load_constants(header_path)
    
    @fs = NDSFileSystem.new
    fs.open_directory(input_folder_path)
    CONSTANT_OVERLAYS.each do |overlay_index|
      fs.load_overlay(overlay_index)
    end
    
    read_from_rom()
  end
  
  def initialize_from_rom(input_rom_path, extract_to_hard_drive)
    unless File.file?(input_rom_path)
      raise "ROM file not present"
    end
    
    verify_game_and_load_constants(input_rom_path)
    
    if extract_to_hard_drive
      @folder = File.dirname(input_rom_path)
      rom_name = File.basename(input_rom_path, ".*")
      @folder = File.join(folder, "Extracted files #{rom_name}")
      
      @fs = NDSFileSystem.new
      fs.open_and_extract_rom(input_rom_path, folder)
    else
      @fs = NDSFileSystem.new
      fs.open_rom(input_rom_path)
    end
    
    CONSTANT_OVERLAYS.each do |overlay_index|
      fs.load_overlay(overlay_index)
    end
    
    read_from_rom()
  end
  
  def read_from_rom
    @areas = []
    AREA_INDEX_TO_OVERLAY_INDEX.each do |area_index, list_of_sub_areas|
      area = Area.new(area_index, self)
      @areas << area
    end
    
    @sectors_by_room_metadata_pointer = {}
    areas.each do |area|
      area.sectors.each do |sector|
        sector.room_pointers.each do |room_pointer|
          @sectors_by_room_metadata_pointer[room_pointer] = sector
        end
      end
    end
    
    @text_database = TextDatabase.new(fs)
  end
  
  def each_room
    areas.each do |area|
      area.sectors.each do |sector|
        sector.load_necessary_overlay()
        sector.rooms.each do |room|
          yield room
        end
      end
    end
  end
  
  def get_room_by_metadata_pointer(room_metadata_pointer)
    sector = @sectors_by_room_metadata_pointer[room_metadata_pointer]
    index = sector.room_pointers.index(room_metadata_pointer)
    room = sector.rooms[index]
    room
  end
  
  def enemy_dnas
    @enemy_dnas ||= begin
      enemy_dnas = []
      
      ENEMY_IDS.each do |enemy_id|
        enemy_dna = EnemyDNA.new(enemy_id, fs)
        enemy_dnas << enemy_dna
      end
      
      enemy_dnas
    end
  end
  
  def get_transition_rooms
    transition_rooms = []
    
    if GAME == "dos"
      transition_room_pointers = fs.read_until_end_marker(TRANSITION_ROOM_LIST_POINTER, [0, 0, 0, 0]).unpack("V*")
      
      transition_rooms = transition_room_pointers.map do |pointer|
        get_room_by_metadata_pointer(pointer)
      end
    else
      areas.each do |area|
        area.map.tiles.each do |tile|
          if tile.is_transition
            transition_rooms << area.sectors[tile.sector_index].rooms[tile.room_index]
          end
        end
      end
      
      transition_rooms.uniq!
    end
    
    transition_rooms
  end
  
  def fix_top_screen_on_new_game
    return unless GAME == "ooe"
    
    fs.load_overlay(20)
    fs.write(NEW_GAME_STARTING_TOP_SCREEN_TYPE_OFFSET, [0x05].pack("C"))
  end
  
  def dos_fix_first_ability_soul
    return unless GAME == "dos"
    
    # This fixes a bug in the original game that occurs when you get your first ability soul. It activates more ability souls than you actually possess.
    
    # The bug works like this: The first time you get an ability soul, the same function that equips the first bullet/guardian/enchant souls you get in the tutorial tries to run on the ability soul you get too. But this is a problem, because while your equipped bullet/guardian/enchant souls are stored as an integer representing the ID of the soul you have equipped, the ability souls you have equipped is stored as a bit field.
    # For example, Doppelganger is the 2nd ability soul (counting from 0, not from 1). 2 in binary is 00000010. When it tries to store this in the bitfield representing the ability souls you have activated, it activates the 1st ability soul, Malphas. In other words, if your first ability soul is Doppelganger you gain both Doppelganger and Malphas. (Though Malphas doesn't show up in the list of ability souls you own, so you can't deactivate it.)
    # This bug isn't noticeable in a normal playthrough because the first ability soul you get is always Balore. Balore is the 0th ability soul, and 0 in binary is still 0, so no extra souls get activated.
    
    address = 0x0202E240 # Where the code for automatically equipping the first souls you get is.
    
    code = [
      0xE3540003, # cmp r4,3h     ; Compares the type of soul Soma just got with 3, type 3 being ability souls.
      0x0A00002D, # beq 0202E300h ; If it's equal, we jump past all this code that equips the soul automatically.
      0x908FF104, # The next 5 lines of code are just shifting the original code down by one line since we needed space for the above line of code.
      0xEA000011,
      0xEA000001,
      0xEA000004,
      0xEA000007,
      # After shifting those 5 lines down, one line at the end got overwritten. But that line only seems to be run for ability souls, so we don't want it anyway.
    ]
    fs.write(address, code.pack("V*"))
  end
  
  def dos_boss_doors_skip_seal
    return unless GAME == "dos"
    
    # This makes it so you don't need a Magic Seal to enter a boss door.
    
    address = 0x021A9AE4 # Location of the door code for loading the boolean for whether the player is in Julius mode or not.
    
    code = [
      0xE3A00001, # mov r0, 1 ; Always load 1 (meaning it is Julius mode).
    ]
    fs.write(address, code.pack("V*"))
  end
  
  def ooe_open_world_map
    return unless GAME == "ooe"
    
    # Make all areas on the world map accessible.
    fs.write(0x020AA8E4, [0xE3A00001].pack("V"))
  end
  
  def set_starting_room(area_index, sector_index, room_index)
    por_allow_changing_starting_room()
    
    if NEW_GAME_STARTING_AREA_INDEX_OFFSET
      fs.write(NEW_GAME_STARTING_AREA_INDEX_OFFSET, [area_index].pack("C"))
    end
    fs.write(NEW_GAME_STARTING_SECTOR_INDEX_OFFSET, [sector_index].pack("C"))
    fs.write(NEW_GAME_STARTING_ROOM_INDEX_OFFSET, [room_index].pack("C"))
  end
  
  def por_allow_changing_starting_room
    return unless GAME == "por"
    
    code = [
      0xEA01B71A, # b 020BFC00 ; Jump to some free space, where we will put our own code for loading the area/sector/room indexes.
    ]
    address = 0x02051F90 # Where the original game's code for loading area/sector/room indexes is.
    fs.write(address, code.pack("V*")) 
    
    code = [
      0xE3A05000, # mov r5,0h ; Load the area index into r5.
      0xE5C05515, # strb r5,[r0,515] ; Store the area index to the ram address where r0 will read it later.
      0xE3A05000, # mov r5,0h ; Load the sector index into r5.
      0xE3A04000, # mov r4,0h ; Load the room index into r4.
      0xEAFE48DF, # b 02051F94 ; Return to where we came from.
    ]
    address = 0x020BFC00 # Free space.
    fs.write(address, code.pack("V*"))
  end
  
  def fix_unnamed_skills
    case GAME
    when "dos"
      soul_name_list_start = TEXT_REGIONS["Soul Names"].begin
      NAMES_FOR_UNNAMED_SKILLS.each do |soul_id, fixed_name|
        text_database.text_list[soul_id + soul_name_list_start].decoded_string = fixed_name
      end
      
      text_database.write_to_rom()
    end
  end
  
  def ooe_enter_any_wall
    return unless GAME == "ooe"
    
    # Allow entering any wall with Paries.
    code = [0xE3A00902] # mov r0, 8000h
    address = 0x0207BFC4
    fs.write(address, code.pack("V*"))
    address = 0x0207C908
    fs.write(address, code.pack("V*"))
    
    
    
    # Remove line that teleports Shanoa's y position to the last seen Paries wall when entering a wall.
    code = [0xE1A00000] # nop
    address = 0x0207C09C
    fs.write(address, code.pack("V*"))
    
    # Move Shanoa left (if entering a left wall) or right (if entering a right wall).
    code = [
      0xE5951108, # ldr r1, [r5, 108h]   ; Load variable for whether shanoa is touching left/right wall.
      0xE3110080, # tst r1, 80h          ; Test if Shanoa is touching a right wall.
      0xE5951030, # ldr r1, [r5, 30h]    ; Load shanoa's current x pos
      0x12811A0A, # addne r1, r1, 0A000h ; Increase x pos if Shanoa is touching a right wall.
      0x02411A0A, # subeq r1, r1, 0A000h ; Decrease x pos if she's not.
      0xE5851030, # str r1, [r5, 30h]    ; Store it back.
      0xEAFEF70E, # b 0207C098           ; Go back to where we came from.
    ]
    address = 0x020BE440 # Free space.
    fs.write(address, code.pack("V*"))
    # Replace line that teleports Shanoa's x position to the last seen Paries wall when entering a wall to a jump to our own code above.
    code = [0xEA0108E9] # b 020BE440
    address = 0x0207C094
    fs.write(address, code.pack("V*"))
    
    # Move Shanoa right (if exiting a left wall) or left (if exiting a right wall).
    address = 0x020BE45C
    code = [
      0xE5950104, # ldr r0, [r5, 104h]   ; Load variable for whether Shanoa is exiting a left/right wall.
      0xE3100004, # tst r0, 4h           ; Test if Shanoa is exiting a left wall.
      0xE5950030, # ldr r0, [r5, 30h]    ; Load shanoa's current x pos.
      0x12800A0A, # addeq r0, r0, 0A000h ; Increase x pos if Shanoa is exiting a left wall.
      0x02400A0A, # subne r0, r0, 0A000h ; Decrease x pos if she's not.
      0xE5850030, # str r0, [r5, 30h]    ; Store it back.
      0xEAFEF94E, # b 0207C9B4           ; Go back to where we came from.
    ]
    fs.write(address, code.pack("V*"))
    # Replace line that always teleports Shanoa to the left when exiting a wall with a jump to our own code above.
    code = [0xEA0106A9] # b 020BE45C
    address = 0x0207C9B0
    fs.write(address, code.pack("V*"))
    
    
    
    # Allow Shanoa to go up/down out of floors/ceilings.
    # This is necessary because otherwise walls that are less than 3 blocks tall will cause Shanoa to get permanently stuck with no way to get out.
    code = [0xE1A00000] # nop
    # Up out of floors.
    address = 0x0207C8A4
    fs.write(address, code.pack("V*"))
    address = 0x0207C8C0
    fs.write(address, code.pack("V*"))
    # Down out of ceilings.
    address = 0x0207C8E8
    fs.write(address, code.pack("V*"))
    address = 0x0207C900
    fs.write(address, code.pack("V*"))
    
    # Make Shanoa instantly enter/exit the wall when she touches the edge of it, instead of having to hold left/right for half a second.
    code = [0xE3500001] # cmp r0, 1h
    address = 0x0207C98C
    fs.write(address, code.pack("V*"))
    code = [0xE3500002] # cmp r0, 2h
    address = 0x0207C048
    fs.write(address, code.pack("V*"))
    
    # Make Shanoa instantly exit Paries mode when she goes above/below the wall, instead of needing to press left/right.
    code = [0xE3A00001] # mov r0, 1h
    address = 0x0207C808
    fs.write(address, code.pack("V*"))
    
    # Allow Shanoa to exit up/down out of a floor/ceiling, even if the player is still holding up or down on the d-pad.
    code = [0xE1A00000] # nop
    address = 0x0207C924
    fs.write(address, code.pack("V*"))
  end
  
private
  
  def verify_game_and_load_constants(header_path)
    case File.read(header_path, 12)
    when "CASTLEVANIA1"
      suppress_warnings { load './constants/dos_constants.rb' }
    when "CASTLEVANIA2"
      suppress_warnings { load './constants/por_constants.rb' }
    when "CASTLEVANIA3"
      suppress_warnings { load './constants/ooe_constants.rb' }
    else
      raise InvalidGameError.new("Specified game is not a DSVania.")
    end
  end
  
  def suppress_warnings(&block)
    orig_verbosity = $VERBOSE
    $VERBOSE = nil
    yield
    $VERBOSE = orig_verbosity
  end
end
