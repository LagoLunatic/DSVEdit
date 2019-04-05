
require_relative 'ui_text_editor'

class TextEditor < Qt::Dialog
  slots "string_changed(int)"
  slots "save_button_pressed()"
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, fs)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_TextEditor.new
    @ui.setup_ui(self)
    
    @fs = fs
    
    @text_database = TextDatabase.new(fs)
    
    TEXT_REGIONS.each do |region_name, text_index_range|
      tab = Qt::Widget.new
      tab.layout = Qt::HBoxLayout.new
      text_list = Qt::ListWidget.new(self)
      tab.layout.addWidget(text_list)
      tab.layout.addWidget(Qt::TextEdit.new(self))
      tab.layout.setStretch(0, 2)
      tab.layout.setStretch(1, 3)
      @ui.tabWidget.addTab(tab, region_name)
      
      connect(text_list, SIGNAL("currentRowChanged(int)"), self, SLOT("string_changed(int)"))
      
      @text_database.text_list[text_index_range].each do |text|
        text_in_list = convert_text_to_list_display_text(text)
        text_list.addItem(text_in_list)
      end
    end
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_pressed(QAbstractButton*)"))
    
    string_changed(0)
    
    self.show()
  end
  
  def convert_text_to_list_display_text(text)
    string = text.decoded_string
    if string.include?("\n")
      newline_index = string.index("\n")
      string = string[0, newline_index]
    end
    if string.length > 36
      string = string[0,36]
    end
    string += "..." unless string == text.decoded_string
    return "%03X %08X %s" % [text.text_id, text.string_ram_pointer, string]
  end
  
  def reload_all_text_lists
    TEXT_REGIONS.values.each_with_index do |text_index_range, tab_index|
      first_text_index_in_tab = text_index_range.begin
      
      tab_layout = @ui.tabWidget.widget(tab_index).layout
      text_list = tab_layout.itemAt(0).widget
      
      text_list.count.times do |row|
        text_id = first_text_index_in_tab + row
        text = @text_database.text_list[text_id]
        
        new_text_in_list = convert_text_to_list_display_text(text)
        list_item = text_list.item(row)
        list_item.setText(new_text_in_list)
      end
    end
  end
  
  def string_changed(text_index_in_tab)
    first_text_index_in_tab = TEXT_REGIONS.values[@ui.tabWidget.currentIndex].begin
    text_id = first_text_index_in_tab + text_index_in_tab
    @current_text_id = text_id
    
    text = @text_database.text_list[text_id]
    current_tab_layout = @ui.tabWidget.currentWidget.layout
    text_edit = current_tab_layout.itemAt(1).widget
    @current_text_edit = text_edit
    
    text_edit.setPlainText(text.decoded_string)
  end
  
  def button_pressed(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_current_text()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_current_text()
    end
  end
  
  def save_current_text
    text = @text_database.text_list[@current_text_id]
    
    text.decoded_string = @current_text_edit.toPlainText()
    
    @text_database.write_to_rom()
    
    reload_all_text_lists()
  rescue Text::TextEncodeError, Encoding::UndefinedConversionError => e
    Qt::MessageBox.warning(self, "Error encoding text", e.message)
  rescue TextDatabase::StringDatabaseTooLargeError => e
    Qt::MessageBox.warning(self, "Not enough free space", "Not enough room to fit all expanded strings")
  end
end
