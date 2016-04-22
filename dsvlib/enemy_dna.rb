
class EnemyDNA
  class InitAIReadError < StandardError ; end
  
  attr_reader :enemy_id,
              :enemy_dna_ram_pointer,
              :fs
  
  attr_accessor :name,
                :description,
                :dna_attributes,
                :dna_attribute_integers,
                :dna_attribute_integer_lengths,
                :dna_attribute_bitfields
  
  def initialize(enemy_id, fs)
    @enemy_id = enemy_id
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    @name = Text.new(TEXT_REGIONS["Enemy Names"].begin + enemy_id, fs)
    @description = Text.new(TEXT_REGIONS["Enemy Descriptions"].begin + enemy_id, fs)
    
    @enemy_dna_ram_pointer = ENEMY_DNA_RAM_START_OFFSET + ENEMY_DNA_LENGTH*enemy_id
    
    @dna_attributes = {}
    @dna_attribute_integers = {}
    @dna_attribute_integer_lengths = []
    @dna_attribute_bitfields = {}
    attributes = fs.read(enemy_dna_ram_pointer, ENEMY_DNA_LENGTH).unpack(attribute_format_string)
    ENEMY_DNA_FORMAT.each do |attribute_length, attribute_name, attribute_type|
      case attribute_type
      when :bitfield
        val = Bitfield.new(attributes.shift)
        @dna_attribute_bitfields[attribute_name] = val
        @dna_attributes[attribute_name] = val
      else
        val = attributes.shift
        @dna_attribute_integers[attribute_name] = val
        @dna_attribute_integer_lengths << attribute_length
        @dna_attributes[attribute_name] = val
      end
    end
  end
  
  def get_gfx_and_palette_and_animation_from_init_ai
    # This function attempts to find the enemy's gfx files, palette pointer, and animation file. These aren't stored directly in the enemy DNA data.
    # Instead they are loaded as part of the Init AI code, so we must look through this code for pointers that look like they could be the pointers we want.
    
    overlay_to_load = OVERLAY_FILE_FOR_ENEMY_AI[enemy_id]
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
    
    possible_gfx_pointers = []
    gfx_page_pointer = nil
    list_of_gfx_page_pointers_wrapper_pointer = nil
    list_of_gfx_page_pointers = []
    possible_palette_pointers = []
    enemy_palette_pointer = nil
    possible_animation_pointers = []
    animation_file_pointer = nil
    
    reused_info = REUSED_ENEMY_INFO[enemy_id] || {}
    init_code_pointer      = reused_info[:init_code] || self["Init AI"]
    gfx_sheet_ptr_index    = reused_info[:gfx_sheet_ptr_index] || 0
    palette_offset         = reused_info[:palette_offset] || 0
    palette_list_ptr_index = reused_info[:palette_list_ptr_index] || 0
    animation_ptr_index    = reused_info[:animation_ptr_index] || 0
    
    p ("ai at %08X" % init_code_pointer)
    data = fs.read(init_code_pointer, 4*1000, allow_length_to_exceed_end_of_file: true)
    
    data.unpack("V*").each_with_index do |word, i|
      if (0x02000000..0x02FFFFFF).include?(word)
        puts "found pointer: %08X at index: %08X" % [word, i*4+init_code_pointer]
      end
      
      if    ENEMY_GFX_POINTER_RANGE.include?(word) || (0x022B0000..0x022B1FFF).include?(word) || (0x022E0000..0x022EFFFF).include?(word) || (0x022DE304..0x022DE304).include?(word)
        possible_gfx_pointers << word
      elsif ENEMY_GFX_LIST_POINTER_RANGES.any?{|range| range.include?(word)}
        possible_gfx_pointers << word
      elsif ENEMY_GFX_LIST_OVERLAY_POINTER_RANGES.any?{|range| range.include?(word)} && overlay_to_load
        possible_gfx_pointers << word
      end
      if (0x02115400..0x021155FF).include?(word) || (0x02130000..0x0213FFFF).include?(word) || (0x021D0000..0x021DFFFF).include?(word)
        possible_animation_pointers << word
      elsif ENEMY_PALETTE_POINTER_RANGES.any?{|range| range.include?(word)} #|| (0x022D0000..0x022DFFFF).include?(word) || (0x022E0014..0x022E0014).include?(word)
        possible_palette_pointers << word
      end
    end
    
    
    
    
    if possible_gfx_pointers.empty?
      raise InitAIReadError.new("Failed to find any possible enemy gfx pointers.")
    end
    
    valid_gfx_pointers = possible_gfx_pointers.select do |pointer|
      header_vals = fs.read(pointer, 4).unpack("C*")
      data = fs.read(pointer+4, 4).unpack("V").first
      if data >= 0x02000000 && data < 0x03000000
        # gfx list
        header_vals.all?{|val| val < 0x50} && (1..2).include?(header_vals[1])
      elsif data == 0x10
        # not a list, just gfx
        header_vals[0] == 0 && (1..2).include?(header_vals[1]) && header_vals[2] == 0x10 && header_vals[3] == 0
      elsif data == 0x20
        # canvas width is doubled.
        header_vals[0] == 0 && (1..2).include?(header_vals[1]) && header_vals[2] == 0x20 && header_vals[3] == 0
      else
        false
      end
    end
    possible_palette_pointers -= valid_gfx_pointers
    
    if valid_gfx_pointers.empty?
      raise InitAIReadError.new("Failed to find any valid enemy gfx pointers.")
    end
    if gfx_sheet_ptr_index >= valid_gfx_pointers.length
      raise InitAIReadError.new("Failed to find enough valid enemy gfx pointers to match the reused enemy gfx sheet index. (#{valid_gfx_pointers.length} found, #{gfx_sheet_ptr_index+1} needed.)")
    end
    
    gfx_pointer = valid_gfx_pointers[gfx_sheet_ptr_index]
    data = fs.read(gfx_pointer+4, 4).unpack("V").first
    if data >= 0x02000000 && data < 0x03000000
      # gfx list
      list_of_gfx_page_pointers_wrapper_pointer = gfx_pointer
    elsif data == 0x10 || data == 0x20
      # not a list, just gfx
      gfx_page_pointer = gfx_pointer
    else
      raise InitAIReadError.new("this error shouldn't happen")
    end
    
    if gfx_page_pointer
      puts "gfx     : %08X" % gfx_page_pointer
      
      list_of_gfx_page_pointers = [gfx_page_pointer]
    elsif list_of_gfx_page_pointers_wrapper_pointer
      pointer_to_list_of_gfx_page_pointers = fs.read(list_of_gfx_page_pointers_wrapper_pointer+4, 4).unpack("V*").first
      
      puts "gfxwrap : %08X" % list_of_gfx_page_pointers_wrapper_pointer if list_of_gfx_page_pointers_wrapper_pointer
      
      i = 0
      while true
        begin
          gfx_page_pointer = fs.read(pointer_to_list_of_gfx_page_pointers+i*4, 4).unpack("V").first
        rescue NDSFileSystem::OffsetPastEndOfFileError
          break
        end
        if gfx_page_pointer < 0x2000000 || gfx_page_pointer >= 0x3000000
          break
        end
        list_of_gfx_page_pointers << gfx_page_pointer
        i += 1
      end
    else
      raise InitAIReadError.new("this error shouldn't happen")
    end
    
    if list_of_gfx_page_pointers.empty?
      raise InitAIReadError.new("list of gfx pages for enemy empty")
    end
    
    
    
    
    if possible_palette_pointers.empty?
      raise InitAIReadError.new("Failed to find any possible enemy palette pointers.")
    end
    
    valid_palette_pointers = possible_palette_pointers.select do |pointer|
      header_vals = fs.read(pointer, 4).unpack("C*")
      header_vals[0] == 0 && header_vals[1] == 01 && header_vals[2] > 0 && header_vals [3] == 0
    end
    
    if valid_palette_pointers.empty?
      raise InitAIReadError.new("Failed to find any valid enemy palette pointers.")
    end
    if palette_list_ptr_index >= valid_palette_pointers.length
      raise InitAIReadError.new("Failed to find enough valid enemy palette pointers to match the reused enemy palette list index. (#{valid_palette_pointers.length} found, #{palette_list_ptr_index+1} needed.)")
    end
    
    enemy_palette_pointer = valid_palette_pointers[palette_list_ptr_index]
    puts "palette : %08X" % enemy_palette_pointer
    
    
    
    gfx_files = []
    list_of_gfx_page_pointers.each_with_index do |gfx_pointer, i|
      gfx_file = fs.find_file_by_ram_start_offset(gfx_pointer)
      if gfx_file.nil?
        if gfx_files.empty?
          raise InitAIReadError.new("Couldn't find gfx file! pointer: %08X" % gfx_pointer) # TODO
        else
          break # this probably just means we read too many gfx pointers from the list, so we just stop looking at the list of pointers now.
        end
      end
      
      render_mode = fs.read(gfx_pointer+1, 1).unpack("C").first
      canvas_width = fs.read(gfx_pointer+2, 1).unpack("C").first
      
      gfx_files << {file: gfx_file, render_mode: render_mode, canvas_width: canvas_width}
    end
    
    if animation_ptr_index >= possible_animation_pointers.length
      raise InitAIReadError.new("Failed to find enough valid enemy animation pointers to match the reused enemy animation index. (#{possible_animation_pointers.length} found, #{animation_ptr_index+1} needed.)")
    end
    animation_file_pointer = possible_animation_pointers[animation_ptr_index]
    if animation_file_pointer.nil?
      raise InitAIReadError.new("Failed to find any possible animation pointers.")
    end
    animation_file = fs.find_file_by_ram_start_offset(animation_file_pointer)
    if animation_file.nil?
      raise InitAIReadError.new("Failed to find animation file corresponding to pointer: %08X" % animation_file_pointer)
    end
    
    
    puts "gfxname : #{gfx_files.first[:file][:file_path]}"
    puts "anim    : %08X" % animation_file[:ram_start_offset] if animation_file[:ram_start_offset]
    puts "animname: #{animation_file[:file_path]}"
    puts "animptr : %08X" % animation_file_pointer if animation_file_pointer
    puts "animname: #{animation_file[:file_path]}"
    
    if animation_file[:file_path] !~ /^\/so\//
      raise InitAIReadError.new("Bad animation file: #{animation_file[:file_path]}")
    end
    
    return [gfx_files, enemy_palette_pointer, palette_offset, animation_file]
  end
  
  def write_to_rom
    new_data = []
    ENEMY_DNA_FORMAT.each do |attribute_length, attribute_name, attribute_type|
      case attribute_type
      when :bitfield
        new_data << @dna_attributes[attribute_name].value
      else
        new_data << @dna_attributes[attribute_name]
      end
    end
    fs.write(enemy_dna_ram_pointer, new_data.pack(attribute_format_string))
  end
  
  def [](attribute_name)
    @dna_attributes[attribute_name]
  end
  
  def []=(attribute_name, new_value)
    @dna_attributes[attribute_name] = new_value
  end
  
private
  
  def attribute_format_string
    ENEMY_DNA_FORMAT.map do |attribute_length, attribute_name, attribute_type|
      case attribute_length
      when 1
        "C"
      when 2
        "v"
      when 4
        "V"
      else
        raise "Invalid enemy DNA format for #{GAME}"
      end
    end.join
  end
end
