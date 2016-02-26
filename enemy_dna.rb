
class EnemyDNA
  attr_reader :enemy_id,
              :enemy_dna_ram_pointer,
              :fs
  
  attr_accessor :name,
                :description,
                :init_ai_ram_pointer,
                :running_ai_ram_pointer,
                :item_1,
                :item_2,
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
    @name = Text.new(STRING_REGIONS["Enemy Names"].begin + enemy_id, fs)
    @description = Text.new(STRING_REGIONS["Enemy Descriptions"].begin + enemy_id, fs)
    
    @enemy_dna_ram_pointer = ENEMY_DNA_RAM_START_OFFSET + 36*enemy_id
    @init_ai_ram_pointer, @running_ai_ram_pointer, @item_1, @item_2,
      @unknown_1, @unknown_2, @max_hp, @max_mp, @exp, 
      @soul_drop_chance, @attack, @defense, @item_drop_chance, 
      @unknown_3, @soul, @unknown_4, weaknesses,
      @unknown_5, resistances, @unknown_6 = fs.read(enemy_dna_ram_pointer, 36).unpack("VVvvCCvvvCCCCvCCvvvv")
    @weaknesses = VulnerabilityList.new(weaknesses)
    @resistances = VulnerabilityList.new(resistances)
  end
  
  def write_to_rom
    new_data = [@init_ai_ram_pointer, @running_ai_ram_pointer, @item_1, @item_2,
      @unknown_1, @unknown_2, @max_hp, @max_mp, @exp, 
      @soul_drop_chance, @attack, @defense, @item_drop_chance, 
      @unknown_3, @soul, @unknown_4, @weaknesses.value,
      @unknown_5, @resistances.value, @unknown_6]
    fs.write(enemy_dna_ram_pointer, new_data.pack("VVvvCCvvvCCCCvCCvvvv"))
  end
end

class VulnerabilityList
  attr_reader :value
  
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
