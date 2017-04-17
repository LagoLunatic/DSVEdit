class Layer
  class LayerReadError < StandardError ; end
  
  attr_reader :room,
              :fs
              
  attr_accessor :layer_list_entry_ram_pointer,
                :layer_metadata_ram_pointer,
                :z_index,
                :scroll_mode,
                :opacity,
                :main_gfx_page_index,
                :bg_control,
                :width,
                :height,
                :tileset_pointer,
                :collision_tileset_pointer,
                :layer_tiledata_ram_start_offset,
                :tiles
  
  def initialize(room, layer_list_entry_ram_pointer, fs)
    @room = room
    @layer_list_entry_ram_pointer = layer_list_entry_ram_pointer
    @fs = fs
  end
    
  def read_from_rom
    read_from_layer_list_entry()
    read_from_layer_metadata()
    read_from_layer_tiledata()
  end
  
  def read_from_layer_list_entry
    if SYSTEM == :nds
      @z_index, @scroll_mode, @opacity, _, _, 
        @main_gfx_page_index, _, _, _,
        @layer_metadata_ram_pointer = fs.read(layer_list_entry_ram_pointer, 16).unpack("CCCCVCCCCV")
    else
      @z_index, @scroll_mode, @bg_control, 
        @main_gfx_page_index, _, _, _,
        @layer_metadata_ram_pointer = fs.read(layer_list_entry_ram_pointer, 12).unpack("CCvCCCCV")
      @opacity = 0x1F
    end
  end
  
  def read_from_layer_metadata
    if layer_metadata_ram_pointer == 0
      return # TODO
    end
    
    @width, @height, _,
      @tileset_pointer,
      @collision_tileset_pointer,
      @layer_tiledata_ram_start_offset = fs.read(layer_metadata_ram_pointer, 16).unpack("CCvVVV")
    
    if width > 15 || height > 15
      raise LayerReadError.new("Invalid layer size: #{width}x#{height}")
    end
  end
  
  def read_from_layer_tiledata
    if layer_tiledata_ram_start_offset.nil?
      return # TODO
    end
    
    tile_data_string = fs.read(layer_tiledata_ram_start_offset, SIZE_OF_A_SCREEN_IN_BYTES*width*height)
    @tiles = tile_data_string.unpack("v*").map do |tile_data|
      Layer.tile_class.new.from_game_data(tile_data)
    end
  end
  
  def write_to_rom
    room.sector.load_necessary_overlay()
    
    # Clamp width/height to valid values.
    @width = [@width, 15].min
    @width = [@width, 1].max
    @height = [@height, 15].min
    @height = [@height, 1].max
    
    old_width, old_height = fs.read(layer_metadata_ram_pointer,2).unpack("C*")
    
    if (width*height) > (old_width*old_height)
      # Size of layer was increased. Repoint to end of file so nothing is overwritten.
      
      blocks_in_room = width * 16 * height * 12
      bytes_in_tiledata = blocks_in_room * 2
      
      new_tiledata_ram_pointer = fs.expand_file_and_get_end_of_file_ram_address(layer_tiledata_ram_start_offset, bytes_in_tiledata)
      fs.write(layer_metadata_ram_pointer+12, [new_tiledata_ram_pointer].pack("V"))
      @layer_tiledata_ram_start_offset = new_tiledata_ram_pointer
    end
    
    if width != old_width || height != old_height
      old_width_in_blocks = old_width * 16
      width_in_blocks = width * 16
      height_in_blocks = height * 12
      
      if old_width_in_blocks == 0
        # New layer.
        tile_rows = []
      else
        tile_rows = tiles.each_slice(old_width_in_blocks).to_a
      end
      
      # Truncate the layer vertically if the layer's height was decreased.
      tile_rows = tile_rows[0, height_in_blocks]
      
      (height_in_blocks - tile_rows.length).times do
        # Pad the layer with empty blocks vertically if layer's height was increased.
        new_row = []
        width_in_blocks.times do
          new_row << Layer.tile_class.new.from_game_data(0)
        end
        tile_rows << new_row
      end
      
      tile_rows.map! do |row|
        # Truncate the layer horizontally if the layer's width was decreased.
        row = row[0, width_in_blocks]
        
        (width_in_blocks - row.length).times do
          # Pad the layer with empty blocks horizontally if layer's width was increased.
          row << Layer.tile_class.new.from_game_data(0)
        end
        
        row
      end
      
      @tiles = tile_rows.flatten
    end
    
    fs.write(layer_metadata_ram_pointer, [width, height].pack("CC"))
    fs.write(layer_metadata_ram_pointer+4, [tileset_pointer, collision_tileset_pointer].pack("VV"))
    fs.write(layer_list_entry_ram_pointer, [z_index, scroll_mode].pack("CC"))
    if SYSTEM == :nds
      fs.write(layer_list_entry_ram_pointer+2, [opacity].pack("C"))
      fs.write(layer_list_entry_ram_pointer+6, [height*0xC0].pack("v")) if GAME == "dos"
      fs.write(layer_list_entry_ram_pointer+8, [main_gfx_page_index].pack("C"))
      fs.write(layer_list_entry_ram_pointer+12, [layer_metadata_ram_pointer].pack("V"))
    else
      fs.write(layer_list_entry_ram_pointer+2, [bg_control].pack("v"))
      #fs.write(layer_list_entry_ram_pointer+6, [height*0x100].pack("v")) if GAME == "aos" # TODO CHECK
      fs.write(layer_list_entry_ram_pointer+4, [main_gfx_page_index].pack("C"))
      fs.write(layer_list_entry_ram_pointer+8, [layer_metadata_ram_pointer].pack("V"))
    end
    tile_data = tiles.map(&:to_tile_data).pack("v*")
    fs.write(layer_tiledata_ram_start_offset, tile_data)
  end
  
  def self.tile_class
    if SYSTEM == :nds
      Tile
    else
      GBATile
    end
  end
  
  def colors_per_palette
    main_gfx_page = room.gfx_pages[main_gfx_page_index]
    
    if main_gfx_page
      main_gfx_page.colors_per_palette
    else
      16
    end
  end
  
  def tileset_filename
    "tileset_%08X_%08X_%08X" % [tileset_pointer, room.palette_wrapper_pointer || 0, @room.gfx_list_pointer]
  end
end

class Tile
  attr_accessor :index_on_tileset,
                :horizontal_flip,
                :vertical_flip
  
  def from_game_data(tile_data)
    @index_on_tileset = (tile_data & 0b0011111111111111)
    @horizontal_flip  = (tile_data & 0b0100000000000000) != 0
    @vertical_flip    = (tile_data & 0b1000000000000000) != 0
    
    return self
  end
  
  def to_tile_data
    tile_data = index_on_tileset
    tile_data |= 0b0100000000000000 if horizontal_flip
    tile_data |= 0b1000000000000000 if vertical_flip
    tile_data
  end
end

class GBATile
  attr_accessor :index_on_tileset,
                :horizontal_flip,
                :vertical_flip,
                :unknown
  
  def from_game_data(tile_data)
    @index_on_tileset = (tile_data & 0b0000000011111111)
    @unknown          = (tile_data & 0b0011111100000000)
    @horizontal_flip  = (tile_data & 0b0100000000000000) != 0
    @vertical_flip    = (tile_data & 0b1000000000000000) != 0
    
    return self
  end
  
  def to_tile_data
    tile_data = index_on_tileset
    tile_data |= 0b0100000000000000 if horizontal_flip
    tile_data |= 0b1000000000000000 if vertical_flip
    tile_data
  end
end
