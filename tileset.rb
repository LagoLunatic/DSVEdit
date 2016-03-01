
class Tileset
  TILESET_WIDTH_IN_BLOCKS = 16
  TILESET_HEIGHT_IN_BLOCKS = 64
  LENGTH_OF_TILESET_IN_BLOCKS = TILESET_WIDTH_IN_BLOCKS*TILESET_HEIGHT_IN_BLOCKS - 1 # -1 because the first (blank) tile in a tileset is always blank.
  
  attr_reader :tileset_ram_pointer,
              :tiles,
              :fs
              
  def initialize(tileset_ram_pointer, fs)
    @tileset_ram_pointer = tileset_ram_pointer
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    @tiles = []
    @tiles << tile_class.new(0) # First entry on every tileset is always blank.
    
    (0..LENGTH_OF_TILESET_IN_BLOCKS-1).each do |i|
      tile_data = fs.read(tileset_ram_pointer + i*4, 4).unpack("V").first
      
      @tiles << tile_class.new(tile_data)
    end
  end
  
  def tile_class
    TilesetTile
  end
end

class TilesetTile
  attr_reader :index_on_tile_page,
              :unknown_1,
              :tile_page,
              :horizontal_flip,
              :vertical_flip,
              :unknown_2,
              :palette_index,
              :is_blank
              
  def initialize(tile_data)
    if tile_data == 0
      # This indicates the tile is completely blank, no graphics or collision.
      @is_blank = true
      return
    end
    
    @index_on_tile_page = (tile_data & 0b00000000_00000000_00000000_00111111)
    @unknown_1          = (tile_data & 0b00000000_00000000_00001111_11000000) >> 6
    @tile_page          = (tile_data & 0b00000000_00000001_11110000_00000000) >> 12
    @horizontal_flip    = (tile_data & 0b00000000_00000010_00000000_00000000) > 0
    @vertical_flip      = (tile_data & 0b00000000_00000100_00000000_00000000) > 0
    @unknown_2          = (tile_data & 0b00000000_11111000_00000000_00000000) >> 19
    @palette_index      = (tile_data & 0b11111111_00000000_00000000_00000000) >> 24
    
    # Unknown 1 and unknown 2 are used in PoR and OoE, not used in DoS.
  end
end

class CollisionTileset < Tileset
  def tile_class
    CollisionTile
  end
end

class CollisionTile
  attr_reader :unknown_1,
              :unknown_2,
              :unknown_3,
              :is_slope,
              :has_top,
              :vertical_flip,
              :horizontal_flip,
              :unknown_4,
              :slope_piece,
              :not_a_half_slope,
              :is_gradual_slope,
              :has_sides_and_bottom,
              :is_damage,
              :is_water,
              :unknown_5
              
  def initialize(tile_data)
    collision_data     = (tile_data & 0x000000FF)
    @unknown_1         = (tile_data & 0x0000FF00) >> 8
    @unknown_2         = (tile_data & 0x00FF0000) >> 16
    @unknown_3         = (tile_data & 0xFF000000) >> 24
    
    @is_slope               = (collision_data & 0b11110000) > 0
    @has_top                = (collision_data & 0b00000001) > 0
    if is_slope
      @vertical_flip        = (collision_data & 0b00000010) > 0
      @horizontal_flip      = (collision_data & 0b00000100) > 0
      @unknown_4            = (collision_data & 0b00001000) > 0
      @slope_piece          = (collision_data & 0b00110000) >> 4
      @not_a_half_slope     = (collision_data & 0b01000000) > 0
      @is_gradual_slope     = (collision_data & 0b10000000) > 0
    else
      @has_sides_and_bottom = (collision_data & 0b00000010) > 0
      @is_damage            = (collision_data & 0b00000100) > 0
      @is_water             = (collision_data & 0b00001000) > 0
      @unknown_5            = (collision_data & 0b11110000) >> 4
    end
  end
end

