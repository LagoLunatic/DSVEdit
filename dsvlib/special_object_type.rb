
class SpecialObjectType
  attr_reader :special_object_id,
              :fs
  attr_accessor :create_code_pointer,
                :update_code_pointer
  
  def initialize(special_object_id, fs)
    @special_object_id = special_object_id
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    @create_code_pointer = fs.read(SPECIAL_OBJECT_CREATE_CODE_LIST + special_object_id*4, 4).unpack("V").first
    @update_code_pointer = fs.read(SPECIAL_OBJECT_UPDATE_CODE_LIST + special_object_id*4, 4).unpack("V").first
  end
  
  def extract_gfx_and_palette_and_sprite_from_create_code
    reused_info = REUSED_SPECIAL_OBJECT_INFO[special_object_id] || {}
    
    if SYSTEM == :nds
      overlay_to_load = OVERLAY_FILE_FOR_SPECIAL_OBJECT[special_object_id]
      ptr_to_ptr_to_files_to_load = SPECIAL_OBJECT_FILES_TO_LOAD_LIST + special_object_id*4
      
      return SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(create_code_pointer, fs, overlay_to_load, reused_info, ptr_to_ptr_to_files_to_load)
    else
      return SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(create_code_pointer, fs, nil, reused_info)
    end
  end
  
  def write_to_rom
    fs.write(SPECIAL_OBJECT_CREATE_CODE_LIST + special_object_id*4, [@create_code_pointer].pack("V"))
    fs.write(SPECIAL_OBJECT_UPDATE_CODE_LIST + special_object_id*4, [@update_code_pointer].pack("V"))
  end
end
