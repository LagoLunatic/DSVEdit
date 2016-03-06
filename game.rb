
class Game
  class InvalidGameError < StandardError ; end
  
  attr_reader :areas, :fs, :folder
  
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
      area = Area.new(area_index, fs)
      @areas << area
    end
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
  
private
  
  def verify_game_and_load_constants(header_path)
    case File.read(header_path, 12)
    when "CASTLEVANIA1"
      require_relative './constants/dos_constants.rb'
    when "CASTLEVANIA2"
      require_relative './constants/por_constants.rb'
    when "CASTLEVANIA3"
      require_relative './constants/ooe_constants.rb'
    else
      raise InvalidGameError.new("Specified game is not a DSVania.")
    end
  end
end
