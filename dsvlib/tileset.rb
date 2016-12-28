
class Tileset
  TILESET_WIDTH_IN_BLOCKS = 16
  TILESET_HEIGHT_IN_BLOCKS = 64
  LENGTH_OF_TILESET_IN_BLOCKS = TILESET_WIDTH_IN_BLOCKS*TILESET_HEIGHT_IN_BLOCKS - 1 # -1 because the first tile in a tileset is always blank.
  
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
    @tiles << tile_class.new(0, 0) # First entry on every tileset is always blank.
    
    (0..LENGTH_OF_TILESET_IN_BLOCKS-1).each do |i|
      tile_data = fs.read(tileset_ram_pointer + i*4, 4).unpack("V").first
      
      @tiles << tile_class.new(tile_data, tileset_ram_pointer + i*4)
    end
  end
  
  def tile_class
    TilesetTile
  end
end

class TilesetTile
  attr_reader :ram_location,
              :index_on_tile_page,
              :unknown_1,
              :tile_page,
              :horizontal_flip,
              :vertical_flip,
              :unknown_2,
              :palette_index,
              :is_blank
              
  def initialize(tile_data, ram_location)
    @ram_location = ram_location
    
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
    
    # Unknown 1 and unknown 2 aren't used, they only sometimes seem to be used because of reading garbage data past the end of the actual tilset.
  end
end

class CollisionTileset < Tileset
  def tile_class
    CollisionTile
  end
end

class CollisionTile
  attr_reader :ram_location,
              :tile_data,
              :unknown_1,
              :unknown_2,
              :unknown_3,
              :has_top,
              :vertical_flip,
              :horizontal_flip,
              :has_sides_and_bottom,
              :block_effect,
              :is_water,
              :block_shape
              
  def initialize(tile_data, ram_location)
    @tile_data = tile_data
    @ram_location = ram_location
    
    collision_data     = (tile_data & 0x000000FF)
    @unknown_1         = (tile_data & 0x0000FF00) >> 8
    @unknown_2         = (tile_data & 0x00FF0000) >> 16
    @unknown_3         = (tile_data & 0xFF000000) >> 24
    
    @has_top     = (collision_data & 0b00000001) > 0
    bit_2        = (collision_data & 0b00000010) > 0
    bit_3        = (collision_data & 0b00000100) > 0
    @is_water    = (collision_data & 0b00001000) > 0
    @block_shape = (collision_data & 0b11110000) >> 4
    
    if block_shape >= 4
      @vertical_flip   = bit_2
      @horizontal_flip = bit_3
    else
      @has_sides_and_bottom = bit_2
      if bit_3
        case block_shape
        when 0..1
          @block_effect = :damage
        when 2
          @block_effect = :conveyor_belt_left
        when 3
          @block_effect = :conveyor_belt_right
        end
      end
    end
  end
end

