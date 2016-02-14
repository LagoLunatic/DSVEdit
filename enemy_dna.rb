
class EnemyDNA
  attr_reader :enemy_id,
              :rom,
              :converter,
              :name,
              :description,
              :item1,
              :item2,
              :max_hp,
              :max_mp,
              :exp,
              :soul_drop_chance,
              :attack,
              :defense,
              :item_drop_chance,
              :soul,
              :weaknesses,
              :resistances,
              :init_ai_ram_pointer,
              :running_ai_ram_pointer
  
  def initialize(enemy_id, rom, converter)
    @enemy_id = enemy_id
    @rom = rom
    @converter = converter
    
    read_from_rom()
  end
  
  def read_from_rom
    name_wrapper_pointer = converter.ram_to_rom(ENEMY_NAME_LIST_RAM_POINTER + 4*enemy_id)
    name_ram_pointer = rom[name_wrapper_pointer, 4].unpack("V").first
    name_pointer = converter.ram_to_rom(name_ram_pointer)
    @name = rom[name_pointer+2, 100]
    name_end = @name.index([0xEA].pack("C*"))
    @name = @name[0,name_end]
    @name = @name.unpack("C*").map do |byte|
      byte + 0x20
    end.pack("C*")
    @name = @name.gsub([0x106].pack("C*"), "\n")
    
    description_wrapper_pointer = converter.ram_to_rom(ENEMY_DESCRIPTION_LIST_RAM_POINTER + 4*enemy_id)
    description_ram_pointer = rom[description_wrapper_pointer, 4].unpack("V").first
    description_pointer = converter.ram_to_rom(description_ram_pointer)
    @description = rom[description_pointer+2, 100]
    description_end = @description.index([0xEA].pack("C*"))
    @description = @description[0,description_end]
    @description = @description.unpack("C*").map do |byte|
      byte + 0x20
    end.pack("C*")
    @description = @description.gsub([0x106].pack("C*"), "\n")
    
    enemy_dna_pointer = converter.ram_to_rom(ENEMY_DNA_RAM_START_OFFSET + 36*enemy_id)
      @init_ai_ram_pointer, @running_ai_ram_pointer, @item1, @item2,
      _, @max_hp, @max_mp, @exp, 
      @soul_drop_chance, @attack, @defense, @item_drop_chance, 
      _, @soul, _, @weaknesses,
      _, @resistances, _ = rom[enemy_dna_pointer, 36].unpack("VVvvvvvvCCCCvCCvvvv")
  end
  
  def write_to_rom
    
  end
end