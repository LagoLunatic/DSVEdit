
require_relative 'ui_sprite_editor'

class SpriteEditor < Qt::Dialog
  RED_PEN_COLOR = Qt::Pen.new(Qt::Color.new(255, 0, 0))
  
  slots "frame_changed(int)"
  slots "animation_frame_changed(int)"
  slots "toggle_hitbox(int)"
  slots "gfx_page_changed(int)"
  slots "palette_changed(int)"
  slots "part_changed(int)"
  slots "enemy_changed(int)"
  slots "animation_changed(int)"
  slots "toggle_animation_paused()"
  slots "advance_frame()"
  
  def initialize(main_window, fs, renderer)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    
    @fs = fs
    @renderer = renderer
    
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
    @gfx_file_graphics_scene = Qt::GraphicsScene.new
    @ui.gfx_file_graphics_view.setScene(@gfx_file_graphics_scene)
    @part_graphics_scene = Qt::GraphicsScene.new
    @ui.part_graphics_view.setScene(@part_graphics_scene)
    
    @enemies = []
    ENEMY_IDS.each do |enemy_id|
      enemy = EnemyDNA.new(enemy_id, fs)
      @enemies << enemy
      @ui.enemy_list.addItem("%03d %s" % [enemy_id, enemy.name.decoded_string])
    end
    
    set_animation_paused(true)
    
    connect(@ui.enemy_list, SIGNAL("currentRowChanged(int)"), self, SLOT("enemy_changed(int)"))
    connect(@ui.frame_index, SIGNAL("activated(int)"), self, SLOT("frame_changed(int)"))
    connect(@ui.seek_slider, SIGNAL("sliderMoved(int)"), self, SLOT("animation_frame_changed(int)"))
    connect(@ui.show_hitbox, SIGNAL("stateChanged(int)"), self, SLOT("toggle_hitbox(int)"))
    connect(@ui.gfx_page_index, SIGNAL("activated(int)"), self, SLOT("gfx_page_changed(int)"))
    connect(@ui.palette_index, SIGNAL("activated(int)"), self, SLOT("palette_changed(int)"))
    connect(@ui.part_index, SIGNAL("activated(int)"), self, SLOT("part_changed(int)"))
    connect(@ui.animation_index, SIGNAL("activated(int)"), self, SLOT("animation_changed(int)"))
    connect(@ui.toggle_paused_button, SIGNAL("clicked()"), self, SLOT("toggle_animation_paused()"))
    
    self.show()
  end
  
  def enemy_changed(enemy_id)
    @gfx_files_with_blanks, @palette_pointer, palette_offset, @sprite_file = begin
      EnemyDNA.new(enemy_id, @fs).get_gfx_and_palette_and_sprite_from_init_ai
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Enemy sprite extraction failed",
        "Failed to extract gfx or palette data for enemy #{enemy_id}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    @sprite = Sprite.new(@sprite_file, @fs)
    
    chunky_frames, @min_x, @min_y, rendered_parts, @palettes, full_width, full_height = begin
      @renderer.render_sprite(@gfx_files_with_blanks, @palette_pointer, palette_offset, @sprite, frame_to_render = 0)
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Enemy sprite rendering failed",
        "Failed to render sprites for enemy #{enemy_id}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    @frame_graphics_scene.clear()
    @frame_graphics_scene.setSceneRect(0, 0, full_width, full_height)
    
    @current_frame_index = 0
    @current_part_index = 0
    
    @ui.sprite_file_name.text = @sprite_file[:file_path]
    
    @ui.frame_index.clear()
    @sprite.frames.each_index do |i|
      @ui.frame_index.addItem("%02X" % i)
    end
    
    @gfx_page_pixmaps_by_palette = {}
    
    @ui.gfx_page_index.clear()
    @gfx_files_with_blanks.each_with_index do |gfx_page, i|
      @ui.gfx_page_index.addItem(i.to_s)
    end
    @ui.gfx_page_index.setCurrentIndex(0)
    
    @ui.palette_pointer.text = "%08X" % @palette_pointer
    
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
      
      part_pixmap_item_for_part_view = Qt::GraphicsPixmapItem.new(pixmap)
      part_pixmap_item_for_part_view.setOffset(part.x_pos - @min_x, part.y_pos - @min_y)
      @part_pixmaps_for_part_view << part_pixmap_item_for_part_view
      part_pixmap_item_for_frame_view = Qt::GraphicsPixmapItem.new(pixmap)
      part_pixmap_item_for_frame_view.setOffset(part.x_pos - @min_x, part.y_pos - @min_y)
      @part_pixmaps_for_frame_view << part_pixmap_item_for_frame_view
      
      @ui.part_index.addItem("%02X" % part_index)
    end
    part_changed(0)
    
    frame_changed(0)
    
    @ui.animation_index.clear()
    @sprite.animations.each_with_index do |animation, i|
      @ui.animation_index.addItem("%02X" % i)
    end
    animation_changed(0)
    
    @ui.enemy_list.setCurrentRow(enemy_id)
  end
  
  def load_gfx_pages(palette_index)
    @gfx_page_pixmaps_by_palette[palette_index] ||= @gfx_files_with_blanks.map do |gfx_page|
      if gfx_page.nil?
        nil
      else
        gfx_file = gfx_page[:file]
        canvas_width = gfx_page[:canvas_width]
        chunky_image = @renderer.render_gfx(gfx_file, @palettes[palette_index], 0, 0, canvas_width*8, canvas_width*8, canvas_width=canvas_width*8)
        
        pixmap = Qt::Pixmap.new
        blob = chunky_image.to_blob
        pixmap.loadFromData(blob, blob.length)
        gfx_page_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
        gfx_page_pixmap_item
      end
    end
    
    @gfx_file_graphics_scene.setSceneRect(0, 0, @gfx_page_pixmaps_by_palette[palette_index].first.pixmap.width, @gfx_page_pixmaps_by_palette[palette_index].first.pixmap.height)
  end
  
  def frame_changed(i)
    @current_frame_index = i
    @frame_graphics_scene.items.each do |item|
      @frame_graphics_scene.removeItem(item)
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
      part_changed(frame.part_indexes.first)
    else
      @ui.frame_first_part.text = ""
    end
    @ui.frame_number_of_parts.text = "%02X" % frame.part_indexes.length
    
    if @ui.show_hitbox.checked
      frame.hitboxes.each do |hitbox|
        hitbox_item = Qt::GraphicsRectItem.new
        hitbox_item.setPen(RED_PEN_COLOR)
        hitbox_item.setRect(hitbox.x_pos - @min_x, hitbox.y_pos - @min_y, hitbox.width, hitbox.height)
        @frame_graphics_scene.addItem(hitbox_item)
      end
    end
  end
  
  def toggle_hitbox(checked)
    frame_changed(@current_frame_index)
  end
  
  def gfx_page_changed(i)
    @gfx_file_graphics_scene.items.each do |item|
      @gfx_file_graphics_scene.removeItem(item)
    end
    
    pixmap = @gfx_page_pixmaps_by_palette[@palette_index][i]
    if pixmap.nil?
      @ui.gfx_file_name.text = "Invalid"
    else
      @gfx_file_graphics_scene.addItem(pixmap)
      @ui.gfx_file_name.text = @gfx_files_with_blanks[i][:file][:file_path]
    end
    
    @ui.gfx_page_index.setCurrentIndex(i)
    
    part = @sprite.parts[@current_part_index]
    selection_rectangle = Qt::GraphicsRectItem.new
    selection_rectangle.setPen(RED_PEN_COLOR)
    selection_rectangle.setRect(part.gfx_x_offset, part.gfx_y_offset, part.width, part.height)
    @gfx_file_graphics_scene.addItem(selection_rectangle)
  end
  
  def palette_changed(palette_index, force=false)
    if palette_index == @palette_index && !force
      return
    end
    @palette_index = palette_index
    
    old_gfx_page_index = @ui.gfx_page_index.currentIndex
    old_gfx_page_index = 0 if old_gfx_page_index == -1
    load_gfx_pages(palette_index)
    gfx_page_changed(old_gfx_page_index)
    
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
    palette_changed(part.palette_index)
  end
  
  def animation_changed(i)
    @ui.seek_slider.value = 0
    @current_animation_frame_index = 0
    
    @current_animation = @sprite.animations[i]
    if @current_animation.nil?
      @ui.seek_slider.enabled = false
      @ui.toggle_paused_button.enabled = false
      set_animation_paused(true)
      return
    end
    
    @ui.seek_slider.enabled = true
    @ui.seek_slider.minimum = 0
    @ui.seek_slider.maximum = @current_animation.frame_delays.length-1
    @ui.toggle_paused_button.enabled = true
    
    animation_frame_changed(0)
  end
  
  def animation_frame_changed(i)
    @current_animation_frame_index = i
    frame_delay = @current_animation.frame_delays[@current_animation_frame_index]
    frame_changed(frame_delay.frame_index)
    @ui.seek_slider.value = @current_animation_frame_index
  end
  
  def set_animation_paused(paused)
    @animation_paused = paused
    if @animation_paused
      @ui.toggle_paused_button.text = "Play"
    else
      @ui.toggle_paused_button.text = "Pause"
      advance_frame()
    end
  end
  
  def toggle_animation_paused
    set_animation_paused(!@animation_paused)
  end
  
  def advance_frame
    if @current_animation && !@animation_paused
      frame_delay = @current_animation.frame_delays[@current_animation_frame_index]
      millisecond_delay = (frame_delay.delay / 60.0 * 1000).round
      
      if @current_animation_frame_index >= @current_animation.frame_delays.length-1
        animation_frame_changed(0)
        
        unless @ui.loop_animation.checked
          set_animation_paused(true)
        end
      else
        animation_frame_changed(@current_animation_frame_index+1)
      end
      
      Qt::Timer.singleShot(millisecond_delay, self, SLOT("advance_frame()"))
    end
  end
end
