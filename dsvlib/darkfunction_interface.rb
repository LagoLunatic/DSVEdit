
require 'nokogiri'

class DarkFunctionInterface
  class ExportError < StandardError ; end
  class ImportError < StandardError ; end
  
  PADDING = 4
  
  def self.export(output_path, name, sprite_info, fs, renderer, transparent_trails: false, one_dimensional_mode: false)
    sprite = sprite_info.sprite
    
    palettes = renderer.generate_palettes(sprite_info.palette_pointer, 16)
    
    if transparent_trails
      # Transparent trails treat palette 0 as normal, and palette 1 as being palette 0 with 0xC/0x1F opacity.
      palettes = palettes[0..0]
      palettes[1] = palettes[0].dup
      palettes[1].map! do |color|
        if ChunkyPNG::Color.fully_transparent?(color)
          color
        else
          ChunkyPNG::Color.rgba(ChunkyPNG::Color.r(color), ChunkyPNG::Color.g(color), ChunkyPNG::Color.b(color), 96)
        end
      end
    end
    
    num_gfx_pages = sprite_info.gfx_pages.size
    num_palettes = palettes.size
    gfx_page_canvas_width = sprite_info.gfx_pages.first.canvas_width*8
    gfx_page_width = gfx_page_canvas_width
    
    big_gfx_page_width = num_gfx_pages
    big_gfx_page_height = num_palettes
    
    # Make sure the big gfx page is at least 256 pixels wide for the hitboxes.
    if gfx_page_width == 128
      big_gfx_page_width = [big_gfx_page_width, 2].max
    end
    # Add an extra 256 pixels to the height for the hitboxes.
    if gfx_page_width == 128
      big_gfx_page_height += 2
    else
      big_gfx_page_height += 1
    end
    
    # Put padding in between each GFX page.
    gfx_page_width_with_padding = gfx_page_width + PADDING
    big_gfx_page_width_px = big_gfx_page_width*gfx_page_width_with_padding
    big_gfx_page_height_px = big_gfx_page_height*gfx_page_width_with_padding
    
    gfx_padding_color = ChunkyPNG::Color.rgba(255, 128, 36, 255)
    
    big_gfx_page = ChunkyPNG::Image.new(big_gfx_page_width_px, big_gfx_page_height_px)
    palettes.each_with_index do |palette, palette_index|
      sprite_info.gfx_pages.each_with_index do |gfx_page, gfx_page_index|
        if one_dimensional_mode
          chunky_gfx_page = renderer.render_gfx_1_dimensional_mode(gfx_page, palette)
        else
          chunky_gfx_page = renderer.render_gfx_page(gfx_page, palette, gfx_page.canvas_width)
        end
        
        i = gfx_page_index + (palette_index*big_gfx_page_width)
        x_on_big_gfx_page = (i % big_gfx_page_width) * gfx_page_width_with_padding
        y_on_big_gfx_page = (i / big_gfx_page_width) * gfx_page_width_with_padding
        big_gfx_page.replace!(chunky_gfx_page, x_on_big_gfx_page, y_on_big_gfx_page)
        
        big_gfx_page.line(
          x_on_big_gfx_page + gfx_page_width + 1,
          0,
          x_on_big_gfx_page + gfx_page_width + 1,
          big_gfx_page_height_px,
          gfx_padding_color
        )
        big_gfx_page.line(
          x_on_big_gfx_page + gfx_page_width + 2,
          0,
          x_on_big_gfx_page + gfx_page_width + 2,
          big_gfx_page_height_px,
          gfx_padding_color
        )
      end
      
      big_gfx_page.line(
        0,
        palette_index*gfx_page_width_with_padding + gfx_page_width + 1,
        big_gfx_page_width_px,
        palette_index*gfx_page_width_with_padding + gfx_page_width + 1,
        gfx_padding_color
      )
      big_gfx_page.line(
        0,
        palette_index*gfx_page_width_with_padding + gfx_page_width + 2,
        big_gfx_page_width_px,
        palette_index*gfx_page_width_with_padding + gfx_page_width + 2,
        gfx_padding_color
      )
    end
    hitbox_red_rect_height = 256 + PADDING*2
    hitbox_red_rect = ChunkyPNG::Image.new(big_gfx_page_width_px, hitbox_red_rect_height, ChunkyPNG::Color.rgba(0xFF, 0, 0, 0x3f))
    hitbox_red_x_off = 0
    hitbox_red_y_off = big_gfx_page.height-hitbox_red_rect.height
    big_gfx_page.replace!(hitbox_red_rect, hitbox_red_x_off, hitbox_red_y_off)
    big_gfx_page.save(output_path + "/#{name}.png", :fast_rgba)
    
    unique_parts_by_index = sprite.get_unique_parts_by_index()
    unique_parts = unique_parts_by_index.values.map{|dup_data| dup_data[:unique_part]}.uniq
    
    unique_hitboxes_by_index = sprite.get_unique_hitboxes_by_index()
    unique_hitboxes = unique_hitboxes_by_index.values.map{|dup_data| dup_data[:unique_hitbox]}.uniq
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.img(:name => "#{name}.png", 
              :w => big_gfx_page_width_px, 
              :h => big_gfx_page_height_px) {
        xml.definitions {
          xml.dir(:name => "/") {
            unique_parts.each_with_index do |part, i|
              part_index = sprite.parts.index(part)
              gfx_page_index = part.gfx_page_index
              part_palette_index = part.palette_index
              if sprite_info.ignore_part_gfx_page
                gfx_page_index = 0
              end
              if gfx_page_canvas_width == 256
                # 256x256 pages take up 4 times the space of 128x128 pages.
                gfx_page_index = gfx_page_index / 4
              end
              if part_palette_index >= num_palettes
                # Failsafe to prevent parts from being put in the hitbox area if there's some invalid palette index.
                part_palette_index = 0
              end
              i_on_big_gfx_page = gfx_page_index + (part_palette_index*big_gfx_page_width)
              big_gfx_x_offset = (i_on_big_gfx_page % big_gfx_page_width) * gfx_page_width_with_padding
              big_gfx_y_offset = (i_on_big_gfx_page / big_gfx_page_width) * gfx_page_width_with_padding
              xml.spr(:name => "part%03X" % part_index,
                      :x => part.gfx_x_offset + big_gfx_x_offset,
                      :y => part.gfx_y_offset + big_gfx_y_offset,
                      :w => part.width,
                      :h => part.height
              )
            end
            
            unique_hitboxes.each_with_index do |hitbox, i|
              hitbox_index = sprite.hitboxes.index(hitbox)
              xml.spr(:name => "hitbox%02X" % hitbox_index,
                      :x => hitbox_red_x_off,
                      :y => hitbox_red_y_off,
                      :w => hitbox.width,
                      :h => hitbox.height
              )
            end
          }
        }
      }
    end
    
    filename = output_path + "/#{name}.sprites"
    FileUtils::mkdir_p(File.dirname(filename))
    File.open(filename, "w") do |f|
      f.write(builder.to_xml)
    end
    
    # We need to preserve unanimated frames by creating dummy animations containing them.
    animations_plus_unanimated_frames = []
    max_seen_frame_index = -1
    all_unanimated_frames = (0..sprite.frames.size-1).to_a
    sprite.animations.each do |animation|
      animation.frame_delays.each do |frame_delay|
        all_unanimated_frames.delete(frame_delay.frame_index)
      end
    end
    sprite.animations.each_with_index do |animation, animation_index|
      unanimated_frame_indexes_to_insert = []
      
      animation.frame_delays.each do |frame_delay|
        if frame_delay.frame_index <= max_seen_frame_index
          # Do nothing. This is just a duplicated frame.
        elsif frame_delay.frame_index == max_seen_frame_index + 1
          # This is the next sequential frame.
          max_seen_frame_index = frame_delay.frame_index
        else
          # It skipped a frame (or multiple frames). We must insert these as unanimated frames before this next animation so that it's correctly preserved.
          unanimated_frame_indexes_to_insert += ((max_seen_frame_index+1..frame_delay.frame_index-1).to_a & all_unanimated_frames)
          max_seen_frame_index = frame_delay.frame_index
        end
      end
      
      unanimated_frame_indexes_to_insert.each do |unanimated_frame_index|
        dummy_frame_delay = FrameDelay.new
        dummy_frame_delay.frame_index = unanimated_frame_index
        
        animations_plus_unanimated_frames << {name: "unanimated frame %02X" % unanimated_frame_index, frame_delays: [dummy_frame_delay]}
      end
      
      if animation.frame_delays.length == 1
        # If the animation only has a single frame in it, it's probably an unanimated frame in disguise ("unanimated animation").
        # In this case we need to preserve both the animation index *and* the frame index.
        frame_index = animation.frame_delays[0].frame_index
        animations_plus_unanimated_frames << {
          name: "unanimated anim %02X-%02X" % [animation_index, frame_index],
          frame_delays: animation.frame_delays
        }
      else
        animations_plus_unanimated_frames << {name: "%02X" % animation_index, frame_delays: animation.frame_delays}
      end
    end
    
    if max_seen_frame_index < sprite.frames.size-1
      (max_seen_frame_index+1..sprite.frames.size-1).each do |unanimated_frame_index|
        dummy_frame_delay = FrameDelay.new
        dummy_frame_delay.frame_index = unanimated_frame_index
        
        animations_plus_unanimated_frames << {name: "unanimated frame %02X" % unanimated_frame_index, frame_delays: [dummy_frame_delay]}
      end
    end
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.animations(:spriteSheet => "#{name}.sprites", 
                     :ver => "1.2") {
        animations_plus_unanimated_frames.each do |hash|
          xml.anim(:name => hash[:name], :loops => 0) {
            hash[:frame_delays].each_with_index do |frame_delay, i|
              xml.cell(:index => "%02X" % i,
                       :delay => frame_delay.delay
              ) {
                frame = sprite.frames[frame_delay.frame_index]
                part_z_index = 0
                frame.part_indexes.each do |part_index|
                  # darkFunction places parts so that their center is at the position given.
                  # But the game engine places it so that the part's upper left corner is at the position given.
                  # So we need to add half the part's width and height so it matches up.
                  dup_data = unique_parts_by_index[part_index]
                  part = dup_data[:unique_part]
                  x = dup_data[:x_pos]
                  y = dup_data[:y_pos]
                  horizontal_flip = dup_data[:horizontal_flip]
                  vertical_flip = dup_data[:vertical_flip]
                  unique_part_index = sprite.parts.index(part)
                  xml.spr(:name => "/part%03X" % unique_part_index,
                          :x => x + part.width/2,
                          :y => y + part.height/2,
                          :z => part_z_index,
                          :flipH => horizontal_flip ? 1 : 0,
                          :flipV => vertical_flip ? 1 : 0
                  )
                  part_z_index += 1
                end
                
                frame.hitbox_indexes.each do |hitbox_index|
                  dup_data = unique_hitboxes_by_index[hitbox_index]
                  hitbox = dup_data[:unique_hitbox]
                  x = dup_data[:x_pos]
                  y = dup_data[:y_pos]
                  unique_hitbox_index = sprite.hitboxes.index(hitbox)
                  xml.spr(:name => "/hitbox%02X" % unique_hitbox_index,
                          :x => x + hitbox.width/2,
                          :y => y + hitbox.height/2,
                          :z => 999 # We want hitboxes to appear below the graphics.
                  )
                end
              }
            end
          }
        end
      }
    end
    
    filename = output_path + "/#{name}.anim"
    FileUtils::mkdir_p(File.dirname(filename))
    File.open(filename, "w") do |f|
      f.write(builder.to_xml)
    end
  end
  
  def self.import(input_path, name, sprite_info, fs, renderer)
    sprite = sprite_info.sprite
    
    gfx_page_canvas_width = sprite_info.gfx_pages.first.canvas_width*8
    gfx_page_width = gfx_page_canvas_width
    num_gfx_pages = sprite_info.gfx_pages.size
    big_gfx_page_width = num_gfx_pages
    
    gfx_page_width_with_padding = gfx_page_width + PADDING
    
    sprites_file = File.read(input_path + "/#{name}.sprites")
    anim_file = File.read(input_path + "/#{name}.anim")
    
    xml = Nokogiri::XML(sprites_file)
    df_unique_parts = {}
    xml.css("spr").each do |df_spr|
      df_unique_parts["/" + df_spr["name"]] = df_spr
    end
    
    # Empty the arrays so we can create them from scratch.
    sprite.frames.clear()
    sprite.parts.clear()
    sprite.hitboxes.clear()
    sprite.animations.clear()
    sprite.frame_delays.clear()
    
    all_created_frames = []
    each_frames_unique_part_and_hitbox_strs = {}
    
    xml = Nokogiri::XML(anim_file)
    df_anims = xml.css("anim")
    
    # We need to preserve the frame index of unanimated frames since these are referenced directly by the game's code, not through animations.
    # Create the unanimated frames first in their proper spots.
    df_anims.each do |df_anim|
      if df_anim[:name] =~ /^unanimated frame (\h+)$/
        unanimated_frame_index = $1.to_i(16)
        
        if !sprite.frames[unanimated_frame_index].nil?
          raise ImportError.new("There are multiple unanimated frames with index %02X" % unanimated_frame_index)
        end
        
        df_cell = df_anim.css("cell").first
        frame, this_frames_unique_part_and_hitbox_strs = import_frame(
          df_cell, df_unique_parts, gfx_page_width_with_padding, big_gfx_page_width, num_gfx_pages, gfx_page_canvas_width
        )
        sprite.frames[unanimated_frame_index] = frame
        all_created_frames[unanimated_frame_index] = frame
        each_frames_unique_part_and_hitbox_strs[unanimated_frame_index] = this_frames_unique_part_and_hitbox_strs
      end
    end
    
    # We also need to preserve both the animation index and the frame index of single-frame "unanimated animations".
    df_anims.each do |df_anim|
      if df_anim[:name] =~ /^unanimated anim (\h+)-(\h+)$/
        unanimated_anim_index = $1.to_i(16)
        unanimated_frame_index = $2.to_i(16)
        
        if !sprite.animations[unanimated_anim_index].nil?
          raise ImportError.new("There are multiple unanimated anims with index %02X" % unanimated_anim_index)
        end
        if !sprite.frames[unanimated_frame_index].nil?
          raise ImportError.new("There are multiple unanimated anim frames with index %02X" % unanimated_frame_index)
        end
        
        df_cell = df_anim.css("cell").first
        frame, this_frames_unique_part_and_hitbox_strs = import_frame(
          df_cell, df_unique_parts, gfx_page_width_with_padding, big_gfx_page_width, num_gfx_pages, gfx_page_canvas_width
        )
        sprite.frames[unanimated_frame_index] = frame
        all_created_frames[unanimated_frame_index] = frame
        each_frames_unique_part_and_hitbox_strs[unanimated_frame_index] = this_frames_unique_part_and_hitbox_strs
        
        animation = Animation.new
        sprite.animations[unanimated_anim_index] = animation
        
        frame_delay = FrameDelay.new
        frame_delay.delay = df_cell["delay"].to_i
        frame_delay.frame_index = unanimated_frame_index
        animation.frame_delays << frame_delay
      end
    end
    
    # Now import animations and animated frames.
    df_anims.each do |df_anim|
      if df_anim[:name] =~ /^unanimated frame (\h+)$/
        next
      end
      if df_anim[:name] =~ /^unanimated anim (\h+)-(\h+)$/
        next
      end
      
      next_blank_anim_index = sprite.animations.index(nil)
      if next_blank_anim_index
        anim_index = next_blank_anim_index
      else
        anim_index = sprite.animations.size
      end
      animation = Animation.new
      sprite.animations[anim_index] = animation
      
      df_cells = df_anim.css("cell")
      df_cells.each do |df_cell|
        frame_delay = FrameDelay.new
        frame_delay.delay = df_cell["delay"].to_i
        animation.frame_delays << frame_delay
        
        frame, this_frames_unique_part_and_hitbox_strs = import_frame(
          df_cell, df_unique_parts, gfx_page_width_with_padding, big_gfx_page_width, num_gfx_pages, gfx_page_canvas_width
        )
        
        duplicated_frame_and_part_names = each_frames_unique_part_and_hitbox_strs.find do |frame_index, other_frames_unique_part_and_hitbox_strs|
          this_frames_unique_part_and_hitbox_strs == other_frames_unique_part_and_hitbox_strs
        end
        if duplicated_frame_and_part_names
          duplicated_frame_index = duplicated_frame_and_part_names[0]
          frame_delay.frame_index = duplicated_frame_index
        else
          next_blank_frame_index = sprite.frames.index(nil)
          if next_blank_frame_index
            frame_index = next_blank_frame_index
          else
            frame_index = sprite.frames.size
          end
          
          frame_delay.frame_index = frame_index
          
          sprite.frames[frame_index] = frame
          all_created_frames[frame_index] = frame
          each_frames_unique_part_and_hitbox_strs[frame_index] = this_frames_unique_part_and_hitbox_strs
        end
      end
    end
    
    all_created_frames.each_with_index do |frame, i|
      if frame.nil?
        # A blank spot caused by the user reducing the number of frames, but an unanimated frame remains that we have to keep in place.
        # Create a dummy frame to fill in the blank spot.
        frame_index = i
        frame = Frame.new
        sprite.frames[frame_index] = frame
      else
        sprite.parts.concat(frame.parts)
        sprite.hitboxes.concat(frame.hitboxes)
      end
    end
    
    sprite.animations.each_with_index do |animation, i|
      if animation.nil?
        # A blank spot caused by the user reducing the number of animations, but an unanimated animation remains that we have to keep in place.
        # Create a dummy animation to fill in the blank spot.
        animation_index = i
        animation = Animation.new
        sprite.animations[animation_index] = animation
      end
    end
    
    sprite.animations.each do |animation|
      animation.frame_delays.each do |frame_delay|
        sprite.frame_delays << frame_delay
      end
    end
    
    sprite.write_to_rom()
  end
  
  def self.import_frame(df_cell, df_unique_parts, gfx_page_width_with_padding, big_gfx_page_width, num_gfx_pages, gfx_page_canvas_width)
    frame = Frame.new
    
    this_frames_unique_part_and_hitbox_strs = []
    
    df_sprs = df_cell.css("spr")
    df_sprs_z_sorted = df_sprs.sort_by{|df_spr| df_spr["z"].to_i}
    df_sprs_z_sorted.each do |df_spr|
      if df_spr["name"].start_with?("/hitbox")
        hitbox = Hitbox.new
        
        df_unique_hitbox = df_unique_parts[df_spr["name"]]
        if df_unique_hitbox.nil?
          raise ImportError.new("Failed to find hitbox with name #{df_spr["name"]}")
        end
        hitbox.width = df_unique_hitbox["w"].to_i
        hitbox.height = df_unique_hitbox["h"].to_i
        
        hitbox.x_pos = df_spr["x"].to_i - hitbox.width/2
        hitbox.y_pos = df_spr["y"].to_i - hitbox.height/2
        
        frame.hitboxes << hitbox
        this_frames_unique_part_and_hitbox_strs << hitbox.to_data
      else
        part = Part.new
        
        df_unique_part = df_unique_parts[df_spr["name"]]
        if df_unique_part.nil?
          raise ImportError.new("Failed to find part with name #{df_spr["name"]}")
        end
        x_on_big_gfx_page = df_unique_part["x"].to_i
        y_on_big_gfx_page = df_unique_part["y"].to_i
        part.gfx_x_offset = x_on_big_gfx_page % gfx_page_width_with_padding
        part.gfx_y_offset = y_on_big_gfx_page % gfx_page_width_with_padding
        part.width = df_unique_part["w"].to_i
        part.height = df_unique_part["h"].to_i
        # Clamp the part width/height so it doesn't go past the bounds of a GFX page.
        part.width = [part.width, gfx_page_canvas_width-part.gfx_x_offset].min
        part.height = [part.height, gfx_page_canvas_width-part.gfx_y_offset].min
        
        gfx_page_index_on_big_gfx_page = (x_on_big_gfx_page / gfx_page_width_with_padding) + (y_on_big_gfx_page / gfx_page_width_with_padding * big_gfx_page_width)
        gfx_page_index = gfx_page_index_on_big_gfx_page % big_gfx_page_width
        if gfx_page_canvas_width == 256
          # 256x256 pages take up 4 times the space of 128x128 pages.
          gfx_page_index = gfx_page_index * 4
        end
        part.gfx_page_index = gfx_page_index
        part.palette_index = gfx_page_index_on_big_gfx_page / big_gfx_page_width
        
        part.x_pos = df_spr["x"].to_i - part.width/2
        part.y_pos = df_spr["y"].to_i - part.height/2
        part.horizontal_flip = (df_spr["flipH"].to_i == 1)
        part.vertical_flip = (df_spr["flipV"].to_i == 1)
        
        frame.parts << part
        this_frames_unique_part_and_hitbox_strs << part.to_data
      end
    end
    
    return [frame, this_frames_unique_part_and_hitbox_strs]
  end
end
