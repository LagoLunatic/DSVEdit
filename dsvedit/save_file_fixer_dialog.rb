
require_relative 'ui_save_file_fixer'

class SaveFileFixerDialog < Qt::Dialog
  slots "select_save_file_dialog()"
  
  attr_reader :game
  
  def initialize(main_window)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_SaveFileFixer.new
    @ui.setup_ui(self)
    
    @game = main_window.game
    
    connect(@ui.select_save_file_button, SIGNAL("clicked()"), self, SLOT("select_save_file_dialog()"))
    
    self.show()
  end
  
  def select_save_file_dialog
    default_dir = nil
    if parent.settings["last_used_folder_for_save_files"] && Dir.exist?(parent.settings["last_used_folder_for_save_files"])
      default_dir = parent.settings["last_used_folder_for_save_files"]
    end
    filter = "NDS Save Files (*.sav *.dsv);;All Files (*)"
    save_path = Qt::FileDialog.getOpenFileName(self, "Select save", default_dir, filter)
    return if save_path.nil?
    
    parent.settings["last_used_folder_for_save_files"] = File.dirname(save_path)
    
    game.fix_save_file_hashes(save_path)
    
    Qt::MessageBox.information(self, "Save file fixed", "Hashes successfully recalculated for all save slots within the selected save file.")
  rescue Game::InvalidSaveFileFormatError
    Qt::MessageBox.warning(self, "Invalid save file format", "Selected file is not the correct save format type, or is for the wrong game.\nSave files should not be compressed, and you can only fix save files for the game you currently have opened in DSVEdit.")
  end
end
