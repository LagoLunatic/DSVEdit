
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
        val = VulnerabilityList.new(attributes.shift)
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
    fs.load_overlay(overlay_to_load) if overlay_to_load
    
    possible_gfx_pointers = []
    gfx_page_pointer = nil
    list_of_gfx_page_pointers_wrapper_pointer = nil
    list_of_gfx_page_pointers = []
    enemy_palette_pointer = nil
    animation_file_pointer = nil
    
    ai_pointer = self["Init AI"]
    if DUPLICATE_ENEMY_INIT_AIS[ai_pointer]
      ai_pointer = DUPLICATE_ENEMY_INIT_AIS[ai_pointer]
    end
    data = fs.read(ai_pointer, 4*1000, allow_length_to_exceed_end_of_file: true)
    p ("ai at %08X" % ai_pointer)
    
    data.unpack("V*").each do |word|
      if (0x02000000..0x02FFFFFF).include?(word)
        puts "found pointer: %08X" % word
      end
      
      if    (0x022C6760..0x022CFFFF).include?(word)
        possible_gfx_pointers << word
      elsif (0x02290000..0x0229FFFF).include?(word)
        possible_gfx_pointers << word
      elsif (0x02300000..0x0230FFFF).include?(word) && overlay_to_load
        possible_gfx_pointers << word
      elsif (0x02115400..0x021155FF).include?(word) && animation_file_pointer.nil?
        animation_file_pointer = word
      elsif (0x022B0000..0x022C675F).include?(word)
        enemy_palette_pointer = word unless enemy_palette_pointer
      end
    end
    
    if possible_gfx_pointers.empty?
      raise InitAIReadError.new("Failed to find any possible enemy gfx pointers.")
    end
    
    valid_pointers = possible_gfx_pointers.select do |pointer|
      header_vals = fs.read(pointer, 4).unpack("C*")
      data = fs.read(pointer+4, 4).unpack("V").first
      if data >= 0x02000000 && data < 0x03000000
        # gfx list
        header_vals.all?{|val| val < 0x10} && header_vals[1] == 1
      elsif data == 0x10
        # not a list, just gfx
        header_vals[0] == 0 && header_vals[1] == 1 && header_vals[2] == 0x10 && header_vals[3] == 0
      else
        false
      end
    end
    
    if valid_pointers.empty?
      raise InitAIReadError.new("Failed to find any valid enemy gfx pointers.")
    end
    
    gfx_pointer = valid_pointers.first
    data = fs.read(gfx_pointer+4, 4).unpack("V").first
    if data >= 0x02000000 && data < 0x03000000
      # gfx list
      list_of_gfx_page_pointers_wrapper_pointer = gfx_pointer
    elsif data == 0x10
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
        gfx_page_pointer = fs.read(pointer_to_list_of_gfx_page_pointers+i*4, 4).unpack("V").first
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
    
    if enemy_palette_pointer.nil?
      raise InitAIReadError.new("Failed to find enemy palette pointer.")
    end
    
    
    
    
    gfx_files = []
    list_of_gfx_page_pointers.each_with_index do |gfx_pointer, i|
      gfx_file = fs.find_file_by_ram_start_offset(gfx_pointer)
      if gfx_file.nil?
        if gfx_files.empty?
          raise "Couldn't find gfx file! pointer: %08X" % gfx_pointer # TODO
        else
          break # this probably just means we read too many gfx pointers from the list, so we just stop looking at the list of pointers now.
        end
      end
      gfx_files << gfx_file
    end
    
    gfx_files.first[:file_path] =~ /^\/sc\/(?:f|t)_([a-z0-9_]*?)(?:(?:_)?\d+)?\.dat$/
    enemy_base_filename = $1
    if enemy_base_filename.nil?
      raise "Couldn't find file path corresponding to: #{gfx_files.first[:file_path]}"
    end
    
    animation_file = fs.files.values.find{|file| file[:file_path] =~ /^\/so\/p_#{enemy_base_filename}.*\.dat$/}
    if animation_file.nil?
      raise "Couldn't find animation file for: #{enemy_base_filename}"
    end
    puts "palette : %08X" % enemy_palette_pointer
    puts "anim    : %08X" % animation_file[:ram_start_offset]
    
    #animation_file = fs.find_file_by_ram_start_offset(animation_file_pointer)
    #if animation_file[:file_path] !~ /^\/so\//
    #  raise "Bad animation file: #{animation_file[:file_path]}"
    #end
    
    return [gfx_files, enemy_palette_pointer, animation_file]
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

class VulnerabilityList
  attr_reader :value
  
  def initialize(value)
    @value = value
  end
  
  def [](index)
    return ((@value >> index) & 0b1) > 0
  end
  
  def []=(index, bool)
    if bool
      @value |= (1 << index)
    else
      @value &= ~(1 << index)
    end
  end
end
