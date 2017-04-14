
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
    @item_type_name = item_type[:name]
    
    @bitfield_docs = case @kind
    when :enemy
      ENEMY_DNA_BITFIELD_ATTRIBUTES
    when :player
      PLAYER_BITFIELD_ATTRIBUTES
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
      @name = Text.new(TEXT_REGIONS["Enemy Names"].begin + index, fs).decoded_string
      @description = Text.new(TEXT_REGIONS["Enemy Descriptions"].begin + index, fs).decoded_string
    when :skill
      case GAME
      when "dos"
        @name = Text.new(TEXT_REGIONS["Soul Names"].begin + index, fs).decoded_string
        @description = Text.new(TEXT_REGIONS["Soul Descriptions"].begin + index, fs).decoded_string
      when "aos"
        case @item_type_name
        when "Red Souls"
          offset = 0
        when "Blue Souls"
          offset = ITEM_TYPES[3][:count]
        when "Yellow Souls"
          offset = ITEM_TYPES[3][:count] + ITEM_TYPES[4][:count]
        when "Ability Souls"
          offset = ITEM_TYPES[3][:count] + ITEM_TYPES[4][:count] + ITEM_TYPES[5][:count]
        end
        @name = Text.new(TEXT_REGIONS["Soul Names"].begin + offset + index, fs).decoded_string
        @description = Text.new(TEXT_REGIONS["Soul Descriptions"].begin + offset + index, fs).decoded_string
      when "por"
        @name = Text.new(TEXT_REGIONS["Skill Names"].begin + index, fs).decoded_string
        @description = Text.new(TEXT_REGIONS["Skill Descriptions"].begin + index, fs).decoded_string
      when "ooe"
        @name = Text.new(TEXT_REGIONS["Item Names"].begin + self["Item ID"], fs).decoded_string
        @description = Text.new(TEXT_REGIONS["Item Descriptions"].begin + self["Item ID"], fs).decoded_string
      end
    when :player
      @name = PLAYER_NAMES[index]
      @description = ""
    else # item
      @name = Text.new(TEXT_REGIONS["Item Names"].begin + self["Item ID"], fs).decoded_string
      @description = Text.new(TEXT_REGIONS["Item Descriptions"].begin + self["Item ID"], fs).decoded_string
    end
    
    @name = @name.strip.gsub("\\n", "")
    @description = @description.strip.gsub("\\n", "")
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
  
  def self.extract_icon_index_and_palette_index(icon_data)
    case GAME
    when "dos", "aos"
      icon_index    = (icon_data & 0b00000000_11111111)
      palette_index = (icon_data & 0b11111111_00000000) >> 8
      [icon_index, palette_index]
    else
      icon_index    = (icon_data & 0b00000111_11111111)
      palette_index = (icon_data & 0b11111000_00000000) >> 11
      [icon_index, palette_index]
    end
  end
  
  def self.pack_icon_index_and_palette_index(icon_index, palette_index)
    case GAME
    when "dos", "aos"
      icon_data  = icon_index
      icon_data |= palette_index << 8
      icon_data
    else
      icon_data  = icon_index
      icon_data |= palette_index << 11
      icon_data
    end
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
