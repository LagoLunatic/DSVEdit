
require_relative 'ui_player_editor'

class PlayerEditor < Qt::Dialog
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, game)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_PlayerEditor.new
    @ui.setup_ui(self)
    
    @game = game
    @fs = game.fs
    
    player_type = {
      name: "Players",
      list_pointer: PLAYER_LIST_POINTER,
      count: PLAYER_COUNT,
      kind: :player,
      format: PLAYER_LIST_FORMAT
    }
    tab = GenericEditorWidget.new(game.fs, game, player_type, main_window.game.player_format_doc, custom_editable_class: Player)
    @ui.tabWidget.addTab(tab, player_type[:name])
    
    if GAME == "hod"
      movement_params_type = {
        name: "Player Movement Params",
        list_pointer: PLAYER_MOVEMENT_PARAMS_LIST_POINTER,
        count: PLAYER_COUNT,
        kind: :player,
        format: PLAYER_MOVEMENT_PARAMS_FORMAT
      }
      tab = GenericEditorWidget.new(game.fs, game, movement_params_type, "", hide_bitfields_tree: true)
      @ui.tabWidget.addTab(tab, movement_params_type[:name])
    end
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_pressed(QAbstractButton*)"))
    
    self.show()
  end
  
  def button_pressed(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      @ui.tabWidget.currentWidget.save_current_item()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      @ui.tabWidget.currentWidget.save_current_item()
    end
  end
end
