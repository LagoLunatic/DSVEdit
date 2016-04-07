
require_relative 'ui_settings'

class SettingsWindow < Qt::Dialog
  slots "browse_for_tiled_path()"
  slots "browse_for_emulator_path()"
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, settings)
    super(main_window)
    @ui = Ui_Settings.new
    @ui.setup_ui(self)
    
    @settings = settings
    
    @ui.tiled_path.text = @settings[:tiled_path]
    @ui.emulator_path.text = @settings[:emulator_path]
    
    connect(@ui.tiled_path_browse_button, SIGNAL("clicked()"), self, SLOT("browse_for_tiled_path()"))
    connect(@ui.emulator_path_browse_button, SIGNAL("clicked()"), self, SLOT("browse_for_emulator_path()"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_pressed(QAbstractButton*)"))
    
    #self.setWindowFlags(Qt::MSWindowsFixedSizeDialogHint);
    
    self.show()
  end
  
  def browse_for_tiled_path
    tiled_path = Qt::FileDialog.getOpenFileName()
    return if tiled_path.nil?
    @ui.tiled_path.text = tiled_path
  end
  
  def browse_for_emulator_path
    emulator_path = Qt::FileDialog.getOpenFileName()
    return if emulator_path.nil?
    @ui.emulator_path.text = emulator_path
  end
  
  def button_pressed(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      @settings[:tiled_path] = @ui.tiled_path.text
      @settings[:emulator_path] = @ui.emulator_path.text
    end
  end
end
