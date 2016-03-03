class Layer
  class LayerReadError < StandardError ; end
  
  SIZE_OF_A_SCREEN_IN_BYTES = 2*16*12
  
  attr_reader :room,
              :layer_list_entry_ram_pointer,
              :layer_metadata_ram_pointer,
              :render_type,
              :opacity,
              :z_index,
              :ram_pointer_to_tileset_for_layer,
              :fs,
              :collision_tileset_ram_pointer,
              :layer_tiledata_ram_start_offset
  attr_accessor :width,
                :height,
                :tiles
  
  def initialize(room, layer_list_entry_ram_pointer, fs)
    @room = room
    @layer_list_entry_ram_pointer = layer_list_entry_ram_pointer
    @fs = fs
    
    read_from_layer_list_entry()
    read_from_layer_metadata()
    read_from_layer_tiledata()
  end
  
  def read_from_layer_list_entry
    # todo: get anything else from the layer list that's useful
    @layer_metadata_ram_pointer = fs.read(layer_list_entry_ram_pointer + 12,4).unpack("V*").first
    @render_type = fs.read(layer_list_entry_ram_pointer + 8,1).unpack("C*").first
    @opacity = fs.read(layer_list_entry_ram_pointer + 2,1).unpack("C*").first
    @z_index = fs.read(layer_list_entry_ram_pointer, 1).unpack("C*").first
  end
  
  def read_from_layer_metadata
    @width, @height = fs.read(layer_metadata_ram_pointer,2).unpack("C*")
    if width > 15 || height > 15
      raise LayerReadError.new("Invalid layer size: #{width}x#{height}")
    end
    @ram_pointer_to_tileset_for_layer = fs.read(layer_metadata_ram_pointer+4,4).unpack("V*").first
    
    is_a_pointer_check = fs.read(layer_metadata_ram_pointer + 7).unpack("C*").first
    if is_a_pointer_check != 0x02
      raise "Tileset pointer is invalid for room %08X" % room.room_metadata_ram_pointer # TODO: FIXME
      return
    end
    
    @collision_tileset_ram_pointer = fs.read(layer_metadata_ram_pointer+8, 4).unpack("V").first
    @layer_tiledata_ram_start_offset = fs.read(layer_metadata_ram_pointer+12, 4).unpack("V").first
  end
  
  def read_from_layer_tiledata
    tile_data_string = fs.read(layer_tiledata_ram_start_offset, SIZE_OF_A_SCREEN_IN_BYTES*width*height)
    @tiles = tile_data_string.unpack("v*").map do |tile_data|
      Tile.new(tile_data)
    end
  end
  
  def write_to_rom
    room.sector.load_necessary_overlay()
    
    old_width, old_height = fs.read(layer_metadata_ram_pointer,2).unpack("C*")
    
    if (width*height) > (old_width*old_height)
      # Size of layer was increased. Repoint to end of file so nothing is overwritten.
      
      blocks_in_room = width * 16 * height * 12
      bytes_in_tiledata = blocks_in_room * 2
      
      new_tiledata_ram_pointer = fs.expand_file_and_get_end_of_file_ram_address(layer_tiledata_ram_start_offset, bytes_in_tiledata)
      fs.write(layer_metadata_ram_pointer+12, [new_tiledata_ram_pointer].pack("V"))
      @layer_tiledata_ram_start_offset = new_tiledata_ram_pointer
    end
    
    fs.write(layer_metadata_ram_pointer, [width, height].pack("CC"))
    tile_data = tiles.map(&:to_tile_data).pack("v*")
    fs.write(layer_tiledata_ram_start_offset, tile_data)
  end
  
  def colors_per_palette
    colors = 16
    if render_type > 1
      colors = 256
    end
    
    return colors
  end
  
  def tileset_filename
    if GAME == "dos"
      "tileset_%08X_%08X_%d" % [ram_pointer_to_tileset_for_layer, room.palette_offset || 0, colors_per_palette]
    else
      "tileset_%08X_%08X_%08X_%d" % [ram_pointer_to_tileset_for_layer, room.palette_offset || 0, room.tileset_wrapper_A_ram_pointer, colors_per_palette]
    end
  end
end

class Tile
  attr_accessor :index_on_tileset,
                :horizontal_flip,
                :vertical_flip
  
  def initialize(tile_data)
    @index_on_tileset = (tile_data & 0b0011111111111111)
    @horizontal_flip  = (tile_data & 0b0100000000000000) != 0
    @vertical_flip    = (tile_data & 0b1000000000000000) != 0
  end
  
  def to_tile_data
    tile_data = index_on_tileset
    tile_data |= 0b0100000000000000 if horizontal_flip
    tile_data |= 0b1000000000000000 if vertical_flip
    tile_data
  end
end
