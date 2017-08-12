
class EntityLayerItem < Qt::GraphicsRectItem
  attr_reader :entities
  
  VILLAGER_EVENT_FLAG_TO_NAME = {
    0x2A => "Jacob",
    0x2D => "Abram",
    0x32 => "Laura",
    0x38 => "Eugen",
    0x3C => "Aeon",
    0x40 => "Marcel",
    0x47 => "Serge",
    0x4B => "Anna",
    0x4F => "Monica",
    0x53 => "Irina",
    0x57 => "Daniela",
  }
  
  def initialize(entities, main_window, game, renderer)
    super()
    
    @main_window = main_window
    @game = game
    @fs = game.fs
    @renderer = renderer
    
    entities.each do |entity|
      add_graphics_item_for_entity(entity)
    end
  end
  
  def add_graphics_item_for_entity(entity)
    if entity.is_enemy?
      enemy_id = entity.subtype
      sprite_info = EnemyDNA.new(enemy_id, @fs).extract_gfx_and_palette_and_sprite_from_init_ai
      add_sprite_item_for_entity(entity, sprite_info,
        BEST_SPRITE_FRAME_FOR_ENEMY[enemy_id],
        sprite_offset: BEST_SPRITE_OFFSET_FOR_ENEMY[enemy_id])
    elsif GAME == "aos" && entity.is_special_object? && [0x0A, 0x0B].include?(entity.subtype) # Conditional enemy
      enemy_id = entity.var_a
      sprite_info = EnemyDNA.new(enemy_id, @fs).extract_gfx_and_palette_and_sprite_from_init_ai
      add_sprite_item_for_entity(entity, sprite_info,
        BEST_SPRITE_FRAME_FOR_ENEMY[enemy_id],
        sprite_offset: BEST_SPRITE_OFFSET_FOR_ENEMY[enemy_id])
    elsif GAME == "dos" && entity.is_special_object? && entity.subtype == 0x01 && entity.var_a == 0 # soul candle
      pointer = OTHER_SPRITES.find{|spr| spr[:desc] == "Destructibles 0"}[:pointer]
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(pointer, @fs, nil, {})
      add_sprite_item_for_entity(entity, sprite_info, 0)
    elsif entity.is_villager? && VILLAGER_EVENT_FLAG_TO_NAME.keys.include?(entity.var_a)
      villager_name = VILLAGER_EVENT_FLAG_TO_NAME[entity.var_a]
      villager_info = OTHER_SPRITES.find{|other| other[:desc] == "#{villager_name} event actor"}
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(pointer, @fs, nil, villager_info)
      add_sprite_item_for_entity(entity, sprite_info, 0)
    elsif GAME == "aos" && entity.is_pickup? && (5..8).include?(entity.subtype) # soul candle
      soul_candle_sprite = COMMON_SPRITE.merge(palette_offset: 4)
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(soul_candle_sprite[:pointer], @fs, soul_candle_sprite[:overlay], soul_candle_sprite)
      add_sprite_item_for_entity(entity, sprite_info, 0x6B)
    elsif entity.is_glyph_statue?
      pointer = OTHER_SPRITES.find{|spr| spr[:desc] == "Glyph statue"}[:pointer]
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(pointer, @fs, nil, {})
      add_sprite_item_for_entity(entity, sprite_info, 0)
    elsif entity.is_item_chest?
      item_global_id = entity.var_a - 1
      item = @game.items[item_global_id]
      item_icon_chunky_image = @renderer.render_icon_by_item(item)
      
      special_object_id = entity.subtype
      sprite_info = SpecialObjectType.new(special_object_id, @fs).extract_gfx_and_palette_and_sprite_from_create_code
      add_sprite_item_for_entity(entity, sprite_info,
        BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT[special_object_id],
        sprite_offset: BEST_SPRITE_OFFSET_FOR_SPECIAL_OBJECT[special_object_id],
        item_icon_image: item_icon_chunky_image)
    elsif entity.is_special_object?
      special_object_id = entity.subtype
      sprite_info = SpecialObjectType.new(special_object_id, @fs).extract_gfx_and_palette_and_sprite_from_create_code
      add_sprite_item_for_entity(entity, sprite_info,
        BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT[special_object_id],
        sprite_offset: BEST_SPRITE_OFFSET_FOR_SPECIAL_OBJECT[special_object_id])
    elsif entity.is_candle?
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(CANDLE_SPRITE[:pointer], @fs, CANDLE_SPRITE[:overlay], CANDLE_SPRITE)
      add_sprite_item_for_entity(entity, sprite_info, CANDLE_FRAME_IN_COMMON_SPRITE)
    elsif entity.is_magic_seal?
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(COMMON_SPRITE[:pointer], @fs, COMMON_SPRITE[:overlay], COMMON_SPRITE)
      add_sprite_item_for_entity(entity, sprite_info, 0xCE)
    elsif entity.is_item?
      if GAME == "ooe"
        item_global_id = entity.var_b - 1
        item = @game.items[item_global_id]
        chunky_image = @renderer.render_icon_by_item(item)
      else
        item_type = entity.subtype
        item_id = entity.var_b
        item = @game.get_item_by_type_and_index(item_type, item_id)
        chunky_image = @renderer.render_icon_by_item(item)
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
    elsif entity.is_heart?
      case GAME
      when "dos"
        frame_id = 0xDA
      when "por", "ooe"
        frame_id = 0x11D
      end
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(COMMON_SPRITE[:pointer], @fs, COMMON_SPRITE[:overlay], COMMON_SPRITE)
      add_sprite_item_for_entity(entity, sprite_info, frame_id)
    elsif entity.is_money_bag?
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(MONEY_SPRITE[:pointer], @fs, MONEY_SPRITE[:overlay], MONEY_SPRITE)
      add_sprite_item_for_entity(entity, sprite_info, MONEY_FRAME_IN_COMMON_SPRITE)
    elsif entity.is_skill? && GAME == "por"
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
    elsif entity.is_glyph? && entity.var_b > 0
      glyph_id = entity.var_b - 1
      item = @game.items[glyph_id]
      
      icon_index = item["Icon"]
      if glyph_id <= 0x36
        palette_index = 2
      else
        palette_index = 1
      end
      chunky_image = @renderer.render_icon(icon_index, palette_index, mode=:glyph)
      
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
    if DEBUG
      unless e.message =~ /has no sprite/
        Qt::MessageBox.warning(@main_window,
          "Sprite error",
          "#{e.message}\n\n#{e.backtrace.join("\n")}"
        )
      end
    end
    graphics_item = EntityRectItem.new(entity, @main_window)
    graphics_item.setParentItem(self)
  end
  
  def add_sprite_item_for_entity(entity, sprite_info, frame_to_render, sprite_offset: nil, item_icon_image: nil)
    if frame_to_render == -1
      # Don't show this entity's sprite in the editor.
      graphics_item = EntityRectItem.new(entity, @main_window)
      graphics_item.setParentItem(self)
      return
    end
    
    frame_to_render ||= 0
    
    sprite_filename = @renderer.ensure_sprite_exists("cache/#{GAME}/sprites/", sprite_info, frame_to_render)
    chunky_frame = ChunkyPNG::Image.from_file(sprite_filename)
    
    if item_icon_image
      chunky_frame.compose!(item_icon_image, 6, 0)
    end
    
    graphics_item = EntityChunkyItem.new(chunky_frame, entity, @main_window)
    
    offset_x = sprite_info.sprite.min_x
    offset_y = sprite_info.sprite.min_y
    if sprite_offset
      offset_x += sprite_offset[:x] || 0
      offset_y += sprite_offset[:y] || 0
    end
    graphics_item.setOffset(offset_x, offset_y)
    graphics_item.setPos(entity.x_pos, entity.y_pos)
    graphics_item.setParentItem(self)
  end
end
