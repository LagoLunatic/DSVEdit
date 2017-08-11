
class Area
  class AreaReadError < StandardError ; end
  
  attr_reader :area_index,
              :fs,
              :game,
              :area_ram_pointer,
              :sectors

  def initialize(area_index, game)
    @area_index = area_index
    @fs = game.fs
    @game = game
    read_from_rom()
  end
  
  def read_from_rom
    fs.load_overlay(AREAS_OVERLAY) if AREAS_OVERLAY
    
    @area_ram_pointer = fs.read(AREA_LIST_RAM_START_OFFSET + area_index*4,4).unpack("V*").first
    
    @sectors = []
    sector_index = 0
    while true
      sector_ram_pointer = fs.read(area_ram_pointer + sector_index*4, 4).unpack("V*").first
      break if sector_ram_pointer == 0
      break if !fs.is_pointer?(sector_ram_pointer)
      
      next_sector_ram_pointer = fs.read(area_ram_pointer + (sector_index+1)*4, 4).unpack("V*").first
      if !fs.is_pointer?(next_sector_ram_pointer)
        next_sector_ram_pointer = nil
      end
      
      sector = Sector.new(self, sector_index, sector_ram_pointer, game, next_sector_pointer: next_sector_ram_pointer)
      @sectors << sector
      
      sector_index += 1
    end
    
    if HARDCODED_BOSSRUSH_ROOM_IDS
      sector = Sector.new(self, sector_index, nil, game, hardcoded_room_pointers: HARDCODED_BOSSRUSH_ROOM_IDS)
      @sectors << sector
    end
  end
  
  def get_sector_and_room_indexes_from_map_x_y(x, y, abyss=false)
    sectors.each_with_index do |sector, sector_index|
      if GAME == "dos" && (0xC..0x10).include?(sector_index)
        # Areas not on either map.
        next
      end
      
      if GAME == "dos" && abyss
        # Exclude areas on the main Dracula Castle map.
        next if (0..9).include?(sector_index)
      elsif GAME == "dos" && !abyss
        # Exclude areas on the Abyss map.
        next if (0xA..0xB).include?(sector_index)
      end
      
      sector.rooms.each_with_index do |room, room_index|
        xrange = (room.room_xpos_on_map..room.room_xpos_on_map+room.main_layer_width-1)
        yrange = (room.room_ypos_on_map..room.room_ypos_on_map+room.main_layer_height-1)
        if xrange.include?(x) && yrange.include?(y)
          return [sector_index, room_index]
        end
      end
    end
    
    return nil
  end
  
  def name
    AREA_INDEX_TO_AREA_NAME[area_index]
  end
end
