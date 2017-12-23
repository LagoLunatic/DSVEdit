class Entity
  attr_reader :room,
              :fs
  attr_accessor :entity_ram_pointer,
                :x_pos,
                :y_pos,
                :unique_id,
                :type,
                :subtype,
                :byte_8,
                :var_a,
                :var_b,
                :offset_up
  
  def initialize(room, fs)
    @room = room
    @fs = fs
    @x_pos = @y_pos = @unique_id = @type = @subtype = @byte_8 = @var_a = @var_b = @offset_up = 0
    @unique_id = @room.get_unused_unique_id()
  end
  
  def read_from_rom(entity_ram_pointer)
    @entity_ram_pointer = entity_ram_pointer
    
    @x_pos, @y_pos = fs.read(entity_ram_pointer,4).unpack("s*")
    if GAME == "hod"
      byte_5, @subtype, @offset_up, @byte_8 = fs.read(entity_ram_pointer+4,4).unpack("C*")
      @type      = (byte_5 & 0xC0) >> 6
      @unique_id =  byte_5 & 0x3F
    else
      @unique_id, @type, @subtype, @byte_8 = fs.read(entity_ram_pointer+4,4).unpack("C*")
    end
    @var_a, @var_b = fs.read(entity_ram_pointer+8,4).unpack("v*")
    
    return self
  end
  
  def write_to_rom
    room.sector.load_necessary_overlay()
    
    if entity_ram_pointer.nil?
      raise "没有指针的物品无法保存"
    end
    
    if SYSTEM == :nds
      fs.write(entity_ram_pointer, self.to_data)
    else
      # If the entities in this room changed position, we need to make sure the entity list is ordered properly (on GBA only).
      room.update_entity_list_order_and_save_entities()
    end
    
    if GAME == "hod"
      room.update_entity_gfx_list()
      room.remove_entities_from_palette_list()
    end
  end
  
  def to_data
    if GAME == "hod"
      byte_5  = (@type      &  0x3) << 6
      byte_5 |= (@unique_id & 0x3F)
      [
        x_pos,
        y_pos,
        byte_5,
        subtype,
        offset_up,
        byte_8,
        var_a,
        var_b
      ].pack("ssCCCCvv")
    else
      [
        x_pos,
        y_pos,
        unique_id,
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
  
  def get_hod_candle_sprite_info
    if GAME != "hod" || !is_candle?
      raise "Not a HoD candle"
    end
    
    if var_a & 0xFFF == 0
      # Candle in common sprite
      candle_type = var_a >> 0xC
      if (0..3).include?(candle_type)
        candle_frame = case candle_type
        when 0
          CANDLE_FRAME_IN_COMMON_SPRITE
        when 1..3
          0x4A
        end
        palette_offset = case candle_type
        when 0
          1
        when 1
          8
        when 2
          9
        when 3
          0xA
        end
        candle_sprite_info = CANDLE_SPRITE.merge(palette_offset: palette_offset)
        sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(CANDLE_SPRITE[:pointer], @fs, CANDLE_SPRITE[:overlay], candle_sprite_info)
        return [sprite_info, candle_frame]
      else
        return nil
      end
    else
      # Candle not in common sprite.
      candle_type = var_a & 0xF
      other_sprite = OTHER_SPRITES.find{|spr| spr[:desc] == "Candle #{candle_type}"}
      if other_sprite
        sprite_info = SpriteInfo.new(other_sprite[:gfx_files], other_sprite[:palette], other_sprite[:palette_offset], other_sprite[:sprite], nil, @fs)
        return [sprite_info, 0]
      else
        return nil
      end
    end
  end
end
