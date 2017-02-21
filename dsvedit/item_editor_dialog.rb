
require_relative 'generic_editor_widget'

require_relative 'ui_item_editor'

class ItemEditor < Qt::Dialog
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, fs)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_ItemEditor.new
    @ui.setup_ui(self)
    
    @fs = fs
    
    ITEM_TYPES.each do |item_type|
      tab = GenericEditorWidget.new(fs, item_type)
      name = item_type[:name]
      @ui.tabWidget.addTab(tab, name)
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
