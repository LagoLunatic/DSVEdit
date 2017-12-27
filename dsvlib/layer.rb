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
                :visual_effect,
                :tileset_type,
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
    elsif GAME == "aos"
      @z_index, @scroll_mode, @bg_control, 
        @main_gfx_page_index, _, _, _,
        @layer_metadata_ram_pointer = fs.read(layer_list_entry_ram_pointer, 12).unpack("CCvCCCCV")
      @opacity = 0x1F
    elsif GAME == "hod"
      @z_index, @visual_effect, @bg_control,
        @layer_metadata_ram_pointer = fs.read(layer_list_entry_ram_pointer, 8).unpack("CCvV")
      @main_gfx_page_index = 0 # TODO
      @scroll_mode = 0 # TODO
      @opacity = 0x1F
      if visual_effect == 0xD
        @opacity = 0x0F
      end
    end
  end
  
  def read_from_layer_metadata
    if layer_metadata_ram_pointer == 0
      # Empty GBA layer.
      @width = @height = 1
      @tileset_type =
        @tileset_pointer =
        @collision_tileset_pointer =
        @layer_tiledata_ram_start_offset = 0
      return
    end
    
    @width, @height, @tileset_type,
      @tileset_pointer,
      @collision_tileset_pointer,
      @layer_tiledata_ram_start_offset = fs.read(layer_metadata_ram_pointer, 16).unpack("CCvVVV")
    
    if width > 15 || height > 15
      raise LayerReadError.new("Invalid layer size: #{width}x#{height}")
    end
  end
  
  def read_from_layer_tiledata
    if layer_tiledata_ram_start_offset == 0
      # Empty GBA layer.
      @tiles = []
      (@height*SCREEN_HEIGHT_IN_TILES*@width*SCREEN_WIDTH_IN_TILES).times do
        @tiles << LayerTile.new.from_game_data(0)
      end
      return
    end
    
    tile_data_string = fs.read(layer_tiledata_ram_start_offset, SIZE_OF_A_SCREEN_IN_BYTES*width*height)
    @tiles = tile_data_string.unpack("v*").map do |tile_data|
      LayerTile.new.from_game_data(tile_data)
    end
  end
  
  def write_to_rom
    room.sector.load_necessary_overlay()
    
    # Clamp width/height to valid values.
    @width = [@width, 15].min
    @width = [@width, 1].max
    @height = [@height, 15].min
    @height = [@height, 1].max
    
    old_width, old_height = fs.read(layer_metadata_ram_pointer, 2).unpack("C*")
    
    if layer_tiledata_ram_start_offset.nil?
      # This is a newly added layer.
      new_tiledata_length = width * height * SIZE_OF_A_SCREEN_IN_BYTES
      
      new_tiledata_ram_pointer = fs.get_free_space(new_tiledata_length, room.overlay_id)
      
      fs.write(layer_metadata_ram_pointer+12, [new_tiledata_ram_pointer].pack("V"))
      @layer_tiledata_ram_start_offset = new_tiledata_ram_pointer
    elsif (width*height) > (old_width*old_height)
      # Size of layer was increased. Repoint to free space so nothing is overwritten.
      
      old_tiledata_length = old_width * old_height * SIZE_OF_A_SCREEN_IN_BYTES
      new_tiledata_length = width * height * SIZE_OF_A_SCREEN_IN_BYTES
      
      new_tiledata_ram_pointer = fs.free_old_space_and_find_new_free_space(layer_tiledata_ram_start_offset, old_tiledata_length, new_tiledata_length, room.overlay_id)
      
      fs.write(layer_metadata_ram_pointer+12, [new_tiledata_ram_pointer].pack("V"))
      @layer_tiledata_ram_start_offset = new_tiledata_ram_pointer
    elsif (width*height) < (old_width*old_height)
      old_tiledata_length = old_width * old_height * SIZE_OF_A_SCREEN_IN_BYTES
      new_tiledata_length = width * height * SIZE_OF_A_SCREEN_IN_BYTES
      
      fs.free_unused_space(layer_tiledata_ram_start_offset + new_tiledata_length, old_tiledata_length - new_tiledata_length)
    end
    
    if width != old_width || height != old_height
      old_width_in_blocks = old_width * SCREEN_WIDTH_IN_TILES
      width_in_blocks = width * SCREEN_WIDTH_IN_TILES
      height_in_blocks = height * SCREEN_HEIGHT_IN_TILES
      
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
          new_row << LayerTile.new.from_game_data(0)
        end
        tile_rows << new_row
      end
      
      tile_rows.map! do |row|
        # Truncate the layer horizontally if the layer's width was decreased.
        row = row[0, width_in_blocks]
        
        (width_in_blocks - row.length).times do
          # Pad the layer with empty blocks horizontally if layer's width was increased.
          row << LayerTile.new.from_game_data(0)
        end
        
        row
      end
      
      @tiles = tile_rows.flatten
    end
    
    fs.write(layer_metadata_ram_pointer, [width, height, tileset_type].pack("CCv"))
    fs.write(layer_metadata_ram_pointer+4, [tileset_pointer, collision_tileset_pointer].pack("VV"))
    fs.write(layer_list_entry_ram_pointer, [z_index].pack("C"))
    if SYSTEM == :nds
      fs.write(layer_list_entry_ram_pointer+1, [scroll_mode].pack("C"))
      fs.write(layer_list_entry_ram_pointer+2, [opacity].pack("C"))
      fs.write(layer_list_entry_ram_pointer+6, [height*0xC0].pack("v")) if GAME == "dos"
      fs.write(layer_list_entry_ram_pointer+8, [main_gfx_page_index].pack("C"))
      fs.write(layer_list_entry_ram_pointer+12, [layer_metadata_ram_pointer].pack("V"))
    elsif GAME == "aos"
      fs.write(layer_list_entry_ram_pointer+1, [scroll_mode].pack("C"))
      fs.write(layer_list_entry_ram_pointer+2, [bg_control].pack("v"))
      fs.write(layer_list_entry_ram_pointer+6, [height*0x100].pack("v")) # Unlike in DoS this doesn't seem necessary for jumpthrough platforms to work, but do it anyway.
      fs.write(layer_list_entry_ram_pointer+4, [main_gfx_page_index].pack("C"))
      fs.write(layer_list_entry_ram_pointer+8, [layer_metadata_ram_pointer].pack("V"))
    else # HoD
      fs.write(layer_list_entry_ram_pointer+1, [visual_effect].pack("C"))
      fs.write(layer_list_entry_ram_pointer+2, [bg_control].pack("v"))
      fs.write(layer_list_entry_ram_pointer+4, [layer_metadata_ram_pointer].pack("V"))
    end
    tile_data = tiles.map(&:to_tile_data).pack("v*")
    fs.write(layer_tiledata_ram_start_offset, tile_data)
  end
  
  def self.layer_list_entry_size
    if SYSTEM == :nds
      16
    elsif GAME == "aos"
      12
    else # HoD
      8
    end
  end
  
  def colors_per_palette
    if SYSTEM == :nds
      main_gfx_page = room.gfx_pages[main_gfx_page_index]
      
      if main_gfx_page
        main_gfx_page.colors_per_palette
      else
        16
      end
    else
      if bg_control & 0x80 > 0
        256
      else
        16
      end
    end
  end
  
  def tileset_filename
    "%08X-%08X_%08X-%02X_%08X" % [tileset_pointer, collision_tileset_pointer, room.palette_wrapper_pointer || 0, room.palette_page_index, @room.gfx_list_pointer]
  end
end

class LayerTile
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
