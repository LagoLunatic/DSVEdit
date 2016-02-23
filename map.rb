
class Map
  attr_reader :map_tile_metadata_ram_pointer,
              :map_tile_line_data_ram_pointer,
              :number_of_tiles,
              :fs,
              :tiles
  
  def initialize(map_tile_metadata_ram_pointer, map_tile_line_data_ram_pointer, number_of_tiles, fs)
    @map_tile_metadata_ram_pointer = map_tile_metadata_ram_pointer
    @map_tile_line_data_ram_pointer = map_tile_line_data_ram_pointer
    @number_of_tiles = number_of_tiles
    @fs = fs
    read_from_rom()
  end
  
  def read_from_rom
    @tiles = []
    (0..number_of_tiles-1).each do |i|
      tile_line_data = fs.read(map_tile_line_data_ram_pointer + i).unpack("C*").first
      tile_metadata = fs.read(map_tile_metadata_ram_pointer + i*4, 4).unpack("vCC")

      @tiles << MapTile.new(tile_metadata, tile_line_data)
    end
  end
end

class MapTile
  attr_reader :tile_metadata,
              :tile_line_data
              
  attr_accessor :bottom_door,
                :bottom_wall,
                :right_door,
                :right_wall,
                :top_door,
                :top_wall,
                :left_door,
                :left_wall,
                :is_save,
                :is_warp,
                :is_secret,
                :is_transition,
                :is_entrance,
                :sector_index,
                :room_index,
                :y_pos,
                :x_pos,
                :is_blank
  
  def initialize(tile_metadata, tile_line_data)
    @tile_metadata = tile_metadata
    @tile_line_data = tile_line_data
    read_from_rom()
  end
  
  def read_from_rom
    @bottom_door    = tile_line_data & 0b10000000 > 0
    @bottom_wall    = tile_line_data & 0b01000000 > 0
    @right_door     = tile_line_data & 0b00100000 > 0
    @right_wall     = tile_line_data & 0b00010000 > 0
    @top_door       = tile_line_data & 0b00001000 > 0
    @top_wall       = tile_line_data & 0b00000100 > 0
    @left_door      = tile_line_data & 0b00000010 > 0
    @left_wall      = tile_line_data & 0b00000001 > 0

    @is_save        =  tile_metadata[0] & 0b10000000_00000000 > 0
    @is_warp        =  tile_metadata[0] & 0b01000000_00000000 > 0
    @is_secret      =  tile_metadata[0] & 0b00100000_00000000 > 0
    @is_transition  =  tile_metadata[0] & 0b00010000_00000000 > 0
    @is_entrance    =  tile_metadata[0] & 0b00001000_00000000 > 0
    @sector_index   = (tile_metadata[0] & 0b00000011_11000000) >> 6
    @room_index     =  tile_metadata[0] & 0b00000000_00111111
    @y_pos          =  tile_metadata[1]
    @x_pos          =  tile_metadata[2]
  end
end

class DoSMap < Map
  def read_from_rom
    @tiles = []
    i = 0
    while i < number_of_tiles
      2.times do
        tile_line_data = fs.read(map_tile_line_data_ram_pointer + i/2).unpack("C*").first
        tile_metadata = fs.read(map_tile_metadata_ram_pointer + i*2, 2).unpack("v")
        if i.even?
          tile_line_data = tile_line_data >> 4
        else
          tile_line_data = tile_line_data & 0b00001111
        end
        
        @tiles << DoSMapTile.new(tile_metadata, tile_line_data, i)
        
        i += 1
      end
    end
  end
end

class DoSMapTile
  attr_reader :tile_metadata,
              :tile_line_data
              
  attr_accessor :bottom_door,
                :bottom_wall,
                :right_door,
                :right_wall,
                :top_door,
                :top_wall,
                :left_door,
                :left_wall,
                :is_save,
                :is_warp,
                :is_secret,
                :is_transition,
                :is_entrance,
                :sector_index,
                :room_index,
                :y_pos,
                :x_pos,
                :is_blank
  
  def initialize(tile_metadata, tile_line_data, tile_index)
    @tile_metadata = tile_metadata
    @tile_line_data = tile_line_data
    @tile_index = tile_index
    read_from_rom()
  end
  
  def read_from_rom
    @top_door       = (tile_line_data >> 2) & 0b0011 == 2
    @top_wall       = (tile_line_data >> 2) & 0b0011 == 3
    @left_door      =  tile_line_data       & 0b0011 == 2
    @left_wall      =  tile_line_data       & 0b0011 == 3

    @is_save        =  tile_metadata[0] & 0b10000000_00000000 > 0
    @is_warp        =  tile_metadata[0] & 0b01000000_00000000 > 0
    @sector_index   = (tile_metadata[0] & 0b00000011_11000000) >> 6
    @room_index     =  tile_metadata[0] & 0b00000000_00111111
    @y_pos          = @tile_index / 64
    @x_pos          = @tile_index % 64
    
    @is_blank       = tile_metadata[0] == 0xFFFF
  end
end
