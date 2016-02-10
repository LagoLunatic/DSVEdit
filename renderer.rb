
require 'chunky_png'

class Renderer
  attr_accessor :rom, :rendered_tilesets_cache, :rendered_tileset_pages_cache, :rendered_tileset_tiles_cache, :rendered_tilesets
  
  def initialize(rom)
    @rom = rom
    @rendered_tilesets_cache = {}
    @rendered_tileset_pages_cache = {} # cache page/palette combinations already rendered so we don't waste time rendering them over and over for every tile.
    @rendered_tileset_tiles_cache = {}
    @rendered_tilesets = {}
  end
  
  def render_room(folder, room)
    rendered_layers = []
    
    room.z_ordered_layers.each do |layer|
      rendered_layers << render_layer(folder, layer, room)
    end
    
    # TODO: find a proper way of determining what the main collision layer is. just looking at the z-index doesn't seem sufficient.

    # make the image encompass all the layers
    max_width = 0
    max_height = 0
    rendered_layers.each do |layer|
      max_width = layer.width if layer.width > max_width
      max_height = layer.height if layer.height > max_height
    end
    
    tile_backgrounds = false
    rendered_level = ChunkyPNG::Image.new(max_width, max_height, ChunkyPNG::Color::BLACK)
    rendered_layers.each do |layer|
      if tile_backgrounds
        # TODO
      else
        rendered_level.compose!(layer)
      end
    end
    
    max_width_in_screens = max_width / SCREEN_WIDTH_IN_PIXELS
    max_height_in_screens = max_height / SCREEN_HEIGHT_IN_PIXELS
    
    filename = "#{folder}/#{room.area_name}/Rendered Rooms/#{room.filename}.png"
    FileUtils::mkdir_p(File.dirname(filename))
    rendered_level.save(filename)
    puts "Wrote #{filename}"
  end
  
  def render_layer(folder, layer, room)
    rendered_layer = ChunkyPNG::Image.new(layer.width*16*16, layer.height*16*12, ChunkyPNG::Color::TRANSPARENT)
    
    tileset_filename = "#{folder}/#{room.area_name}/Tilesets/#{layer.tileset_filename}.png"
    #tileset = get_tileset(layer.pointer_to_tileset_for_layer, room.palette_offset, room.graphic_tilesets_for_room, layer.colors_per_palette, tileset_filename)
    tileset = ChunkyPNG::Image.from_file(tileset_filename)
    #tileset = render_tileset(layer.pointer_to_tileset_for_layer, room.palette_offset, room.graphic_tilesets_for_room, layer.colors_per_palette, tileset_filename)
    
    layer.level_blocks.each_with_index do |block, index_on_level|
      horizontal_flip  = (block & 0b0100000000000000) != 0 # second highest bit controls h. flipping
      vertical_flip    = (block & 0b1000000000000000) != 0
      index_on_tileset = (block & 0b0011111111111111) # get rid of the horizontal/vertical flip bits
      
      # tileset is 16 blocks wide
      tileset_length = 16*64
      
      x_on_tileset = index_on_tileset % 16
      y_on_tileset = index_on_tileset / 16
      x_on_level = index_on_level % (layer.width*16)
      y_on_level = index_on_level / (layer.width*16)
      
      #tile = tileset.export_pixels(x=x_on_tileset*16, y=y_on_tileset*16, columns=16, rows=16, map="RGBA")
      tile = tileset.crop(x_on_tileset*16, y_on_tileset*16, 16, 16)
      
      if horizontal_flip
        tile.mirror!
      end
      if vertical_flip
        tile.flip!
      end
      
      rendered_layer.compose!(tile, x_on_level*16, y_on_level*16)
    end
    
    # TODO: OPACITY
    #layer_opacity_float = layer.opacity / 31.0
    #blank_canvas = Image.new(rendered_layer.columns, rendered_layer.rows) { self.background_color = "none" }
    #blank_canvas.opacity = Magick::QuantumRange - (Magick::QuantumRange * layer_opacity_float)
    ## In order for partial transparency to work correctly, this intermediate step with DstInCompositeOp is necessary.
    #rendered_layer_with_transparency = rendered_layer.composite(blank_canvas, Magick::NorthWestGravity, 0, 0, Magick::DstInCompositeOp)
    return rendered_layer#_with_transparency
  end

  def get_tileset(tileset_offset, palette_offset, graphic_tilesets_for_room, colors_per_palette, output_filename)
    puts "Getting tileset %08X" % tileset_offset
    if rendered_tilesets_cache["#{tileset_offset}_#{palette_offset}_#{graphic_tilesets_for_room}_#{colors_per_palette}"]
      puts "cached"
      return rendered_tilesets_cache["#{tileset_offset}_#{palette_offset}_#{graphic_tilesets_for_room}_#{colors_per_palette}"]
    else
      rendered_tileset = render_tileset(tileset_offset, palette_offset, graphic_tilesets_for_room, colors_per_palette, output_filename)
      @rendered_tilesets_cache["#{tileset_offset}_#{palette_offset}_#{graphic_tilesets_for_room}_#{colors_per_palette}"] = rendered_tileset
      return rendered_tileset
    end
  end
  
  def generate_palettes(palette_data_start_offset, colors_per_palette)
    if palette_data_start_offset.nil?
      palette = [ChunkyPNG::Color.rgba(0, 0, 0, 0)] * colors_per_palette
      palette_list = [palette] * 128 # 128 is the maximum number of palettes
      return palette_list
    end
    
    number_of_palettes = rom[palette_data_start_offset+2,1].unpack("C*").first
    if number_of_palettes == 1
      # When this value is 1, it means this tileset has no palette of its own. Instead it simply leeches off the palette of whatever the previously loaded room was.
      # Since we can't know what room the player was in last, we can instead simply use the palette of whatever room this room's first door leads to.
      # This should work fine in theory. But there's a tiny possibility of one of the first door leading to an unused, inaccessible room, which may not have the right palette.
      
      # TODO: the above can only be done once functions are organized in such a way that we can get the doors for this room and the palette of another room.
      # the below is just a hack. it works for the only room in dawn of sorrow that needs this anyway.
      number_of_palettes = 0x40
      palette_data_start_offset -= 0x804
    end
    
    #puts "graphic_tile_data_start_offset: %08X" % graphic_tile_data_start_offset
    palette_data_start_offset += 4 # Skip the first 4 bytes, as they contain the length of this palette page, not the palette data itself.

    puts "palette_data_start_offset: %08X" % palette_data_start_offset
    palette_list = []
    (0..number_of_palettes*2).each do |palette_index| # todo: cache palettes
      palette_data = rom[palette_data_start_offset + 32*palette_index,colors_per_palette*2]
      palette = palette_data.scan(/.{2}/m).map do |color|
        color = color.unpack("v*").first
        # these two bytes hold the rgb data for the color in this format:
        # ?bbbbbgggggrrrrr
        # the ? is unknown.
        unknown_bit = (color >> 15) & 0b0000_0000_0000_0001
        blue_bits   = (color >> 10) & 0b0000_0000_0001_1111
        green_bits  = (color >> 5)  & 0b0000_0000_0001_1111
        red_bits    =  color        & 0b0000_0000_0001_1111
        
        #if palette_index == 255
        #  unknown_bit = 0
        #  blue_bits = 0
        #  green_bits = 0
        #  red_bits = 0
        #end
        
        red = (red_bits / 32.0 * 255).to_i
        green = (green_bits / 32.0 * 255).to_i
        blue = (blue_bits / 32.0 * 255).to_i
        alpha = 255
        ChunkyPNG::Color.rgba(red, green, blue, alpha)
      end
      palette_list << palette
    end
    
    palette_list
  end
  
  def render_tileset(tileset_offset, palette_offset, graphic_tilesets_for_room, colors_per_palette, output_filename)
    return rendered_tilesets[output_filename] if rendered_tilesets[output_filename]
    
    tileset_width_in_blocks = 16
    tileset_height_in_blocks = 64
    rendered_tileset = ChunkyPNG::Image.new(tileset_width_in_blocks*16, tileset_height_in_blocks*16, ChunkyPNG::Color::TRANSPARENT)

    length_of_tileset_in_bytes = tileset_width_in_blocks*tileset_height_in_blocks*4
    tileset = rom[tileset_offset,length_of_tileset_in_bytes-4]
    #puts "Tileset data starting at %08X" % tileset_offset
    tileset = "\x00\x00\x00\x00" + tileset
    
    #puts "palette_offset: %08X" % (palette_offset || 0)
    palette_list = generate_palettes(palette_offset, colors_per_palette)
    tileset_data = tileset.unpack("C*")

    tileset_data.each_slice(4).each_with_index do |tile_data, i|
      #puts "tile_data: #{tile_data.each_byte.to_a.map{|x| "%02X" % x}}"
      tile_index_on_page, tile_page, extra_bits, palette_index = tile_data
      #puts "palette_index: #{palette_index}"
      
      if tile_index_on_page == 0 && tile_page == 0 && extra_bits == 0 && palette_index == 0
        next # if it's all 0s then it's a blank tile, don't render it at all.
      end
      
      # The bits below are always 00. The below code was ran on every room in the game with no exceptions raised.
      #unknown1 = tile_index_on_page & 0b11000000
      #unknown2 = tile_page & 0b00001111
      #unknown3 = extra_bits & 0b11111000
      #if unknown1 != 0
      #  raise "unknown1: #{unknown1}"
      #end
      #if unknown2 != 0
      #  raise "unknown2: #{unknown2}"
      #end
      #if unknown3 != 0
      #  raise "unknown3: #{unknown3}"
      #end
      
      tile_index_on_page = tile_index_on_page & 0b00111111 # get rid of top 2 bits. they're sometimes set, but they seem to be for something else besides the tile index. TODO: figure out what those 2 are for.
      horizontal_flip = ((extra_bits >> 1) & 0b00000001) != 0
      vertical_flip = ((extra_bits >> 2) & 0b00000001) != 0
      most_significant_bit = extra_bits & 0b00000001
      tile_page = tile_page >> 4
      tile_page = tile_page | (most_significant_bit << 4)
      
      if graphic_tilesets_for_room.nil?
        graphic_tile_data_start_offset = nil
      else
        #puts graphic_tilesets_for_room.inspect
        #puts tile_page.inspect
        graphic_tile_data_start_offset = graphic_tilesets_for_room[tile_page]
        if graphic_tile_data_start_offset.nil?
          #puts "%08X" % (tileset_offset + i*4)
          #puts "graphic_tile_data_start_offset is nil. tile_page: #{tile_page}. length: #{graphic_tilesets_for_room.length}. i: #{i}"
          next # TODO: figure out why this sometimes happens.
        end
      end
      
      #puts "graphic_tile_data_start_offset: %08X" % graphic_tile_data_start_offset
      if palette_index == 0xFF # TODO. 255 seems to have some special meaning besides an actual palette index.
        palette_index = 0x00
      end
      palette = palette_list[palette_index]
      if palette.nil?
        puts "Palette index #{palette_index} out of range"
        next # TODO: figure out why this sometimes happens.
      end
      
      render_mode = :tile
      if render_mode == :page # render the whole tileset page
        cache_key = "#{graphic_tile_data_start_offset}_#{palette_offset}_#{palette.length}_#{palette_index}"
        
        if rendered_tileset_pages_cache[cache_key]
          rendered_graphic_tile_page = rendered_tileset_pages_cache[cache_key]
        else
          rendered_graphic_tile_page = render_graphic_tile_page(graphic_tile_data_start_offset, palette)
          rendered_tileset_pages_cache[cache_key] = rendered_graphic_tile_page
        end
        
        x_block_on_tileset = tile_index_on_page % 8
        y_block_on_tileset = tile_index_on_page / 8
        graphic_tile = rendered_graphic_tile_page.export_pixels(x=x_block_on_tileset*16, y=y_block_on_tileset*16, columns=16, rows=16, map="RGBA")
      else # render just the tile
        #cache_key = "#{graphic_tile_data_start_offset}_#{palette_offset}_#{palette.length}_#{palette_index}_#{tile_index_on_page}"
        
        if false#rendered_tileset_tiles_cache[cache_key]
          graphic_tile = rendered_tileset_tiles_cache[cache_key]
        else
          graphic_tile = render_graphic_tile(graphic_tile_data_start_offset, palette, tile_index_on_page)
          #rendered_tileset_tiles_cache[cache_key] = graphic_tile
        end
        #graphic_tile = render_graphic_tile(graphic_tile_data_start_offset, palette, tile_index_on_page)
        #graphic_tile = graphic_tile.export_pixels(x=0, y=0, columns=16, rows=16, map="RGBA")
      end
      
      if horizontal_flip
        graphic_tile.mirror!
      end
      if vertical_flip
        graphic_tile.flip!
      end
      
      x_on_tileset = i % 16
      y_on_tileset = i / 16
      rendered_tileset.compose!(graphic_tile, x_on_tileset*16, y_on_tileset*16)
    end
    
    FileUtils::mkdir_p(File.dirname(output_filename))
    rendered_tileset.save(output_filename, :fast_rgba)
    puts "Wrote #{output_filename}"
    rendered_tilesets[output_filename] = true
    return rendered_tileset
  end
  
  def render_graphic_tile(graphic_tile_data_start_offset, palette, tile_index_on_page)
    graphic_tile = ChunkyPNG::Image.new(16, 16, ChunkyPNG::Color::TRANSPARENT)
    
    if graphic_tile_data_start_offset.nil?
      # This room has no graphics, so just return a black tile. Could be a save room, warp room, transition room, etc.
      # TODO: instead it would be better to use the debug squares for these rooms so you can see what's what.
      
      graphic_tile = ChunkyPNG::Image.new(16, 16, ChunkyPNG::Color::WHITE)
      return graphic_tile
    end
    
    x_block_on_tileset = tile_index_on_page % 8
    y_block_on_tileset = tile_index_on_page / 8
    if palette.length == 16
      size_of_block_in_bytes = 16 * 16 / 2 # 16 pixels tall, 16 pixels wide, each byte has 2 pixels in it
    elsif palette.length == 256
      size_of_block_in_bytes = 16 * 16 # 16 pixels tall, 16 pixels wide, each byte has 1 pixel in it
    else
      raise "Unknown palette length: #{palette.length}"
    end
    size_of_row_in_bytes = 8 * size_of_block_in_bytes
    row_of_graphic_tiles = rom[graphic_tile_data_start_offset + y_block_on_tileset*size_of_row_in_bytes, size_of_row_in_bytes]
    
    if palette.length == 16
      x = 8
    elsif palette.length == 256
      x = 16
    else
      raise "Unknown palette length: #{palette.length}"
    end
    
    i = 0
    j = 0
    row_of_graphic_tiles.each_byte do |byte|
      if ((i / x) % 8) != x_block_on_tileset
        i += 1
        next
      end
      
      if palette.length == 16
        pixels = [byte & 0b00001111, byte >> 4] # get the low 4 bits, then the high 4 bits (it's reversed). each is one pixel, two pixels total inside this byte.
      elsif palette.length == 256
        pixels = [byte]
      else
        raise "Unknown palette length: #{palette.length}"
      end
      
      pixels.each do |pixel|
        x_pixel_on_tile = j % 16
        y_pixel_on_tile = j / 16
        j += 1
        
        pixel = pixel % palette.length # REMOVEME, HACK, DON'T KNOW WHY THIS IS NECESSARY
        if pixel >= palette.length
          raise "Pixel value #{pixel} larger than palette length #{palette.length}"
        end
        pixel_color = palette[pixel]
        if pixel == 0
          alpha_percent = 0
        else
          alpha_percent = 1.0
        end

        graphic_tile[x_pixel_on_tile,y_pixel_on_tile] = pixel_color unless alpha_percent == 0
      end
      
      i += 1
    end
    
    return graphic_tile
  end
  
  def render_graphic_tile_page(graphic_tile_data_start_offset, palette)
    #puts "graphic_tile_data_start_offset: %08X" % graphic_tile_data_start_offset
    page_of_graphic_tiles = rom[graphic_tile_data_start_offset, 1024*16] # row is 1024 bytes long, 16 rows in a page
    rendered_page = Image.new(128,128) do
      self.background_color = "rgba(0,0,0,0)" # transparent background
    end
    
    pixels_for_rmagick = []
    i = 0
    page_of_graphic_tiles.each_byte do |byte|
      if palette.length == 16
        pixels = [byte & 0b00001111, byte >> 4] # get the low 4 bits, then the high 4 bits (it's reversed). each is one pixel, two pixels total inside this byte.
      elsif palette.length == 256
        pixels = [byte]
      else
        raise "Unknown palette length: #{palette.length}"
      end
      pixels.each do |pixel|
        x_pixel_on_tileset = i % 128
        y_pixel_on_tileset = i / 128
        i += 1
        
        pixel = pixel % palette.length # REMOVEME, HACK, DON'T KNOW WHY THIS IS NECESSARY
        if pixel >= palette.length
          raise "Pixel value #{pixel} larger than palette length #{palette.length}"
        end
        pixel_color = palette[pixel]
        if pixel == 0
          alpha_percent = 0
          #next
        else
          alpha_percent = 1.0#100
        end
        # each of the three colors are 5 bits long, so their value can be between 0 and 31 (in hex it's 0x00 and 0x1F).
        #pixel_color[:unknown].to_f / 1 * 100
        red_percent = pixel_color[:red].to_f / 31 #* 100
        green_percent = pixel_color[:green].to_f / 31 #* 100
        blue_percent = pixel_color[:blue].to_f / 31 #* 100

        #rendered_page.pixel_color(x_pixel_on_tileset, y_pixel_on_tileset, "rgba(#{red_percent}%,#{green_percent}%,#{blue_percent}%,#{alpha_percent}%)")
        pixels_for_rmagick << red_percent * Magick::QuantumRange
        pixels_for_rmagick << green_percent * Magick::QuantumRange
        pixels_for_rmagick << blue_percent * Magick::QuantumRange
        pixels_for_rmagick << alpha_percent * Magick::QuantumRange
      end
    end
    
    #rendered_page.write("rendered_page_#{graphic_tile_data_start_offset}.png")
    #FileUtils.mv("rendered_page_#{graphic_tile_data_start_offset}.png", "./Tilesets & Rendered Rooms/rendered_page_#{graphic_tile_data_start_offset}.png")
    #puts "Wrote " + "rendered_page_#{graphic_tile_data_start_offset}.png"
    rendered_page.import_pixels(x=0, y=0, columns=128, rows=128, map="RGBA", pixels_for_rmagick, type=CharPixel)
    return rendered_page
  end
  
  def render_map(map, folder, area_index)
    map_width_in_blocks = 64
    map_height_in_blocks = 48
    fill_img = Image.new(map_width_in_blocks*4, map_height_in_blocks*4) { self.background_color = "none" }
    lines_img = Image.new(map_width_in_blocks*4, map_height_in_blocks*4) { self.background_color = "none" }
    
    fill_color          = MAP_FILL_COLOR         .map{|v| v / 255.0 * Magick::QuantumRange}
    save_fill_color     = MAP_SAVE_FILL_COLOR    .map{|v| v / 255.0 * Magick::QuantumRange}
    warp_fill_color     = MAP_WARP_FILL_COLOR    .map{|v| v / 255.0 * Magick::QuantumRange}
    entrance_fill_color = MAP_ENTRANCE_FILL_COLOR.map{|v| v / 255.0 * Magick::QuantumRange}
    line_color          = MAP_LINE_COLOR         .map{|v| v / 255.0 * Magick::QuantumRange}
    door_color          = MAP_DOOR_COLOR         .map{|v| v / 255.0 * Magick::QuantumRange}
    
    # 25 pixels per tile. though they overlap, so the left and top of a tile overlaps the right and bottom of other tiles.
    i = 0
    map.tiles.each do |tile|
      if tile[:is_blank] && !tile[:left_door] && !tile[:left_wall] && !tile[:top_door] && !tile[:top_wall] && !tile[:right_door] && !tile[:right_wall] && !tile[:bottom_door] && !tile[:bottom_wall]
        i += 1
        next
      end
      
      if tile[:is_blank]
        fill_pixels = [[0,0,0,0]]*25
      elsif tile[:is_entrance]
        fill_pixels = [entrance_fill_color]*25
      elsif tile[:is_warp]
        fill_pixels = [warp_fill_color]*25
      elsif tile[:is_save]
        fill_pixels = [save_fill_color]*25
      else
        fill_pixels = [fill_color]*25
      end
      
      line_pixels = [[0,0,0,0]]*25
      
      if GAME == "dos"
        if tile[:left_door]
          line_pixels[0] = line_color
          (5..19).step(5) do |i|
            line_pixels[i] = door_color
          end
          line_pixels[20] = line_color
        elsif tile[:left_wall]
          (0..24).step(5) do |i|
            line_pixels[i] = line_color
          end
        end
        
        if tile[:top_door]
          line_pixels[0] = line_color
          (1..3).each do |i|
            line_pixels[i] = door_color
          end
          line_pixels[4] = line_color
        elsif tile[:top_wall]
          (0..4).each do |i|
            line_pixels[i] = line_color
          end
        end
        
      elsif GAME == "por" || GAME == "ooe"
        if tile[:left_door]
          (0..24).step(5) do |i|
            next if i == 10
            line_pixels[i] = door_color
          end
        elsif tile[:left_wall]
          (0..24).step(5) do |i|
            line_pixels[i] = line_color
          end
        end
        
        if tile[:right_door] # Never used in game because it would always get overwritten by the tile to the right.
          (4..24).step(5) do |i|
            next if i == 14
            line_pixels[i] = door_color
          end
        elsif tile[:right_wall]
          (4..24).step(5) do |i|
            line_pixels[i] = line_color
          end
        end
        
        if tile[:top_door]
          (0..4).each do |i|
            next if i == 2
            line_pixels[i] = door_color
          end
        elsif tile[:top_wall]
          (0..4).each do |i|
            line_pixels[i] = line_color
          end
        end
        
        if tile[:bottom_door] # Never used in game because it would always get overwritten by the tile below.
          (20..24).each do |i|
            next if i == 22
            line_pixels[i] = door_color
          end
        elsif tile[:bottom_wall]
          (20..24).each do |i|
            line_pixels[i] = line_color
          end
        end
      end
      
      fill_img.import_pixels(x=tile[:x_pos]*4, y=tile[:y_pos]*4, columns=5, rows=5, map="RGBA", fill_pixels.flatten, type=CharPixel)
      drawn_tile = Image.new(5,5) { self.background_color = "none" }
      drawn_tile.import_pixels(0, 0, columns=5, rows=5, map="RGBA", line_pixels.flatten, type=CharPixel)
      lines_img.composite!(drawn_tile, tile[:x_pos]*4, tile[:y_pos]*4, OverCompositeOp)
      
      i += 1
    end
    
    img = Image.new(map_width_in_blocks*4, map_height_in_blocks*4) { self.background_color = "none" }
    img.composite!(fill_img, 0, 0, OverCompositeOp)
    img.composite!(lines_img, 0, 0, OverCompositeOp)
    img.resize!(map_width_in_blocks*4*3, map_height_in_blocks*4*3, filter=PointFilter)
    
    FileUtils::mkdir_p(folder)
    img.write("#{folder}/map-#{area_index}.png")
  end
end
