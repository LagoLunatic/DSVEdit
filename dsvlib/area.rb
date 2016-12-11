
class Area
  class AreaReadError < StandardError ; end
  
  attr_reader :area_index,
              :fs,
              :game,
              :area_ram_pointer,
              :sectors,
              :map,
              :abyss_map

  def initialize(area_index, game)
    @area_index = area_index
    @fs = game.fs
    @game = game
    read_from_rom()
  end
  
  def read_from_rom
    @area_ram_pointer = fs.read(AREA_LIST_RAM_START_OFFSET + area_index*4,4).unpack("V*").first
    
    @sectors = []
    sector_index = 0
    while true
      sector_ram_pointer = fs.read(area_ram_pointer + sector_index*4, 4).unpack("V*").first
      break if sector_ram_pointer == 0
      
      sector = Sector.new(self, sector_index, sector_ram_pointer, game)
      @sectors << sector
      
      sector_index += 1
    end
  end
end
