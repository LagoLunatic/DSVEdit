
require_relative 'ui_enemy_editor'

class EnemyEditor < Qt::Dialog
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, game)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_EnemyDNAEditor.new
    @ui.setup_ui(self)
    
    @game = game
    @fs = game.fs
    
    enemy_type = {
      name: "Enemies",
      list_pointer: ENEMY_DNA_RAM_START_OFFSET,
      count: ENEMY_IDS.size,
      kind: :enemy,
      format: ENEMY_DNA_FORMAT
    }
    @editor_widget = GenericEditorWidget.new(game.fs, game, enemy_type, main_window.game.enemy_format_doc, custom_editable_class: EnemyDNA)
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
