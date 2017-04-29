
class Tileset
  attr_reader :tileset_ram_pointer,
              :tiles,
              :fs
              
  def initialize(tileset_ram_pointer, fs)
    @tileset_ram_pointer = tileset_ram_pointer
    @fs = fs
    
    if SYSTEM == :gba
      read_from_rom_gba()
    else
      read_from_rom_nds()
    end
  end
  
  def read_from_rom_nds
    @tiles = []
    @tiles << tile_class.new(0) # First entry on every tileset is always blank.
    
    tileset_data = fs.read(tileset_ram_pointer, 4*LENGTH_OF_TILESET_IN_BLOCKS, allow_length_to_exceed_end_of_file: true)
    
    offset = 0
    while true
      tile_data = tileset_data[offset, 4].unpack("V").first
      
      @tiles << tile_class.new(tile_data)
      
      offset += 4
      if offset >= tileset_data.length
        break
      end
    end
  end
  
  def read_from_rom_gba
    @tiles = []
    @tiles << tile_class.new("\0\0"*16) # First entry on every tileset is always blank.
    
    tileset_data = fs.decompress(tileset_ram_pointer)
    
    offset = 0
    while true
      tile_data = tileset_data[offset, 32]
      
      @tiles << tile_class.new(tile_data)
      
      offset += 32
      if offset >= tileset_data.length
        break
      end
    end
  end
  
  def tile_class
    if SYSTEM == :gba
      GBATilesetTile
    else
      TilesetTile
    end
  end
end

class TilesetTile
  attr_accessor :index_on_tile_page,
                :unknown_1,
                :tile_page,
                :horizontal_flip,
                :vertical_flip,
                :unknown_2,
                :palette_index
              
  def initialize(tile_data)
    @index_on_tile_page = (tile_data & 0b00000000_00000000_00000000_00111111)
    @unknown_1          = (tile_data & 0b00000000_00000000_00001111_11000000) >> 6
    @tile_page          = (tile_data & 0b00000000_00000001_11110000_00000000) >> 12
    @horizontal_flip    = (tile_data & 0b00000000_00000010_00000000_00000000) > 0
    @vertical_flip      = (tile_data & 0b00000000_00000100_00000000_00000000) > 0
    @unknown_2          = (tile_data & 0b00000000_11111000_00000000_00000000) >> 19
    @palette_index      = (tile_data & 0b11111111_00000000_00000000_00000000) >> 24
    
    # Unknown 1 and unknown 2 aren't used, they only sometimes seem to be used because of reading garbage data past the end of the actual tilset.
  end
  
  def to_data
    tile_data = 0
    tile_data |= (@index_on_tile_page      ) & 0b00000000_00000000_00000000_00111111
    tile_data |= (@unknown_1          <<  6) & 0b00000000_00000000_00001111_11000000
    tile_data |= (@tile_page          << 12) & 0b00000000_00000001_11110000_00000000
    tile_data |=                               0b00000000_00000010_00000000_00000000 if @horizontal_flip
    tile_data |=                               0b00000000_00000100_00000000_00000000 if @vertical_flip
    tile_data |= (@unknown_2          << 19) & 0b00000000_11111000_00000000_00000000
    tile_data |= (@palette_index      << 24) & 0b11111111_00000000_00000000_00000000
    [tile_data].pack("V")
  end
  
  def is_blank
    # This indicates the tile is completely blank, no graphics or collision.
    index_on_tile_page == 0 && tile_page == 0
  end
end

class GBATilesetTile
  attr_reader :minitiles
              
  def initialize(tile_data)
    @minitiles = []
    tile_data.unpack("v*").each do |minitile_data|
      @minitiles << MiniTile.new(minitile_data)
    end
  end
  
  def is_blank
    false # TODO
  end
end

class MiniTile
  attr_accessor :index_on_tile_page,
                :tile_page,
                :horizontal_flip,
                :vertical_flip,
                :palette_index
              
  def initialize(minitile_data)
    @index_on_tile_page = (minitile_data & 0b00000000_11111111)
    @tile_page          = (minitile_data & 0b00000011_00000000) >> 8
    @horizontal_flip    = (minitile_data & 0b00000100_00000000) > 0
    @vertical_flip      = (minitile_data & 0b00001000_00000000) > 0
    @palette_index      = (minitile_data & 0b11110000_00000000) >> 12
  end
  
  def is_blank
    false
  end
end

class CollisionTileset < Tileset
  def read_from_rom_gba
    @tiles = [] # TODO
  end
  
  def tile_class
    CollisionTile
  end
end

class CollisionTile
  attr_reader :tile_data,
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
              
  def initialize(tile_data)
    @tile_data = tile_data
    
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
  
  def to_data
    raise NotImplementedError.new
  end
end
