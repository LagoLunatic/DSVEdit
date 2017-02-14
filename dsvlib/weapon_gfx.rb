
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
      gfx_file_index, sprite_file_index, gfx_pointer, unknown, @palette_pointer = fs.read(WEAPON_GFX_LIST_START + weapon_gfx_index*16, 16).unpack("vvVVV")
      @gfx_file_pointer = fs.files_by_index[gfx_file_index][:ram_start_offset]
      @sprite_file_pointer = fs.files_by_index[sprite_file_index][:ram_start_offset]
    else
      @gfx_file_pointer, @sprite_file_pointer, @palette_pointer = fs.read(WEAPON_GFX_LIST_START + weapon_gfx_index*12, 12).unpack("VVV")
    end
  end
  
  def write_to_rom
    raise NotImplementedError.new
  end
end
