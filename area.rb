
class Area
  class AreaReadError < StandardError ; end
  
  attr_reader :area_index,
              :fs,
              :area_ram_pointer,
              :sectors,
              :map,
              :abyss_map

  def initialize(area_index, fs)
    @area_index = area_index
    @fs = fs
    read_from_rom()
  end
  
  def read_from_rom
    @area_ram_pointer = fs.read(AREA_LIST_RAM_START_OFFSET + area_index*4,4).unpack("V*").first
    #@area_pointer = converter.ram_to_rom(@area_ram_pointer)
    
    @sectors = []
    sector_index = 0
    while true
      sector_ram_pointer = fs.read(area_ram_pointer + sector_index*4, 4).unpack("V*").first
      break if sector_ram_pointer == 0
      
      #sector_pointer = converter.ram_to_rom(sector_ram_pointer)
      #puts "sector_ram_pointer: %08X" % sector_ram_pointer
      sector = Sector.new(self, sector_index, sector_ram_pointer, fs)
      @sectors << sector
      
      sector_index += 1
    end
    
    if GAME == "dos"
      @map = DoSMap.new(MAP_TILE_METADATA_START_OFFSET, MAP_TILE_LINE_DATA_START_OFFSET, 3008, fs)
      @abyss_map = DoSMap.new(ABYSS_MAP_TILE_METADATA_START_OFFSET, ABYSS_MAP_TILE_LINE_DATA_START_OFFSET, 448, fs, is_abyss = true)
    else
      map_tile_metadata_ram_pointer = fs.read(MAP_TILE_METADATA_LIST_START_OFFSET + area_index*4, 4).unpack("V*").first
      map_tile_line_data_ram_pointer = fs.read(MAP_TILE_LINE_DATA_LIST_START_OFFSET + area_index*4, 4).unpack("V*").first
      number_of_map_tiles = fs.read(MAP_LENGTH_DATA_START_OFFSET + area_index*2, 2).unpack("v*").first
      
      @map = Map.new(map_tile_metadata_ram_pointer, map_tile_line_data_ram_pointer, number_of_map_tiles, fs)
    end
  end
end
