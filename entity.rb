class Entity
  attr_reader :room,
              :fs,
              :entity_ram_pointer
  attr_accessor :x_pos,
                :y_pos,
                :byte_5,
                :type,
                :subtype,
                :byte_8,
                :var_a,
                :var_b
  
  def initialize(room, entity_ram_pointer, fs)
    @room = room
    @fs = fs
    @entity_ram_pointer = entity_ram_pointer
    
    read_from_rom()
  end
  
  def read_from_rom
    @x_pos, @y_pos = fs.read(entity_ram_pointer,4).unpack("v*")
    @byte_5, @type, @subtype, @byte_8 = fs.read(entity_ram_pointer+4,4).unpack("C*")
    @var_a, @var_b = fs.read(entity_ram_pointer+8,4).unpack("v*")
  end
  
  def write_to_rom
    room.sector.load_necessary_overlay()
    
    fs.write(entity_ram_pointer, [x_pos, y_pos].pack("v*"))
    fs.write(entity_ram_pointer+4, [byte_5, type, subtype, byte_8].pack("C*"))
    fs.write(entity_ram_pointer+8, [var_a, var_b].pack("v*"))
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