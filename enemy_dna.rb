
class EnemyDNA
  attr_reader :enemy_id,
              :enemy_dna_ram_pointer,
              :fs
  
  attr_accessor :name,
                :description,
                :dna_attributes,
                :dna_attribute_bitfields
  
  def initialize(enemy_id, fs)
    @enemy_id = enemy_id
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    @name = Text.new(STRING_REGIONS["Enemy Names"].begin + enemy_id, fs)
    @description = Text.new(STRING_REGIONS["Enemy Descriptions"].begin + enemy_id, fs)
    
    @enemy_dna_ram_pointer = ENEMY_DNA_RAM_START_OFFSET + ENEMY_DNA_LENGTH*enemy_id
    
    @dna_attributes = {}
    @dna_attribute_bitfields = {}
    attributes = fs.read(enemy_dna_ram_pointer, ENEMY_DNA_LENGTH).unpack(attribute_format_string)
    ENEMY_DNA_FORMAT.each do |attribute_length, attribute_name, attribute_type|
      case attribute_type
      when :bitfield
        @dna_attribute_bitfields[attribute_name] = VulnerabilityList.new(attributes.shift)
      else
        @dna_attributes[attribute_name] = attributes.shift
      end
    end
  end
  
  def write_to_rom
    new_data = []
    ENEMY_DNA_FORMAT.each do |attribute_length, attribute_name, attribute_type|
      case attribute_type
      when :bitfield
        new_data << @dna_attribute_bitfields[attribute_name].value
      else
        new_data << @dna_attributes[attribute_name]
      end
    end
    fs.write(enemy_dna_ram_pointer, new_data.pack(attribute_format_string))
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
