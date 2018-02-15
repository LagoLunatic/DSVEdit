
class Tileset
  attr_reader :tileset_pointer,
              :tileset_type,
              :tiles,
              :fs
              
  def initialize(tileset_pointer, tileset_type, fs)
    @tileset_pointer = tileset_pointer
    @fs = fs
    @tileset_type = tileset_type
    
    if SYSTEM == :gba
      read_from_rom_gba()
    else
      read_from_rom_nds()
    end
  end
  
  def read_from_rom_nds
    @tiles = []
    @tiles << tile_class.new("\0"*tile_class.data_size) # First entry on every tileset is always blank.
    
    tileset_data = fs.read(tileset_pointer, 4*LENGTH_OF_TILESET_IN_BLOCKS, allow_length_to_exceed_end_of_file: true)
    
    offset = 0
    while true
      tile_data = tileset_data[offset, 4]
      
      @tiles << tile_class.new(tile_data)
      
      offset += 4
      if offset >= tileset_data.length
        break
      end
    end
  end
  
  def read_from_rom_gba
    @tiles = []
    
    if self.is_a?(CollisionTileset) || (tileset_type & 0x2) > 0
      tileset_data = fs.decompress(tileset_pointer)
    elsif tileset_type == 1
      tileset_data = fs.read(tileset_pointer, 0x1000)
    else
      puts "Unknown tileset type: #{tileset_type}"
      return
    end
    
    # First entry on every tileset is always blank.
    if self.is_a?(CollisionTileset)
      16.times do
        @tiles << tile_class.new("\0"*tile_class.data_size)
      end
    else
      @tiles << tile_class.new("\0"*tile_class.data_size)
    end
    
    offset = 0
    while true
      tile_data = tileset_data[offset, tile_class.data_size]
      
      @tiles << tile_class.new(tile_data)
      
      offset += tile_class.data_size
      if offset >= tileset_data.length
        break
      end
    end
  end
  
  def write_to_rom
    tileset_data = ""
    
    if self.is_a?(CollisionTileset) && SYSTEM == :gba
      tiles_to_write = @tiles[16..-1]
    else
      tiles_to_write = @tiles[1..-1]
    end
    tiles_to_write.each_with_index do |tile, i|
      tileset_data << tile.to_data
    end
    
    if SYSTEM == :nds
      fs.write(tileset_pointer, tileset_data)
    elsif self.is_a?(CollisionTileset) || (tileset_type & 0x2) > 0
      fs.compress_write(tileset_pointer, tileset_data)
    else
      fs.write(tileset_pointer, tileset_data)
    end
  end
  
  def tile_class
    if SYSTEM == :gba
      if tileset_type & 0x1 > 0
        GBA256TilesetTile
      else
        GBATilesetTile
      end
    else
      TilesetTile
    end
  end
  
  def colors_per_palette
    if SYSTEM == :gba
      if tileset_type & 0x1 > 0
        256
      else
        16
      end
    else
      raise "Tilesets don't have a colors_per_palette in the DSVanias"
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
    tile_data = tile_data.unpack("V").first
    
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
  
  def self.data_size
    4
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
  
  def to_data
    @minitiles.map{|mt| mt.to_data}.join
  end
  
  def is_blank
    @minitiles.all?{|mt| mt.is_blank}
  end
  
  def self.data_size
    32
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
  
  def to_data
    minitile_data = 0
    minitile_data |= (@index_on_tile_page      ) & 0b00000000_11111111
    minitile_data |= (@tile_page          <<  8) & 0b00000011_00000000
    minitile_data |=                               0b00000100_00000000 if @horizontal_flip
    minitile_data |=                               0b00001000_00000000 if @vertical_flip
    minitile_data |= (@palette_index      << 12) & 0b11110000_00000000
    [minitile_data].pack("v")
  end
  
  def is_blank
    # This indicates the tile is completely blank, no graphics or collision.
    index_on_tile_page == 0 && tile_page == 0
  end
end

class GBA256TilesetTile < GBATilesetTile
  attr_reader :minitiles
              
  def initialize(tile_data)
    @minitiles = []
    tile_data.unpack("C*").each do |minitile_data|
      @minitiles << MiniTile256.new(minitile_data)
    end
  end
  
  def self.data_size
    16
  end
