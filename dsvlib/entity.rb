class Entity
  attr_reader :room,
              :fs
  attr_accessor :entity_ram_pointer,
                :x_pos,
                :y_pos,
                :byte_5,
                :type,
                :subtype,
                :byte_8,
                :var_a,
                :var_b,
                :candle_offset_up
  
  def initialize(room, fs)
    @room = room
    @fs = fs
    @x_pos = @y_pos = @byte_5 = @type = @subtype = @byte_8 = @var_a = @var_b = @candle_offset_up = 0
  end
  
  def read_from_rom(entity_ram_pointer)
    @entity_ram_pointer = entity_ram_pointer
    
    @x_pos, @y_pos = fs.read(entity_ram_pointer,4).unpack("s*")
    if GAME == "hod"
      byte_5_and_type, @subtype, @candle_offset_up, @byte_8 = fs.read(entity_ram_pointer+4,4).unpack("C*")
      @type   = (byte_5_and_type & 0xC0) >> 6
      @byte_5 =  byte_5_and_type & 0x3F
    else
      @byte_5, @type, @subtype, @byte_8 = fs.read(entity_ram_pointer+4,4).unpack("C*")
    end
    @var_a, @var_b = fs.read(entity_ram_pointer+8,4).unpack("v*")
    
    return self
  end
  
  def write_to_rom(skip_updating_entity_list_order=false)
    room.sector.load_necessary_overlay()
    
    if entity_ram_pointer.nil?
      raise "Can't save an entity that doesn't have a pointer"
    end
    
    fs.write(entity_ram_pointer, self.to_data)
    
    unless skip_updating_entity_list_order
      # If the entities in this room changed position, we need to make sure their byte 5s are reordered properly (on GBA only).
      room.update_entity_list_order()
    end
    
    if GAME == "hod"
      room.update_entity_gfx_list()
    end
  end
  
  def to_data
    if GAME == "hod"
      byte_5_and_type  = (@type   &  0x3) << 6
      byte_5_and_type |= (@byte_5 & 0x3F)
      [
        x_pos,
        y_pos,
        byte_5_and_type,
        subtype,
        candle_offset_up,
        byte_8,
        var_a,
        var_b
      ].pack("ssCCCCvv")
    else
      [
        x_pos,
        y_pos,
        byte_5,
        type,
        subtype,
        byte_8,
        var_a,
        var_b
      ].pack("ssCCCCvv")
    end
  end
  
  def is_enemy?
    type == ENEMY_ENTITY_TYPE
  end
  
  def is_common_enemy?
    is_enemy? && COMMON_ENEMY_IDS.include?(subtype)
  end
  
  def is_boss?
    is_enemy? && BOSS_IDS.include?(subtype)
  end
  
  def is_special_object?
    type == SPECIAL_OBJECT_ENTITY_TYPE
  end
  
  def is_candle?
    type == CANDLE_ENTITY_TYPE
  end
  
  def is_normal_pickup?
    type == PICKUP_ENTITY_TYPE
  end
  
  def is_hidden_pickup?
    type == 0x07 && (GAME == "por" || GAME == "ooe")
  end
  
  def is_all_quests_complete_pickup?
    type == 0x06 && GAME == "por"
  end
  
  def is_hard_mode_pickup?
    type == 0x05 && GAME == "aos"
  end
  
  def is_pickup?
    is_normal_pickup? || is_hidden_pickup? || is_all_quests_complete_pickup? || is_hard_mode_pickup?
  end
  
  def is_heart?
    is_pickup? && subtype == 0x00
  end
  
  def is_money_bag?
    is_pickup? && subtype == 0x01
  end
  
  def is_item?
    if GAME == "ooe"
      is_pickup? && subtype == 0xFF
    else
      is_pickup? && ITEM_LOCAL_ID_RANGES.keys.include?(subtype)
    end
  end
  
  def is_skill?
    is_pickup? && PICKUP_SUBTYPES_FOR_SKILLS.include?(subtype)
  end
  
  def is_magic_seal?
    GAME == "dos" && is_pickup? && subtype == 2 && (0x3D..0x41).include?(var_b)
  end
  
  def is_glyph?
    GAME == "ooe" && is_pickup? && (2..4).include?(subtype)
  end
  
  def is_glyph_statue?
    GAME == "ooe" && is_special_object? && subtype == 0x02 && var_a == 0
  end
  
  def is_item_chest?
    GAME == "ooe" && is_special_object? && (0x16..0x17).include?(subtype)
  end
  
  def is_money_chest?
    case GAME
    when "dos"
      is_special_object? && subtype == 1 && var_a == 0x10
    when "por"
      is_special_object? && subtype == 1 && (0xE..0xF).include?(var_a)
    else
      false
    end
  end
  
  def is_boss_door?
    is_special_object? && subtype == BOSS_DOOR_SUBTYPE
  end
  
  def is_wooden_door?
    is_special_object? && subtype == WOODEN_DOOR_SUBTYPE
  end
  
  def is_save_point?
    is_special_object? && subtype == SAVE_POINT_SUBTYPE
  end
  
  def is_villager?
    GAME == "ooe" && is_special_object? && subtype == 0x89
  end
end
