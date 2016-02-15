
class Area
  class AreaReadError < StandardError ; end
  
  attr_reader :area_index,
              :fs,
              :area_ram_pointer,
              :sectors

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
  end
end