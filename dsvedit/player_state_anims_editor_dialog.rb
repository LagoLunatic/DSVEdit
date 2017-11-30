
require_relative 'ui_player_state_anims_editor'

class PlayerStateAnimsEditor < Qt::Dialog
  slots "player_changed(int)"
  slots "state_changed(int)"
  slots "anim_changed(int)"
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
    @sprite_frames, _, _ = @renderer.render_sprite(sprite_info)
    
    state_changed(0)
  end
  
  def state_changed(state_index)
    @state_index = state_index
    
    @ui.states.setCurrentRow(state_index)
    
    anim_index = @state_anims[state_index]
    anim_changed(anim_index)
  end
  
  def anim_changed(anim_index)
    @anim_graphics_scene.clear()
    
    @ui.anim_index.setCurrentIndex(anim_index)
    
    @state_anims[@state_index] = anim_index
    
    anim = @sprite.animations[anim_index]
    if anim.nil?
      return
    end
    
    frame_index = anim.frame_delays.first.frame_index
    frame = @sprite_frames[frame_index]
    item = GraphicsChunkyItem.new(frame)
    @anim_graphics_scene.addItem(item)
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
end
