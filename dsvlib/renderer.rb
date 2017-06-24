
require 'oily_png'

class Renderer
  COLLISION_SOLID_COLOR = ChunkyPNG::Color::BLACK
  COLLISION_SEMISOLID_COLOR = ChunkyPNG::Color.rgba(127, 127, 127, 255)
  COLLISION_DAMAGE_COLOR = ChunkyPNG::Color.rgba(208, 32, 32, 255)
  COLLISION_WATER_COLOR = ChunkyPNG::Color.rgba(32, 32, 208, 255)
  COLLISION_CONVEYOR_COLOR = ChunkyPNG::Color.rgba(32, 208, 32, 255)
  
  class GFXImportError < StandardError ; end
  
  attr_reader :fs,
              :fill_color,
              :save_fill_color,
              :warp_fill_color,
              :secret_fill_color,
              :entrance_fill_color,
              :transition_fill_color,
              :line_color,
              :door_color,
              :door_center_color,
              :secret_door_color,
              :wall_pixels,
              :door_pixels,
              :secret_door_pixels
              
  def initialize(fs)
    @fs = fs
  end
  
  def render_room(folder, room, collision = false)
    rendered_layers = []
    
    if collision
      rendered_layers << render_layer(folder, layers.first, room, collision)
    else
      room.z_ordered_layers.each do |layer|
        rendered_layers << render_layer(folder, layer, room, collision)
      end
    end
    
    if collision
      bg_color = ChunkyPNG::Color::WHITE
    else
      bg_color = ChunkyPNG::Color::BLACK
    end
    
    rendered_level = ChunkyPNG::Image.new(room.max_layer_width*SCREEN_WIDTH_IN_PIXELS, room.max_layer_height*SCREEN_HEIGHT_IN_PIXELS, bg_color)
    rendered_layers.each do |layer|
      rendered_level.compose!(layer)
    end
    
    if collision
      filename = "#{folder}/#{room.area_name}/Rendered Rooms/#{room.filename}_collision.png"
    else
      filename = "#{folder}/#{room.area_name}/Rendered Rooms/#{room.filename}.png"
    end
    FileUtils::mkdir_p(File.dirname(filename))
    rendered_level.save(filename)
    puts "Wrote #{filename}"
  end
  
  def render_layer(folder, layer, room, collision = false)
    rendered_layer = ChunkyPNG::Image.new(layer.width*SCREEN_WIDTH_IN_PIXELS, layer.height*SCREEN_HEIGHT_IN_PIXELS, ChunkyPNG::Color::TRANSPARENT)
    
    tileset_filename = "#{folder}/#{room.area_name}/Tilesets/#{layer.tileset_filename}.png"
    fs.load_overlay(AREA_INDEX_TO_OVERLAY_INDEX[room.area_index][room.sector_index])
    if collision
      tileset_filename = "#{folder}/#{room.area_name}/Tilesets/#{layer.tileset_filename}_collision.png"
      tileset = render_collision_tileset(layer.collision_tileset_pointer, tileset_filename)
    else
      tileset = get_tileset(layer.tileset_pointer, layer.tileset_type, room.palette_pages, room.graphic_tilesets_for_room, layer.colors_per_palette, layer.collision_tileset_pointer, tileset_filename)
    end
    
    layer.tiles.each_with_index do |tile, index_on_level|
      x_on_tileset = tile.index_on_tileset % TILESET_WIDTH_IN_TILES
      y_on_tileset = tile.index_on_tileset / TILESET_WIDTH_IN_TILES
      x_on_level = index_on_level % (layer.width*SCREEN_WIDTH_IN_TILES)
      y_on_level = index_on_level / (layer.width*SCREEN_WIDTH_IN_TILES)
      
      tile_gfx = tileset.crop(x_on_tileset*TILE_WIDTH, y_on_tileset*TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)
      
      if tile.horizontal_flip
        tile_gfx.mirror!
      end
      if tile.vertical_flip
        tile_gfx.flip!
      end
      
      rendered_layer.compose!(tile_gfx, x_on_level*TILE_WIDTH, y_on_level*TILE_HEIGHT)
    end
    
    # TODO: OPACITY
    return rendered_layer
  end
  
  def get_tileset(pointer_to_tileset_for_layer, tileset_type, palette_pages, gfx_pages, colors_per_palette, collision_tileset_offset, tileset_filename)
    if File.exist?(tileset_filename)
      ChunkyPNG::Image.from_file(tileset_filename)
    else
      render_tileset(pointer_to_tileset_for_layer, tileset_type, palette_pages, gfx_pages, colors_per_palette, collision_tileset_offset, tileset_filename)
    end
  end
  
  def ensure_tilesets_exist(folder, room, collision=false)
    room.layers.each do |layer|
      next if layer.layer_metadata_ram_pointer == 0 # TODO
      
      tileset_filename = "#{folder}/#{room.area_name}/Tilesets/#{layer.tileset_filename}.png"
      if !File.exist?(tileset_filename)
        render_tileset(layer.tileset_pointer, layer.tileset_type, room.palette_pages, room.gfx_pages, layer.colors_per_palette, layer.collision_tileset_pointer, tileset_filename)
      end
      
      if collision
        collision_tileset_filename = "#{folder}/#{room.area_name}/Tilesets/#{layer.tileset_filename}_collision.png"
        
        if !File.exist?(collision_tileset_filename)
          render_collision_tileset(layer.collision_tileset_pointer, collision_tileset_filename)
        end
      end
    end
  end
  
  def render_tileset(tileset_offset, tileset_type, palette_pages, gfx_pages, colors_per_palette, collision_tileset_offset, output_filename=nil)
    if SYSTEM == :nds
      render_tileset_nds(tileset_offset, tileset_type, palette_pages, gfx_pages, colors_per_palette, collision_tileset_offset, output_filename)
    else
      render_tileset_gba(tileset_offset, tileset_type, palette_pages, gfx_pages, colors_per_palette, collision_tileset_offset, output_filename)
    end
  end
  
  def render_tileset_nds(tileset_offset, tileset_type, palette_pages, gfx_pages, colors_per_palette, collision_tileset_offset, output_filename=nil)
    if gfx_pages.empty?
      return render_collision_tileset(collision_tileset_offset, output_filename)
    end
    
    tileset = Tileset.new(tileset_offset, tileset_type, fs)
    rendered_tileset = ChunkyPNG::Image.new(TILESET_WIDTH_IN_TILES*16, TILESET_HEIGHT_IN_TILES*16, ChunkyPNG::Color::TRANSPARENT)
    palette_list = generate_palettes(palette_pages.first.palette_list_pointer, 16)
    gfx_wrappers = gfx_pages.map{|gfx_page| gfx_page.gfx_wrapper}
    if gfx_wrappers.any?{|gfx| gfx.colors_per_palette == 256}
      palette_list_256 = generate_palettes(palette_pages.first.palette_list_pointer, 256)
    end
    
    tileset.tiles.each_with_index do |tile, index_on_tileset|
      if tile.is_blank
        next
      end
      
      gfx = gfx_wrappers[tile.tile_page]
      if gfx.nil?
        next # TODO: figure out why this sometimes happens.
      end
      
      if tile.palette_index == 0xFF # TODO. 255 seems to have some special meaning besides an actual palette index.
        puts "Palette index is 0xFF, tileset #{output_filename}"
        next
      end
      
      if gfx.colors_per_palette == 16
        palette = palette_list[tile.palette_index]
      else
        palette = palette_list_256[tile.palette_index]
      end
      if palette.nil?
        puts "Palette index #{tile.palette_index} out of range, tileset #{output_filename}"
        next # TODO: figure out why this sometimes happens.
      end
      
      graphic_tile = render_graphic_tile(gfx.file, palette, tile.index_on_tile_page)
      
      if tile.horizontal_flip
        graphic_tile.mirror!
      end
      if tile.vertical_flip
        graphic_tile.flip!
      end
      
      x_on_tileset = index_on_tileset % 16
      y_on_tileset = index_on_tileset / 16
      rendered_tileset.compose!(graphic_tile, x_on_tileset*16, y_on_tileset*16)
    end
    
    if output_filename
      FileUtils::mkdir_p(File.dirname(output_filename))
      rendered_tileset.save(output_filename, :fast_rgba)
      puts "Wrote #{output_filename}"
    end
    return rendered_tileset
  end
  
  def render_tileset_gba(tileset_offset, tileset_type, palette_pages, gfx_pages, colors_per_palette, collision_tileset_offset, output_filename=nil)
    if gfx_pages.empty?
      return render_collision_tileset(collision_tileset_offset, output_filename)
    end
    
    tileset = Tileset.new(tileset_offset, tileset_type, fs)
    rendered_tileset = ChunkyPNG::Image.new(TILESET_WIDTH_IN_TILES*TILE_WIDTH, TILESET_HEIGHT_IN_TILES*TILE_HEIGHT, ChunkyPNG::Color::TRANSPARENT)
    palettes = []
    palette_pages.each do |palette_page|
      pals_for_page = generate_palettes(palette_page.palette_list_pointer, colors_per_palette)
      
      palettes[palette_page.palette_load_offset, palette_page.num_palettes] = pals_for_page[palette_page.palette_index, palette_page.num_palettes]
    end
    
    gfx_chunks = []
    gfx_wrappers = []
    gfx_pages.each do |gfx_page|
      gfx_wrappers << gfx_page.gfx_wrapper
      gfx_wrapper_index = gfx_wrappers.length-1
      
      gfx_page.num_chunks.times do |i|
        if gfx_page.gfx_load_offset < 0x10
          puts "Unknown gfx load offset: %02X" % gfx_page.gfx_load_offset
          next
        end
        gfx_chunks[gfx_page.gfx_load_offset-0x10+i] = [gfx_wrapper_index, gfx_page.first_chunk_index+i]
      end
    end

    tileset.tiles.each_with_index do |tile, index_on_tileset|
      if tile.is_blank
        next
      end
      
      rendered_tile = ChunkyPNG::Image.new(32, 32)
      minitile_x = 0
      minitile_y = 0
      tile.minitiles.each do |minitile|
        x_on_gfx_page = minitile.index_on_tile_page % 16
        y_on_gfx_page = minitile.index_on_tile_page / 16
        
        if minitile.tile_page >= gfx_wrappers.length
          rendered_minitile = ChunkyPNG::Image.new(8, 8, ChunkyPNG::Color.rgba(255, 0, 0, 255))
        else
          gfx_chunk_index_on_page = (minitile.index_on_tile_page & 0xC0) >> 6
          gfx_chunk_index = minitile.tile_page*4 + gfx_chunk_index_on_page
          gfx_wrapper_index, chunk_offset = gfx_chunks[gfx_chunk_index]
          break if chunk_offset.nil?
          minitile_index_on_page = minitile.index_on_tile_page & 0x3F
          minitile_index_on_page += chunk_offset * 0x40
          
          gfx_page = gfx_wrappers[gfx_wrapper_index]
          palette = palettes[minitile.palette_index]
          
          rendered_minitile = render_1_dimensional_minitile(gfx_page, palette, minitile_index_on_page)
        end
        
        if minitile.horizontal_flip
          rendered_minitile.mirror!
        end
        if minitile.vertical_flip
          rendered_minitile.flip!
        end
        rendered_tile.compose!(rendered_minitile, minitile_x*8, minitile_y*8)
        minitile_x += 1
        if minitile_x > 3
          minitile_x = 0
          minitile_y += 1
        end
      end
      
      x_on_tileset = index_on_tileset % TILESET_WIDTH_IN_TILES
      y_on_tileset = index_on_tileset / TILESET_WIDTH_IN_TILES
      rendered_tileset.compose!(rendered_tile, x_on_tileset*TILE_WIDTH, y_on_tileset*TILE_HEIGHT)
    end
    
    if output_filename
      FileUtils::mkdir_p(File.dirname(output_filename))
      rendered_tileset.save(output_filename, :fast_rgba)
      puts "Wrote #{output_filename}"
    end
    return rendered_tileset
  end
  
  def render_graphic_tile(gfx_file, palette, tile_index_on_page)
    x_block_on_tileset = tile_index_on_page % 8
    y_block_on_tileset = tile_index_on_page / 8
    render_gfx(gfx_file, palette, x=x_block_on_tileset*16, y=y_block_on_tileset*16, width=16, height=16)
  end
  
  def render_gfx_page(gfx_file, palette, canvas_width=16)
    render_gfx(gfx_file, palette, x=0, y=0, width=canvas_width*8, height=canvas_width*8, canvas_width=canvas_width*8)
  end
  
  def render_gfx(gfx_file, palette, x, y, width, height, canvas_width=128)
    rendered_gfx = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
    
    if gfx_file.nil?
      # Invalid graphics, render a red rectangle instead.
      
      rendered_gfx = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color.rgba(255, 0, 0, 255))
      return rendered_gfx
    end
    if palette.nil?
      # Invalid palette, use a dummy palette instead.
      
      palette = generate_palettes(nil, 256).first
    end
    
    if palette.length == 16
      pixels_per_byte = 2
    elsif palette.length == 256
      pixels_per_byte = 1
    else
      raise "Unknown palette length: #{palette.length}"
    end
    
    bytes_per_full_row = canvas_width / pixels_per_byte
    bytes_per_requested_row = width / pixels_per_byte
    
    offset = y*bytes_per_full_row + x/pixels_per_byte
    (0..height-1).each do |i|
      pixels_for_chunky = []
      
      fs.read_by_file(gfx_file[:file_path], offset, bytes_per_requested_row, allow_reading_into_next_file_in_ram: true).each_byte do |byte|
        if pixels_per_byte == 2
          pixels = [byte & 0b00001111, byte >> 4] # get the low 4 bits, then the high 4 bits (it's reversed). each is one pixel, two pixels total inside this byte.
        else
          pixels = [byte]
        end
        
        pixels.each do |pixel|
          if pixel == 0 # transparent
            pixels_for_chunky << ChunkyPNG::Color::TRANSPARENT
          else
            pixel_color = palette[pixel]
            pixels_for_chunky << pixel_color
          end
        end
      end
      
      rendered_gfx.replace_row!(i, pixels_for_chunky)
      offset += bytes_per_full_row
    end
    
    return rendered_gfx
  rescue NDSFileSystem::OffsetPastEndOfFileError
    rendered_gfx = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color.rgba(255, 0, 0, 255))
    return rendered_gfx
  end
  
  def render_1_dimensional_minitile(gfx_page, palette, minitile_index_on_page)
    width = height = 8
    
    if gfx_page.nil?
      # Invalid graphics, render a red rectangle instead.
      
      rendered_minitile = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color.rgba(255, 0, 0, 255))
      return rendered_minitile
    end
    if palette.nil?
      # Invalid palette, use a dummy palette instead.
      
      palette = generate_palettes(nil, 16).first
    end
    
    rendered_minitile = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
    
    if palette.length == 16
      pixels_per_byte = 2
    elsif palette.length == 256
      pixels_per_byte = 1
    else
      raise "Unknown palette length: #{palette.length}"
    end
    
    bytes_per_block = 8*8 / pixels_per_byte
    
    pixels_for_chunky = []
    
    offset = bytes_per_block*minitile_index_on_page
    gfx_page.gfx_data[offset, bytes_per_block].each_byte do |byte|
      if pixels_per_byte == 2
        pixels = [byte & 0b00001111, byte >> 4] # get the low 4 bits, then the high 4 bits (it's reversed). each is one pixel, two pixels total inside this byte.
      else
        pixels = [byte]
      end
      
      pixels.each do |pixel|
        if pixel == 0 # transparent
          pixels_for_chunky << ChunkyPNG::Color::TRANSPARENT
        else
          pixel_color = palette[pixel]
          pixels_for_chunky << pixel_color
        end
      end
    end
    
    pixels_for_chunky.each_with_index do |pixel, pixel_num|
      pixel_x = (pixel_num % 8)
      pixel_y = (pixel_num / 8)
      
      rendered_minitile[pixel_x, pixel_y] = pixel
    end
    
    return rendered_minitile
  rescue StandardError => e
    puts e
    return ChunkyPNG::Image.new(width, height, ChunkyPNG::Color.rgba(255, 0, 0, 255))
  end
  
  def render_gfx_1_dimensional_mode(gfx_page, palette, first_minitile_index: 0, max_num_minitiles: nil)
    width = 128
    height = 128
    if max_num_minitiles
      height = (max_num_minitiles/16.0).ceil * 8
    end
    
    rendered_gfx = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
    
    if gfx_page.nil?
      # Invalid graphics, render a red rectangle instead.
      
      rendered_gfx = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color.rgba(255, 0, 0, 255))
      return rendered_gfx
    end
    if palette.nil?
      # Invalid palette, use a dummy palette instead.
      
      palette = generate_palettes(nil, 16).first
    end
    
    if palette.length == 16
      pixels_per_byte = 2
    elsif palette.length == 256
      pixels_per_byte = 1
    else
      raise "Unknown palette length: #{palette.length}"
    end
    
    bytes_per_block = 8*8 / pixels_per_byte
    
    num_minitiles = gfx_page.gfx_data.length / bytes_per_block
    if max_num_minitiles && num_minitiles > max_num_minitiles
      num_minitiles = max_num_minitiles
    end
    
    (0..num_minitiles-1).each do |minitile_index|
      rendered_minitile = render_1_dimensional_minitile(gfx_page, palette, minitile_index+first_minitile_index)
      
      minitile_x = (minitile_index % 16) * 8
      minitile_y = (minitile_index / 16) * 8
      
      rendered_gfx.compose!(rendered_minitile, minitile_x, minitile_y)
    end
    
    return rendered_gfx
  end
  
  def generate_palettes(palette_data_start_offset, colors_per_palette)
    if palette_data_start_offset.nil?
      # Invalid palette, use a dummy palette instead.
      
      palette = [ChunkyPNG::Color.rgba(0, 0, 0, 0)] + [ChunkyPNG::Color.rgba(255, 0, 0, 255)] * (colors_per_palette-1)
      palette_list = [palette] * 128 # 128 is the maximum number of palettes
      return palette_list
    end
    
    if colors_per_palette == 256
      # color_offsets_per_palette_index: How many colors one index offsets by. This is always 16 for 16-color palettes. But for 256-color palettes it differs between DoS and PoR/OoE. In DoS one index only offsets by 16 colors, meaning you use indexes 0x00, 0x10, 0x20, etc. In PoR and OoE one index offsets by the full 256 colors, meaning you use indexes 0x00, 0x01, 0x02, etc
      color_offsets_per_palette_index = COLOR_OFFSETS_PER_256_PALETTE_INDEX
    else
      color_offsets_per_palette_index = 16
    end
    
    number_of_palettes = fs.read(palette_data_start_offset+2,1).unpack("C*").first / (color_offsets_per_palette_index/16)
    
    palette_data_start_offset += 4 # Skip the first 4 bytes, as they contain the length of this palette page, not the palette data itself.

    palette_list = []
    (0..number_of_palettes-1).each do |palette_index| # todo: cache palettes
      palette_data = fs.read(palette_data_start_offset + (2*color_offsets_per_palette_index)*palette_index, colors_per_palette*2, allow_length_to_exceed_end_of_file: true)
      
      palette = palette_data.unpack("v*").map do |color|
        # These two bytes hold the rgb data for the color in this format:
        # ?bbbbbgggggrrrrr
        # the ? is unknown.
        #unknown_bit = (color & 0b1000_0000_0000_0000) >> 15
        blue_bits   = (color & 0b0111_1100_0000_0000) >> 10
        green_bits  = (color & 0b0000_0011_1110_0000) >> 5
        red_bits    =  color & 0b0000_0000_0001_1111
        
        red = red_bits << 3
        green = green_bits << 3
        blue = blue_bits << 3
        alpha = 255
        ChunkyPNG::Color.rgba(red, green, blue, alpha)
      end
      palette_list << palette
    end
    
    palette_list
  end
  
  def export_palette_to_palette_swatches_file(palette, file_path)
    image = ChunkyPNG::Image.new(16, palette.size/16)
    palette.each_with_index do |color, i|
      x = i % 16
      y = i / 16
      image[x,y] = color
    end
    image.resample_nearest_neighbor!(image.width*16, image.height*16) # Make the color swatches 16 by 16 instead of a single pixel.
    image.save(file_path)
  end
  
  def import_palette_from_palette_swatches_file(file_path, colors_per_palette)
    image = ChunkyPNG::Image.from_file(file_path)
    if image.width != 16*16 || image.height != colors_per_palette
      raise GFXImportError.new("The palette file #{file_path} is not the right size, it must be a palette exported by DSVEdit.\n\nIf you want to generate a palette from an arbitrary file use \"Generate palette from file(s)\" instead.")
    end
    
    colors = []
    (0..image.height-1).step(16) do |y|
      (0..image.width-1).step(16) do |x|
        colors << image[x,y]
      end
    end
    if colors.size > colors_per_palette
      raise GFXImportError.new("The number of colors in this file (#{file_path}) is greater than #{colors_per_palette}. Cannot import.")
    end
    
    return colors
  end
  
  def import_palette_from_file(file_path, colors_per_palette)
    image = ChunkyPNG::Image.from_file(file_path)
    colors = [ChunkyPNG::Color::TRANSPARENT]
    image.pixels.each do |pixel|
      colors << pixel unless colors.include?(pixel)
    end
    if colors.size > colors_per_palette
      raise GFXImportError.new("The number of colors in this file (#{file_path}) is greater than #{colors_per_palette}. Cannot import.")
    end
    
    return colors
  end
  
  def import_palette_from_multiple_files(file_paths, colors_per_palette)
    colors = []
    file_paths.each do |file_path|
      colors += import_palette_from_file(file_path, colors_per_palette)
    end
    colors.uniq!
    
    if colors.size > colors_per_palette
      raise GFXImportError.new("The combined number of unique colors in these files is greater than #{colors_per_palette}. Cannot import.")
    end
    
    return colors
  end
  
  def save_palette(colors, palette_list_pointer, palette_index, colors_per_palette)
    if colors_per_palette == 256
      color_offsets_per_palette_index = COLOR_OFFSETS_PER_256_PALETTE_INDEX
    else
      color_offsets_per_palette_index = 16
    end
    
    specific_palette_pointer = palette_list_pointer + 4 + (2*color_offsets_per_palette_index)*palette_index
    new_palette_data = convert_chunky_color_list_to_palette_data(colors)
    fs.write(specific_palette_pointer, new_palette_data)
  end
  
  def convert_chunky_color_list_to_palette_data(chunky_colors)
    game_colors = []
    chunky_colors.each do |chunky_color|
      red = ChunkyPNG::Color.r(chunky_color)
      green = ChunkyPNG::Color.g(chunky_color)
      blue = ChunkyPNG::Color.b(chunky_color)
      
      red_bits   = red >> 3
      green_bits = green >> 3
      blue_bits  = blue >> 3
      
      bits = (blue_bits << 10) | (green_bits << 5) | red_bits
      
      game_colors << bits
    end
    
    return game_colors.pack("v*")
  end
  
  def import_gfx_page(input_filename, gfx, palette_list_pointer, colors_per_palette, palette_index)
    input_image = ChunkyPNG::Image.from_file(input_filename)
    
    if input_image.width != input_image.height || ![128, 256].include?(input_image.width)
      raise GFXImportError.new("Invalid image size. Image must be 128x128 or 256x256.")
    end
    
    colors = generate_palettes(palette_list_pointer, colors_per_palette)[palette_index]
    colors[0] = ChunkyPNG::Color::TRANSPARENT
    
    colors = colors.map{|color| color & 0b11111000111110001111100011111111} # Get rid of unnecessary bits so equality checks work correctly.
    
    gfx_data_bytes = []
    input_image.pixels.each_with_index do |pixel, i|
      if pixel & 0xFF == 0 # Transparent
        color_index = 0
      else
        pixel &= 0b11111000111110001111100011111111
        color_index = colors.index(pixel)
        
        if color_index.nil?
          raise GFXImportError.new("The imported image uses different colors than the existing palette. Cannot import.")
        end
        if color_index < 0 || color_index > colors_per_palette-1
          raise GFXImportError.new("Invalid color (this error shouldn't happen)")
        end
      end
      
      if i.even? || colors_per_palette == 256
        gfx_data_bytes << color_index
      else
        gfx_data_bytes[-1] = (gfx_data_bytes[-1] | color_index << 4)
      end
    end
    
    fs.overwrite_file(gfx.file[:file_path], gfx_data_bytes.pack("C*"))
    
    gfx.canvas_width = input_image.width/8
    gfx.write_to_rom()
  end
  
  def import_gfx_page_1_dimensional_mode(input_filename, gfx, palette_list_pointer, colors_per_palette, palette_index)
    input_image = ChunkyPNG::Image.from_file(input_filename)
    
    colors = generate_palettes(palette_list_pointer, colors_per_palette)[palette_index]
    colors[0] = ChunkyPNG::Color::TRANSPARENT
    
    colors = colors.map{|color| color & 0b11111000111110001111100011111111} # Get rid of unnecessary bits so equality checks work correctly.
    
    gfx_data_bytes = []
    (0..256-1).each do |block_num|
      (0..64-1).each do |pixel_num|
        block_x = (block_num % 16) * 8
        block_y = (block_num / 16) * 8
        pixel_x = (pixel_num % 8) + block_x
        pixel_y = (pixel_num / 8) + block_y
        
        pixel = input_image[pixel_x,pixel_y]
        
        if pixel & 0xFF == 0 # Transparent
          color_index = 0
        else
          pixel &= 0b11111000111110001111100011111111
          color_index = colors.index(pixel)
          
          if color_index.nil?
            raise GFXImportError.new("The imported image uses different colors than the existing palette. Cannot import.")
          end
          if color_index < 0 || color_index > colors_per_palette-1
            raise GFXImportError.new("Invalid color (this error shouldn't happen)")
          end
        end
        
        if pixel_num.even? || colors_per_palette == 256
          gfx_data_bytes << color_index
        else
          gfx_data_bytes[-1] = (gfx_data_bytes[-1] | color_index << 4)
        end
      end
    end
    
    gfx.write_gfx_data(gfx_data_bytes.pack("C*"))
  end
  
  def render_collision_tileset(collision_tileset_offset, output_filename=nil)
    if output_filename && File.exist?(output_filename)
      return ChunkyPNG::Image.from_file(output_filename)
    end
    
    collision_tileset = CollisionTileset.new(collision_tileset_offset, fs)
    rendered_tileset = ChunkyPNG::Image.new(TILESET_WIDTH_IN_TILES*16, TILESET_HEIGHT_IN_TILES*16, ChunkyPNG::Color::TRANSPARENT)
    
    collision_tileset.tiles.each_with_index do |tile, index_on_tileset|
      graphic_tile = render_collision_tile(tile)
      
      x_on_tileset = index_on_tileset % 16
      y_on_tileset = index_on_tileset / 16
      rendered_tileset.compose!(graphic_tile, x_on_tileset*16, y_on_tileset*16)
    end
    
    if output_filename
      FileUtils::mkdir_p(File.dirname(output_filename))
      rendered_tileset.save(output_filename, :fast_rgba)
      puts "Wrote #{output_filename}"
    end
    return rendered_tileset
  end
  
  def render_collision_tile(tile)
    color = COLLISION_SOLID_COLOR
    bg_color = ChunkyPNG::Color::TRANSPARENT
    if tile.is_water
      if tile.is_slope?
        if tile.has_top
          bg_color = COLLISION_WATER_COLOR
        else
          # Water slopes with no top are water slopes instead of solid slopes, so they don't have water in the background.
          bg_color = ChunkyPNG::Color::TRANSPARENT
          color = COLLISION_WATER_COLOR
        end
      else
        bg_color = COLLISION_WATER_COLOR
      end
    elsif tile.is_damage?
      bg_color = COLLISION_DAMAGE_COLOR
    end
    graphic_tile = ChunkyPNG::Image.new(16, 16, bg_color)
    
    case tile.block_shape
    when 0..1
      # Full block.
      if tile.has_top && tile.has_sides_and_bottom
        graphic_tile.rect(0, 0, 15, 15, stroke_color = color, fill_color = color)
      elsif tile.has_top
        graphic_tile.rect(0, 0, 15, 15, stroke_color = color, fill_color = COLLISION_SEMISOLID_COLOR)
          
        # Add an upwards pointing arrow for jumpthrough platforms.
        graphic_tile.polygon([4, 4, 7, 1, 8, 1, 11, 4, 8, 4, 8, 6, 7, 6, 7, 4], stroke_color = color, fill_color = color)
      elsif tile.has_sides_and_bottom
        graphic_tile.polygon([0, 0, 7, 7, 15, 0, 15, 15, 0, 15], stroke_color = color, fill_color = color)
      end
    when 2
      # Half-height block (top half).
      if tile.is_conveyor_left?
        if tile.has_top && tile.has_sides_and_bottom
          graphic_tile.rect(0, 0, 15, 15, stroke_color = color, fill_color = color)
          graphic_tile.polygon([10, 1, 4, 7, 4, 8, 10, 14], stroke_color = COLLISION_CONVEYOR_COLOR, fill_color = COLLISION_CONVEYOR_COLOR)
        elsif tile.has_top
          graphic_tile.rect(0, 0, 15, 7, stroke_color = color, fill_color = COLLISION_SEMISOLID_COLOR)
          graphic_tile.polygon([5, 1, 3, 3, 3, 4, 5, 6, 5, 4, 12, 4, 12, 3, 5, 3], stroke_color = COLLISION_CONVEYOR_COLOR, fill_color = COLLISION_CONVEYOR_COLOR)
        else
          graphic_tile.polygon([10, 1, 4, 7, 4, 8, 10, 14], stroke_color = COLLISION_CONVEYOR_COLOR, fill_color = COLLISION_CONVEYOR_COLOR)
        end
      else
        if tile.has_top && tile.has_sides_and_bottom
          graphic_tile.rect(0, 0, 15, 7, stroke_color = color, fill_color = color)
        elsif tile.has_top
          graphic_tile.rect(0, 0, 15, 7, stroke_color = color, fill_color = COLLISION_SEMISOLID_COLOR)
          
          # Add an upwards pointing arrow for jumpthrough platforms.
          graphic_tile.polygon([4, 4, 7, 1, 8, 1, 11, 4, 8, 4, 8, 6, 7, 6, 7, 4], stroke_color = color, fill_color = color)
        end
      end
    when 3
      # Half-height block (bottom half).
      if tile.is_conveyor_right?
        if tile.has_top && tile.has_sides_and_bottom
          graphic_tile.rect(0, 0, 15, 15, stroke_color = color, fill_color = color)
          graphic_tile.polygon([5, 1, 11, 7, 11, 8, 5, 14], stroke_color = COLLISION_CONVEYOR_COLOR, fill_color = COLLISION_CONVEYOR_COLOR)
        elsif tile.has_top
          graphic_tile.rect(0, 0, 15, 7, stroke_color = color, fill_color = COLLISION_SEMISOLID_COLOR)
          graphic_tile.polygon([10, 1, 12, 3, 12, 4, 10, 6, 10, 4, 3, 4, 3, 3, 10, 3], stroke_color = COLLISION_CONVEYOR_COLOR, fill_color = COLLISION_CONVEYOR_COLOR)
        else
          graphic_tile.polygon([5, 1, 11, 7, 11, 8, 5, 14], stroke_color = COLLISION_CONVEYOR_COLOR, fill_color = COLLISION_CONVEYOR_COLOR)
        end
      else
        if tile.has_top && tile.has_sides_and_bottom
          graphic_tile.rect(0, 8, 15, 15, stroke_color = color, fill_color = color)
        elsif tile.has_top
          graphic_tile.rect(0, 8, 15, 15, stroke_color = color, fill_color = COLLISION_SEMISOLID_COLOR)
          
          # Add an upwards pointing arrow for jumpthrough platforms.
          graphic_tile.polygon([4, 12, 7, 9, 8, 9, 11, 12, 8, 12, 8, 14, 7, 14, 7, 12], stroke_color = color, fill_color = color)
        end
      end
    when 4..15
      # Slope.
      case tile.block_shape
      when 4
        width = 16
        x_offset = 0
      when 8, 10
        width = 2*16
        x_offset = (tile.block_shape-8)*8
      when 12..15
        width = 4*16
        x_offset = (tile.block_shape-12)*16
      else
        puts "Unknown block shape: #{tile.block_shape}"
        graphic_tile.rect(1, 1, 14, 14, stroke_color = color, fill_color = ChunkyPNG::Color.rgba(0, 255, 0, 255))
        return graphic_tile
      end
      
      if tile.vertical_flip
        x_end = width-1
        y_end = 0
      else
        x_end = 0
        y_end = 15
      end
      
      graphic_tile.polygon([0-x_offset, 0, width-1-x_offset, 15, x_end-x_offset, y_end], stroke_color = color, fill_color = color)
      if tile.horizontal_flip
        graphic_tile.mirror!
      end
    end
    
    return graphic_tile
  end
  
  def render_map(map, scale = 1)
    if map.tiles.any?
      map_width_in_blocks = map.tiles.map{|tile| tile.x_pos}.max + 1
      map_height_in_blocks = map.tiles.map{|tile| tile.y_pos}.max + 1
    else
      map_width_in_blocks = map_height_in_blocks = 0
    end
    map_image_width = map_width_in_blocks*4 + 1
    map_image_height = map_height_in_blocks*4 + 1
    fill_img = ChunkyPNG::Image.new(map_image_width, map_image_height, ChunkyPNG::Color::TRANSPARENT)
    lines_img = ChunkyPNG::Image.new(map_image_width, map_image_height, ChunkyPNG::Color::TRANSPARENT)
    
    # 25 pixels per tile. But they overlap, so the left and top of a tile overlaps the right and bottom of other tiles.
    map.tiles.each do |tile|
      if tile.is_blank && !tile.left_door && !tile.left_wall && !tile.top_door && !tile.top_wall && !tile.right_door && !tile.right_wall && !tile.bottom_door && !tile.bottom_wall
        next
      end
      
      fill_tile, lines_tile = render_map_tile(tile)
      
      fill_img.compose!(fill_tile, tile.x_pos*4, tile.y_pos*4)
      lines_img.compose!(lines_tile, tile.x_pos*4, tile.y_pos*4)
    end
    
    img = fill_img
    img.compose!(lines_img, 0, 0)
    unless scale == 1
      img.resample_nearest_neighbor!(map_image_width*scale, map_image_height*scale)
    end
    
    return img
  end
  
  def render_map_tile(tile)
    @fill_color            ||= ChunkyPNG::Color.rgba(*MAP_FILL_COLOR)
    @save_fill_color       ||= ChunkyPNG::Color.rgba(*MAP_SAVE_FILL_COLOR)
    @warp_fill_color       ||= ChunkyPNG::Color.rgba(*MAP_WARP_FILL_COLOR)
    @secret_fill_color     ||= ChunkyPNG::Color.rgba(*MAP_SECRET_FILL_COLOR)
    @entrance_fill_color   ||= ChunkyPNG::Color.rgba(*MAP_ENTRANCE_FILL_COLOR)
    @transition_fill_color ||= ChunkyPNG::Color.rgba(0, 0, 0, 255)
    @line_color            ||= ChunkyPNG::Color.rgba(*MAP_LINE_COLOR)
    @door_color            ||= ChunkyPNG::Color.rgba(*MAP_DOOR_COLOR)
    @door_center_color     ||= ChunkyPNG::Color.rgba(*MAP_DOOR_CENTER_PIXEL_COLOR)
    @secret_door_color     ||= ChunkyPNG::Color.rgba(*MAP_SECRET_DOOR_COLOR)
  
    @wall_pixels           ||= [line_color]*5
    @door_pixels           ||= [line_color, door_color, door_center_color, door_color, line_color]
    @secret_door_pixels    ||= [line_color, secret_door_color, secret_door_color, secret_door_color, line_color]
    
    color = if tile.is_blank
      ChunkyPNG::Color::TRANSPARENT
    elsif tile.is_transition
      transition_fill_color
    elsif tile.is_entrance
      entrance_fill_color
    elsif tile.is_warp
      warp_fill_color
    elsif tile.is_secret
      secret_fill_color
    elsif tile.is_save
      save_fill_color
    else
      fill_color
    end
    
    fill_tile = ChunkyPNG::Image.new(5, 5, color)
    lines_tile = ChunkyPNG::Image.new(5, 5, ChunkyPNG::Color::TRANSPARENT)
    
    if tile.left_secret
      lines_tile.replace_column!(0, secret_door_pixels)
    elsif tile.left_wall
      lines_tile.replace_column!(0, wall_pixels)
    elsif tile.left_door
      lines_tile.replace_column!(0, door_pixels)
    end
    
    if tile.right_secret
      lines_tile.replace_column!(4, secret_door_pixels)
    elsif tile.right_wall
      lines_tile.replace_column!(4, wall_pixels)
    elsif tile.right_door
      lines_tile.replace_column!(4, door_pixels)
    end
    
    if tile.top_secret
      lines_tile.replace_row!(0, secret_door_pixels)
    elsif tile.top_wall
      lines_tile.replace_row!(0, wall_pixels)
    elsif tile.top_door
      lines_tile.replace_row!(0, door_pixels)
    end
    
    if tile.bottom_secret
      lines_tile.replace_row!(4, secret_door_pixels)
    elsif tile.bottom_wall
      lines_tile.replace_row!(4, wall_pixels)
    elsif tile.bottom_door
      lines_tile.replace_row!(4, door_pixels)
    end
    
    return [fill_tile, lines_tile]
  end
  
  def ensure_sprite_exists(folder, sprite_info, frame_to_render)
    sprite_filename = "%08X %08X %08X %02X" % [sprite_info.sprite.sprite_pointer, sprite_info.gfx_file_pointers.first, sprite_info.palette_pointer, sprite_info.palette_offset]
    output_path = "#{folder}/#{sprite_filename}_frame#{frame_to_render}.png"
    
    if !File.exist?(output_path)
      FileUtils::mkdir_p(File.dirname(output_path))
      rendered_frames, _ = render_sprite(sprite_info, frame_to_render: frame_to_render)
      rendered_frames.first.save(output_path, :fast_rgba)
      puts "Wrote #{output_path}"
    end
    
    return output_path
  end
  
  def render_sprite(sprite_info, frame_to_render: :all, render_hitboxes: false, override_part_palette_index: nil, one_dimensional_mode: false)
    gfx_pages = sprite_info.gfx_pages
    palette_pointer = sprite_info.palette_pointer
    palette_offset = sprite_info.palette_offset
    sprite = sprite_info.sprite
    
    if SYSTEM == :gba
      one_dimensional_mode = true
    end
    
    gfx_with_blanks = []
    gfx_pages.each do |gfx|
      gfx_with_blanks << gfx
      blanks_needed = (gfx.canvas_width/0x10 - 1) * 3
      gfx_with_blanks += [nil]*blanks_needed
    end
    
    if gfx_with_blanks.first.render_mode == 1
      palettes = generate_palettes(palette_pointer, 16)
      dummy_palette = generate_palettes(nil, 16).first
    elsif gfx_with_blanks.first.render_mode == 2
      palettes = generate_palettes(palette_pointer, 256)
      dummy_palette = generate_palettes(nil, 256).first
    else
      raise "Unknown render mode: #{gfx_with_blanks.first.render_mode}"
    end
    
    rendered_gfx_files_by_palette = Hash.new{|h, k| h[k] = {}}
    
    rendered_parts = {}
    
    if frame_to_render == :all
      frames = sprite.frames
    elsif frame_to_render
      frame = sprite.frames[frame_to_render]
      if frame.nil?
        raise "Invalid frame to render: #{frame_to_render}"
      end
      frames = [frame]
    else
      frames = []
    end
    
    parts_and_hitboxes = (sprite.parts + sprite.hitboxes)
    min_x = parts_and_hitboxes.map{|item| item.x_pos}.min
    min_y = parts_and_hitboxes.map{|item| item.y_pos}.min
    max_x = parts_and_hitboxes.map{|item| item.x_pos + item.width}.max
    max_y = parts_and_hitboxes.map{|item| item.y_pos + item.height}.max
    full_width = max_x - min_x
    full_height = max_y - min_y
    
    sprite.parts.each_with_index do |part, part_index|
      if part.gfx_page_index >= gfx_with_blanks.length
        puts "GFX page index too large (#{part.gfx_page_index+1} pages needed, have #{gfx_with_blanks.length})"
        
        # Invalid gfx page index, so just render a big red square.
        first_canvas_width = gfx_with_blanks.first.canvas_width
        rendered_gfx_files_by_palette[part.palette_index+palette_offset][part.gfx_page_index] ||= render_gfx(nil, nil, 0, 0, first_canvas_width*8, first_canvas_width*8, canvas_width=first_canvas_width*8)
      else
        gfx_page = gfx_with_blanks[part.gfx_page_index]
        canvas_width = gfx_page.canvas_width
        if override_part_palette_index
          # For weapons (which always use the first palette) and skeletally animated enemies (which have their palette specified in the skeleton file).
          palette = palettes[override_part_palette_index+palette_offset]
        else
          palette = palettes[part.palette_index+palette_offset]
        end
        
        if one_dimensional_mode
          rendered_gfx_files_by_palette[part.palette_index+palette_offset][part.gfx_page_index] ||= render_gfx_1_dimensional_mode(gfx_page, palette || dummy_palette)
        else
          gfx_file = gfx_page.file
          rendered_gfx_files_by_palette[part.palette_index+palette_offset][part.gfx_page_index] ||= render_gfx(gfx_file, palette || dummy_palette, 0, 0, canvas_width*8, canvas_width*8, canvas_width=canvas_width*8)
        end
      end
      
      rendered_gfx_file = rendered_gfx_files_by_palette[part.palette_index+palette_offset][part.gfx_page_index]
      rendered_parts[part_index] ||= render_sprite_part(part, rendered_gfx_file)
    end
    
    hitbox_color = ChunkyPNG::Color.rgba(255, 0, 0, 128)
    rendered_frames = []
    frames.each do |frame|
      rendered_frame = ChunkyPNG::Image.new(full_width, full_height, ChunkyPNG::Color::TRANSPARENT)

      frame.part_indexes.reverse.each do |part_index|
        part = sprite.parts[part_index]
        part_gfx = rendered_parts[part_index]
        
        x = part.x_pos - min_x
        y = part.y_pos - min_y
        rendered_frame.compose!(part_gfx, x, y)
      end
      
      if render_hitboxes
        puts frame.hitboxes.size
        frame.hitboxes.each do |hitbox|
          x = hitbox.x_pos - min_x
          y = hitbox.y_pos - min_y
          rendered_frame.rect(x, y, x + hitbox.width, y + hitbox.height, stroke_color = hitbox_color, fill_color = ChunkyPNG::Color::TRANSPARENT)
        end
      end
      
      rendered_frames << rendered_frame
    end
    
    return [rendered_frames, min_x, min_y, rendered_parts, gfx_with_blanks, palettes, full_width, full_height]
  end
  
  def render_sprite_part(part, rendered_gfx_file)
    part_gfx = rendered_gfx_file.crop(part.gfx_x_offset, part.gfx_y_offset, part.width, part.height)
    if part.horizontal_flip
      part_gfx.mirror!
    end
    if part.vertical_flip
      part_gfx.flip!
    end
    
    return part_gfx
  end
  
  def nil_image_if_invisible(image)
    invisible = image.palette.all? do |color|
      ChunkyPNG::Color.fully_transparent?(color)
    end
    
    if invisible
      nil
    else
      image
    end
  end
  
  def render_icon_by_item(item, mode=:item)
    icon_index, palette_index = GenericEditable.extract_icon_index_and_palette_index(item["Icon"])
    
    render_icon(icon_index, palette_index, mode)
  end
  
  def render_icon(icon_index, palette_index, mode=:item)
    icon_width = mode == :item ? 16 : 32
    icon_height = icon_width
    icons_per_row = 128 / icon_width
    icons_per_column = 128 / icon_height
    icons_per_page = 128*128 / icon_width / icon_width
    
    gfx_page_index = icon_index / icons_per_page
    
    palette_pointer = mode == :item ? ITEM_ICONS_PALETTE_POINTER : GLYPH_ICONS_PALETTE_POINTER
    palettes = generate_palettes(palette_pointer, 16)
    palette = palettes[palette_index]
    
    gfx_page = icon_gfx_pages(mode)[gfx_page_index]
    
    if mode == :item
      gfx_page_image = render_gfx_1_dimensional_mode(gfx_page, palette)
    else
      gfx_page_image = render_gfx_page(gfx_page.file, palette)
    end
    
    x_pos = ((icon_index % icons_per_page) % icons_per_row) * icon_width
    y_pos = ((icon_index % icons_per_page) / icons_per_column) * icon_height
    item_image = gfx_page_image.crop(x_pos, y_pos, icon_width, icon_height)
    
    item_image = nil_image_if_invisible(item_image)
    
    return item_image
  end
  
  def icon_gfx_pages(mode)
    gfx_pages = []
    
    if SYSTEM == :nds
      filename = mode == :item ? "item" : "rune"
      gfx_files = fs.files.values.select do |file|
        file[:file_path] =~ /\/sc\/f_#{filename}\d+\.dat/
      end
      
      gfx_files.each do |gfx_file|
        gfx_page = GfxWrapper.new(gfx_file[:asset_pointer], fs)
        gfx_pages << gfx_page
      end
    else
      ITEM_ICONS_GFX_POINTERS.each do |gfx_pointer|
        gfx_page = GfxWrapper.new(gfx_pointer, fs, unwrapped: true)
        gfx_pages << gfx_page
      end
    end
    
    gfx_pages
  end
  
  def inspect; to_s; end
end
