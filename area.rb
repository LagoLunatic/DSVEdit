
class Area
  class AreaReadError < StandardError ; end
  
  attr_reader :area_index,
              :rom,
              :converter,
              :area_pointer,
              :sectors

  def initialize(area_index, rom, converter)
    @area_index = area_index
    @rom = rom
    @converter = converter
    read_from_rom()
  end
  
  def read_from_rom
    @area_pointer = converter.ram_to_rom(rom[AREA_LIST_START_OFFSET + area_index*4,4].unpack("V*").first)
    
    @sectors = []
    sector_index = 0
    while true
      sector_ram_pointer = rom[area_pointer + sector_index*4,4].unpack("V*").first
      break if sector_ram_pointer == 0
      
      sector_pointer = converter.ram_to_rom(sector_ram_pointer)
      sector = Sector.new(self, sector_index, sector_pointer, rom, converter)
      @sectors << sector
      
      sector_index += 1
    end
  end
end