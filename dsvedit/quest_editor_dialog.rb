
require_relative 'ui_quest_editor'

class QuestEditor < Qt::Dialog
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, game)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_QuestEditor.new
    @ui.setup_ui(self)
    
    @game = game
    @fs = game.fs
    
    quest_type = {
      name: "Quests",
      list_pointer: QUEST_LIST_POINTER,
      count: QUEST_COUNT,
      kind: :quest,
      format: QUEST_LIST_FORMAT
    }
    @editor_widget = GenericEditorWidget.new(game.fs, game, quest_type, main_window.game.quest_format_doc, custom_editable_class: Quest)
    @ui.horizontalLayout.addWidget(@editor_widget)
    
    # Adjust some of the text field sizes to be bigger for quests.
    @editor_widget.ui.item_name.maximumWidth = 250
    @editor_widget.ui.item_desc.maximumHeight = 92
    @editor_widget.ui.horizontalLayout.setStretch(0, 4)
    @editor_widget.ui.horizontalLayout.setStretch(1, 5)
    @editor_widget.ui.horizontalLayout.setStretch(2, 6)
    
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
