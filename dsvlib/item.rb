
class Item
  attr_reader :ram_pointer,
              :item_type_format,
              :index,
              :is_skill,
              :fs,
              :name,
              :description,
              :item_attributes,
              :item_attribute_integers,
              :item_attribute_integer_lengths,
              :item_attribute_bitfields,
              :item_attribute_bitfield_lengths
  
  def initialize(index, item_type, fs)
    @index = index
    @fs = fs
    format_length = item_type[:format].inject(0){|sum, attr| sum += attr[0]}
    @ram_pointer = item_type[:list_pointer] + index*format_length
    @item_type_format = item_type[:format]
    @is_skill = item_type[:is_skill]
    
    read_from_rom()
  end
  
  def read_from_rom()
    @item_attributes = {}
    @item_attribute_integers = {}
    @item_attribute_integer_lengths = []
    @item_attribute_bitfields = {}
    @item_attribute_bitfield_lengths = []
    
    attributes = fs.read(ram_pointer, item_format_length).unpack(attribute_format_string)
    item_type_format.each do |attribute_length, attribute_name, attribute_type|
      if @item_attributes[attribute_name]
        raise "Duplicate item attribute name: #{attribute_name}"
      end
      
      case attribute_type
      when :bitfield
        val = Bitfield.new(attributes.shift)
        @item_attribute_bitfields[attribute_name] = val
        @item_attribute_bitfield_lengths << attribute_length
        @item_attributes[attribute_name] = val
      else
        val = attributes.shift
        @item_attribute_integers[attribute_name] = val
        @item_attribute_integer_lengths << attribute_length
        @item_attributes[attribute_name] = val
      end
    end
    
    if is_skill
      case GAME
      when "dos"
        @name = Text.new(TEXT_REGIONS["Soul Names"].begin + index, fs)
        @description = Text.new(TEXT_REGIONS["Soul Descriptions"].begin + index, fs)
      when "por"
        @name = Text.new(TEXT_REGIONS["Skill Names"].begin + index, fs)
        @description = Text.new(TEXT_REGIONS["Skill Descriptions"].begin + index, fs)
      when "ooe"
        raise NotImplementedError.new
      end
    else
      @name = Text.new(TEXT_REGIONS["Item Names"].begin + self["Item ID"], fs)
      @description = Text.new(TEXT_REGIONS["Item Descriptions"].begin + self["Item ID"], fs)
    end
  end
  
  def write_to_rom
    new_data = []
    item_type_format.each do |attribute_length, attribute_name, attribute_type|
      case attribute_type
      when :bitfield
        new_data << @item_attributes[attribute_name].value
      else
        new_data << @item_attributes[attribute_name]
      end
    end
    fs.write(ram_pointer, new_data.pack(attribute_format_string))
  end
  
  def [](attribute_name)
    @item_attributes[attribute_name]
  end
  
  def []=(attribute_name, new_value)
    @item_attributes[attribute_name] = new_value
    
    if @item_attribute_integers.include?(attribute_name)
      @item_attribute_integers[attribute_name] = new_value
    else
      @item_attribute_bitfields[attribute_name] = new_value
    end
  end
  
  def item_format_length
    item_type_format.inject(0){|sum, attr| sum += attr[0]}
  end
  
private
  
  def attribute_format_string
    item_type_format.map do |attribute_length, attribute_name, attribute_type|
      case attribute_length
      when 1
        "C"
      when 2
        "v"
      when 4
        "V"
      else
        raise "Invalid item format for #{GAME}"
      end
    end.join
  end
end
