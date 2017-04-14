
class WeaponGfx
  attr_reader :weapon_gfx_index,
              :fs,
              :gfx_file_pointer,
              :sprite_file_pointer,
              :palette_pointer
  
  def initialize(weapon_gfx_index, fs)
    @weapon_gfx_index = weapon_gfx_index
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    if GAME == "ooe"
      raise "No weapons in OoE"
    elsif GAME == "aos"
      @gfx_file_pointer = fs.read(WEAPON_GFX_LIST_START + weapon_gfx_index*4, 4).unpack("V").first
      @sprite_file_pointer = fs.read(WEAPON_SPRITES_LIST_START + weapon_gfx_index*4, 4).unpack("V").first
      @palette_pointer = WEAPON_PALETTE_LIST
    else
      @gfx_file_pointer, @sprite_file_pointer, @palette_pointer = fs.read(WEAPON_GFX_LIST_START + weapon_gfx_index*12, 12).unpack("VVV")
    end
  end
  
  def write_to_rom
    raise NotImplementedError.new
  end
end
