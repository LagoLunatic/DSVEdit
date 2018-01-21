
require_relative 'ui_armips_patcher'

class ArmipsPatcherDialog < Qt::Dialog
  slots "browse_for_patch_path()"
  slots "apply_patch()"
  
  def initialize(main_window, game)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_ArmipsPatcher.new
    @ui.setup_ui(self)
    
    @game = game
    
    connect(@ui.patch_path_browse_button, SIGNAL("clicked()"), self, SLOT("browse_for_patch_path()"))
    connect(@ui.apply_patch_button, SIGNAL("clicked()"), self, SLOT("apply_patch()"))
    
    self.show()
  end
  
  def browse_for_patch_path
    default_folder = "./asm"
    
    filename_prefix = @game.armips_patch_filename_prefix()
    filter = "Program Files (#{filename_prefix}_*.asm);;All Files (*)"
    
    patch_path = Qt::FileDialog.getOpenFileName(self, "Select ARMIPS patch location", default_folder, filter)
    return if patch_path.nil?
    @ui.patch_path.text = patch_path
  end
  
  def apply_patch
    patch_path = @ui.patch_path.text
    if !File.file?(patch_path)
      Qt::MessageBox.warning(self,
        "No patch specified",
        "No ARMIPS patch specified."
      )
      return
    end
    
    @game.apply_armips_patch(patch_path, full_path: true)
    
    Qt::MessageBox.warning(self,
      "Patch applied",
      "Successfully applied the ARMIPS patch."
    )
  rescue StandardError => e
    Qt::MessageBox.warning(self,
      "Failed to apply patch",
      "Failed to apply patch with error:\n#{e.message}\n\n#{e.backtrace.join("\n")}"
    )
  end
end
