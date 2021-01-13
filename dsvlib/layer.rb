
class BGLayer
  class LayerReadError < StandardError ; end
  
  attr_reader :fs,
              :overlay_id
  attr_accessor :layer_metadata_ram_pointer,
                :width,
                :height,
                :tileset_type,
                :tileset_pointer,
                :collision_tileset_pointer,
                :layer_tiledata_ram_start_offset,
                :tiles
  
  def initialize(layer_metadata_ram_pointer, fs, overlay_id: nil)
    @layer_metadata_ram_pointer = layer_metadata_ram_pointer
    @fs = fs
    @overlay_id = overlay_id
  end
  
  def read_from_rom
    read_from_layer_metadata()
    read_from_layer_tiledata()
  end
  
  def read_from_layer_metadata
    if layer_metadata_ram_pointer == 0
      # Empty layer.
      @width = @height = 1
      @tileset_type =
        @tileset_pointer =
        @collision_tileset_pointer = 0
      @layer_tiledata_ram_start_offset = nil
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
    if layer_tiledata_ram_start_offset.nil?
      # Empty layer.
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
  
  def write_to_rom(default_tileset_pointer: 0, default_tileset_type: 0, layer_metadata_duplicated: false)
    # Clamp width/height to valid values.
    @width = [@width, 15].min
    @width = [@width, 1].max
    @height = [@height, 15].min
    @height = [@height, 1].max
    
    if layer_metadata_ram_pointer == 0
      # Empty layer.
      old_width = old_height = 1
      
      all_tiles_blank = @tiles.all?{|tile| tile.to_tile_data == 0}
      
      # First detect if the user has changed this layer in a way that it actually needs to have free space assigned for the tile list.
      if @width == old_width && @height == old_height && @tileset_type == 0 && @tileset_pointer == 0 && @collision_tileset_pointer == 0 && @layer_tiledata_ram_start_offset == nil && all_tiles_blank
        # No changes made that require free space.
        return
      else
        # Assign layer metadata in free space.
        @layer_metadata_ram_pointer = fs.get_free_space(16, overlay_id)
        
        if tileset_pointer == 0 && !all_tiles_blank && default_tileset_pointer != 0
          # The user added tiles to this layer in Tiled but did not set the tileset pointer manually.
          # So we automatically set the tileset pointer to a default (the first non-blank tileset in this room).
          @tileset_pointer = default_tileset_pointer
          @tileset_type = default_tileset_type
        end
      end
    elsif layer_metadata_duplicated
      # Layer that was used in two different rooms in the base game.
      
      # First detect if the user has changed this layer compared to how it originally was.
      orig_layer = BGLayer.new(layer_metadata_ram_pointer, fs, overlay_id: overlay_id)
      orig_layer.read_from_rom()
      tile_data_unchanged = (@tiles.map{|tile| tile.to_tile_data} == orig_layer.tiles.map{|tile| tile.to_tile_data})
      @tiles.all?{|tile| tile.to_tile_data == 0}
      if @width == orig_layer.width && @height == orig_layer.height && @tileset_type == orig_layer.tileset_type && @tileset_pointer == orig_layer.tileset_pointer && @collision_tileset_pointer == orig_layer.collision_tileset_pointer && tile_data_unchanged
        # No changes made.
        return
      else
        # Assign new layer metadata in free space.
        @layer_metadata_ram_pointer = fs.get_free_space(16, overlay_id)
        
        @layer_tiledata_ram_start_offset = nil # (This will be handled by the below code.)
      end
      
      old_width, old_height = orig_layer.width, orig_layer.height
    else
      old_width, old_height = fs.read(layer_metadata_ram_pointer, 2).unpack("C*")
    end
    
    if layer_tiledata_ram_start_offset.nil?
      # This is a previously empty layer, or a duplicated layer that needs new space for tile data.
      new_tiledata_length = width * height * SIZE_OF_A_SCREEN_IN_BYTES
      
      new_tiledata_ram_pointer = fs.get_free_space(new_tiledata_length, overlay_id)
      
      fs.write(layer_metadata_ram_pointer+12, [new_tiledata_ram_pointer].pack("V"))
      @layer_tiledata_ram_start_offset = new_tiledata_ram_pointer
    elsif (width*height) > (old_width*old_height)
      # Size of layer was increased. Repoint to free space so nothing is overwritten.
      
      old_tiledata_length = old_width * old_height * SIZE_OF_A_SCREEN_IN_BYTES
      new_tiledata_length = width * height * SIZE_OF_A_SCREEN_IN_BYTES
      
      new_tiledata_ram_pointer = fs.free_old_space_and_find_new_free_space(layer_tiledata_ram_start_offset, old_tiledata_length, new_tiledata_length, overlay_id)
      
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
    
    tile_data = tiles.map(&:to_tile_data).pack("v*")
    fs.write(layer_tiledata_ram_start_offset, tile_data)
  end
  
  def clear_contents
    # Clear out all the tiles.
    (@height*SCREEN_HEIGHT_IN_TILES*@width*SCREEN_WIDTH_IN_TILES).times do |i|
      tiles[i].index_on_tileset = 0
      tiles[i].horizontal_flip = false
      tiles[i].vertical_flip = false
    end
    
    @width = 1
    @height = 1
    
    # We don't clear the tileset that this layer uses, just leave that as it was so it's not blank.
    
    write_to_rom()
  end
