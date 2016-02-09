class Layer
  class LayerReadError < StandardError ; end
  
  SIZE_OF_A_SCREEN_IN_BYTES = 2*16*12
  
  attr_reader :room,
              :layer_list_entry_pointer,
              :layer_metadata_ram_pointer,
              :render_type,
              :opacity,
              :z_index,
              :width,
              :height,
              :pointer_to_tileset_for_layer,
              :rom,
              :converter,
              :layer_tiledata_start_offset
  attr_accessor :level_blocks
  
  def initialize(room, layer_list_entry_pointer, rom, converter)
    @room = room
    @rom = rom
    @layer_list_entry_pointer = layer_list_entry_pointer
    @converter = converter
    
    read_from_layer_list_entry()
    read_from_layer_metadata()
    read_from_layer_tiledata()
  end
  
  def read_from_layer_list_entry
    # todo: get anything else from the layer list that's useful
    @layer_metadata_ram_pointer = rom[layer_list_entry_pointer + 12,4].unpack("V*").first
    #puts "layer_metadata_ram_pointer: %08X" % layer_metadata_ram_pointer
    @render_type = rom[layer_list_entry_pointer + 8,1].unpack("C*").first
    @opacity = rom[layer_list_entry_pointer + 2,1].unpack("C*").first
    @z_index = rom[layer_list_entry_pointer,1].unpack("C*").first
  end
  
  def read_from_layer_metadata
    #layer_metadata_offset = ram_to_rom(layer_metadata_ram_pointer, room.overlay_offset)
    layer_metadata_offset = converter.ram_to_rom(layer_metadata_ram_pointer)

    #puts "layer_metadata_offset: %08X" % layer_metadata_offset
    @width, @height = rom[layer_metadata_offset,2].unpack("C*")
    if width > 15 || height > 15
      raise LayerReadError.new("Invalid layer size: #{width}x#{height}")
    end
    ram_pointer_to_tileset_for_layer = rom[layer_metadata_offset+4,4].unpack("V*").first
    #puts "ram_pointer_to_tileset_for_layer: %08X" % ram_pointer_to_tileset_for_layer
    is_a_pointer_check = rom[layer_metadata_offset + 7].unpack("C*").first
    if is_a_pointer_check != 0x02
      raise "Tileset pointer is invalid for room %08X" % room.room_metadata_ram_pointer # TODO: FIXME
      return
    end
    #@pointer_to_tileset_for_layer = ram_to_rom(ram_pointer_to_tileset_for_layer, room.overlay_offset)
    @pointer_to_tileset_for_layer = converter.ram_to_rom(ram_pointer_to_tileset_for_layer)
    #puts "pointer_to_tileset_for_layer: %08X" % pointer_to_tileset_for_layer
    @layer_tiledata_start_offset = layer_metadata_offset + 0x10 # FIXME, HACK
  end
  
  def read_from_layer_tiledata
    level_data_string = rom[layer_tiledata_start_offset, SIZE_OF_A_SCREEN_IN_BYTES*width*height] 
    @level_blocks = level_data_string.unpack("v*")
  end
  
  def write_to_rom
    blocks_in_room = width * 16 * height * 12
    if level_blocks.length != blocks_in_room
      raise "Blocks in tmx layer doesn't match blocks in game layer (room: #{room.room_metadata_ram_pointer})"
    end
    rom[layer_tiledata_start_offset,blocks_in_room*2] = level_blocks.pack("v*")
  end
  
  def colors_per_palette
    colors = 16
    if render_type > 0
      colors = 256
    end
    
    return colors
  end
  
  def tileset_filename
    "tileset_%08X_%08X_%d" % [pointer_to_tileset_for_layer, room.palette_offset || 0, colors_per_palette]
  end
end