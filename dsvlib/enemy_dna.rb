
class EnemyDNA
  class InitAIReadError < StandardError ; end
  
  attr_reader :enemy_id,
              :enemy_dna_ram_pointer,
              :fs,
              :name,
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
  
  def get_gfx_and_palette_and_sprite_from_init_ai
    # This function attempts to find the enemy's gfx files, palette pointer, and sprite file. These aren't stored directly in the enemy DNA data.
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
    possible_palette_pointers = []
    palette_pointer = nil
    possible_sprite_pointers = []
    sprite_file_pointer = nil
    
    reused_info = REUSED_ENEMY_INFO[enemy_id] || {}
    init_code_pointer      = reused_info[:init_code] || self["Init AI"]
    gfx_sheet_ptr_index    = reused_info[:gfx_sheet_ptr_index] || 0
    palette_offset         = reused_info[:palette_offset] || 0
    palette_list_ptr_index = reused_info[:palette_list_ptr_index] || 0
    sprite_ptr_index       = reused_info[:sprite_ptr_index] || 0
    
    data = fs.read(init_code_pointer, 4*1000, allow_length_to_exceed_end_of_file: true)
    
    data.unpack("V*").each_with_index do |word, i|
      if (0x02000000..0x02FFFFFF).include?(word)
        #puts "found pointer: %08X at index: %08X" % [word, i*4+init_code_pointer]
        
        possible_gfx_pointers << word
        possible_palette_pointers << word
        possible_sprite_pointers << word
      end
    end
    
    
    
    if possible_gfx_pointers.empty?
      raise InitAIReadError.new("Failed to find any possible enemy gfx pointers.")
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
    
    if valid_gfx_pointers.empty?
      raise InitAIReadError.new("Failed to find any valid enemy gfx pointers.")
    end
    if gfx_sheet_ptr_index >= valid_gfx_pointers.length
      raise InitAIReadError.new("Failed to find enough valid enemy gfx pointers to match the reused enemy gfx sheet index. (#{valid_gfx_pointers.length} found, #{gfx_sheet_ptr_index+1} needed.)")
    end
    
    gfx_pointer = valid_gfx_pointers[gfx_sheet_ptr_index]
    
    
    
    if possible_palette_pointers.empty?
      raise InitAIReadError.new("Failed to find any possible enemy palette pointers.")
    end
    
    valid_palette_pointers = possible_palette_pointers.select do |pointer|
      header_vals = fs.read(pointer, 4).unpack("C*") rescue next
      header_vals[0] == 0 && header_vals[1] == 01 && header_vals[2] > 0 && header_vals [3] == 0
    end
    
    if valid_palette_pointers.empty?
      raise InitAIReadError.new("Failed to find any valid enemy palette pointers.")
    end
    if palette_list_ptr_index >= valid_palette_pointers.length
      raise InitAIReadError.new("Failed to find enough valid enemy palette pointers to match the reused enemy palette list index. (#{valid_palette_pointers.length} found, #{palette_list_ptr_index+1} needed.)")
    end
    
    palette_pointer = valid_palette_pointers[palette_list_ptr_index]
    
    
    
    all_sprite_pointers = fs.files.select do |id, file|
      file[:type] == :file && file[:file_path] =~ /^\/so\/p_/
    end.map do |id, file|
      file[:ram_start_offset]
    end
    valid_sprite_pointers = possible_sprite_pointers.select do |pointer|
      all_sprite_pointers.include?(pointer)
    end
    if valid_sprite_pointers.empty?
      raise InitAIReadError.new("Failed to find any valid enemy sprite pointers.")
    end
    
    if sprite_ptr_index >= valid_sprite_pointers.length
      raise InitAIReadError.new("Failed to find enough valid enemy sprite pointers to match the reused enemy sprite index. (#{valid_sprite_pointers.length} found, #{sprite_ptr_index+1} needed.)")
    end
    sprite_file_pointer = valid_sprite_pointers[sprite_ptr_index]
    if sprite_file_pointer.nil?
      raise InitAIReadError.new("Failed to find any possible sprite pointers.")
    end
    
    sprite_file = fs.get_sprite_file_from_pointer(sprite_file_pointer)
    
    
    
    return [gfx_pointer, palette_pointer, palette_offset, sprite_file]
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
    
    if @dna_attribute_integers.include?(attribute_name)
      @dna_attribute_integers[attribute_name] = new_value
    else
      @dna_attribute_bitfields[attribute_name] = new_value
    end
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
