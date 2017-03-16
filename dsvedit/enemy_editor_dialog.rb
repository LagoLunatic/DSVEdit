
require_relative 'ui_enemy_editor'

class EnemyEditor < Qt::Dialog
  slots "enemy_changed(int)"
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, fs)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_EnemyDNAEditor.new
    @ui.setup_ui(self)
    
    @fs = fs
    
    enemy_type = {
      name: "Enemies",
      list_pointer: ENEMY_DNA_RAM_START_OFFSET,
      count: ENEMY_IDS.size,
      kind: :enemy,
      format: ENEMY_DNA_FORMAT
    }
    editor_widget = GenericEditorWidget.new(fs, enemy_type, main_window.game.enemy_format_doc)
    @ui.horizontalLayout.addWidget(editor_widget)
    
    self.show()
  end
end
