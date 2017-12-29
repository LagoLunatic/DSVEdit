
class GenericEditable
  attr_reader :ram_pointer,
              :data_format,
              :index,
              :bitfield_docs,
              :kind,
              :item_type_name,
              :fs,
              :game,
              :name,
              :description,
              :attributes,
              :attribute_integers,
              :attribute_integer_lengths,
              :attribute_bitfields,
              :attribute_bitfield_lengths
  
  def initialize(index, item_type, game, data_fs = nil)
    @index = index
    @game = game
    if data_fs
      @fs = data_fs
    else
      @fs = game.fs
    end
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
      if GAME == "hod" && index > 0x63
        # Enemies not in the bestiary.
        if game.enemy_docs[index]
          @name = game.enemy_docs[index].split("\n").first
        else
          @name = ""
        end
      else
        @name_text_id = TEXT_REGIONS["Enemy Names"].begin + index
      end
      
      if GAME == "hod"
        @description = ""
      else
        @description_text_id = TEXT_REGIONS["Enemy Descriptions"].begin + index
      end
    when :skill
      case GAME
      when "dos"
        @name_text_id = TEXT_REGIONS["Soul Names"].begin + index
        @description_text_id = TEXT_REGIONS["Soul Descriptions"].begin + index
      when "hod"
        subweapon_index = index % 8
        spellbook_index = index / 8
        subweapon_name = [
          "None",
          "Knife",
          "Axe",
          "Cross",
          "Holy Water",
          "Holy Book",
          "Sacred Fist",
          "Shuriken",
        ][subweapon_index]
        spellbook_name = [
          "Unused",
          "Fire",
          "Ice",
          "Bolt",
          "Wind",
          "Summoning",
        ][spellbook_index]
        @name = "#{spellbook_name} #{subweapon_name}"
        if @name == "Unused Knife"
          @name = "Maxim Mirage"
        end
        if @name == "Unused Shuriken"
          @name = "Healing Spell"
        end
        @description = ""
      when "aos"
        if @item_type_name == "Julius Skills"
          @name = ["Cross", "Holy Water", "Axe", "Grand Cross"][index]
          @description = ""
        elsif index == 0
          @name = "---"
          @description = ""
        else
          zero_index = index - 1
          case @item_type_name
          when "Red Souls"
            @name_text_id = TEXT_REGIONS["Red Soul Names"].begin + zero_index
            @description_text_id = TEXT_REGIONS["Red Soul Descriptions"].begin + zero_index
          when "Blue Souls"
            @name_text_id = TEXT_REGIONS["Blue Soul Names"].begin + zero_index
            @description_text_id = TEXT_REGIONS["Blue Soul Descriptions"].begin + zero_index
          when "Yellow Souls"
            @name_text_id = TEXT_REGIONS["Yellow Soul Names"].begin + zero_index
            @description_text_id = TEXT_REGIONS["Yellow Soul Descriptions"].begin + zero_index
          when "Ability Souls"
            @name_text_id = TEXT_REGIONS["Ability Soul Names"].begin + zero_index
            @description_text_id = TEXT_REGIONS["Ability Soul Descriptions"].begin + zero_index
          end
        end
      when "por"
        @name_text_id = TEXT_REGIONS["Skill Names"].begin + index
        @description_text_id = TEXT_REGIONS["Skill Descriptions"].begin + index
      when "ooe"
        @name_text_id = TEXT_REGIONS["Item Names"].begin + self["Item ID"]
        @description_text_id = TEXT_REGIONS["Item Descriptions"].begin + self["Item ID"]
      end
    when :subweapon # for HoD subweapons
      case GAME
      when "hod"
        subweapon_index = index % 8
        is_strengthed = (index / 8) > 0
        subweapon_name = [
          "None",
          "Knife",
          "Axe",
          "Cross",
          "Holy Water",
          "Holy Book",
          "Sacred Fist",
          "Shuriken",
        ][subweapon_index]
        if is_strengthed
          @name = "Strengthened #{subweapon_name}"
        else
          @name = "#{subweapon_name}"
        end
        @description = ""
      end
    when :player
      @name = PLAYER_NAMES[index]
      @description = ""
    else # item
      @name_text_id = TEXT_REGIONS["Item Names"].begin + self["Item ID"]
      @description_text_id = TEXT_REGIONS["Item Descriptions"].begin + self["Item ID"]
    end
  end
  
  def name
    @name || game.text_database.text_list[@name_text_id].decoded_string.strip.gsub("\\n", "")
  end
  
  def description
    @description || game.text_database.text_list[@description_text_id].decoded_string.strip.gsub("\\n", "")
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
    when "dos"
      icon_index    = (icon_data & 0b00000000_11111111)
      palette_index = (icon_data & 0b11111111_00000000) >> 8
      [icon_index, palette_index]
    when "aos"
      icon_index    = (icon_data & 0b00000000_11111111)
      palette_index = (icon_data & 0b11111111_00000000) >> 8
      # palette_index in AoS is the index in the GBA's object palette RAM.
      # The palette list for item icons gets loaded at offset 4, so to compensate for this we subtract 4 here (and add 4 when writing it back).
      [icon_index-1, palette_index-4]
    when "hod"
      icon_index    = (icon_data & 0b00000000_11111111)
      palette_index = (icon_data & 0b11111111_00000000) >> 8
      [icon_index-1, palette_index]
    else
      icon_index    = (icon_data & 0b00000111_11111111)
      palette_index = (icon_data & 0b11111000_00000000) >> 11
      [icon_index, palette_index]
    end
  end
  
  def self.pack_icon_index_and_palette_index(icon_index, palette_index)
    case GAME
    when "dos"
      icon_data  = icon_index
      icon_data |= palette_index << 8
      icon_data
    when "aos"
      palette_index += 4
      icon_data  = icon_index + 1
      icon_data |= palette_index << 8
      icon_data
    when "hod"
      icon_data  = icon_index + 1
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
