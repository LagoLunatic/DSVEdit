
class EntityLayerItem < Qt::GraphicsRectItem
  attr_reader :entities
  
  def initialize(entities, main_window, fs, renderer)
    super()
    
    @main_window = main_window
    @fs = fs
    @renderer = renderer
    
    entities.each do |entity|
      add_graphics_item_for_entity(entity)
    end
  end
  
  def add_graphics_item_for_entity(entity)
    if entity.is_enemy?
      enemy_id = entity.subtype
      sprite_info = EnemyDNA.new(enemy_id, @fs).extract_gfx_and_palette_and_sprite_from_init_ai
      add_sprite_item_for_entity(entity, sprite_info, BEST_SPRITE_FRAME_FOR_ENEMY[enemy_id])
    elsif GAME == "dos" && entity.is_special_object? && entity.subtype == 0x01 && entity.var_a == 0 # soul candle
      pointer = OTHER_SPRITES.find{|spr| spr[:desc] == "Destructibles 0"}[:pointer]
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(pointer, @fs, nil, {})
      add_sprite_item_for_entity(entity, sprite_info, 0)
    elsif GAME == "ooe" && entity.is_special_object? && entity.subtype == 0x02 && entity.var_a == 0 # glyph statue
      pointer = OTHER_SPRITES.find{|spr| spr[:desc] == "Glyph statue"}[:pointer]
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(pointer, @fs, nil, {})
      add_sprite_item_for_entity(entity, sprite_info, 0)
    elsif entity.is_special_object?
      special_object_id = entity.subtype
      sprite_info = SpecialObjectType.new(special_object_id, @fs).extract_gfx_and_palette_and_sprite_from_create_code
      add_sprite_item_for_entity(entity, sprite_info, BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT[special_object_id])
    elsif entity.is_candle?
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(OTHER_SPRITES[0][:pointer], @fs, OTHER_SPRITES[0][:overlay], OTHER_SPRITES[0])
      add_sprite_item_for_entity(entity, sprite_info, 0xDB)
    elsif entity.is_magic_seal?
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(OTHER_SPRITES[0][:pointer], @fs, OTHER_SPRITES[0][:overlay], OTHER_SPRITES[0])
      add_sprite_item_for_entity(entity, sprite_info, 0xCE)
    elsif entity.is_item? || entity.is_hidden_item?
      if GAME == "ooe"
        item_global_id = entity.var_b - 1
        chunky_image = @renderer.render_icon_by_global_id(item_global_id)
        
        if chunky_image.nil?
          graphics_item = EntityRectItem.new(entity, @main_window)
          graphics_item.setParentItem(self)
          return
        end
        
        graphics_item = EntityChunkyItem.new(chunky_image, entity, @main_window)
        graphics_item.setOffset(-8, -16)
        graphics_item.setPos(entity.x_pos, entity.y_pos)
        graphics_item.setParentItem(self)
      else
        item_type = entity.subtype
        item_id = entity.var_b
        chunky_image = @renderer.render_icon_by_item_type(item_type-2, item_id)
        
        if chunky_image.nil?
          graphics_item = EntityRectItem.new(entity, @main_window)
          graphics_item.setParentItem(self)
          return
        end
        
        graphics_item = EntityChunkyItem.new(chunky_image, entity, @main_window)
        graphics_item.setOffset(-8, -16)
        graphics_item.setPos(entity.x_pos, entity.y_pos)
        graphics_item.setParentItem(self)
      end
    elsif entity.is_heart? || entity.is_hidden_heart?
      case GAME
      when "dos"
        frame_id = 0xDA
      when "por", "ooe"
        frame_id = 0x11D
      end
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(OTHER_SPRITES[0][:pointer], @fs, OTHER_SPRITES[0][:overlay], OTHER_SPRITES[0])
      add_sprite_item_for_entity(entity, sprite_info, frame_id)
    elsif entity.is_money_bag? || entity.is_hidden_money_bag?
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(OTHER_SPRITES[0][:pointer], @fs, OTHER_SPRITES[0][:overlay], OTHER_SPRITES[0])
      add_sprite_item_for_entity(entity, sprite_info, 0xEF)
    elsif (entity.is_skill? || entity.is_hidden_skill?) && GAME == "por"
      case entity.var_b
      when 0x00..0x26
        chunky_image = @renderer.render_icon(64 + 0, 0)
      when 0x27..0x50
        chunky_image = @renderer.render_icon(64 + 2, 2)
      when 0x51..0x5B
        chunky_image = @renderer.render_icon(64 + 1, 0)
      else
        chunky_image = @renderer.render_icon(64 + 3, 0)
      end
      
      if chunky_image.nil?
        graphics_item = EntityRectItem.new(entity, @main_window)
        graphics_item.setParentItem(self)
        return
      end
      
      graphics_item = EntityChunkyItem.new(chunky_image, entity, @main_window)
      graphics_item.setOffset(-8, -16)
      graphics_item.setPos(entity.x_pos, entity.y_pos)
      graphics_item.setParentItem(self)
    elsif (entity.is_glyph? || entity.is_hidden_glyph?) && entity.var_b > 0
      glyph_id = entity.var_b - 1
      if glyph_id <= 0x36
        chunky_image = @renderer.render_icon_by_item_type(0, glyph_id, mode=:glyph)
      else
        chunky_image = @renderer.render_icon_by_item_type(1, glyph_id-0x37, mode=:glyph)
      end
      
      if chunky_image.nil?
        graphics_item = EntityRectItem.new(entity, @main_window)
        graphics_item.setParentItem(self)
        return
      end
      
      graphics_item = EntityChunkyItem.new(chunky_image, entity, @main_window)
      graphics_item.setOffset(-16, -16)
      graphics_item.setPos(entity.x_pos, entity.y_pos)
      graphics_item.setParentItem(self)
    else
      graphics_item = EntityRectItem.new(entity, @main_window)
      graphics_item.setParentItem(self)
    end
  rescue StandardError => e
    graphics_item = EntityRectItem.new(entity, @main_window)
    graphics_item.setParentItem(self)
  end
  
  def add_sprite_item_for_entity(entity, sprite_info, frame_to_render)
    if frame_to_render == -1
      # Don't show this entity's sprite in the editor.
      graphics_item = EntityRectItem.new(entity, @main_window)
      graphics_item.setParentItem(self)
      return
    end
    
    frame_to_render ||= 0
    
    sprite_filename = @renderer.ensure_sprite_exists("cache/#{GAME}/sprites/", sprite_info, frame_to_render)
    chunky_frame = ChunkyPNG::Image.from_file(sprite_filename)
    
    graphics_item = EntityChunkyItem.new(chunky_frame, entity, @main_window)
    
    graphics_item.setOffset(sprite_info.sprite.min_x, sprite_info.sprite.min_y)
    graphics_item.setPos(entity.x_pos, entity.y_pos)
    graphics_item.setParentItem(self)
  end
end
