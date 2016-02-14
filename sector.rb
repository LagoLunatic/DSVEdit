class Sector
  class SectorReadError < StandardError ; end
  
  attr_reader :rom,
              :converter,
              :area,
              :sector_pointer,
              :sector_index,
              :rooms

  def initialize(area, sector_index, sector_pointer, rom, converter)
    @area = area
    @sector_pointer = sector_pointer
    @sector_index = sector_index
    @rom = rom
    @converter = converter
    read_from_rom()
  end
  
  def read_from_rom
    overlay_index = AREA_INDEX_TO_OVERLAY_INDEX[area.area_index][sector_index]
    converter.load_overlay(overlay_index)
    
    @rooms = []
    room_index = 0
    while true
      #puts "#{area.area_index}-#{sector_index}-#{room_index}"
      room_metadata_ram_pointer = rom[sector_pointer + room_index*4,4].unpack("V*").first
      
      break if room_metadata_ram_pointer == 0
      if INVALID_ROOMS.include?(room_metadata_ram_pointer)
        room_index += 1
        next # unused, mispointed rooms
      end
      
      room = Room.new(room_metadata_ram_pointer, rom, area.area_index, sector_index, room_index, converter)
      @rooms << room
      
      room_index += 1
    end
  end
end