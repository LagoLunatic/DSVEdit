
class SkillGfx
  attr_reader :skill_gfx_index,
              :fs,
              :gfx_file_pointer,
              :sprite_file_pointer,
              :palette_pointer
  
  def initialize(skill_gfx_index, fs)
    @skill_gfx_index = skill_gfx_index
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    case GAME
    when "dos"
      gfx_filename_pointer, @gfx_file_pointer, @sprite_file_pointer, @palette_pointer = fs.read(SKILL_GFX_LIST_START + skill_gfx_index*16, 16).unpack("VVVV")
    when "por", "ooe"
      gfx_asset_index, sprite_asset_index, gfx_pointer, unknown, @palette_pointer = fs.read(SKILL_GFX_LIST_START + skill_gfx_index*16, 16).unpack("vvVVV")
      @gfx_file_pointer = fs.assets[gfx_asset_index][:ram_start_offset]
      @sprite_file_pointer = fs.assets[sprite_asset_index][:ram_start_offset]
    end
  end
  
  def write_to_rom
    raise NotImplementedError.new
  end
end
