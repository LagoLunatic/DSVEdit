
require_relative 'ui_animation_editor'

class AnimationEditor < Qt::Dialog
  RED_PEN_COLOR = Qt::Pen.new(Qt::Color.new(255, 0, 0))
  
  slots "frame_changed(int)"
  slots "toggle_hitbox(int)"
  slots "gfx_page_changed(int)"
  slots "palette_changed(int)"
  slots "part_changed(int)"
  slots "enemy_changed(int)"
  slots "toggle_paused()"
  slots "advance_frame()"
  
  def initialize(main_window, fs, renderer)
    super(main_window)
    
    @fs = fs
    @renderer = renderer
    
    @ui = Ui_AnimationEditor.new
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
    
    connect(@ui.enemy_list, SIGNAL("currentRowChanged(int)"), self, SLOT("enemy_changed(int)"))
    connect(@ui.seek_slider, SIGNAL("valueChanged(int)"), self, SLOT("frame_changed(int)"))
    connect(@ui.frame_index, SIGNAL("activated(int)"), self, SLOT("frame_changed(int)"))
    connect(@ui.show_hitbox, SIGNAL("stateChanged(int)"), self, SLOT("toggle_hitbox(int)"))
    connect(@ui.gfx_page_index, SIGNAL("activated(int)"), self, SLOT("gfx_page_changed(int)"))
    connect(@ui.palette_index, SIGNAL("activated(int)"), self, SLOT("palette_changed(int)"))
    connect(@ui.part_index, SIGNAL("activated(int)"), self, SLOT("part_changed(int)"))
    connect(@ui.toggle_paused_button, SIGNAL("clicked()"), self, SLOT("toggle_paused()"))
    
    self.show()
  end
  
  def enemy_changed(enemy_id)
    @gfx_files_with_blanks, palette, palette_offset, animation_file = begin
      EnemyDNA.new(enemy_id, @fs).get_gfx_and_palette_and_animation_from_init_ai
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Enemy animation extraction failed",
        "Failed to extract gfx or palette data for enemy #{enemy_id}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    @animation = Animation.new(animation_file, @fs)
    
    chunky_frames, @min_x, @min_y, rendered_parts, @palettes, full_width, full_height = begin
      @renderer.render_entity(@gfx_files_with_blanks, palette, palette_offset, @animation, frame_to_render = 0)
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Enemy animation rendering failed",
        "Failed to render animations for enemy #{enemy_id}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    @frame_graphics_scene.clear()
    @frame_graphics_scene.setSceneRect(0, 0, full_width, full_height)
    
    @current_frame_index = 0
    @paused = true
    
    @ui.frame_index.clear()
    @animation.frames.each_index do |i|
      @ui.frame_index.addItem("%02X" % i)
    end
    
    @ui.seek_slider.minimum = 0
    @ui.seek_slider.maximum = @animation.frames.length-1
    @ui.seek_slider.value = 0
    
    @ui.gfx_page_index.setCurrentIndex(0)
    
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
      part = @animation.parts[part_index]
      
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
  end
  
  def load_gfx_pages(palette_index)
    @gfx_page_pixmaps = []
    @ui.gfx_page_index.clear()
    @gfx_files_with_blanks.each_with_index do |gfx_page, i|
      @ui.gfx_page_index.addItem(i.to_s)
      
      if gfx_page.nil?
        @gfx_page_pixmaps << nil
      else
        gfx_file = gfx_page[:file]
        canvas_width = gfx_page[:canvas_width]
        chunky_image = @renderer.render_gfx(gfx_file, @palettes[palette_index], 0, 0, canvas_width*8, canvas_width*8, canvas_width=canvas_width*8)
        
        pixmap = Qt::Pixmap.new
        blob = chunky_image.to_blob
        pixmap.loadFromData(blob, blob.length)
        gfx_page_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
        @gfx_page_pixmaps << gfx_page_pixmap_item
      end
    end
    
    @gfx_file_graphics_scene.setSceneRect(0, 0, @gfx_page_pixmaps.first.pixmap.width, @gfx_page_pixmaps.first.pixmap.height)
  end
  
  def frame_changed(i)
    @current_frame_index = i
    @frame_graphics_scene.items.each do |item|
      @frame_graphics_scene.removeItem(item)
    end
    
    @animation.frames[i].part_indexes.reverse.each do |part_index|
      part = @animation.parts[part_index]
      
      part_pixmap = @part_pixmaps_for_frame_view[part_index]
      @frame_graphics_scene.addItem(part_pixmap)
    end
    
    @ui.frame_index.setCurrentIndex(i)
    @ui.seek_slider.value = @current_frame_index
    
    frame = @animation.frames[i]
    
    @ui.frame_first_part.text = "%02X" % (frame.part_indexes.first || 0)
    @ui.frame_number_of_parts.text = "%02X" % frame.part_indexes.length
    
    if frame.hitbox && @ui.show_hitbox.checked
      hitbox_item = Qt::GraphicsRectItem.new
      hitbox_item.setPen(RED_PEN_COLOR)
      hitbox_item.setRect(frame.hitbox.x_pos - @min_x, frame.hitbox.y_pos - @min_y, frame.hitbox.width, frame.hitbox.height)
      @frame_graphics_scene.addItem(hitbox_item)
    end
  end
  
  def toggle_hitbox(checked)
    frame_changed(@current_frame_index)
  end
  
  def gfx_page_changed(i)
    @gfx_file_graphics_scene.items.each do |item|
      @gfx_file_graphics_scene.removeItem(item)
    end
    
    pixmap = @gfx_page_pixmaps[i]
    if pixmap.nil?
      @ui.gfx_file_name.text = "Invalid"
    else
      @gfx_file_graphics_scene.addItem(pixmap)
      @ui.gfx_file_name.text = @gfx_files_with_blanks[i][:file][:file_path]
    end
    
    @ui.gfx_page_index.setCurrentIndex(i)
  end
  
  def palette_changed(palette_index, force=false)
    if palette_index == @palette_index && !force
      return
    end
    @palette_index = palette_index
    
    # TODO: cache rendered pages by the palette so that changing the palette doesn't mean all pages need to be rerendered.
    old_gfx_page_index = @ui.gfx_page_index.currentIndex
    old_gfx_page_index = 0 if old_gfx_page_index == -1
    load_gfx_pages(palette_index)
    gfx_page_changed(old_gfx_page_index)
    
    @ui.palette_index.setCurrentIndex(palette_index)
  end
  
  def part_changed(i)
    @part_graphics_scene.items.each do |item|
      @part_graphics_scene.removeItem(item)
    end
    
    @part_graphics_scene.addItem(@part_pixmaps_for_part_view[i])
    
    @ui.part_index.setCurrentIndex(i)
    
    part = @animation.parts[i]
    gfx_page_changed(part.gfx_page_index)
    palette_changed(part.palette_index)
    selection_rectangle = Qt::GraphicsRectItem.new
    selection_rectangle.setPen(RED_PEN_COLOR)
    selection_rectangle.setRect(part.gfx_x_offset, part.gfx_y_offset, part.width, part.height)
    @gfx_file_graphics_scene.addItem(selection_rectangle)
  end
  
  def toggle_paused
    @paused = !@paused
    unless @paused
      advance_frame()
    end
  end
  
  def advance_frame
    unless @paused
      if @current_frame_index >= @pixmap_frames.length-1
        frame_changed(0)
        @paused = true
      else
        frame_changed(@current_frame_index+1)
      end
      Qt::Timer.singleShot(50, self, SLOT("advance_frame()")) # Todo: Accurate per-frame delays.
    end
  end
end