end

class MiniTile256 < MiniTile
  def initialize(minitile_data)
    @index_on_tile_page = minitile_data
    @tile_page          = 0
    @horizontal_flip    = false
    @vertical_flip      = false
    @palette_index      = 0
  end
  
  def to_data
    minitile_data = index_on_tile_page
    [minitile_data].pack("C")
  end
end

class CollisionTileset < Tileset
  def initialize(tileset_pointer, fs)
    @tileset_pointer = tileset_pointer
    @fs = fs
    
    if SYSTEM == :gba
      read_from_rom_gba()
    else
      read_from_rom_nds()
    end
  end
  
  def tile_class
    CollisionTile
  end
end

class CollisionTile
  attr_reader :tile_data
  attr_accessor :has_top,
                :vertical_flip,
                :horizontal_flip,
                :has_sides_and_bottom,
                :has_effect,
                :is_water,
                :block_shape,
                :unknown_1,
                :unknown_2,
                :unknown_3
              
  def initialize(tile_data)
    if SYSTEM == :gba
      @tile_data = tile_data.unpack("C")
    else
      @tile_data = tile_data.unpack("CCCC")
    end
    
    collision_data     = @tile_data[0]
    if SYSTEM == :nds
      @unknown_1         = @tile_data[1]
      @unknown_2         = @tile_data[2]
      @unknown_3         = @tile_data[3]
    end
    
    @has_top     = (collision_data & 0b00000001) > 0
    bit_2        = (collision_data & 0b00000010) > 0
    bit_3        = (collision_data & 0b00000100) > 0
    @is_water    = (collision_data & 0b00001000) > 0
    @block_shape = (collision_data & 0b11110000) >> 4
    
    # TODO fix certain collision tiles in HoD:
    # full block that has effect should be slope
    # has top, block shape 08, v and h flip: also a regular slope
    # 0201288F is where the collision data for one of the slopes in the second room of the game is.
    # 080016B0 checks bits 00001100
    # 080016D0 checks bits 01111111
    # 08001760 checks if the data == 10000011
    # 08001796 checks bits 00001100
    # 0800179C checks bit  10000000
    # 11110000 (F0) means it's a door trigger block
    # 10000011 (83) means it's solid but you can bounce of it and it clinks
    
    if block_shape >= 4
      @vertical_flip   = bit_2
      @horizontal_flip = bit_3
    else
      @has_sides_and_bottom = bit_2
      @has_effect = bit_3
    end
  end
  
  def to_data
    tile_data = 0
    tile_data |=   0b00000001 if @has_top
    if @block_shape >= 4
      tile_data |= 0b00000010 if @vertical_flip
      tile_data |= 0b00000100 if @horizontal_flip
    else
      tile_data |= 0b00000010 if @has_sides_and_bottom
      tile_data |= 0b00000100 if @has_effect
    end
    tile_data |=   0b00001000 if @is_water
    tile_data |= (@block_shape <<  4) & 0b11110000
    if SYSTEM == :nds
      tile_data |= (@unknown_1   <<  8) & 0x0000FF00
      tile_data |= (@unknown_2   << 16) & 0x00FF0000
      tile_data |= (@unknown_3   << 24) & 0xFF000000
      
      [tile_data].pack("V")
    else
      [tile_data].pack("C")
    end
  end
  
  def is_blank
    [0, 1].include?(block_shape) && !has_top && !has_sides_and_bottom && !has_effect
  end
  
  def is_solid?
    block_shape == 0 && has_top && has_sides_and_bottom
  end
  
  def is_jumpthrough_platform?
    [0, 1, 2, 3].include?(block_shape) && has_top && !has_sides_and_bottom && !has_effect
  end
  
  def is_bottom_half?
    block_shape == 3 && is_jumpthrough_platform?
  end
  
  def is_slope?
    block_shape >= 4
  end
  
  def is_damage?
    (0..1).include?(block_shape) && has_effect
  end
  
  def is_conveyor_left?
    block_shape == 2 && has_effect
  end
  
  def is_conveyor_right?
    block_shape == 3 && has_effect
  end
  
  def is_conveyor?
    is_conveyor_left? || is_conveyor_right?
  end
  
  def self.data_size
    if SYSTEM == :nds
      4
    else
      1
    end
  end
end
