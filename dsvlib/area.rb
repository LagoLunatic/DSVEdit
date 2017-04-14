
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
  end
  
  def get_sector_and_room_indexes_from_map_x_y(x, y)
    sectors.each_with_index do |sector, sector_index|
      sector.rooms.each_with_index do |room, room_index|
        xrange = (room.room_xpos_on_map..room.room_xpos_on_map+room.main_layer_width-1)
        yrange = (room.room_ypos_on_map..room.room_ypos_on_map+room.main_layer_height-1)
        if xrange.include?(x) && yrange.include?(y)
          return [sector_index, room_index]
        end
      end
    end
    
    return [0, 0]
  end
end
