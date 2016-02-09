class SubArea
  class SubAreaReadError < StandardError ; end
  
  attr_reader :rom,
              :converter,
              :major_area,
              :sub_area_pointer,
              :sub_area_index,
              :rooms

  def initialize(major_area, sub_area_index, sub_area_pointer, rom, converter)
    @major_area = major_area
    @sub_area_pointer = sub_area_pointer
    @sub_area_index = sub_area_index
    @rom = rom
    @converter = converter
    read_from_rom()
  end
  
  def read_from_rom
    overlay_index = AREA_INDEX_TO_OVERLAY_INDEX[major_area.major_area_index][sub_area_index]
    converter.load_overlay(overlay_index)
    
    @rooms = []
    room_index = 0
    while true
      #puts "#{major_area.major_area_index}-#{sub_area_index}-#{room_index}"
      room_metadata_ram_pointer = rom[sub_area_pointer + room_index*4,4].unpack("V*").first
      
      break if room_metadata_ram_pointer == 0
      if INVALID_ROOMS.include?(room_metadata_ram_pointer)
        room_index += 1
        next # unused, mispointed rooms
      end
      
      room = Room.new(room_metadata_ram_pointer, rom, major_area.major_area_index, sub_area_index, room_index, converter)
      @rooms << room
      
      room_index += 1
    end
  end
end