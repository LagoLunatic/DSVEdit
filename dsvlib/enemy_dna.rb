
class EnemyDNA
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
    overlay_to_load = OVERLAY_FILE_FOR_ENEMY_AI[enemy_id]
    reused_info = REUSED_ENEMY_INFO[enemy_id] || {}
    ptr_to_ptr_to_files_to_load = ENEMY_FILES_TO_LOAD_LIST + enemy_id*4
    
    return SpriteInfoExtractor.get_gfx_and_palette_and_sprite_from_create_code(self["Init AI"], fs, overlay_to_load, reused_info, ptr_to_ptr_to_files_to_load)
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
