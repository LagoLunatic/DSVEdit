
class Game
  class InvalidGameError < StandardError ; end
  
  attr_reader :areas, :fs, :folder
  
  def initialize_from_folder(input_folder_path)
    header_path = File.join(input_folder_path, "ftc", "ndsheader.bin")
    unless File.exist?(header_path) && File.file?(header_path)
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
  
  def initialize_from_rom(input_rom_path)
    verify_game_and_load_constants(input_rom_path)
    
    @folder = File.dirname(input_rom_path)
    rom_name = File.basename(input_rom_path, ".*")
    @folder = File.join(folder, "Extracted files #{rom_name}")
    
    @fs = NDSFileSystem.new
    fs.open_and_extract_rom(input_rom_path, folder)
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
  
  def fix_top_screen_on_new_game
    return unless GAME == "ooe"
    
    fs.load_overlay(20)
    fs.write(NEW_GAME_STARTING_TOP_SCREEN_TYPE_OFFSET, [0x05].pack("C"))
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
