
class EnemyDNA < GenericEditable
  attr_reader :enemy_id
  
  def initialize(enemy_id, fs)
    @enemy_id = enemy_id
    @fs = fs
    
    enemy_type = {
      name: "Enemies",
      list_pointer: ENEMY_DNA_RAM_START_OFFSET,
      count: ENEMY_IDS.size,
      kind: :enemy,
      format: ENEMY_DNA_FORMAT
    }
    super(enemy_id, enemy_type, fs)
  end
  
  def extract_gfx_and_palette_and_sprite_from_init_ai
    reused_info = REUSED_ENEMY_INFO[enemy_id] || {}
    
    if SYSTEM == :nds
      overlay_to_load = OVERLAY_FILE_FOR_ENEMY_AI[enemy_id]
      ptr_to_ptr_to_files_to_load = ENEMY_FILES_TO_LOAD_LIST + enemy_id*4
      
      return SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(self["Create Code"], fs, overlay_to_load, reused_info, ptr_to_ptr_to_files_to_load)
    else
      return SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(self["Create Code"], fs, nil, reused_info)
    end
  end
end
