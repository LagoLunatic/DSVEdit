
class MajorArea
  class MajorAreaReadError < StandardError ; end
  
  attr_reader :major_area_index,
              :rom,
              :converter,
              :major_area_pointer,
              :sub_areas

  def initialize(major_area_index, rom, converter)
    @major_area_index = major_area_index
    @rom = rom
    @converter = converter
    read_from_rom()
  end
  
  def read_from_rom
    @major_area_pointer = converter.ram_to_rom(rom[MAJOR_AREA_LIST_START_OFFSET + major_area_index*4,4].unpack("V*").first)
    
    @sub_areas = []
    sub_area_index = 0
    while true
      sub_area_ram_pointer = rom[major_area_pointer + sub_area_index*4,4].unpack("V*").first
      break if sub_area_ram_pointer == 0
      
      sub_area_pointer = converter.ram_to_rom(sub_area_ram_pointer)
      sub_area = SubArea.new(self, sub_area_index, sub_area_pointer, rom, converter)
      @sub_areas << sub_area
      
      sub_area_index += 1
    end
  end
end