
class GenericEditable
  attr_reader :ram_pointer,
              :data_format,
              :index,
              :bitfield_docs,
              :kind,
              :fs,
              :name,
              :description,
              :attributes,
              :attribute_integers,
              :attribute_integer_lengths,
              :attribute_bitfields,
              :attribute_bitfield_lengths
  
  def initialize(index, item_type, fs)
    @index = index
    @fs = fs
    format_length = item_type[:format].inject(0){|sum, attr| sum += attr[0]}
    @ram_pointer = item_type[:list_pointer] + index*format_length
    @data_format = item_type[:format]
    @kind = item_type[:kind]
    
    @bitfield_docs = case @kind
    when :enemy
      ENEMY_DNA_BITFIELD_ATTRIBUTES
    else
      ITEM_BITFIELD_ATTRIBUTES
    end
    
    read_from_rom()
  end
  
  def read_from_rom()
    @attributes = {}
    @attribute_integers = {}
    @attribute_integer_lengths = []
    @attribute_bitfields = {}
    @attribute_bitfield_lengths = []
    
    attr_data = fs.read(ram_pointer, data_format_length).unpack(attribute_format_string)
    data_format.each do |attribute_length, attribute_name, attribute_type|
      if @attributes[attribute_name]
        raise "Duplicate attribute name: #{attribute_name}"
      end
      
      case attribute_type
      when :bitfield
        bitfield_doc = @bitfield_docs[attribute_name]
        val = Bitfield.new(attr_data.shift, bitfield_doc)
        @attribute_bitfields[attribute_name] = val
        @attribute_bitfield_lengths << attribute_length
        @attributes[attribute_name] = val
      else
        val = attr_data.shift
        @attribute_integers[attribute_name] = val
        @attribute_integer_lengths << attribute_length
        @attributes[attribute_name] = val
      end
    end
    
    case kind
    when :enemy
      @name = Text.new(TEXT_REGIONS["Enemy Names"].begin + index, fs)
      @description = Text.new(TEXT_REGIONS["Enemy Descriptions"].begin + index, fs)
    when :skill
      case GAME
      when "dos"
        @name = Text.new(TEXT_REGIONS["Soul Names"].begin + index, fs)
        @description = Text.new(TEXT_REGIONS["Soul Descriptions"].begin + index, fs)
      when "por"
        @name = Text.new(TEXT_REGIONS["Skill Names"].begin + index, fs)
        @description = Text.new(TEXT_REGIONS["Skill Descriptions"].begin + index, fs)
      when "ooe"
        @name = Text.new(TEXT_REGIONS["Item Names"].begin + self["Item ID"], fs)
        @description = Text.new(TEXT_REGIONS["Item Descriptions"].begin + self["Item ID"], fs)
      end
    else # item
      @name = Text.new(TEXT_REGIONS["Item Names"].begin + self["Item ID"], fs)
      @description = Text.new(TEXT_REGIONS["Item Descriptions"].begin + self["Item ID"], fs)
    end
  end
  
  def write_to_rom
    new_data = []
    data_format.each do |attribute_length, attribute_name, attribute_type|
      case attribute_type
      when :bitfield
        new_data << @attributes[attribute_name].value
      else
        new_data << @attributes[attribute_name]
      end
    end
    fs.write(ram_pointer, new_data.pack(attribute_format_string))
  end
  
  def [](attribute_name)
    @attributes[attribute_name]
  end
  
  def []=(attribute_name, new_value)
    @attributes[attribute_name] = new_value
    
    if @attribute_integers.include?(attribute_name)
      @attribute_integers[attribute_name] = new_value
    else
      @attribute_bitfields[attribute_name] = new_value
    end
  end
  
  def data_format_length
    data_format.inject(0){|sum, attr| sum += attr[0]}
  end
  
private
  
  def attribute_format_string
    data_format.map do |attribute_length, attribute_name, attribute_type|
      case attribute_length
      when 1
        "C"
      when 2
        "v"
      when 4
        "V"
      else
        raise "Invalid data format for #{GAME}"
      end
    end.join
  end
end
