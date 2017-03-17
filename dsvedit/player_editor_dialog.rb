
require_relative 'ui_player_editor'

class PlayerEditor < Qt::Dialog
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, fs)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_PlayerEditor.new
    @ui.setup_ui(self)
    
    @fs = fs
    
    player_type = {
      name: "Players",
      list_pointer: PLAYER_LIST_POINTER,
      count: PLAYER_COUNT,
      kind: :player,
      format: PLAYER_LIST_FORMAT
    }
    @editor_widget = GenericEditorWidget.new(fs, player_type, "")
    @ui.horizontalLayout.addWidget(@editor_widget)
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_pressed(QAbstractButton*)"))
    
    self.show()
  end
  
  def button_pressed(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      @editor_widget.save_current_item()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      @editor_widget.save_current_item()
    end
  end
end
