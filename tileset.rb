
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
    @tiles << TilesetTile.new(0) # First entry on every tileset is always blank.
    
    (0..LENGTH_OF_TILESET_IN_BLOCKS-1).each do |i|
      tile_data = fs.read(tileset_ram_pointer + i*4, 4).unpack("V").first
      
      @tiles << TilesetTile.new(tile_data)
    end
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
