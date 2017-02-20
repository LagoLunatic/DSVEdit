class SpriteInfoExtractor
  class CreateCodeReadError < StandardError ; end
  
  def self.get_gfx_and_palette_and_sprite_from_create_code(create_code_pointer, fs, overlay_to_load, reused_info, ptr_to_ptr_to_files_to_load=nil)
    # This function attempts to find the enemy/object's gfx files, palette pointer, and sprite file.
    # It first looks in the list of files to load for that enemy/object (if given).
    # If any are missing after looking there, it then looks in the create code for pointers that look like they could be the pointers we want.
    
    #puts "create code: %08X" % create_code_pointer if create_code_pointer
    
    if overlay_to_load.is_a?(Integer)
      fs.load_overlay(overlay_to_load)
    elsif overlay_to_load.is_a?(Array)
      overlay_to_load.each do |overlay|
        fs.load_overlay(overlay)
      end
    end
    
    if GAME == "por"
      fs.load_overlay(4)
    end
    
    init_code_pointer      = reused_info[:init_code] || create_code_pointer
    gfx_sheet_ptr_index    = reused_info[:gfx_sheet_ptr_index] || 0
    palette_offset         = reused_info[:palette_offset] || 0
    palette_list_ptr_index = reused_info[:palette_list_ptr_index] || 0
    sprite_ptr_index       = reused_info[:sprite_ptr_index] || 0
    ignore_files_to_load   = reused_info[:ignore_files_to_load] || false
    sprite_file_pointer    = reused_info[:sprite] || nil
    gfx_file_pointers      = reused_info[:gfx_files] || nil
    gfx_wrapper            = reused_info[:gfx_wrapper] || nil
    palette_pointer        = reused_info[:palette] || nil
    
    if sprite_file_pointer && gfx_file_pointers && palette_pointer
      return [gfx_file_pointers, palette_pointer, palette_offset, sprite_file_pointer, nil]
    elsif sprite_file_pointer && gfx_wrapper && palette_pointer
      gfx_file_pointers = unpack_gfx_pointer_list(gfx_wrapper, fs)
      return [gfx_file_pointers, palette_pointer, palette_offset, sprite_file_pointer, nil]
    end
    
    if init_code_pointer == -1
      raise CreateCodeReadError.new("This entity has no sprite.")
    end
    
    gfx_files_to_load = []
    sprite_files_to_load = []
    skeleton_files_to_load = []
    palette_pointer_to_load = nil
    if ptr_to_ptr_to_files_to_load && !ignore_files_to_load
      pointer_to_start_of_file_index_list = fs.read(ptr_to_ptr_to_files_to_load, 4).unpack("V").first
      
      i = 0
      while true
        file_index_or_palette_pointer, file_data_type = fs.read(pointer_to_start_of_file_index_list+i*8, 8).unpack("VV")
        #puts "%08X %08X" % [file_index_or_palette_pointer, file_data_type]
        if file_index_or_palette_pointer == 0xFFFFFFFF
          # End of list.
          break
        end
        if file_data_type == 1 || file_data_type == 2
          file_index = file_index_or_palette_pointer
          file = fs.files_by_index[file_index]
          
          if file_data_type == 1
            render_mode = fs.read(file[:ram_start_offset]+1, 1).unpack("C").first
            canvas_width = fs.read(file[:ram_start_offset]+2, 1).unpack("C").first
            gfx_files_to_load << {file: file, render_mode: render_mode, canvas_width: canvas_width}
          elsif file_data_type == 2
            if file[:file_path] =~ /\/so2?\/.+\.dat/
              sprite_files_to_load << file
            elsif file[:file_path] =~ /\/jnt\/.+\.jnt/
              skeleton_files_to_load << file
            else
              puts file
            end
          end
        elsif file_data_type == 3
          palette_pointer_to_load = file_index_or_palette_pointer
        else
          raise CreateCodeReadError.new("Unknown file data type: #{file_data_type}")
        end
        
        i += 1
      end
      
      #if gfx_files_to_load.empty? && sprite_files_to_load.empty?
      #  raise CreateCodeReadError.new("No gfx files or sprite files to load found")
      #end
      #if gfx_files_to_load.empty?
      #  raise CreateCodeReadError.new("No gfx files to load found")
      #end
      #if sprite_files_to_load.empty?
      #  raise CreateCodeReadError.new("No sprite file to load found")
      #end
      #if palette_pointer_to_load.nil?
      #  raise CreateCodeReadError.new("No palette to load found")
      #end
      
      if gfx_files_to_load.length > 0 && sprite_files_to_load.length > 0 && palette_pointer_to_load
        gfx_file_pointers = gfx_files_to_load.map{|file| file[:file][:ram_start_offset]}
        sprite_file_pointer = sprite_files_to_load.first[:ram_start_offset]
        
        return [gfx_file_pointers, palette_pointer_to_load, palette_offset, sprite_file_pointer, skeleton_files_to_load.first]
      end
    end
    
    
    
    possible_gfx_pointers = []
    gfx_page_pointer = nil
    list_of_gfx_page_pointers_wrapper_pointer = nil
    possible_palette_pointers = []
    palette_pointer = nil
    possible_sprite_pointers = []
    sprite_file_pointer = nil
    
    data = fs.read(init_code_pointer, 4*1000, allow_length_to_exceed_end_of_file: true)
    
    data.unpack("V*").each_with_index do |word, i|
      if (0x02000000..0x02FFFFFF).include?(word)
        possible_gfx_pointers << word
        possible_palette_pointers << word
        possible_sprite_pointers << word
      end
    end
    
    
    
    if possible_gfx_pointers.empty? && gfx_files_to_load.empty?
      raise CreateCodeReadError.new("Failed to find any possible enemy gfx pointers.")
    end
    
    valid_gfx_pointers = possible_gfx_pointers.select do |pointer|
      header_vals = fs.read(pointer, 4).unpack("C*") rescue next
      data = fs.read(pointer+4, 4).unpack("V").first
      if data >= 0x02000000 && data < 0x03000000
        # There's a chance this might just be something that looks like a pointer (like palette data), so check to make sure it really is one.
        possible_gfx_page_pointer = fs.read(data, 4).unpack("V").first rescue next
        if possible_gfx_page_pointer >= 0x02000000 && possible_gfx_page_pointer < 0x03000000
          # List of GFX pages
          header_vals.all?{|val| val < 0x50} && (1..2).include?(header_vals[1])
        else
          false
        end
      elsif data == 0x10
        # Just one GFX page, not a list
        header_vals[0] == 0 && (1..2).include?(header_vals[1]) && header_vals[2] == 0x10 && header_vals[3] == 0
      elsif data == 0x20
        # Canvas width is doubled.
        header_vals[0] == 0 && (1..2).include?(header_vals[1]) && header_vals[2] == 0x20 && header_vals[3] == 0
      else
        false
      end
    end
    possible_palette_pointers -= valid_gfx_pointers
    
    if gfx_files_to_load.empty?
      if valid_gfx_pointers.empty?
        raise CreateCodeReadError.new("Failed to find any valid enemy gfx pointers.")
      end
      if gfx_sheet_ptr_index >= valid_gfx_pointers.length
        raise CreateCodeReadError.new("Failed to find enough valid enemy gfx pointers to match the reused enemy gfx sheet index. (#{valid_gfx_pointers.length} found, #{gfx_sheet_ptr_index+1} needed.)")
      end
      
      gfx_wrapper = valid_gfx_pointers[gfx_sheet_ptr_index]
      
      gfx_file_pointers = unpack_gfx_pointer_list(gfx_wrapper, fs)
    end
    
    
    
    if possible_palette_pointers.empty?
      raise CreateCodeReadError.new("Failed to find any possible enemy palette pointers.")
    end
    
    valid_palette_pointers = possible_palette_pointers.select do |pointer|
      header_vals = fs.read(pointer, 4).unpack("C*") rescue next
      header_vals[0] == 0 && header_vals[1] == 01 && header_vals[2] > 0 && header_vals [3] == 0
    end
    
    if valid_palette_pointers.empty?
      raise CreateCodeReadError.new("Failed to find any valid enemy palette pointers.")
    end
    if palette_list_ptr_index >= valid_palette_pointers.length
      raise CreateCodeReadError.new("Failed to find enough valid enemy palette pointers to match the reused enemy palette list index. (#{valid_palette_pointers.length} found, #{palette_list_ptr_index+1} needed.)")
    end
    
    palette_pointer = valid_palette_pointers[palette_list_ptr_index]
    
    
    
    if sprite_files_to_load.empty?
      all_sprite_pointers = fs.files.select do |id, file|
        file[:type] == :file && file[:file_path] =~ /^\/so\/p_/
      end.map do |id, file|
        file[:ram_start_offset]
      end
      valid_sprite_pointers = possible_sprite_pointers.select do |pointer|
        if all_sprite_pointers.include?(pointer)
          true
        else
          # Check if any of the overlay files containing sprite data include this pointer.
          OVERLAY_FILES_WITH_SPRITE_DATA.any? do |overlay_id|
            overlay = fs.overlays[overlay_id]
            range = (overlay[:ram_start_offset]..overlay[:ram_start_offset]+overlay[:size]-1)
            range.include?(pointer)
          end
        end
      end
      if valid_sprite_pointers.empty?
        raise CreateCodeReadError.new("Failed to find any valid enemy sprite pointers.")
      end
      
      if sprite_ptr_index >= valid_sprite_pointers.length
        raise CreateCodeReadError.new("Failed to find enough valid enemy sprite pointers to match the reused enemy sprite index. (#{valid_sprite_pointers.length} found, #{sprite_ptr_index+1} needed.)")
      end
      sprite_file_pointer = valid_sprite_pointers[sprite_ptr_index]
      if sprite_file_pointer.nil?
        raise CreateCodeReadError.new("Failed to find any possible sprite pointers.")
      end
    end
    
    
    
    if ptr_to_ptr_to_files_to_load
      if gfx_files_to_load.length > 0
        gfx_file_pointers = gfx_files_to_load.map{|file| file[:file][:ram_start_offset]}
      end
      if palette_pointer_to_load
        palette_pointer = palette_pointer_to_load
      end
      if sprite_files_to_load.length > 0
        sprite_file_pointer = sprite_files_to_load.first[:ram_start_offset]
      end
      if skeleton_files_to_load.length > 0
        skeleton_file = skeleton_files_to_load.first
      end
    end
    
    return [gfx_file_pointers, palette_pointer, palette_offset, sprite_file_pointer, skeleton_file]
  end
  
  def self.unpack_gfx_pointer_list(gfx_wrapper, fs)
    data = fs.read(gfx_wrapper+4, 4).unpack("V").first
    if data >= 0x02000000 && data < 0x03000000
      _, _, number_of_gfx_pages, _ = fs.read(gfx_wrapper, 4).unpack("C*")
      pointer_to_list_of_gfx_file_pointers = data
      
      gfx_file_pointers = fs.read(pointer_to_list_of_gfx_file_pointers, 4*number_of_gfx_pages).unpack("V*")
    else
      gfx_file_pointers = [gfx_wrapper]
    end
    
    return gfx_file_pointers
  end
end
