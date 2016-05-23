
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
  attr_reader :is_abyss
  
  def initialize(map_tile_metadata_ram_pointer, map_tile_line_data_ram_pointer, number_of_tiles, fs, is_abyss = false)
    @is_abyss = is_abyss
    if is_abyss
      @width = 18
    else
      @width = 64
    end
    
    super(map_tile_metadata_ram_pointer, map_tile_line_data_ram_pointer, number_of_tiles, fs)
  end
  
  def read_from_rom
    @tiles = []
    i = 0
    while i < number_of_tiles
      2.times do
        tile_line_data = fs.read(map_tile_line_data_ram_pointer + i/2).unpack("C*").first
        if i.even?
          tile_line_data = tile_line_data >> 4
        else
          tile_line_data = tile_line_data & 0b00001111
        end
        
        index_for_metadata = i
        if is_abyss
          # For some reason, the Abyss's tile metadata (but not line data) has an extra block at the end of each row.
          # Here we skip that extra block so that the tile metadata and line data stay in sync.
          index_for_metadata += i / @width
        end
        tile_metadata = fs.read(map_tile_metadata_ram_pointer + index_for_metadata*2, 2).unpack("v")
        
        @tiles << DoSMapTile.new(tile_metadata, tile_line_data, i, @width)
        
        i += 1
      end
    end
  end
end

class DoSMapTile
  attr_reader :tile_metadata,
              :tile_line_data,
              :map_width
              
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
  
  def initialize(tile_metadata, tile_line_data, tile_index, map_width)
    @tile_metadata = tile_metadata
    @tile_line_data = tile_line_data
    @tile_index = tile_index
    @map_width = map_width
    
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
    
    @y_pos          = @tile_index / map_width
    @x_pos          = @tile_index % map_width
    
    @is_blank       = tile_metadata[0] == 0xFFFF
  end
end