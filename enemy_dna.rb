
class EnemyDNA
  attr_reader :enemy_id,
              :fs
  
  attr_accessor :name,
                :description,
                :init_ai_ram_pointer,
                :running_ai_ram_pointer,
                :item1,
                :item2,
                :unknown_1,
                :unknown_2,
                :max_hp,
                :max_mp,
                :exp,
                :soul_drop_chance,
                :attack,
                :defense,
                :item_drop_chance,
                :unknown_3,
                :soul,
                :unknown_4,
                :weaknesses,
                :unknown_5,
                :resistances,
                :unknown_6
  
  def initialize(enemy_id, fs)
    @enemy_id = enemy_id
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    name_wrapper_ram_pointer = ENEMY_NAME_LIST_RAM_POINTER + 4*enemy_id
    name_ram_pointer = fs.read(name_wrapper_ram_pointer, 4).unpack("V").first
    @name = fs.read(name_ram_pointer+2, 100)
    name_end = @name.index([0xEA].pack("C*"))
    @name = @name[0,name_end]
    @name = @name.unpack("C*").map do |byte|
      byte + 0x20
    end.pack("C*")
    @name = @name.gsub([0x106].pack("C*"), "\n")
    
    description_wrapper_ram_pointer = ENEMY_DESCRIPTION_LIST_RAM_POINTER + 4*enemy_id
    description_ram_pointer = fs.read(description_wrapper_ram_pointer, 4).unpack("V").first
    @description = fs.read(description_ram_pointer+2, 100)
    description_end = @description.index([0xEA].pack("C*"))
    @description = @description[0,description_end]
    @description = @description.unpack("C*").map do |byte|
      byte + 0x20
    end.pack("C*")
    @description = @description.gsub([0x106].pack("C*"), "\n")
    
    enemy_dna_ram_pointer = ENEMY_DNA_RAM_START_OFFSET + 36*enemy_id
      @init_ai_ram_pointer, @running_ai_ram_pointer, @item1, @item2,
      @unknown_1, @unknown_2, @max_hp, @max_mp, @exp, 
      @soul_drop_chance, @attack, @defense, @item_drop_chance, 
      @unknown_3, @soul, @unknown_4, weaknesses,
      @unknown_5, resistances, @unknown_6 = fs.read(enemy_dna_ram_pointer, 36).unpack("VVvvCCvvvCCCCvCCvvvv")
    @weaknesses = VulnerabilityList.new(weaknesses)
    @resistances = VulnerabilityList.new(resistances)
  end
  
  def write_to_rom
    
  end
end

class VulnerabilityList
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
