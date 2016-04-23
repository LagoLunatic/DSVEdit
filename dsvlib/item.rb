
class Item
  attr_reader :ram_pointer,
              :item_type_format,
              :fs,
              :name,
              :description,
              :item_attributes,
              :item_attribute_integers,
              :item_attribute_integer_lengths,
              :item_attribute_bitfields
  
  def initialize(pointer, format, fs)
    @fs = fs
    @ram_pointer = pointer
    @item_type_format = format
    
    read_from_rom()
  end
  
  def read_from_rom()
    @item_attributes = {}
    @item_attribute_integers = {}
    @item_attribute_integer_lengths = []
    @item_attribute_bitfields = {}
    
    attributes = fs.read(ram_pointer, item_format_length).unpack(attribute_format_string)
    item_type_format.each do |attribute_length, attribute_name, attribute_type|
      if @item_attributes[attribute_name]
        raise "Duplicate item attribute name: #{attribute_name}"
      end
      
      case attribute_type
      when :bitfield
        val = Bitfield.new(attributes.shift)
        @item_attribute_bitfields[attribute_name] = val
        @item_attributes[attribute_name] = val
      else
        val = attributes.shift
        @item_attribute_integers[attribute_name] = val
        @item_attribute_integer_lengths << attribute_length
        @item_attributes[attribute_name] = val
      end
    end
    
    @name = Text.new(TEXT_REGIONS["Item Names"].begin + self["Item ID"], fs)
    @description = Text.new(TEXT_REGIONS["Item Descriptions"].begin + self["Item ID"], fs)
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
