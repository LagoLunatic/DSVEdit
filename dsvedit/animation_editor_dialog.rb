
require_relative 'ui_animation_editor'

class AnimationEditor < Qt::Dialog
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
    @gfx_files, palette, palette_offset, animation_file = begin
      EnemyDNA.new(enemy_id, @fs).get_gfx_and_palette_and_animation_from_init_ai
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Enemy animation extraction failed",
        "Failed to extract gfx or palette data for enemy #{enemy_id}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    @animation = Animation.new(animation_file, @fs)
    
    chunky_frames, @min_x, @min_y, rendered_parts, @palettes = begin
      @renderer.render_entity(@gfx_files, palette, palette_offset, @animation)
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Enemy animation rendering failed",
        "Failed to render animations for enemy #{enemy_id}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    @frame_graphics_scene.clear()
    @frame_graphics_scene.setSceneRect(0, 0, chunky_frames.first.width, chunky_frames.first.height)
    
    @current_frame_index = 0
    @paused = true
    
    @pixmap_frames = []
    @ui.frame_index.clear()
    chunky_frames.each_with_index do |chunky_frame, i|
      pixmap = Qt::Pixmap.new
      blob = chunky_frame.to_blob
      pixmap.loadFromData(blob, blob.length)
      frame_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
      @pixmap_frames << frame_pixmap_item
      
      @ui.frame_index.addItem(i.to_s)
    end
    frame_changed(0)
    
    @ui.seek_slider.minimum = 0
    @ui.seek_slider.maximum = @pixmap_frames.length-1
    @ui.seek_slider.value = 0
    
    @ui.palette_index.clear()
    @palettes.each_with_index do |palette, i|
      @ui.palette_index.addItem(i.to_s)
    end
    palette_changed(0)
    
    @part_pixmaps = []
    @ui.part_index.clear()
    rendered_parts.each_with_index do |chunky_image, i|
      pixmap = Qt::Pixmap.new
      blob = chunky_image.to_blob
      pixmap.loadFromData(blob, blob.length)
      part_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
      @part_pixmaps << part_pixmap_item
      
      @ui.part_index.addItem(i.to_s)
    end
    part_changed(0)
  end
  
  def load_gfx_pages(palette_index)
    @gfx_page_pixmaps = []
    @ui.gfx_page_index.clear()
    @gfx_files.each_with_index do |gfx_page, i|
      chunky_image = @renderer.render_gfx(gfx_page[:file], @palettes[palette_index], 0, 0, 16*8, 16*8, canvas_width=16*8)
      
      pixmap = Qt::Pixmap.new
      blob = chunky_image.to_blob
      pixmap.loadFromData(blob, blob.length)
      gfx_page_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
      @gfx_page_pixmaps << gfx_page_pixmap_item
      
      @ui.gfx_page_index.addItem(i.to_s)
    end
  end
  
  def frame_changed(i)
    @current_frame_index = i
    @frame_graphics_scene.items.each do |item|
      @frame_graphics_scene.removeItem(item)
    end
    
    @frame_graphics_scene.addItem(@pixmap_frames[@current_frame_index])
    @ui.frame_index.setCurrentIndex(i)
    @ui.seek_slider.value = @current_frame_index
    
    #@ui.frame_delay.text = @animation.frame_delays[i].to_s
    
    frame = @animation.frames[i]
    if frame.hitbox && @ui.show_hitbox.checked
      hitbox_item = Qt::GraphicsRectItem.new
      hitbox_item.setPen(Qt::Pen.new(Qt::Color.new(255, 0, 0)))
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
    
    @gfx_file_graphics_scene.addItem(@gfx_page_pixmaps[i])
    
    @ui.gfx_file_name.text = @gfx_files[i][:file][:file_path]
    @ui.gfx_page_index.setCurrentIndex(i)
  end
  
  def palette_changed(palette_index)
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
    
    @part_graphics_scene.addItem(@part_pixmaps[i])
    
    @ui.part_index.setCurrentIndex(i)
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
