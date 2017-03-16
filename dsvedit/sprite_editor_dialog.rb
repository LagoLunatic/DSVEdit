
require_relative 'ui_sprite_editor'

class SpriteEditor < Qt::Dialog
  RED_PEN_COLOR = Qt::Pen.new(Qt::Color.new(255, 0, 0))
  
  attr_reader :game, :fs
  
  slots "frame_changed(int)"
  slots "animation_frame_changed(int)"
  slots "toggle_hitbox(int)"
  slots "gfx_page_changed(int)"
  slots "palette_changed(int)"
  slots "part_changed(int)"
  slots "tab_changed(int)"
  slots "enemy_changed(int)"
  slots "special_object_changed(int)"
  slots "weapon_changed(int)"
  slots "skill_changed(int)"
  slots "other_sprite_changed(int)"
  slots "animation_changed(int)"
  slots "frame_delay_changed()"
  slots "toggle_animation_paused()"
  slots "advance_frame()"
  slots "reload_sprite()"
  slots "open_skeleton_editor()"
  slots "click_gfx_scene(int, int, const Qt::MouseButton&)"
  slots "drag_gfx_scene(int, int, const Qt::MouseButton&)"
  slots "stop_dragging_gfx_scene(int, int, const Qt::MouseButton&)"
  slots "toggle_part_flips(int)"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, game, renderer)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    
    @game = game
    @fs = game.fs
    @renderer = renderer
    @override_part_palette_index = nil
    
    @ui = Ui_SpriteEditor.new
    @ui.setup_ui(self)
    
    # rbuic4 is bugged and ignores stretch values, so they must be manually set.
    @ui.horizontalLayout_3.setStretch(0, 1)
    @ui.horizontalLayout_3.setStretch(1, 1)
    @ui.horizontalLayout_3.setStretch(2, 1)
    @ui.horizontalLayout_5.setStretch(0, 1)
    @ui.horizontalLayout_5.setStretch(1, 1)
    @ui.horizontalLayout_5.setStretch(2, 1)
    
    @frame_graphics_scene = Qt::GraphicsScene.new
    @ui.frame_graphics_view.setScene(@frame_graphics_scene)
    
    @gfx_file_graphics_scene = ClickableGraphicsScene.new
    @ui.gfx_file_graphics_view.setScene(@gfx_file_graphics_scene)
    connect(@gfx_file_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("click_gfx_scene(int, int, const Qt::MouseButton&)"))
    connect(@gfx_file_graphics_scene, SIGNAL("moved(int, int, const Qt::MouseButton&)"), self, SLOT("drag_gfx_scene(int, int, const Qt::MouseButton&)"))
    connect(@gfx_file_graphics_scene, SIGNAL("released(int, int, const Qt::MouseButton&)"), self, SLOT("stop_dragging_gfx_scene(int, int, const Qt::MouseButton&)"))
    
    @part_graphics_scene = Qt::GraphicsScene.new
    @ui.part_graphics_view.setScene(@part_graphics_scene)
    
    @animation_timer = Qt::Timer.new()
    @animation_timer.setSingleShot(true)
    connect(@animation_timer, SIGNAL("timeout()"), self, SLOT("advance_frame()"))
    
    @enemies = []
    ENEMY_IDS.each do |enemy_id|
      enemy = EnemyDNA.new(enemy_id, fs)
      @enemies << enemy
      @ui.enemy_list.addItem("%02X %s" % [enemy_id, enemy.name.decoded_string])
    end
    
    @special_objects = []
    SPECIAL_OBJECT_IDS.each do |special_object_id|
      special_object = SpecialObjectType.new(special_object_id, fs)
      @special_objects << special_object
      object_name = game.special_object_docs[special_object_id]
      object_name = " " if object_name.nil? || object_name.empty?
      object_name = object_name.lines.first.strip
      if object_name.length > 41
        object_name = object_name[0..40]
        object_name << "..."
      end
      @ui.special_object_list.addItem("%02X %s" % [special_object_id, object_name])
    end
    
    weapon_items = []
    skill_items = []
    max_weapon_gfx_index = 0
    max_skill_gfx_index = 0
    ITEM_TYPES.each do |item_type|
      (0..item_type[:count]-1).each do |index|
        item = GenericEditable.new(index, item_type, fs)
        if item.kind == :skill
          if item["Sprite"] && item["Sprite"] > max_skill_gfx_index
            max_skill_gfx_index = item["Sprite"]
          end
          skill_items << item
        else
          if item["Sprite"] && item["Sprite"] > max_weapon_gfx_index
            max_weapon_gfx_index = item["Sprite"]
          end
          weapon_items << item
        end
      end
    end
    if GAME == "ooe"
      max_weapon_gfx_index -= 1
    end
    max_skill_gfx_index -= 1
    
    @weapons = []
    (0..max_weapon_gfx_index).each do |weapon_gfx_index|
      weapon = WeaponGfx.new(weapon_gfx_index, fs)
      @weapons << weapon
      if GAME == "ooe"
        items = weapon_items.select{|item| item["Sprite"] == weapon_gfx_index+1}
      else
        items = weapon_items.select{|item| item["Sprite"] == weapon_gfx_index}
      end
      if items.any?
        weapon_name = items.map do |item|
          if item.name.decoded_string.empty?
            "..."
          else
            item.name.decoded_string
          end
        end.join(", ")
      else
        weapon_name = "Unused"
      end
      @ui.weapon_list.addItem("%02X %s" % [weapon_gfx_index, weapon_name])
    end
    
    @skills = []
    (0..max_skill_gfx_index).each do |skill_gfx_index|
      skill = SkillGfx.new(skill_gfx_index, fs)
      @skills << skill
      items = skill_items.select{|item| item["Sprite"] == skill_gfx_index+1}
      if items.any?
        skill_name = items.map do |item|
          if item.name.decoded_string.empty?
            "..."
          else
            item.name.decoded_string
          end
        end.join(", ")
      else
        skill_name = "Unused"
      end
      @ui.skill_list.addItem("%02X %s" % [skill_gfx_index + 1, skill_name])
    end
    
    OTHER_SPRITES.each_with_index do |other_sprite, id|
      @ui.other_sprites_list.addItem("%02X %s" % [id, other_sprite[:desc]])
    end
    
    set_animation_paused(true)
    
    connect(@ui.tabWidget, SIGNAL("currentChanged(int)"), self, SLOT("tab_changed(int)"))
    connect(@ui.enemy_list, SIGNAL("currentRowChanged(int)"), self, SLOT("enemy_changed(int)"))
    connect(@ui.special_object_list, SIGNAL("currentRowChanged(int)"), self, SLOT("special_object_changed(int)"))
    connect(@ui.weapon_list, SIGNAL("currentRowChanged(int)"), self, SLOT("weapon_changed(int)"))
    connect(@ui.skill_list, SIGNAL("currentRowChanged(int)"), self, SLOT("skill_changed(int)"))
    connect(@ui.other_sprites_list, SIGNAL("currentRowChanged(int)"), self, SLOT("other_sprite_changed(int)"))
    connect(@ui.frame_index, SIGNAL("activated(int)"), self, SLOT("frame_changed(int)"))
    connect(@ui.seek_slider, SIGNAL("sliderMoved(int)"), self, SLOT("animation_frame_changed(int)"))
    connect(@ui.show_hitbox, SIGNAL("stateChanged(int)"), self, SLOT("toggle_hitbox(int)"))
    connect(@ui.gfx_page_index, SIGNAL("activated(int)"), self, SLOT("gfx_page_changed(int)"))
    connect(@ui.palette_index, SIGNAL("activated(int)"), self, SLOT("palette_changed(int)"))
    connect(@ui.part_index, SIGNAL("activated(int)"), self, SLOT("part_changed(int)"))
    connect(@ui.animation_index, SIGNAL("activated(int)"), self, SLOT("animation_changed(int)"))
    connect(@ui.frame_delay, SIGNAL("editingFinished()"), self, SLOT("frame_delay_changed()"))
    connect(@ui.part_horizontal_flip, SIGNAL("stateChanged(int)"), self, SLOT("toggle_part_flips(int)"))
    connect(@ui.part_vertical_flip, SIGNAL("stateChanged(int)"), self, SLOT("toggle_part_flips(int)"))
    connect(@ui.toggle_paused_button, SIGNAL("clicked()"), self, SLOT("toggle_animation_paused()"))
    connect(@ui.reload_button, SIGNAL("clicked()"), self, SLOT("reload_sprite()"))
    connect(@ui.view_skeleton_button, SIGNAL("clicked()"), self, SLOT("open_skeleton_editor()"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    self.show()
  end
  
  def tab_changed(tab_id)
    case tab_id
    when 0
      id = @ui.enemy_list.currentRow
      return if id == -1
      enemy_changed(id)
    when 1
      id = @ui.special_object_list.currentRow
      return if id == -1
      special_object_changed(id)
    when 2
      id = @ui.weapon_list.currentRow
      return if id == -1
      weapon_changed(id)
    when 3
      id = @ui.skill_list.currentRow
      return if id == -1
      skill_changed(id)
    when 4
      id = @ui.other_sprites_list.currentRow
      return if id == -1
      other_sprite_changed(id)
    end
  end
  
  def enemy_changed(enemy_id)
    begin
      @sprite_info = EnemyDNA.new(enemy_id, @fs).extract_gfx_and_palette_and_sprite_from_init_ai
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Enemy sprite extraction failed",
        "Failed to extract gfx or palette data for enemy #{enemy_id}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    @override_part_palette_index = nil
    @one_dimensional_render_mode = false
    load_sprite()
    
    @ui.enemy_list.setCurrentRow(enemy_id)
  end
  
  def special_object_changed(special_object_id)
    if (REUSED_SPECIAL_OBJECT_INFO[special_object_id] || {})[:init_code] == -1
      load_blank_sprite()
      return
    end
    
    begin
      @sprite_info = SpecialObjectType.new(special_object_id, @fs).extract_gfx_and_palette_and_sprite_from_create_code
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Special object sprite extraction failed",
        "Failed to extract gfx or palette data for special object #{special_object_id}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    @override_part_palette_index = nil
    @one_dimensional_render_mode = false
    load_sprite()
    
    @ui.special_object_list.setCurrentRow(special_object_id)
  end
  
  def weapon_changed(weapon_gfx_index)
    begin
      weapon = @weapons[weapon_gfx_index]
      
      gfx_file_pointers = [weapon.gfx_file_pointer]
      palette_pointer = weapon.palette_pointer
      palette_offset = 0
      sprite_pointer = weapon.sprite_file_pointer
      skeleton_file = nil
      
      @sprite_info = SpriteInfo.new(gfx_file_pointers, palette_pointer, palette_offset, sprite_pointer, skeleton_file, @fs)
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Weapon sprite extraction failed",
        "Failed to extract gfx or palette data for weapon #{weapon_gfx_index}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    @override_part_palette_index = 0 # Weapons always use the first palette. Instead the part's palette index value is used to indicate that it should start out partially transparent.
    @one_dimensional_render_mode = false
    load_sprite()
    
    @ui.weapon_list.setCurrentRow(weapon_gfx_index)
  end
  
  def skill_changed(skill_gfx_index)
    begin
      skill = @skills[skill_gfx_index]
      
      gfx_file_pointers = [skill.gfx_file_pointer]
      palette_pointer = skill.palette_pointer
      palette_offset = 0
      sprite_pointer = skill.sprite_file_pointer
      skeleton_file = nil
      
      @sprite_info = SpriteInfo.new(gfx_file_pointers, palette_pointer, palette_offset, sprite_pointer, skeleton_file, @fs)
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Skill sprite extraction failed",
        "Failed to extract gfx or palette data for skill #{skill_gfx_index}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    @override_part_palette_index = nil
    @one_dimensional_render_mode = false
    load_sprite()
    
    @ui.skill_list.setCurrentRow(skill_gfx_index)
  end
  
  def other_sprite_changed(id)
    begin
      @sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(OTHER_SPRITES[id][:pointer], @fs, OTHER_SPRITES[id][:overlay], OTHER_SPRITES[id])
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Sprite extraction failed",
        "Failed to extract gfx or palette data for other sprite #{id}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    @override_part_palette_index = nil
    @one_dimensional_render_mode = OTHER_SPRITES[id][:one_dimensional_mode]
    load_sprite()
    
    @ui.other_sprites_list.setCurrentRow(id)
  end
  
  def load_blank_sprite
    @ui.view_skeleton_button.enabled = false
    @ui.sprite_file_name.text = ""
    @ui.gfx_pointer.text = ""
    @ui.frame_index.clear()
    @ui.gfx_page_index.clear()
    @ui.palette_pointer.text = ""
    @ui.palette_index.clear()
    @ui.part_index.clear()
    @ui.frame_first_part.text = ""
    @ui.frame_number_of_parts.text = ""
    @ui.gfx_file_name.text = ""
    @ui.show_hitbox.enabled = false
    @ui.seek_slider.enabled = false
    @ui.toggle_paused_button.enabled = false
    @ui.frame_delay.text = ""
    
    @rendered_gfx_pages_by_palette = {}
    @part_pixmaps_for_part_view = []
    @part_pixmaps_for_frame_view = []
    @ui.animation_index.clear()
    @frame_graphics_scene.clear()
    @part_graphics_scene.clear()
    @gfx_file_graphics_scene.clear()
  end
  
  def load_sprite
    begin
      @sprite = @sprite_info.sprite
      
      @chunky_frames, @min_x, @min_y, rendered_parts, @gfx_pages_with_blanks, @palettes, @full_width, @full_height = 
        @renderer.render_sprite(@sprite_info, frame_to_render: 0, override_part_palette_index: @override_part_palette_index, one_dimensional_mode: @one_dimensional_render_mode)
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Sprite rendering failed",
        "Failed to render sprite.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    if @sprite_info.skeleton_file
      @ui.view_skeleton_button.enabled = true
    else
      @ui.view_skeleton_button.enabled = false
    end
    
    @frame_graphics_scene.setSceneRect(@min_x, @min_y, @full_width, @full_height)
    @part_graphics_scene.setSceneRect(@min_x, @min_y, @full_width, @full_height)
    
    @current_frame_index = 0
    @current_part_index = 0
    
    sprite_file_text = "%08X" % @sprite_info.sprite_file_pointer
    if @sprite_info.sprite_file
      sprite_file_text += " (#{@sprite_info.sprite_file[:file_path]})"
    end
    if @sprite_info.skeleton_file
      sprite_file_text += ", #{@sprite_info.skeleton_file[:file_path]}"
    end
    @ui.sprite_file_name.text = sprite_file_text
    
    @ui.frame_index.clear()
    @sprite.frames.each_index do |i|
      @ui.frame_index.addItem("%02X" % i)
    end
    
    @rendered_gfx_pages_by_palette = {}
    
    @ui.gfx_pointer.text = @sprite_info.gfx_file_pointers.map{|ptr| "%08X" % ptr}.join(", ")
    
    @ui.gfx_page_index.clear()
    @gfx_pages_with_blanks.each_with_index do |gfx_page, i|
      @ui.gfx_page_index.addItem(i.to_s)
    end
    @ui.gfx_page_index.setCurrentIndex(0)
    
    @ui.palette_pointer.text = "%08X" % @sprite_info.palette_pointer
    
    @ui.palette_index.clear()
    @palettes.each_with_index do |palette, i|
      @ui.palette_index.addItem("%02X" % i)
    end
    palette_changed(0, force=true)
    
    @part_pixmaps_for_part_view = []
    @part_pixmaps_for_frame_view = []
    @ui.part_index.clear()
    ordered_rendered_parts = rendered_parts.sort_by{|part_index, chunky_image| part_index}
    ordered_rendered_parts.each do |part_index, chunky_image|
      part = @sprite.parts[part_index]
      
      pixmap = Qt::Pixmap.new
      blob = chunky_image.to_blob
      pixmap.loadFromData(blob, blob.length)
      
      @part_pixmaps_for_part_view << PartItem.new(self, part, part_index, pixmap)
      @part_pixmaps_for_frame_view << PartItem.new(self, part, part_index, pixmap)
      
      @ui.part_index.addItem("%02X" % part_index)
    end
    part_changed(0)
    
    frame_changed(0)
    
    @ui.animation_index.clear()
    @sprite.animations.each_with_index do |animation, i|
      @ui.animation_index.addItem("%02X" % i)
    end
    animation_changed(0)
  end
  
  def ensure_gfx_pages_for_palette_exist(palette_index)
    @rendered_gfx_pages_by_palette[palette_index] ||= @gfx_pages_with_blanks.map do |gfx|
      if gfx.nil?
        nil
      else
        canvas_width = gfx.canvas_width
        if @one_dimensional_render_mode
          chunky_image = @renderer.render_gfx_1_dimensional_mode(gfx.file, @palettes[palette_index])
        else
          chunky_image = @renderer.render_gfx(gfx.file, @palettes[palette_index], 0, 0, canvas_width*8, canvas_width*8, canvas_width=canvas_width*8)
        end
        
        chunky_image
      end
    end
  end
  
  def load_gfx_pages(palette_index)
    ensure_gfx_pages_for_palette_exist(palette_index)
    
    @gfx_file_graphics_scene.setSceneRect(0, 0, @rendered_gfx_pages_by_palette[palette_index].first.width, @rendered_gfx_pages_by_palette[palette_index].first.height)
  end
  
  def frame_changed(i, do_not_change_current_part: false)
    @current_frame_index = i
    @frame_graphics_scene.items.each do |item|
      @frame_graphics_scene.removeItem(item)
    end
    
    if i == nil
      @ui.frame_index.setCurrentIndex(-1)
      @ui.frame_first_part.text = ""
      @ui.frame_number_of_parts.text = ""
      return
    end
    
    @sprite.frames[i].part_indexes.reverse.each do |part_index|
      part = @sprite.parts[part_index]
      
      part_pixmap = @part_pixmaps_for_frame_view[part_index]
      @frame_graphics_scene.addItem(part_pixmap)
    end
    
    @ui.frame_index.setCurrentIndex(i)
    
    frame = @sprite.frames[i]
    
    if frame.part_indexes.first
      @ui.frame_first_part.text = "%02X" % frame.part_indexes.first
      unless do_not_change_current_part
        part_changed(frame.part_indexes.first)
      end
    else
      @ui.frame_first_part.text = ""
    end
    @ui.frame_number_of_parts.text = "%02X" % frame.part_indexes.length
    
    if @ui.show_hitbox.checked
      frame.hitboxes.each do |hitbox|
        hitbox_item = Qt::GraphicsRectItem.new
        hitbox_item.setPen(RED_PEN_COLOR)
        hitbox_item.setRect(hitbox.x_pos, hitbox.y_pos, hitbox.width, hitbox.height)
        @frame_graphics_scene.addItem(hitbox_item)
      end
    end
  end
  
  def toggle_hitbox(checked)
    frame_changed(@current_frame_index)
  end
  
  def gfx_page_changed(gfx_page_index)
    @gfx_file_graphics_scene.items.each do |item|
      @gfx_file_graphics_scene.removeItem(item)
    end
    @gfx_page_index = gfx_page_index
    
    chunky_gfx_page = @rendered_gfx_pages_by_palette[@palette_index][gfx_page_index]
    if chunky_gfx_page.nil?
      @ui.gfx_file_name.text = "Invalid (gfx page index #{gfx_page_index})"
    else
      pixmap = Qt::Pixmap.new
      blob = chunky_gfx_page.to_blob
      pixmap.loadFromData(blob, blob.length)
      gfx_page_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
      @gfx_file_graphics_scene.addItem(gfx_page_pixmap_item)
      @ui.gfx_file_name.text = @gfx_pages_with_blanks[gfx_page_index].file[:file_path]
    end
    
    @ui.gfx_page_index.setCurrentIndex(gfx_page_index)
    
    part = @sprite.parts[@current_part_index]
    if part.gfx_page_index == @gfx_page_index
      @selection_rectangle = Qt::GraphicsRectItem.new
      @selection_rectangle.setPen(RED_PEN_COLOR)
      @selection_rectangle.setRect(part.gfx_x_offset, part.gfx_y_offset, part.width, part.height)
      @gfx_file_graphics_scene.addItem(@selection_rectangle)
    end
  end
  
  def palette_changed(palette_index, force=false)
    if palette_index == @palette_index && !force
      return
    end
    @palette_index = palette_index
    
    old_gfx_page_index = @gfx_page_index
    old_gfx_page_index = 0 if old_gfx_page_index.nil?
    load_gfx_pages(palette_index)
    gfx_page_changed(old_gfx_page_index)
    
    part = @sprite.parts[@current_part_index]
    if part && part.palette_index != @palette_index && !force
      part.palette_index = @palette_index
      reload_current_part()
    end
    
    @ui.palette_index.setCurrentIndex(palette_index)
  end
  
  def part_changed(i)
    @current_part_index = i
    @part_graphics_scene.items.each do |item|
      @part_graphics_scene.removeItem(item)
    end
    
    @part_graphics_scene.addItem(@part_pixmaps_for_part_view[i])
    
    @ui.part_index.setCurrentIndex(i)
    
    part = @sprite.parts[i]
    gfx_page_changed(part.gfx_page_index)
    if @override_part_palette_index
      palette_changed(@override_part_palette_index)
    else
      palette_changed(part.palette_index)
    end
    
    @ui.part_horizontal_flip.setChecked(part.horizontal_flip)
    @ui.part_vertical_flip.setChecked(part.vertical_flip)
  end
  
  def animation_changed(i)
    @animation_timer.stop()
    @current_animation_index = i
    @ui.animation_index.setCurrentIndex(i)
    @ui.seek_slider.value = 0
    @current_animation_frame_index = 0
    
    @current_animation = @sprite.animations[i]
    if @current_animation.nil?
      @ui.seek_slider.enabled = false
      @ui.toggle_paused_button.enabled = false
      @ui.frame_delay.text = ""
      return
    end
    
    @ui.seek_slider.enabled = true
    @ui.seek_slider.minimum = 0
    @ui.seek_slider.maximum = @current_animation.frame_delays.length-1
    @ui.toggle_paused_button.enabled = true
    
    if @current_animation.number_of_frames > 0
      animation_frame_changed(0)
      start_animation()
    else
      frame_changed(nil) # Blank out the frame display
    end
  end
  
  def animation_frame_changed(i)
    @current_animation_frame_index = i
    frame_delay = @current_animation.frame_delays[@current_animation_frame_index]
    frame_changed(frame_delay.frame_index)
    @ui.seek_slider.value = @current_animation_frame_index
    @ui.frame_delay.text = "%04X" % frame_delay.delay
  end
  
  def set_animation_paused(paused)
    @animation_paused = paused
    if @animation_paused
      @ui.toggle_paused_button.text = "Play"
    else
      @ui.toggle_paused_button.text = "Pause"
      
      start_animation()
    end
  end
  
  def start_animation
    frame_delay = @current_animation.frame_delays[@current_animation_frame_index]
    millisecond_delay = (frame_delay.delay / 60.0 * 1000).round
    @animation_timer.start(millisecond_delay)
  end
  
  def toggle_animation_paused
    set_animation_paused(!@animation_paused)
  end
  
  def advance_frame
    if @current_animation && !@animation_paused
      if @current_animation_frame_index >= @current_animation.frame_delays.length-1
        animation_frame_changed(0)
        
        unless @ui.loop_animation.checked
          set_animation_paused(true)
        end
      else
        animation_frame_changed(@current_animation_frame_index+1)
      end
      
      frame_delay = @current_animation.frame_delays[@current_animation_frame_index]
      millisecond_delay = (frame_delay.delay / 60.0 * 1000).round
      @animation_timer.start(millisecond_delay)
    end
  end
  
  def frame_delay_changed
    return if @current_animation.nil?
    frame_delay = @current_animation.frame_delays[@current_animation_frame_index]
    return if frame_delay.nil?
    delay_num = @ui.frame_delay.text.to_i(16)
    delay_num = [delay_num, 1].max
    frame_delay.delay = delay_num
    @ui.frame_delay.text = "%04X" % frame_delay.delay
  end
  
  def open_skeleton_editor
    if @sprite_info.skeleton_file
      @skeleton_editor = SkeletonEditorDialog.new(self, @sprite_info, game.fs, @renderer)
    end
  end
  
  def save_sprite
    @sprite.write_to_rom()
  rescue Sprite::SaveError => e
    Qt::MessageBox.warning(self,
      "Failed to save sprite",
      e.message
    )
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_sprite()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_sprite()
    end
  end
  
  def reload_sprite
    gfx_file_pointers = @ui.gfx_pointer.text.split(/,\s*/).map{|ptr| ptr.to_i(16)}
    palette_pointer = @ui.palette_pointer.text.to_i(16)
    sprite_file = @fs.files_by_path[@ui.sprite_file_name.text]
    sprite_pointer = @ui.sprite_file_name.text.to_i(16)
    
    @sprite_info = SpriteInfo.new(gfx_file_pointers, palette_pointer, @sprite_info.palette_offset, sprite_pointer, @sprite_info.skeleton_file, @fs)
    
    load_sprite()
  end
  
  def click_gfx_scene(mouse_x, mouse_y, button)
    # Start selecting part on gfx page.
    
    return unless @selection_rectangle
    
    max_w = @gfx_file_graphics_scene.width
    max_h = @gfx_file_graphics_scene.height
    mouse_x = [mouse_x, 0].max
    mouse_y = [mouse_y, 0].max
    mouse_x = [mouse_x, max_w].min
    mouse_y = [mouse_y, max_h].min
    
    @selection_origin = Qt::PointF.new(mouse_x, mouse_y)
    x = mouse_x
    y = mouse_y
    w = 0
    h = 0
    @selection_rectangle.setRect(x, y, w, h)
  end
  
  def drag_gfx_scene(mouse_x, mouse_y, button)
    # Resize part selection on gfx page.
    
    return unless @selection_rectangle
    
    max_w = @gfx_file_graphics_scene.width
    max_h = @gfx_file_graphics_scene.height
    mouse_x = [mouse_x, 0].max
    mouse_y = [mouse_y, 0].max
    mouse_x = [mouse_x, max_w].min
    mouse_y = [mouse_y, max_h].min
    
    x = [mouse_x, @selection_origin.x].min
    y = [mouse_y, @selection_origin.y].min
    w = [mouse_x, @selection_origin.x].max - x
    h = [mouse_y, @selection_origin.y].max - y
    @selection_rectangle.setRect(x, y, w, h)
  end
  
  def stop_dragging_gfx_scene(mouse_x, mouse_y, button)
    update_current_part()
  end
  
  def toggle_part_flips(checked)
    update_current_part()
  end
  
  def update_current_part
    x = @selection_rectangle.rect.x
    y = @selection_rectangle.rect.y
    w = @selection_rectangle.rect.width
    h = @selection_rectangle.rect.height
    
    if w == 0 || h == 0
      return
    end
    if x < 0 || x >= @gfx_file_graphics_scene.width || y < 0 || y >= @gfx_file_graphics_scene.height
      return
    end
    if x+w < 0 || x+w > @gfx_file_graphics_scene.width || y+h < 0 || y+h > @gfx_file_graphics_scene.height
      return
    end
    
    part = @sprite.parts[@current_part_index]
    part.gfx_x_offset = x.to_i
    part.gfx_y_offset = y.to_i
    part.width        = w.to_i
    part.height       = h.to_i
    
    part.gfx_page_index = @gfx_page_index
    part.palette_index = @palette_index
    
    part.horizontal_flip = @ui.part_horizontal_flip.checked
    part.vertical_flip = @ui.part_vertical_flip.checked
    
    reload_current_part()
  end
  
  def reload_current_part
    part = @sprite.parts[@current_part_index]
    ensure_gfx_pages_for_palette_exist(@palette_index)
    chunky_gfx_page = @rendered_gfx_pages_by_palette[@palette_index][@gfx_page_index]
    chunky_part = @renderer.render_sprite_part(part, chunky_gfx_page)
    
    pixmap = Qt::Pixmap.new
    blob = chunky_part.to_blob
    pixmap.loadFromData(blob, blob.length)
    
    @part_pixmaps_for_part_view[@current_part_index] = PartItem.new(self, part, @current_part_index, pixmap)
    @part_pixmaps_for_frame_view[@current_part_index] = PartItem.new(self, part, @current_part_index, pixmap)
    
    part_changed(@current_part_index)
    frame_changed(@current_frame_index, do_not_change_current_part: true)
  end
  
  def update_part_position(part_index)
    part = @sprite.parts[part_index]
    @part_pixmaps_for_part_view[part_index].setPos(part.x_pos, part.y_pos)
    @part_pixmaps_for_frame_view[part_index].setPos(part.x_pos, part.y_pos)
    
    min_x = @sprite.min_x
    min_y = @sprite.min_y
    full_width = @sprite.full_width
    full_height = @sprite.full_height
    @frame_graphics_scene.setSceneRect(min_x, min_y, full_width, full_height)
    @part_graphics_scene.setSceneRect(min_x, min_y, full_width, full_height)
  end
  
  def inspect; to_s; end
end

class PartItem < Qt::GraphicsPixmapItem
  def initialize(sprite_editor, part, part_index, pixmap)
    super(pixmap)
    setPos(part.x_pos, part.y_pos)
    
    @sprite_editor = sprite_editor
    @part = part
    @part_index = part_index
    
    setFlag(Qt::GraphicsItem::ItemIsMovable)
    setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges)
    setFlag(Qt::GraphicsItem::ItemIsFocusable)
  end
  
  def itemChange(change, value)
    if change == ItemPositionChange && scene()
      new_pos = value.toPointF()
      x = new_pos.x
      y = new_pos.y
      new_pos.setX(x)
      new_pos.setY(y)
      
      @part.x_pos = x.round
      @part.y_pos = y.round
      
      return super(change, Qt::Variant.new(new_pos))
    end
    
    return super(change, value)
  end
  
  def keyPressEvent(event)
    case event.key
    when Qt::Key_Up
      setPos(pos.x, pos.y-1)
      @sprite_editor.update_part_position(@part_index)
    when Qt::Key_Down
      setPos(pos.x, pos.y+1)
      @sprite_editor.update_part_position(@part_index)
    when Qt::Key_Left
      setPos(pos.x-1, pos.y)
      @sprite_editor.update_part_position(@part_index)
    when Qt::Key_Right
      setPos(pos.x+1, pos.y)
      @sprite_editor.update_part_position(@part_index)
    end
    
    super(event)
  end
  
  def mouseReleaseEvent(event)
    @sprite_editor.update_part_position(@part_index)
    super(event)
  end
end
