
require_relative 'ui_animation_editor'

class AnimationEditor < Qt::Dialog
  slots "frame_changed(int)"
  slots "enemy_changed(int)"
  slots "toggle_paused()"
  slots "advance_frame()"
  
  def initialize(main_window, fs, renderer)
    super(main_window)
    
    @fs = fs
    @renderer = renderer
    
    @ui = Ui_AnimationEditor.new
    @ui.setup_ui(self)
    
    @frame_graphics_scene = Qt::GraphicsScene.new
    @ui.frame_graphics_view.setScene(@frame_graphics_scene)
    
    @enemies = []
    ENEMY_IDS.each do |enemy_id|
      enemy = EnemyDNA.new(enemy_id, fs)
      @enemies << enemy
      @ui.enemy_list.addItem("%03d %s" % [enemy_id, enemy.name.decoded_string])
    end
    
    connect(@ui.enemy_list, SIGNAL("currentRowChanged(int)"), self, SLOT("enemy_changed(int)"))
    connect(@ui.seek_slider, SIGNAL("valueChanged(int)"), self, SLOT("frame_changed(int)"))
    connect(@ui.toggle_paused_button, SIGNAL("clicked()"), self, SLOT("toggle_paused()"))
    
    self.show()
  end
  
  def enemy_changed(enemy_id)
    gfx_files, palette, palette_offset, animation_file = begin
      EnemyDNA.new(enemy_id, @fs).get_gfx_and_palette_and_animation_from_init_ai
    rescue StandardError => e
      Qt::MessageBox.warning(self,
        "Enemy animation extraction failed",
        "Failed to extract gfx or palette data for enemy #{enemy_id}.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      )
      return
    end
    
    chunky_frames, min_x, min_y = begin
      @renderer.render_entity(gfx_files, palette, palette_offset, animation_file)
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
    
    chunky_frames.each do |chunky_frame|
      pixmap = Qt::Pixmap.new
      blob = chunky_frame.to_blob
      pixmap.loadFromData(blob, blob.length)
      frame_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
      @pixmap_frames << frame_pixmap_item
    end
    
    frame_changed(0)
    
    @ui.seek_slider.minimum = 0
    @ui.seek_slider.maximum = @pixmap_frames.length-1
    @ui.seek_slider.value = 0
  end
  
  def frame_changed(i)
    @current_frame_index = i
    @frame_graphics_scene.items.each do |item|
      @frame_graphics_scene.removeItem(item)
    end
    
    @frame_graphics_scene.addItem(@pixmap_frames[@current_frame_index])
    @ui.frame_label.text = "Frame: #{@current_frame_index}"
    @ui.seek_slider.value = @current_frame_index
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
