
require_relative 'ui_special_object_editor'

class SpecialObjectEditor < Qt::Dialog
  slots "special_object_changed(int)"
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, game)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_SpecialObjectEditor.new
    @ui.setup_ui(self)
    
    @game = game
    
    @special_objects = []
    SPECIAL_OBJECT_IDS.each do |special_object_id|
      special_object = SpecialObjectType.new(special_object_id, game.fs)
      @special_objects << special_object
      object_name = game.special_object_docs[special_object_id]
      object_name = " " if object_name.nil? || object_name.empty?
      object_name = object_name.lines.first.strip
      if object_name.length > 41
        object_name = object_name[0..40]
        object_name << "..."
      end
      @ui.special_object_list.addItem("%02X %s" % [special_object_id, object_name])
    end
    connect(@ui.special_object_list, SIGNAL("currentRowChanged(int)"), self, SLOT("special_object_changed(int)"))
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_pressed(QAbstractButton*)"))
    
    self.show()
  end
  
  def special_object_changed(special_object_id)
    @special_object_id = special_object_id
    obj = @special_objects[@special_object_id]
    
    @ui.create_code.text = "%08X" % obj.create_code_pointer
    @ui.update_code.text = "%08X" % obj.update_code_pointer
    
    doc = @game.special_object_docs[@special_object_id]
    @ui.special_object_doc.setPlainText(doc)
    
    @ui.special_object_list.setCurrentRow(@special_object_id)
  end
  
  def save_current_object
    obj = @special_objects[@special_object_id]
    
    obj.create_code_pointer = @ui.create_code.text.to_i(16)
    obj.update_code_pointer = @ui.update_code.text.to_i(16)
    
    obj.write_to_rom()
  end
  
  def button_pressed(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_current_object()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_current_object()
    end
  end
  
  def inspect; to_s; end
end
