
require_relative 'ui_settings'

class SettingsDialog < Qt::Dialog
  slots "browse_for_tiled_path()"
  slots "browse_for_nds_emulator_path()"
  slots "browse_for_gba_emulator_path()"
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, settings)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_Settings.new
    @ui.setup_ui(self)
    
    @settings = settings
    
    @ui.tiled_path.text = @settings[:tiled_path]
    @ui.nds_emulator_path.text = @settings[:emulator_path]
    @ui.gba_emulator_path.text = @settings[:gba_emulator_path]
    
    connect(@ui.tiled_path_browse_button, SIGNAL("clicked()"), self, SLOT("browse_for_tiled_path()"))
    connect(@ui.nds_emulator_path_browse_button, SIGNAL("clicked()"), self, SLOT("browse_for_nds_emulator_path()"))
    connect(@ui.gba_emulator_path_browse_button, SIGNAL("clicked()"), self, SLOT("browse_for_gba_emulator_path()"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_pressed(QAbstractButton*)"))
    
    self.show()
  end
  
  def browse_for_tiled_path
    possible_install_path_x86 = File.join(ENV["ProgramFiles"], "Tiled", "tiled.exe")
    possible_install_path_x64 = File.join(ENV["ProgramW6432"], "Tiled", "tiled.exe")
    if File.file?(possible_install_path_x86)
      default_dir = possible_install_path_x86
    elsif File.file?(possible_install_path_x64)
      default_dir = possible_install_path_x64
    end
    tiled_path = Qt::FileDialog.getOpenFileName(self, "Select Tiled install location", default_dir, "Program Files (*.exe)")
    return if tiled_path.nil?
    @ui.tiled_path.text = tiled_path
  end
  
  def browse_for_nds_emulator_path
    emulator_path = Qt::FileDialog.getOpenFileName()
    return if emulator_path.nil?
    @ui.nds_emulator_path.text = emulator_path
  end
  
  def browse_for_gba_emulator_path
    emulator_path = Qt::FileDialog.getOpenFileName()
    return if emulator_path.nil?
    @ui.gba_emulator_path.text = emulator_path
  end
  
  def button_pressed(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      @settings[:tiled_path] = @ui.tiled_path.text
      @settings[:emulator_path] = @ui.nds_emulator_path.text
      @settings[:gba_emulator_path] = @ui.gba_emulator_path.text
    end
  end
end
