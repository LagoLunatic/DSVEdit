
require_relative 'generic_editor_widget'

require_relative 'ui_item_editor'

class ItemEditor < Qt::Dialog
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, fs)
    super(main_window)
    @ui = Ui_ItemEditor.new
    @ui.setup_ui(self)
    
    @fs = fs
    
    ITEM_TYPES.each do |item_type|
      tab = GenericEditorWidget.new(item_type[:list_pointer], item_type[:count], item_type[:format], fs)
      name = item_type[:name]
      @ui.tabWidget.addTab(tab, name)
    end
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_pressed(QAbstractButton*)"))
    
    self.show()
  end
  
  def button_pressed(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      @ui.tabWidget.currentWidget.save_current_item()
    end
  end
end
