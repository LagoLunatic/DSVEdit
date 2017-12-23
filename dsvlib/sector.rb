class Sector
  class SectorReadError < StandardError ; end
  
  attr_reader :fs,
              :game,
              :area,
              :sector_ram_pointer,
              :area_index,
              :sector_index,
              :room_pointers,
              :rooms,
              :is_hardcoded

  def initialize(area, sector_index, sector_ram_pointer, game, next_sector_pointer: nil, hardcoded_room_pointers: nil)
    @area = area
    @sector_ram_pointer = sector_ram_pointer
    @next_sector_pointer = next_sector_pointer
    @area_index = area.area_index
    @sector_index = sector_index
    @fs = game.fs
    @game = game
    
    if hardcoded_room_pointers
      @room_pointers = hardcoded_room_pointers
      @is_hardcoded = true
    else
      read_room_pointers_from_rom()
    end
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
  
  def name
    if SECTOR_INDEX_TO_SECTOR_NAME[area_index]
      SECTOR_INDEX_TO_SECTOR_NAME[area_index][sector_index]
    else
      return AREA_INDEX_TO_AREA_NAME[area_index]
    end
  end
  
  def inspect; to_s; end
  
private
  
  def read_room_pointers_from_rom
    @room_pointers = []
    room_index = 0
    while true
      break if sector_ram_pointer + room_index*4 == @next_sector_pointer
      
      room_metadata_ram_pointer = fs.read(sector_ram_pointer + room_index*4, 4).unpack("V*").first
      
      break if room_metadata_ram_pointer == 0
      break if room_metadata_ram_pointer < 0x084E589C && GAME == "aos" && REGION == :cn # TODO: less hacky way to do this
      break if room_metadata_ram_pointer < 0x0850EF9C && GAME == "aos" && REGION == :usa # TODO: less hacky way to do this
      
      room_pointers << room_metadata_ram_pointer
      
      room_index += 1
    end
  end
  
  def read_rooms_from_rom
    fs.load_overlay(AREAS_OVERLAY) if AREAS_OVERLAY
    
    load_necessary_overlay()
    
    rooms = []
    room_pointers.each_with_index do |room_pointer, room_index|
      room = Room.new(self, room_pointer, area.area_index, sector_index, room_index, game)
      rooms << room
    end
    
    rooms
  end
end
