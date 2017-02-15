
require_relative 'ui_generic_editor'

class GenericEditorWidget < Qt::Widget
  attr_reader :fs
  
  slots "item_changed(int)"
  slots "open_icon_chooser()"
  
  def initialize(fs, item_type)
    super()
    @ui = Ui_GenericEditorWidget.new
    @ui.setup_ui(self)
    
    @fs = fs
    
    @item_type_name = item_type[:name]
    
    @items = []
    (0..item_type[:count]-1).each do |index|
      item = Item.new(index, item_type, fs)
      @items << item
      @ui.item_list.addItem("%02X %s" % [index, item.name.decoded_string])
    end
    connect(@ui.item_list, SIGNAL("currentRowChanged(int)"), self, SLOT("item_changed(int)"))
    
    @attribute_text_fields = {}
    @items.first.item_attribute_integers.keys.each_with_index do |attribute_name, i|
      if i.even?
        form_layout = @ui.attribute_layout_left
      else
        form_layout = @ui.attribute_layout_right
      end
      
      label = Qt::Label.new(self)
      label.text = attribute_name
      form_layout.setWidget(i/2, Qt::FormLayout::LabelRole, label)
      
      if attribute_name == "Icon"
        field = Qt::PushButton.new(self)
        connect(field, SIGNAL("clicked()"), self, SLOT("open_icon_chooser()"))
      else
        field = Qt::LineEdit.new(self)
      end
      field.setMaximumSize(80, 16777215)
      form_layout.setWidget(i/2, Qt::FormLayout::FieldRole, field)
      
      @attribute_text_fields[attribute_name] = field
    end
    
    @items.first.item_attribute_bitfields.keys.each_with_index do |attribute_name, col|
      (0..15).each do |row|
        item = @ui.treeWidget.topLevelItem(row)
        if item.nil?
          item = Qt::TreeWidgetItem.new(@ui.treeWidget)
        end
        
        @ui.treeWidget.headerItem.setText(col, attribute_name)
        
        bitfield_attribute_names = ITEM_BITFIELD_ATTRIBUTES[attribute_name]
        
        item.setText(col, bitfield_attribute_names[row])
      end
      @ui.treeWidget.setColumnWidth(col, 150)
    end
    if @items.first.item_attribute_bitfields.empty?
      # If there are no bitfields then blank out the tree widget, otherwise it defaults to showing just a "1".
      @ui.treeWidget.headerItem.setText(0, "")
    end
    
    item_changed(0)
  end
  
  def item_changed(index)
    item = @items[index]
    
    @ui.item_name.setText(item.name.decoded_string)
    @ui.item_pointer.setText("%08X" % item.ram_pointer)
    @ui.item_desc.setPlainText(item.description.decoded_string)
    
    item.item_attribute_integers.values.each_with_index do |value, i|
      if i.even?
        form_layout = @ui.attribute_layout_left
      else
        form_layout = @ui.attribute_layout_right
      end
      
      attribute_length = item.item_attribute_integer_lengths[i]
      string_length = attribute_length*2
      
      field = form_layout.itemAt(i/2, Qt::FormLayout::FieldRole).widget
      field.text = "%0#{string_length}X" % value
    end
    
    item.item_attribute_bitfields.values.each_with_index do |value, col|
      (0..15).each do |row|
        item = @ui.treeWidget.topLevelItem(row)
        
        if value[row]
          item.setCheckState(col, Qt::Checked)
        else
          item.setCheckState(col, Qt::Unchecked)
        end
      end
    end
    
    @ui.item_list.setCurrentRow(index)
  end
  
  def save_current_item
    item = @items[@ui.item_list.currentRow]
    
    item.item_attribute_integers.each do |attribute_name, value|
      item[attribute_name] = @attribute_text_fields[attribute_name].text.to_i(16)
    end
    
    item.item_attribute_bitfields.keys.each_with_index do |attribute_name, col|
      (0..15).each do |row|
        item = @ui.treeWidget.topLevelItem(row)
        
        if item.checkState(col) == Qt::Checked
          item.item_attribute_bitfields[attribute_name][row] = true
        else
          item.item_attribute_bitfields[attribute_name][row] = false
        end
      end
    end
    
    item.write_to_rom()
  end
  
  def set_icon(new_icon_data)
    @attribute_text_fields["Icon"].text = "%04X" % new_icon_data
  end
  
  def open_icon_chooser
    icon_data = @attribute_text_fields["Icon"].text.to_i(16)
    if @item_type_name =~ /Glyph/
      mode = :glyph
    else
      mode = :item
    end
    @icon_chooser_dialog = IconChooserDialog.new(self, fs, mode, icon_data)
  end
end
