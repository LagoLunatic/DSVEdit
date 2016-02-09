
class Map
  attr_reader :map_tile_metadata_ram_pointer,
              :map_tile_line_data_ram_pointer,
              :number_of_tiles,
              :rom,
              :converter,
              :tiles
  
  def initialize(map_tile_metadata_ram_pointer, map_tile_line_data_ram_pointer, number_of_tiles, rom, converter)
    @map_tile_metadata_ram_pointer = map_tile_metadata_ram_pointer
    @map_tile_line_data_ram_pointer = map_tile_line_data_ram_pointer
    @number_of_tiles = number_of_tiles
    @rom = rom
    @converter = converter
    read_from_rom()
  end
  
  def read_from_rom
    map_tile_metadata_pointer = converter.ram_to_rom(map_tile_metadata_ram_pointer)
    map_tile_line_data_pointer = converter.ram_to_rom(map_tile_line_data_ram_pointer)
    @tiles = []
    (0..number_of_tiles-1).each do |i|
      tile_line_data = rom[map_tile_line_data_pointer + i].unpack("C*").first
      tile_metadata = rom[map_tile_metadata_pointer + i*4,4].unpack("C*")
      
      tile = {}
      tile[:bottom_door] = tile_line_data & 0b10000000 > 0
      tile[:bottom_wall] = tile_line_data & 0b01000000 > 0
      tile[:right_door]  = tile_line_data & 0b00100000 > 0
      tile[:right_wall]  = tile_line_data & 0b00010000 > 0
      tile[:top_door]    = tile_line_data & 0b00001000 > 0
      tile[:top_wall]    = tile_line_data & 0b00000100 > 0
      tile[:left_door]   = tile_line_data & 0b00000010 > 0
      tile[:left_wall]   = tile_line_data & 0b00000001 > 0
      
      tile[:is_save]     = tile_metadata[1] & 0b10000000 > 0
      tile[:is_warp]     = tile_metadata[1] & 0b01000000 > 0
      tile[:is_entrance] = tile_metadata[1] & 0b00001000 > 0
      tile[:x_pos]       = tile_metadata[3]
      tile[:y_pos]       = tile_metadata[2]
      @tiles << tile
    end
  end
end

class DoSMap < Map
  def read_from_rom
    map_tile_metadata_pointer = converter.ram_to_rom(map_tile_metadata_ram_pointer)
    map_tile_line_data_pointer = converter.ram_to_rom(map_tile_line_data_ram_pointer)
    @tiles = []
    i = 0
    while i < number_of_tiles
      2.times do
        tile_line_data = rom[map_tile_line_data_pointer + i/2].unpack("C*").first
        tile_metadata = rom[map_tile_metadata_pointer + i*2, 2].unpack("C*")
        if i.even?
          tile_line_data = tile_line_data >> 4
        else
          tile_line_data = tile_line_data & 0b00001111
        end
        
        tile = {}
        tile[:top_door]    = (tile_line_data >> 2) & 0b0011 == 2
        tile[:top_wall]    = (tile_line_data >> 2) & 0b0011 == 3
        tile[:left_door]   =  tile_line_data       & 0b0011 == 2
        tile[:left_wall]   =  tile_line_data       & 0b0011 == 3
        
        tile[:is_blank]    = tile_metadata[1] == 0xFF
        tile[:is_save]     = tile_metadata[1] & 0b10000000 > 0
        tile[:is_warp]     = tile_metadata[1] & 0b01000000 > 0
        tile[:x_pos]       = i % 64
        tile[:y_pos]       = i / 64
        @tiles << tile
        
        i += 1
      end
    end
  end
end

