
class EntityLayerItem < Qt::GraphicsRectItem
  attr_reader :entities
  
  VILLAGER_EVENT_FLAG_TO_NAME = {
    0x0D => "George",
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
  
  AOS_BREAKABLE_WALL_INDEX_TO_DATA = {
    # Graphic index, palette index, frame index
    0x00 => [0, 0, 0],
    0x01 => [0, 1, 1],
    0x02 => [0, 2, 2],
    0x03 => [1, 0, 0],
    0x04 => [1, 1, 1],
    0x05 => [1, 2, 1],
    0x06 => [2, 0, 0],
    0x07 => [2, 1, 1],
    0x08 => [5, 4, 0],
    0x09 => [3, 0, 0],
    0x0A => [3, 0, 1],
    0x0B => [4, 4, 3],
    0x0C => [4, 5, 4],
    0x0D => [4, 3, 5],
    0x0E => [1, 2, 3],
    0x0F => [6, 3, 1],
    0x10 => [6, 3, 0],
    0x11 => [7, 6, 6],
    0x12 => [2, 0, 0],
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
      sprite_info = @game.enemy_dnas[enemy_id].extract_gfx_and_palette_and_sprite_from_init_ai
      add_sprite_item_for_entity(entity, sprite_info,
        BEST_SPRITE_FRAME_FOR_ENEMY[enemy_id],
        sprite_offset: BEST_SPRITE_OFFSET_FOR_ENEMY[enemy_id])
    elsif GAME == "aos" && entity.is_special_object? && [0x0A, 0x0B].include?(entity.subtype) # Conditional enemy
      enemy_id = entity.var_a
      sprite_info = @game.enemy_dnas[enemy_id].extract_gfx_and_palette_and_sprite_from_init_ai
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
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(nil, @fs, nil, villager_info)
      if villager_name == "George"
        best_frame_index = 2
      else
        best_frame_index = 0
      end
      add_sprite_item_for_entity(entity, sprite_info, best_frame_index)
    elsif GAME == "aos" && entity.is_pickup? && (5..8).include?(entity.subtype) # soul candle
      soul_candle_sprite = COMMON_SPRITE.merge(palette_offset: 4)
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(soul_candle_sprite[:pointer], @fs, soul_candle_sprite[:overlay], soul_candle_sprite)
      add_sprite_item_for_entity(entity, sprite_info, 0x6B)
    elsif GAME == "aos" && entity.is_special_object? && [8, 9].include?(entity.subtype) # Breakable wall
      if AOS_BREAKABLE_WALL_INDEX_TO_DATA.include?(entity.var_a)
        graphic_index, palette_index, frame_index = AOS_BREAKABLE_WALL_INDEX_TO_DATA[entity.var_a]
        breakable_wall_sprite = OTHER_SPRITES.find{|spr| spr[:desc] == "Breakable wall graphics %d" % graphic_index}
        breakable_wall_sprite = breakable_wall_sprite.merge(palette_offset: palette_index)
      else
        breakable_wall_sprite = OTHER_SPRITES.find{|spr| spr[:desc] == "Breakable wall graphics 0"}
        frame_index = 0
      end
      
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(breakable_wall_sprite[:pointer], @fs, nil, breakable_wall_sprite)
      add_sprite_item_for_entity(entity, sprite_info, frame_index)
    elsif GAME == "aos" && entity.is_special_object? && [0x29, 0x2A].include?(entity.subtype) && [2, 3].include?(entity.var_b) # Moving platform that doesn't use the normal sprite
      case entity.var_b
      when 2
        other_sprite = OTHER_SPRITES.find{|spr| spr[:desc] == "Wet rock moving platform"}
      when 3
        other_sprite = OTHER_SPRITES.find{|spr| spr[:desc] == "Clock moving platform"}
      end
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(other_sprite[:pointer], @fs, nil, other_sprite)
      add_sprite_item_for_entity(entity, sprite_info, 0)
    elsif GAME == "hod" && entity.is_pickup? && entity.subtype == 9 && (0..1).include?(entity.var_b) # max up
      chunky_image = @renderer.render_icon(0xB + entity.var_b, 1)
      
      graphics_item = EntityChunkyItem.new(chunky_image, entity, @main_window)
      graphics_item.setOffset(-8, -16)
      graphics_item.setPos(entity.x_pos, entity.y_pos)
      graphics_item.setParentItem(self)
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
    elsif entity.is_portrait? && (0..9).include?(entity.var_a)
      if entity.subtype == 0x75 # Portrait to the Throne Room
        other_sprite = OTHER_SPRITES.find{|spr| spr[:desc] == "Portrait painting 2"}
        frame_to_render = 0
        palette_offest = 0
        art_offset_x = 0
        art_offset_y = 0
      else
        other_sprite = case entity.var_a
        when 1, 3, 5, 7
          OTHER_SPRITES.find{|spr| spr[:desc] == "Portrait painting 0"}
        when 2, 4, 6, 8
          OTHER_SPRITES.find{|spr| spr[:desc] == "Portrait painting 1"}
        when 0, 9
          OTHER_SPRITES.find{|spr| spr[:desc] == "Portrait painting 3"}
        end
        frame_to_render = [0, 0, 0, 1, 1, 3, 2, 2, 3, 1][entity.var_a]
        palette_offset = case entity.var_a
        when 5 # Nation of Fools hardcodes the palette offset instead of having the sprite set a palette index normally.
          1
        else
          0
        end
        art_offset_x = 24
        art_offset_y = 24
      end
      
      reused_info = other_sprite.merge({palette_offset: palette_offset})
      painting_sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(other_sprite[:pointer], @fs, nil, reused_info)
      sprite_filename = @renderer.ensure_sprite_exists("cache/#{GAME}/sprites/", painting_sprite_info, frame_to_render)
      portrait_art_image = ChunkyPNG::Image.from_file(sprite_filename)
      
      special_object_id = entity.subtype
      sprite_info = SpecialObjectType.new(special_object_id, @fs).extract_gfx_and_palette_and_sprite_from_create_code
      add_sprite_item_for_entity(entity, sprite_info,
        BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT[special_object_id],
        sprite_offset: BEST_SPRITE_OFFSET_FOR_SPECIAL_OBJECT[special_object_id],
        portrait_art: [portrait_art_image, art_offset_x, art_offset_y])
    elsif GAME == "por" && entity.is_special_object? && [0x77, 0x8A].include?(entity.subtype)
      studio_portrait_frame_sprite_info = SpecialObjectType.new(0x5F, @fs).extract_gfx_and_palette_and_sprite_from_create_code
      studio_portrait_art_sprite_info = SpecialObjectType.new(entity.subtype, @fs).extract_gfx_and_palette_and_sprite_from_create_code
      
      frame_to_render = 0
      sprite_filename = @renderer.ensure_sprite_exists("cache/#{GAME}/sprites/", studio_portrait_art_sprite_info, frame_to_render)
      studio_portrait_art_image = ChunkyPNG::Image.from_file(sprite_filename)
      art_offset_x = 208
      art_offset_y = 40
      
      frame_num_for_studio_portrait_frame = 0x18
      special_object_id = entity.subtype
      sprite_info = SpecialObjectType.new(special_object_id, @fs).extract_gfx_and_palette_and_sprite_from_create_code
      add_sprite_item_for_entity(entity, studio_portrait_frame_sprite_info,
        frame_num_for_studio_portrait_frame,
        sprite_offset: BEST_SPRITE_OFFSET_FOR_SPECIAL_OBJECT[special_object_id],
        portrait_art: [studio_portrait_art_image, art_offset_x, art_offset_y])
    elsif GAME == "por" && entity.is_special_object? && entity.subtype == 0x3A
      # Objects from the Behemoth chase room.
      special_object_id = entity.subtype
      sprite_info = SpecialObjectType.new(special_object_id, @fs).extract_gfx_and_palette_and_sprite_from_create_code
      
      frame_index = entity.var_a
      add_sprite_item_for_entity(entity, sprite_info, frame_index)
    elsif entity.is_special_object?
      special_object_id = entity.subtype
      sprite_info = SpecialObjectType.new(special_object_id, @fs).extract_gfx_and_palette_and_sprite_from_create_code
      add_sprite_item_for_entity(entity, sprite_info,
        BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT[special_object_id],
        sprite_offset: BEST_SPRITE_OFFSET_FOR_SPECIAL_OBJECT[special_object_id])
    elsif entity.is_candle?
      if GAME == "hod"
        sprite_info, candle_frame = entity.get_hod_candle_sprite_info()
        if sprite_info.nil?
          graphics_item = EntityRectItem.new(entity, @main_window)
          graphics_item.setParentItem(self)
        else
          add_sprite_item_for_entity(entity, sprite_info, candle_frame)
        end
      else
        sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(CANDLE_SPRITE[:pointer], @fs, CANDLE_SPRITE[:overlay], CANDLE_SPRITE)
        add_sprite_item_for_entity(entity, sprite_info, CANDLE_FRAME_IN_COMMON_SPRITE)
      end
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
  
  def add_sprite_item_for_entity(entity, sprite_info, frame_to_render, sprite_offset: nil, item_icon_image: nil, portrait_art: nil)
    if frame_to_render == -1
      # Don't show this entity's sprite in the editor.
      graphics_item = EntityRectItem.new(entity, @main_window)
      graphics_item.setParentItem(self)
      return
    end
    
    frame_to_render ||= 0
    
    if sprite_info.sprite.frames[frame_to_render].nil?
      frame_to_render = 0
    end
    
    sprite_filename = @renderer.ensure_sprite_exists("cache/#{GAME}/sprites/", sprite_info, frame_to_render)
    chunky_frame = ChunkyPNG::Image.from_file(sprite_filename)
    
    if item_icon_image
      chunky_frame.compose!(item_icon_image, 6, 0)
    end
    
    if portrait_art
      portrait_art_image, x_offset, y_offset = portrait_art
      chunky_frame.compose!(portrait_art_image, x_offset, y_offset)
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
  
  def inspect; to_s; end
end
