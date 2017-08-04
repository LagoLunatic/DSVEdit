class SpriteInfo
  class CreateCodeReadError < StandardError ; end
  
  attr_reader :gfx_file_pointers,
              :palette_pointer,
              :palette_offset,
              :sprite_file_pointer,
              :skeleton_file,
              :sprite_file,
              :sprite,
              :gfx_pages
  
  def initialize(gfx_file_pointers, palette_pointer, palette_offset, sprite_file_pointer, skeleton_file, fs, unwrapped_gfx: false)
    @gfx_file_pointers = gfx_file_pointers
    @palette_pointer = palette_pointer
    @palette_offset = palette_offset
    @sprite_file_pointer = sprite_file_pointer
    @skeleton_file = skeleton_file
    @sprite_file = fs.assets_by_pointer[sprite_file_pointer]
    @sprite = Sprite.new(sprite_file_pointer, fs)
    
    @gfx_pages = @gfx_file_pointers.map do |gfx_pointer|
      GfxWrapper.new(gfx_pointer, fs, unwrapped: unwrapped_gfx)
    end
  end
  
  def self.extract_gfx_and_palette_and_sprite_from_create_code(create_code_pointer, fs, overlay_to_load, reused_info, ptr_to_ptr_to_files_to_load=nil)
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
    unwrapped_gfx          = reused_info[:unwrapped_gfx] || false
    
    if sprite_file_pointer && gfx_file_pointers && palette_pointer
      return SpriteInfo.new(gfx_file_pointers, palette_pointer, palette_offset, sprite_file_pointer, nil, fs, unwrapped_gfx: unwrapped_gfx)
    elsif sprite_file_pointer && gfx_wrapper && palette_pointer
      gfx_file_pointers = unpack_gfx_pointer_list(gfx_wrapper, fs)
      return SpriteInfo.new(gfx_file_pointers, palette_pointer, palette_offset, sprite_file_pointer, nil, fs, unwrapped_gfx: unwrapped_gfx)
    end
    
    if init_code_pointer == -1
      raise CreateCodeReadError.new("This entity has no sprite.")
    end
    
    # Clear lowest two bits of init code pointer so it's aligned to 4 bytes.
    init_code_pointer = init_code_pointer & 0xFFFFFFFC
    
    gfx_files_to_load = []
    sprite_files_to_load = []
    skeleton_files_to_load = []
    palette_pointer_to_load = nil
    if ptr_to_ptr_to_files_to_load && !ignore_files_to_load
      pointer_to_start_of_file_index_list = fs.read(ptr_to_ptr_to_files_to_load, 4).unpack("V").first
      
      i = 0
      while true
        asset_index_or_palette_pointer, file_data_type = fs.read(pointer_to_start_of_file_index_list+i*8, 8).unpack("VV")
        
        if asset_index_or_palette_pointer == 0xFFFFFFFF
          # End of list.
          break
        end
        if file_data_type == 1 || file_data_type == 2
          asset_index = asset_index_or_palette_pointer
          file = fs.assets[asset_index]
          
          if file_data_type == 1
            gfx_files_to_load << GfxWrapper.new(file[:asset_pointer], fs)
          elsif file_data_type == 2
            if file[:file_path] =~ /\/so2?\/.+\.dat/
              sprite_files_to_load << file
            elsif file[:file_path] =~ /\/jnt\/.+\.jnt/
              skeleton_files_to_load << file
            elsif file[:file_path] =~ /\/sm\/.+\.nsbmd/
              # 3D model
            elsif file[:file_path] =~ /\/sm\/.+\.nsbtx/
              # 3D texture
            else
              puts "Unknown type of file to load: #{file.inspect}"
            end
          end
        elsif file_data_type == 3
          palette_pointer_to_load = asset_index_or_palette_pointer
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
        gfx_file_pointers = gfx_files_to_load.map{|gfx| gfx.file[:asset_pointer]}
        sprite_file_pointer = sprite_files_to_load.first[:asset_pointer]
        
        return SpriteInfo.new(gfx_file_pointers, palette_pointer_to_load, palette_offset, sprite_file_pointer, skeleton_files_to_load.first, fs, unwrapped_gfx: unwrapped_gfx)
      end
    end
    
    
    
    possible_gfx_pointers = []
    gfx_page_pointer = nil
    list_of_gfx_page_pointers_wrapper_pointer = nil
    possible_palette_pointers = []
    possible_sprite_pointers = []
    
    data = fs.read(init_code_pointer, 4*1000, allow_length_to_exceed_end_of_file: true)
    
    data.unpack("V*").each_with_index do |word, i|
      if fs.is_pointer?(word)
        possible_gfx_pointers << word
        possible_palette_pointers << word
        possible_sprite_pointers << word
      end
    end
    
    
    
    if palette_pointer.nil?
      if possible_gfx_pointers.empty? && gfx_files_to_load.empty?
        raise CreateCodeReadError.new("Failed to find any possible sprite gfx pointers.")
      end
      
      valid_gfx_pointers = possible_gfx_pointers.select do |pointer|
        check_if_valid_gfx_pointer(pointer, fs)
      end
      possible_palette_pointers -= valid_gfx_pointers
      
      if gfx_files_to_load.empty?
        if gfx_wrapper.nil?
          if valid_gfx_pointers.empty?
            raise CreateCodeReadError.new("Failed to find any valid sprite gfx pointers.")
          end
          if gfx_sheet_ptr_index >= valid_gfx_pointers.length
            raise CreateCodeReadError.new("Failed to find enough valid sprite gfx pointers to match the reused sprite gfx sheet index. (#{valid_gfx_pointers.length} found, #{gfx_sheet_ptr_index+1} needed.)")
          end
          
          gfx_wrapper = valid_gfx_pointers[gfx_sheet_ptr_index]
        end
        
        gfx_file_pointers = unpack_gfx_pointer_list(gfx_wrapper, fs)
      end
      possible_palette_pointers -= gfx_files_to_load.map{|gfx| gfx.gfx_pointer}
      
      
      
      if possible_palette_pointers.empty?
        raise CreateCodeReadError.new("Failed to find any possible sprite palette pointers.")
      end
      
      valid_palette_pointers = possible_palette_pointers.select do |pointer|
        check_if_valid_palette_pointer(pointer, fs)
      end
      
      if valid_palette_pointers.empty?
        raise CreateCodeReadError.new("Failed to find any valid sprite palette pointers.")
      end
      if palette_list_ptr_index >= valid_palette_pointers.length
        raise CreateCodeReadError.new("Failed to find enough valid sprite palette pointers to match the reused sprite palette list index. (#{valid_palette_pointers.length} found, #{palette_list_ptr_index+1} needed.)")
      end
      
      palette_pointer = valid_palette_pointers[palette_list_ptr_index]
    end
    
    
    
    if sprite_files_to_load.empty? && sprite_file_pointer.nil?
      valid_sprite_pointers = possible_sprite_pointers.select do |pointer|
        check_if_valid_sprite_pointer(pointer, fs)
      end
      if valid_sprite_pointers.empty?
        raise CreateCodeReadError.new("Failed to find any valid sprite pointers.")
      end
      
      if sprite_ptr_index >= valid_sprite_pointers.length
        raise CreateCodeReadError.new("Failed to find enough valid sprite pointers to match the reused sprite index. (#{valid_sprite_pointers.length} found, #{sprite_ptr_index+1} needed.)")
      end
      sprite_file_pointer = valid_sprite_pointers[sprite_ptr_index]
      if sprite_file_pointer.nil?
        raise CreateCodeReadError.new("Failed to find any possible sprite pointers.")
      end
    end
    
    
    
    if ptr_to_ptr_to_files_to_load
      if gfx_files_to_load.length > 0
        gfx_file_pointers = gfx_files_to_load.map{|gfx| gfx.file[:asset_pointer]}
      end
      if palette_pointer_to_load
        palette_pointer = palette_pointer_to_load
      end
      if sprite_files_to_load.length > 0 && reused_info[:sprite].nil?
        sprite_file_pointer = sprite_files_to_load.first[:asset_pointer]
      end
      if skeleton_files_to_load.length > 0
        skeleton_file = skeleton_files_to_load.first
      end
    end
    
    return SpriteInfo.new(gfx_file_pointers, palette_pointer, palette_offset, sprite_file_pointer, skeleton_file, fs, unwrapped_gfx: unwrapped_gfx)
  end
  
  def self.unpack_gfx_pointer_list(gfx_wrapper, fs)
    if SYSTEM == :nds
      data = fs.read(gfx_wrapper+4, 4).unpack("V").first
      if fs.is_pointer?(data)
        _, _, number_of_gfx_pages, _ = fs.read(gfx_wrapper, 4).unpack("C*")
        pointer_to_list_of_gfx_file_pointers = data
        
        gfx_file_pointers = fs.read(pointer_to_list_of_gfx_file_pointers, 4*number_of_gfx_pages).unpack("V*")
      else
        gfx_file_pointers = [gfx_wrapper]
      end
      
      return gfx_file_pointers
    elsif SYSTEM == :gba
      header_vals = fs.read(gfx_wrapper, 4).unpack("C*")
      is_single_gfx_page = header_vals[0] == 1 && header_vals[1] == 4 && header_vals[2] == 0x10 && header_vals[3] <= 0x10
      
      if is_single_gfx_page
        gfx_file_pointers = [gfx_wrapper]
      else
        number_of_gfx_pages = header_vals[2]
        gfx_file_pointers = fs.read(gfx_wrapper+4, 4*number_of_gfx_pages).unpack("V*")
      end
      
      return gfx_file_pointers
    else
      return [gfx_wrapper]
    end
  end
  
  def self.check_if_valid_gfx_pointer(pointer, fs)
    if SYSTEM == :nds
      header_vals = fs.read(pointer, 4).unpack("C*") rescue return
      data = fs.read(pointer+4, 4).unpack("V").first
      if fs.is_pointer?(data)#data >= 0x02000000 && data < 0x03000000
        # There's a chance this might just be something that looks like a pointer (like palette data), so check to make sure it really is one.
        possible_gfx_page_pointer = fs.read(data, 4).unpack("V").first rescue return
        if fs.is_pointer?(possible_gfx_page_pointer)#possible_gfx_page_pointer >= 0x02000000 && possible_gfx_page_pointer < 0x03000000
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
    else
      header_vals = fs.read(pointer, 4).unpack("C*") rescue return
      data = fs.read(pointer+4, 4).unpack("V").first
      if fs.is_pointer?(data)
        is_single_gfx_page = header_vals[0] == 1 && header_vals[1] == 4 && header_vals[2] == 0x10 && header_vals[3] <= 0x10
        return true if is_single_gfx_page
        
        is_gfx_list = header_vals[0] == 3 && header_vals[1] == 4 && header_vals[2] == 4 && header_vals[3] == 2
        return is_gfx_list
      else
        false
      end
    end
  end
  
  def self.check_if_valid_palette_pointer(pointer, fs)
    if SYSTEM == :nds
      header_vals = fs.read(pointer, 4).unpack("C*") rescue return
      header_vals[0] == 0 && header_vals[1] == 1 && header_vals[2] > 0 && header_vals [3] == 0
    else
      header_vals = fs.read(pointer, 4).unpack("C*") rescue return
      header_vals[0] == 0 && header_vals[1] == 4 && header_vals[2] > 0 && header_vals [3] == 0
    end
  end
  
  def self.check_if_valid_sprite_pointer(pointer, fs)
    if SYSTEM == :nds
      if fs.all_sprite_pointers.include?(pointer)
        true
      else
        # Check if any of the overlay files containing sprite data include this pointer.
        OVERLAY_FILES_WITH_SPRITE_DATA.any? do |overlay_id|
          overlay = fs.overlays[overlay_id]
          range = (overlay[:ram_start_offset]..overlay[:ram_start_offset]+overlay[:size]-1)
          range.include?(pointer)
        end
      end
    else
      num_frames, num_anims, frames_ptr, anims_ptr = fs.read(pointer, 12).unpack("vvVV") rescue return
      return false if !fs.is_pointer?(frames_ptr)
      return false if num_frames == 0
      return false if num_anims > 0 && anims_ptr == 0
      return false if num_frames >= 0x100 # TODO
      return false if num_anims >= 0x100 # TODO
      return false if frames_ptr % 4 != 0
      return false if anims_ptr % 4 != 0
      return false if pointer < 0x08200000 # HACK TODO
      return true
    end
  end
end
