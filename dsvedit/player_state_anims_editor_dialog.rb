
require_relative 'ui_player_state_anims_editor'

class PlayerStateAnimsEditor < Qt::Dialog
  slots "player_changed(int)"
  slots "state_changed(int)"
  slots "anim_changed(int)"
  slots "advance_keyframe()"
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, game, renderer)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_PlayerStateAnimsEditor.new
    @ui.setup_ui(self)
    
    # rbuic4 is bugged and ignores stretch values, so they must be manually set.
    @ui.horizontalLayout.setStretch(0, 1)
    @ui.horizontalLayout.setStretch(1, 2)
    @ui.horizontalLayout.setStretch(2, 1)
    
    @game = game
    @fs = game.fs
    @renderer = renderer
    
    @anim_graphics_scene = ClickableGraphicsScene.new
    @ui.anim_graphics_view.setScene(@anim_graphics_scene)
    
    connect(@ui.players, SIGNAL("currentRowChanged(int)"), self, SLOT("player_changed(int)"))
    connect(@ui.states, SIGNAL("currentRowChanged(int)"), self, SLOT("state_changed(int)"))
    connect(@ui.anim_index, SIGNAL("activated(int)"), self, SLOT("anim_changed(int)"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_pressed(QAbstractButton*)"))
    
    @game.players.each_with_index do |player, i|
      @ui.players.addItem("%02X %s" % [i, player.name])
    end
    PLAYER_ANIM_STATE_NAMES.each_with_index do |name, i|
      @ui.states.addItem("%02X %s" % [i, name])
    end
    (0..0xFF).each do |i|
      @ui.anim_index.addItem("%02X" % i)
    end
    
    @animation_timer = Qt::Timer.new()
    @animation_timer.setSingleShot(true)
    connect(@animation_timer, SIGNAL("timeout()"), self, SLOT("advance_keyframe()"))
    
    player_changed(0)
    
    self.show()
  end
  
  def player_changed(player_index)
    @player_index = player_index
    
    @ui.players.setCurrentRow(player_index)
    
    @state_anims = @game.state_anims_for_player(player_index)
    
    player = @game.players[player_index]
    sprite_info = SpriteInfo.new(nil, player["Palette pointer"], 0, player["Sprite pointer"], nil, @fs, gfx_list_pointer: player["GFX list pointer"])
    @sprite = sprite_info.sprite
    sprite_frames, _, _ = @renderer.render_sprite(sprite_info)
    @frame_graphics_items = sprite_frames.map{|frame| GraphicsChunkyItem.new(frame)}
    
    state_changed(0)
  end
  
  def state_changed(state_index)
    @state_index = state_index
    
    @ui.states.setCurrentRow(state_index)
    
    anim_index = @state_anims[state_index]
    anim_changed(anim_index)
  end
  
  def anim_changed(anim_index)
    @animation_timer.stop()
    @anim_graphics_scene.items.each do |item|
      @anim_graphics_scene.removeItem(item)
    end
    @current_anim_keyframe_index = 0
    
    @ui.anim_index.setCurrentIndex(anim_index)
    
    @state_anims[@state_index] = anim_index
    
    @current_anim = @sprite.animations[anim_index]
    if @current_anim.nil?
      return
    end
    
    if @current_anim.number_of_frames > 0
      anim_keyframe_changed(0)
      start_animation()
    else
      frame_changed(nil) # Blank out the frame display
    end
  end
  
  def anim_keyframe_changed(i)
    @current_anim_keyframe_index = i
    frame_delay = @current_anim.frame_delays[@current_anim_keyframe_index]
    frame_changed(frame_delay.frame_index)
  end
  
  def start_animation
    frame_delay = @current_anim.frame_delays[@current_anim_keyframe_index]
    millisecond_delay = (frame_delay.delay / 60.0 * 1000).round
    @animation_timer.start(millisecond_delay)
  end
  
  def advance_keyframe
    return if @current_anim.nil?
    
    if @current_anim_keyframe_index >= @current_anim.frame_delays.length-1
      anim_keyframe_changed(0)
    else
      anim_keyframe_changed(@current_anim_keyframe_index+1)
    end
    
    frame_delay = @current_anim.frame_delays[@current_anim_keyframe_index]
    millisecond_delay = (frame_delay.delay / 60.0 * 1000).round
    @animation_timer.start(millisecond_delay)
  end
  
  def frame_changed(frame_index)
    @anim_graphics_scene.items.each do |item|
      @anim_graphics_scene.removeItem(item)
    end
    
    if frame_index == nil || @frame_graphics_items[frame_index] == nil
      return
    end
    
    frame_graphics_item = @frame_graphics_items[frame_index]
    @anim_graphics_scene.addItem(frame_graphics_item)
  end
  
  def save_states
    @game.save_state_anims_for_player(@player_index, @state_anims)
  end
  
  def button_pressed(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_states()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_states()
    end
  end
  
  def inspect; to_s; end
end
