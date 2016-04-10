
require 'oily_png'

class Renderer
  COLLISION_SOLID_COLOR = ChunkyPNG::Color::BLACK
  COLLISION_DAMAGE_COLOR = ChunkyPNG::Color.rgba(255, 0, 0, 255)
  COLLISION_WATER_COLOR = ChunkyPNG::Color.rgba(0, 0, 255, 255)
  
  attr_reader :fs
  
  def initialize(fs)
    @fs = fs
  end
  
  def render_room(folder, room, collision = false)
    rendered_layers = []
    
    room.z_ordered_layers.each do |layer|
      rendered_layers << render_layer(folder, layer, room, collision)
    end
    
    # TODO: find a proper way of determining what the main collision layer is. just looking at the z-index doesn't seem sufficient.

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
    rendered_layer = ChunkyPNG::Image.new(layer.width*16*16, layer.height*16*12, ChunkyPNG::Color::TRANSPARENT)
    
    tileset_filename = "#{folder}/#{room.area_name}/Tilesets/#{layer.tileset_filename}.png"
    fs.load_overlay(AREA_INDEX_TO_OVERLAY_INDEX[room.area_index][room.sector_index])
    if collision
      tileset_filename = "#{folder}/#{room.area_name}/Tilesets/#{layer.tileset_filename}_collision.png"
      tileset = render_collision_tileset(layer.collision_tileset_ram_pointer, tileset_filename)
    else
      tileset = get_tileset(layer.ram_pointer_to_tileset_for_layer, room.palette_offset, room.graphic_tilesets_for_room, layer.colors_per_palette, layer.collision_tileset_ram_pointer, tileset_filename)
    end
    
    layer.tiles.each_with_index do |tile, index_on_level|
      x_on_tileset = tile.index_on_tileset % 16
      y_on_tileset = tile.index_on_tileset / 16
      x_on_level = index_on_level % (layer.width*16)
      y_on_level = index_on_level / (layer.width*16)
      
      tile_gfx = tileset.crop(x_on_tileset*16, y_on_tileset*16, 16, 16)
      
      if tile.horizontal_flip
        tile_gfx.mirror!
      end
      if tile.vertical_flip
        tile_gfx.flip!
      end
      
      rendered_layer.compose!(tile_gfx, x_on_level*16, y_on_level*16)
    end
    
    # TODO: OPACITY
    return rendered_layer
  end
  
  def get_tileset(pointer_to_tileset_for_layer, palette_offset, graphic_tilesets_for_room, colors_per_palette, collision_tileset_offset, tileset_filename)
    if File.exist?(tileset_filename)
      ChunkyPNG::Image.from_file(tileset_filename)
    else
      render_tileset(pointer_to_tileset_for_layer, palette_offset, graphic_tilesets_for_room, colors_per_palette, collision_tileset_offset, tileset_filename)
    end
  end
  
  def ensure_tilesets_exist(folder, room)
    room.layers.each do |layer|
      tileset_filename = "#{folder}/#{room.area_name}/Tilesets/#{layer.tileset_filename}.png"
      if File.exist?(tileset_filename)
        next
      else
        render_tileset(layer.ram_pointer_to_tileset_for_layer, room.palette_offset, room.graphic_tilesets_for_room, layer.colors_per_palette, tileset_filename)
      end
    end
  end
  
  def render_tileset(tileset_offset, palette_offset, graphic_tilesets_for_room, colors_per_palette, collision_tileset_offset, output_filename)
    if graphic_tilesets_for_room.nil?
      return render_collision_tileset(collision_tileset_offset, output_filename)
    end
    
    tileset = Tileset.new(tileset_offset, fs)
    rendered_tileset = ChunkyPNG::Image.new(Tileset::TILESET_WIDTH_IN_BLOCKS*16, Tileset::TILESET_HEIGHT_IN_BLOCKS*16, ChunkyPNG::Color::TRANSPARENT)
    palette_list = generate_palettes(palette_offset, colors_per_palette)

    tileset.tiles.each_with_index do |tile, index_on_tileset|
      if tile.is_blank
        next
      end
      
      graphic_tile_data_file = graphic_tilesets_for_room[tile.tile_page]
      if graphic_tile_data_file.nil?
        next # TODO: figure out why this sometimes happens.
      end
      
      if tile.palette_index == 0xFF # TODO. 255 seems to have some special meaning besides an actual palette index.
        puts "Palette index is 0xFF, tileset #{output_filename}"
        next
      end
      palette = palette_list[tile.palette_index]
      if palette.nil?
        puts "Palette index #{tile.palette_index} out of range, tileset #{output_filename}"
        next # TODO: figure out why this sometimes happens.
      end
      
      graphic_tile = render_graphic_tile(graphic_tile_data_file, palette, tile.index_on_tile_page)
      
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
    
    FileUtils::mkdir_p(File.dirname(output_filename))
    rendered_tileset.save(output_filename, :fast_rgba)
    puts "Wrote #{output_filename}"
    return rendered_tileset
  end
  
  def render_graphic_tile(graphic_tile_data_file, palette, tile_index_on_page)
    x_block_on_tileset = tile_index_on_page % 8
    y_block_on_tileset = tile_index_on_page / 8
    render_gfx(graphic_tile_data_file, palette, x=x_block_on_tileset*16, y=y_block_on_tileset*16, width=16, height=16)
  end
  
  def render_gfx_page(gfx_file, palette)
    render_gfx(gfx_file, palette, x=0, y=0, width=128, height=128)
  end
  
  def render_gfx(gfx_file, palette, x, y, width, height, canvas_width=128)
    rendered_gfx = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
    
    if gfx_file.nil? || palette.nil?
      # This room has no graphics, so just return a black tile. Could be a save room, warp room, transition room, etc.
      # TODO: instead it would be better to use the debug squares for these rooms so you can see what's what.
      
      rendered_gfx = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color.rgba(255, 0, 0, 255))
      return rendered_gfx
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
      
      fs.rom[gfx_file[:start_offset] + offset, bytes_per_requested_row].each_byte do |byte|
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
  end
  
  def generate_palettes(palette_data_start_offset, colors_per_palette)
    if palette_data_start_offset.nil?
      palette = [ChunkyPNG::Color.rgba(0, 0, 0, 0)] * colors_per_palette
      palette_list = [palette] * 128 # 128 is the maximum number of palettes
      return palette_list
    end
    
    number_of_palettes = fs.read(palette_data_start_offset+2,1).unpack("C*").first
    
    palette_data_start_offset += 4 # Skip the first 4 bytes, as they contain the length of this palette page, not the palette data itself.

    palette_list = []
    (0..number_of_palettes).each do |palette_index| # todo: cache palettes
      palette_data = fs.read(palette_data_start_offset + 32*palette_index, colors_per_palette*2, allow_length_to_exceed_end_of_file: true)
      palette = palette_data.scan(/.{2}/m).map do |color|
        color = color.unpack("v*").first
        # these two bytes hold the rgb data for the color in this format:
        # ?bbbbbgggggrrrrr
        # the ? is unknown.
        #unknown_bit = (color >> 15) & 0b0000_0000_0000_0001
        blue_bits   = (color >> 10) & 0b0000_0000_0001_1111
        green_bits  = (color >> 5)  & 0b0000_0000_0001_1111
        red_bits    =  color        & 0b0000_0000_0001_1111
        
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
  
  def render_collision_tileset(collision_tileset_offset, output_filename)
    if File.exist?(output_filename)
      return ChunkyPNG::Image.from_file(output_filename)
    end
    
    collision_tileset = CollisionTileset.new(collision_tileset_offset, fs)
    rendered_tileset = ChunkyPNG::Image.new(Tileset::TILESET_WIDTH_IN_BLOCKS*16, Tileset::TILESET_HEIGHT_IN_BLOCKS*16, ChunkyPNG::Color::TRANSPARENT)
    
    collision_tileset.tiles.each_with_index do |tile, index_on_tileset|
      graphic_tile = render_collision_tile(tile)
      
      x_on_tileset = index_on_tileset % 16
      y_on_tileset = index_on_tileset / 16
      rendered_tileset.compose!(graphic_tile, x_on_tileset*16, y_on_tileset*16)
    end
    
    FileUtils::mkdir_p(File.dirname(output_filename))
    rendered_tileset.save(output_filename, :fast_rgba)
    puts "Wrote #{output_filename}"
    return rendered_tileset
  end
  
  def render_collision_tile(tile)
    graphic_tile = ChunkyPNG::Image.new(16, 16, ChunkyPNG::Color::TRANSPARENT)
    
    if tile.is_slope
      if tile.has_top && tile.slope_piece > 0 && !tile.is_gradual_slope
        graphic_tile.rect(0, 0, 15, 4, stroke_color = COLLISION_SOLID_COLOR, fill_color = COLLISION_SOLID_COLOR)
      elsif tile.has_top
        if tile.is_gradual_slope && tile.not_a_half_slope
          x_offset = tile.slope_piece*16
          width = 16*4
        elsif tile.is_gradual_slope
          x_offset = tile.slope_piece/2*16
          width = 16*2
        else
          if tile.slope_piece > 0
            # ???
            x_offset = 0
            width = 16
          else
            x_offset = 0
            width = 16
          end
        end
        if tile.vertical_flip
          x_end = width-1
          y_end = 0
        else
          x_end = 0
          y_end = 15
        end
        graphic_tile.polygon([0-x_offset, 0, width-1-x_offset, 15, x_end-x_offset, y_end], stroke_color = COLLISION_SOLID_COLOR, fill_color = COLLISION_SOLID_COLOR)
      
        if tile.horizontal_flip
          graphic_tile.mirror!
        end
      end
    else
      color = COLLISION_SOLID_COLOR
      if tile.is_damage
        color = COLLISION_DAMAGE_COLOR
      end
      if tile.is_water
        color = COLLISION_WATER_COLOR
      end
      
      if tile.has_top && tile.has_sides_and_bottom
        graphic_tile.rect(0, 0, 15, 15, stroke_color = color, fill_color = color)
      elsif tile.has_top
        graphic_tile.rect(0, 0, 4, 4, stroke_color = color, fill_color = color)
      elsif tile.has_sides_and_bottom
        graphic_tile.polygon([0, 0, 7, 7, 15, 0, 15, 15, 0, 15], stroke_color = color, fill_color = color)
      end
    end
    
    return graphic_tile
  end
  
  def render_map(map, scale = 1)
    map_width_in_blocks = 64
    map_height_in_blocks = 48
    map_image_width = map_width_in_blocks*4 + 1
    map_image_height = map_height_in_blocks*4 + 1
    fill_img = ChunkyPNG::Image.new(map_image_width, map_image_height, ChunkyPNG::Color::TRANSPARENT)
    lines_img = ChunkyPNG::Image.new(map_image_width, map_image_height, ChunkyPNG::Color::TRANSPARENT)
    
    fill_color            = ChunkyPNG::Color.rgba(*MAP_FILL_COLOR)
    save_fill_color       = ChunkyPNG::Color.rgba(*MAP_SAVE_FILL_COLOR)
    warp_fill_color       = ChunkyPNG::Color.rgba(*MAP_WARP_FILL_COLOR)
    secret_fill_color     = ChunkyPNG::Color.rgba(*MAP_SECRET_FILL_COLOR)
    entrance_fill_color   = ChunkyPNG::Color.rgba(*MAP_ENTRANCE_FILL_COLOR)
    transition_fill_color = ChunkyPNG::Color.rgba(0, 0, 0, 255)
    line_color            = ChunkyPNG::Color.rgba(*MAP_LINE_COLOR)
    door_color            = ChunkyPNG::Color.rgba(*MAP_DOOR_COLOR)
    door_center_color     = ChunkyPNG::Color.rgba(*MAP_DOOR_CENTER_PIXEL_COLOR)
  
    wall_pixels = [line_color]*5
    door_pixels = [line_color, door_color, door_center_color, door_color, line_color]
  
    # 25 pixels per tile. But they overlap, so the left and top of a tile overlaps the right and bottom of other tiles.
    i = 0
    map.tiles.each do |tile|
      if tile.is_blank && !tile.left_door && !tile.left_wall && !tile.top_door && !tile.top_wall && !tile.right_door && !tile.right_wall && !tile.bottom_door && !tile.bottom_wall
        i += 1
        next
      end
      
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
      
      if tile.left_door
        lines_tile.replace_column!(0, door_pixels)
      elsif tile.left_wall
        lines_tile.replace_column!(0, wall_pixels)
      end
      
      if tile.right_door # Never used in game because it would always get overwritten by the tile to the right.
        lines_tile.replace_column!(4, door_pixels)
      elsif tile.right_wall
        lines_tile.replace_column!(4, wall_pixels)
      end
      
      if tile.top_door
        lines_tile.replace_row!(0, door_pixels)
      elsif tile.top_wall
        lines_tile.replace_row!(0, wall_pixels)
      end
      
      if tile.bottom_door # Never used in game because it would always get overwritten by the tile below.
        lines_tile.replace_row!(4, door_pixels)
      elsif tile.bottom_wall
        lines_tile.replace_row!(4, wall_pixels)
      end
      
      fill_img.compose!(fill_tile, tile.x_pos*4, tile.y_pos*4)
      lines_img.compose!(lines_tile, tile.x_pos*4, tile.y_pos*4)
      
      i += 1
    end
    
    img = ChunkyPNG::Image.new(map_image_width, map_image_height, ChunkyPNG::Color::TRANSPARENT)
    img.compose!(fill_img, 0, 0)
    img.compose!(lines_img, 0, 0)
    unless scale == 1
      img.resample_nearest_neighbor!(map_image_width*scale, map_image_height*scale)
    end
    
    return img
  end
  
  def render_entity(gfx_files, palette_pointer, palette_offset, animation_file, frame_to_render = nil, render_hitbox = false)
    if gfx_files.first[:render_mode] == 1
      palettes = generate_palettes(palette_pointer, 16)
    elsif gfx_files.first[:render_mode] == 2
      palettes = generate_palettes(palette_pointer, 256)
    else
      raise NotImplementedError.new("Unknown render mode.")
    end
    animation = Animation.new(animation_file, fs)
    
    gfx_files_with_blanks = []
    gfx_files.each do |gfx_file|
      gfx_files_with_blanks << gfx_file
      blanks_needed = (gfx_file[:canvas_width]/0x10 - 1) * 3
      gfx_files_with_blanks += [nil]*blanks_needed
    end
    
    rendered_gfx_files_by_palette = Hash.new{|h, k| h[k] = {}}
    
    rendered_parts = {}
    
    if frame_to_render
      frame = animation.frames[frame_to_render]
      if frame.nil?
        raise "Invalid frame to render: #{frame_to_render}"
      end
      frames = [frame]
    else
      frames = animation.frames
    end
    
    min_x = 0
    min_y = 0
    max_x = 0
    max_y = 0
    frames.each do |frame|
      frame.parts.each do |part|
        min_x = part.x_pos if part.x_pos < min_x
        min_y = part.y_pos if part.y_pos < min_y
        max_x = part.x_pos + part.width if part.x_pos + part.width > max_x
        max_y = part.y_pos + part.height if part.y_pos + part.height > max_y
      end
    end
    full_width = max_x - min_x
    full_height = max_y - min_y
    
    hitbox_color = ChunkyPNG::Color.rgba(255, 0, 0, 128)
    rendered_frames = []
    frames.each do |frame|
      rendered_frame = ChunkyPNG::Image.new(full_width, full_height, ChunkyPNG::Color::TRANSPARENT)

      frame.part_indexes.reverse.each do |part_index|
        part = animation.parts[part_index]
        
        if part.gfx_page_index >= gfx_files_with_blanks.length
          raise "GFX page index too large (#{part.gfx_page_index+1} pages needed, have #{gfx_files_with_blanks.length})"
        end
        gfx_page = gfx_files_with_blanks[part.gfx_page_index]
        gfx_file = gfx_page[:file]
        canvas_width = gfx_page[:canvas_width]
        palette = palettes[part.palette_index+palette_offset]
        
        rendered_gfx_files_by_palette[part.palette_index+palette_offset][part.gfx_page_index] ||= render_gfx(gfx_file, palette, 0, 0, canvas_width*8, canvas_width*8, canvas_width=canvas_width*8)
        rendered_gfx_file = rendered_gfx_files_by_palette[part.palette_index+palette_offset][part.gfx_page_index]
        rendered_parts[part_index] ||= render_animation_part(part, rendered_gfx_file)
        part_gfx = rendered_parts[part_index]
        
        x = part.x_pos - min_x
        y = part.y_pos - min_y
        rendered_frame.compose!(part_gfx, x, y)
      end
      
      if frame.hitbox && render_hitbox
        x = frame.hitbox.x_pos - min_x
        y = frame.hitbox.y_pos - min_y
        rendered_frame.rect(x, y, x + frame.hitbox.width, y + frame.hitbox.height, stroke_color = hitbox_color, fill_color = ChunkyPNG::Color::TRANSPARENT)
      end
      
      rendered_frames << rendered_frame
    end
    
    return [rendered_frames, min_x, min_y]
  end
  
  def render_animation_part(part, rendered_gfx_file)
    part_gfx = rendered_gfx_file.crop(part.gfx_x_offset, part.gfx_y_offset, part.width, part.height)
    if part.horizontal_flip
      part_gfx.mirror!
    end
    if part.vertical_flip
      part_gfx.flip!
    end
    
    return part_gfx
  end
end
