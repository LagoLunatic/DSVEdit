
class Game
  class InvalidGameError < StandardError ; end
  
  attr_reader :areas, :fs
  
  def initialize(input_rom_path)
    case File.read(input_rom_path, 12)
    when "CASTLEVANIA1"
      require_relative './constants/dos_constants.rb'
    when "CASTLEVANIA2"
      require_relative './constants/por_constants.rb'
    when "CASTLEVANIA3"
      require_relative './constants/ooe_constants.rb'
    else
      raise InvalidGameError.new("Specified game is not a DSVania.")
    end
    
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
end
