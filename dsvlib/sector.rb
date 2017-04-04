class Sector
  class SectorReadError < StandardError ; end
  
  attr_reader :fs,
              :game,
              :area,
              :sector_ram_pointer,
              :sector_index,
              :room_pointers,
              :rooms

  def initialize(area, sector_index, sector_ram_pointer, game)
    @area = area
    @sector_ram_pointer = sector_ram_pointer
    @sector_index = sector_index
    @fs = game.fs
    @game = game
    
    read_room_pointers_from_rom()
  end
  
  def rooms
    @rooms ||= read_rooms_from_rom()
  end
  
  def overlay_id
    AREA_INDEX_TO_OVERLAY_INDEX[area.area_index][sector_index]
  end
  
  def load_necessary_overlay
    fs.load_overlay(overlay_id)
  end
  
private
  
  def read_room_pointers_from_rom
    @room_pointers = []
    room_index = 0
    while true
      room_metadata_ram_pointer = fs.read(sector_ram_pointer + room_index*4, 4).unpack("V*").first
      
      break if room_metadata_ram_pointer == 0
      
      room_pointers << room_metadata_ram_pointer
      
      room_index += 1
    end
  end
  
  def read_rooms_from_rom
    load_necessary_overlay()
    
    rooms = []
    room_pointers.each_with_index do |room_pointer, room_index|
      room = Room.new(self, room_pointer, area.area_index, sector_index, room_index, game)
      rooms << room
    end
    
    rooms
  end
end
