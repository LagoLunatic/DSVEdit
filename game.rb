
class Game
  class InvalidGameError < StandardError ; end
  
  attr_reader :areas, :fs
  
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
    
    folder = File.dirname(input_rom_path)
    folder = File.join(folder, "extracted_files_#{GAME}")
    
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
  
  def open_world_map
    raise "Wrong game" unless GAME == "ooe"
    
    # Make all areas on the world map accessible.
    fs.write(0x020AA8E4, [0xE3A00001].pack("V"))
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
