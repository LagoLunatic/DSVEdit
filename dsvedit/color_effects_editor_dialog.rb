
require_relative 'ui_color_effects_editor'

class ColorEffectsEditorDialog < Qt::Dialog
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, room, color_effects)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_ColorEffectsEditor.new
    @ui.setup_ui(self)
    
    @game = main_window.game
    @room = room
    @color_effects = color_effects
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    read_color_effects()
    
    self.show()
  end
  
  def read_color_effects
    @ui.t1_hud.checked      = (@color_effects & 0x0001)
    @ui.t1_layer_0.checked  = (@color_effects & 0x0002)
    @ui.t1_layer_1.checked  = (@color_effects & 0x0004)
    @ui.t1_layer_2.checked  = (@color_effects & 0x0008)
    @ui.t1_entities.checked = (@color_effects & 0x0010)
    @ui.t1_backdrop.checked = (@color_effects & 0x0020)
    
    @ui.effect_type.setCurrentIndex((@color_effects & 0x00C0) >> 6)
    
    @ui.t2_hud.checked      = (@color_effects & 0x0100)
    @ui.t2_layer_0.checked  = (@color_effects & 0x0200)
    @ui.t2_layer_1.checked  = (@color_effects & 0x0400)
    @ui.t2_layer_2.checked  = (@color_effects & 0x0800)
    @ui.t2_entities.checked = (@color_effects & 0x1000)
    @ui.t2_backdrop.checked = (@color_effects & 0x2000)
  end
  
  def save_color_effects
    @color_effects = 0x0000
    
    @color_effects |= ((1 <<  0) & 0x0001) if @ui.t1_hud.checked
    @color_effects |= ((1 <<  1) & 0x0002) if @ui.t1_layer_0.checked
    @color_effects |= ((1 <<  2) & 0x0004) if @ui.t1_layer_1.checked
    @color_effects |= ((1 <<  3) & 0x0008) if @ui.t1_layer_2.checked
    @color_effects |= ((1 <<  4) & 0x0010) if @ui.t1_entities.checked
    @color_effects |= ((1 <<  5) & 0x0020) if @ui.t1_backdrop.checked
    
    @color_effects |= ((@ui.effect_type.currentIndex << 6) & 0x00C0)
    
    @color_effects |= ((1 <<  8) & 0x0100) if @ui.t2_hud.checked
    @color_effects |= ((1 <<  9) & 0x0200) if @ui.t2_layer_0.checked
    @color_effects |= ((1 << 10) & 0x0400) if @ui.t2_layer_1.checked
    @color_effects |= ((1 << 11) & 0x0800) if @ui.t2_layer_2.checked
    @color_effects |= ((1 << 12) & 0x1000) if @ui.t2_entities.checked
    @color_effects |= ((1 << 13) & 0x2000) if @ui.t2_backdrop.checked
    
    parent.set_color_effects(@color_effects)
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_color_effects()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_color_effects()
    end
  end
end