end

class RoomLayer
  attr_reader :room,
              :fs,
              :game
  attr_accessor :bg_layer,
                :layer_list_entry_ram_pointer,
                :z_index,
                :scroll_mode,
                :opacity,
                :main_gfx_page_index,
                :palette_offset, # NOTE: Palette offset is not implemented into DSVEdit's GUI, neither for editing nor displaying.
                :bg_control,
                :visual_effect
  
  def initialize(room, layer_list_entry_ram_pointer, game)
    @room = room
    @layer_list_entry_ram_pointer = layer_list_entry_ram_pointer
    @fs = game.fs
    @game = game
  end
    
  def read_from_rom
    read_from_layer_list_entry()
  end
  
  def read_from_layer_list_entry
    if SYSTEM == :nds
      @z_index, @scroll_mode, @opacity, _, @width_in_pixels, @height_in_pixels,
        @main_gfx_page_index, @palette_offset, unknown,
        layer_metadata_ram_pointer = fs.read(layer_list_entry_ram_pointer, 16).unpack("CCCCvvCCvV")
    elsif GAME == "aos"
      @z_index, @scroll_mode, @bg_control, 
        @width_in_pixels, @height_in_pixels,
        layer_metadata_ram_pointer = fs.read(layer_list_entry_ram_pointer, 12).unpack("CCvvvV")
      @main_gfx_page_index = 0
      @opacity = 0x1F
      @palette_offset = 0
    elsif GAME == "hod"
      @z_index, @visual_effect, @bg_control,
        layer_metadata_ram_pointer = fs.read(layer_list_entry_ram_pointer, 8).unpack("CCvV")
      @main_gfx_page_index = 0 # TODO
      @scroll_mode = 0 # TODO
      @palette_offset = 0
      @opacity = 0x1F
      if visual_effect == 0xD
        @opacity = 0x0F
      end
    end
    
    @bg_layer = BGLayer.new(layer_metadata_ram_pointer, fs, overlay_id: room.overlay_id)
    bg_layer.read_from_rom()
  end
  
  def write_to_rom
    # Detect if the tile metadata is used by any other layers in the game.
    # If so the BGLayer will need to assign itself new metadata in free space.
    layer_metadata_duplicated = false
    if layer_metadata_ram_pointer != 0
      room.sector.load_necessary_overlay()
      layer_metadata_path_and_offset = fs.convert_ram_address_to_path_and_offset(self.layer_metadata_ram_pointer)
      game.each_room do |other_room|
        other_room.sector.load_necessary_overlay()
        other_room.layers.each do |layer|
          next if layer.layer_metadata_ram_pointer == 0
          next if layer == self
          
          other_layer_metadata_path_and_offset = fs.convert_ram_address_to_path_and_offset(layer.layer_metadata_ram_pointer)
          if other_layer_metadata_path_and_offset == layer_metadata_path_and_offset
            layer_metadata_duplicated = true
            break
          end
        end
        break if layer_metadata_duplicated
      end
    end
    
    room.sector.load_necessary_overlay()
    
    first_layer_with_valid_tileset = room.layers.find{|layer| layer.tileset_pointer != 0}
    if first_layer_with_valid_tileset
      default_tileset_pointer = first_layer_with_valid_tileset.tileset_pointer
      default_tileset_type = first_layer_with_valid_tileset.tileset_type
    else
      default_tileset_pointer = 0
      default_tileset_type = 0
    end
    
    bg_layer.write_to_rom(
      default_tileset_pointer: default_tileset_pointer,
      default_tileset_type: default_tileset_type,
      layer_metadata_duplicated: layer_metadata_duplicated
    )
    
    write_layer_list_entry_to_rom()
  end
  
  def write_layer_list_entry_to_rom
    fs.write(layer_list_entry_ram_pointer, [z_index].pack("C"))
    if SYSTEM == :nds
      fs.write(layer_list_entry_ram_pointer+1, [scroll_mode].pack("C"))
      fs.write(layer_list_entry_ram_pointer+2, [opacity].pack("C"))
      if GAME == "dos"
        @width_in_pixels = width*SCREEN_WIDTH_IN_PIXELS
        @height_in_pixels = height*SCREEN_HEIGHT_IN_PIXELS
        fs.write(layer_list_entry_ram_pointer+4, [@width_in_pixels].pack("v"))
        fs.write(layer_list_entry_ram_pointer+6, [@height_in_pixels].pack("v"))
      end
      fs.write(layer_list_entry_ram_pointer+8, [main_gfx_page_index].pack("C"))
      fs.write(layer_list_entry_ram_pointer+9, [palette_offset].pack("C"))
      fs.write(layer_list_entry_ram_pointer+12, [layer_metadata_ram_pointer].pack("V"))
    else # GBA
      # Force the screen base block value in the BG control to the correct value.
      # There's no reason the user would need this to be changed to an incorrect value.
      # Also, because of the hack DSVEdit uses for detecting where a door list ends in HoD, we need to be 100% sure the BG control can't resemble the start of a pointer. If the user could change the screen base block freely they could theoretically set it to something that looks like a pointer.
      layer_index = room.layers.index(self)
      @bg_control &= ~0x1F00
      @bg_control |= (0x1D + layer_index) << 8
      
      if GAME == "aos"
        fs.write(layer_list_entry_ram_pointer+1, [scroll_mode].pack("C"))
        fs.write(layer_list_entry_ram_pointer+2, [bg_control].pack("v"))
        
        @width_in_pixels = width*SCREEN_WIDTH_IN_PIXELS
        @height_in_pixels = height*SCREEN_HEIGHT_IN_PIXELS
        fs.write(layer_list_entry_ram_pointer+4, [@width_in_pixels].pack("v"))
        fs.write(layer_list_entry_ram_pointer+6, [@height_in_pixels].pack("v")) # Unlike in DoS this doesn't seem necessary for jumpthrough platforms to work, but do it anyway to be safe.
        
        fs.write(layer_list_entry_ram_pointer+8, [layer_metadata_ram_pointer].pack("V"))
      else # HoD
        fs.write(layer_list_entry_ram_pointer+1, [visual_effect].pack("C"))
        fs.write(layer_list_entry_ram_pointer+2, [bg_control].pack("v"))
        fs.write(layer_list_entry_ram_pointer+4, [layer_metadata_ram_pointer].pack("V"))
      end
    end
  end
  
  def clear_contents
    layer_index = room.layers.index(self)
    @z_index = 0x16 + layer_index
    @scroll_mode = 1
    @opacity = 0x1F
    @bg_control = 0x1D40 + (layer_index << 8)
    if layer_index == 0
      @visual_effect = 1
    else
      @visual_effect = 0
    end
    @main_gfx_page_index = 0
    @palette_offset = 0
    
    @bg_layer.clear_contents()
    write_to_rom()
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
  
  def width
    bg_layer.width
  end
  def width=(val)
    bg_layer.width = val
  end
  
  def height
    bg_layer.height
  end
  def height=(val)
    bg_layer.height = val
  end
  
  def tileset_type
    bg_layer.tileset_type
  end
  def tileset_type=(val)
    bg_layer.tileset_type = val
  end
  
  def tileset_pointer
    bg_layer.tileset_pointer
  end
  def tileset_pointer=(val)
    bg_layer.tileset_pointer = val
  end
  
  def collision_tileset_pointer
    bg_layer.collision_tileset_pointer
  end
  def collision_tileset_pointer=(val)
    bg_layer.collision_tileset_pointer = val
  end
  
  def layer_tiledata_ram_start_offset
    bg_layer.layer_tiledata_ram_start_offset
  end
  def layer_tiledata_ram_start_offset=(val)
    bg_layer.layer_tiledata_ram_start_offset = val
  end
  
  def tiles
    bg_layer.tiles
  end
  def tiles=(val)
    bg_layer.tiles = val
  end
  
  def layer_metadata_ram_pointer
    bg_layer.layer_metadata_ram_pointer
  end
  def layer_metadata_ram_pointer=(val)
    bg_layer.layer_metadata_ram_pointer = val
  end
  
  def opacity
    if GAME == "aos"
      layer_index = room.layers.index(self)
      if room.color_effects & 0xC0 == 0x40 && room.color_effects & 1<<(layer_index+1) > 0
        0x0F
      else
        0x1F
      end
    elsif GAME == "hod"
      layer_index = room.layers.index(self)
      layer_controlling_visual_effect = room.layers.select{|layer| [0x0D, 0x0F].include?(layer.visual_effect)}.last
      if layer_controlling_visual_effect
        if layer_controlling_visual_effect.visual_effect == 0x0D && layer_index == 1
          0x0F
        elsif layer_controlling_visual_effect.visual_effect == 0x0F && layer_index == 0
          0x0F
        else
          0x1F
        end
      else
        0x1F
      end
    else # NDS
      @opacity
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
  
  def gfx_base_block
    if SYSTEM == :nds
      return 0
    else
      return (bg_control & 0x000C) >> 2
    end
  end
  
  def gfx_base_block=(val)
    if SYSTEM == :nds
      # Do nothing
    else
      @bg_control = (@bg_control & ~0x000C) | ((val << 2) & 0x000C)
    end
  end
  
  def tileset_filename
    if tileset_pointer == 0
      # Has no tileset assigned.
      return nil
    end
    
    "%08X-%02X-%08X_%08X-%02X_%08X-%02X" % [
      tileset_pointer, tileset_type, collision_tileset_pointer,
      room.palette_wrapper_pointer || 0, room.palette_page_index,
      @room.gfx_list_pointer, gfx_base_block
    ]
  end
end

class LayerTile
  attr_accessor :index_on_tileset,
                :horizontal_flip,
                :vertical_flip
  
  def from_game_data(tile_data)
    @index_on_tileset = (tile_data & 0b0011111111111111)
    @horizontal_flip  = (tile_data & 0b0100000000000000) > 0
    @vertical_flip    = (tile_data & 0b1000000000000000) > 0
    
    return self
  end
  
  def to_tile_data
    tile_data = index_on_tileset
    tile_data |= 0b0100000000000000 if horizontal_flip
    tile_data |= 0b1000000000000000 if vertical_flip
    tile_data
  end
end
