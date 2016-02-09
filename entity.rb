class Entity
  attr_reader :room,
              :rom,
              :converter,
              :entity_pointer
  attr_accessor :x_pos,
                :y_pos,
                :byte_5,
                :type,
                :subtype,
                :byte_8,
                :var_a,
                :var_b
  
  def initialize(room, entity_pointer, rom, converter)
    @room = room
    @rom = rom
    @converter = converter
    @entity_pointer = entity_pointer
    
    read_from_rom()
  end
  
  def read_from_rom
    @x_pos, @y_pos = rom[entity_pointer,4].unpack("v*")
    @byte_5, @type, @subtype, @byte_8 = rom[entity_pointer+4,4].unpack("C*")
    @var_a, @var_b = rom[entity_pointer+8,4].unpack("v*")
  end
  
  def write_to_rom
    rom[entity_pointer,4] = [x_pos, y_pos].pack("v*")
    rom[entity_pointer+4,4] = [byte_5, type, subtype, byte_8].pack("C*")
    rom[entity_pointer+8,4] = [var_a, var_b].pack("v*")
  end
  
  def is_enemy?
    type == 0x01
  end
  
  def is_common_enemy?
    is_enemy? && COMMON_ENEMY_IDS.include?(subtype)
  end
  
  def is_boss?
    is_enemy? && BOSS_IDS.include?(subtype)
  end
  
  def is_pickup?
    
  end
end