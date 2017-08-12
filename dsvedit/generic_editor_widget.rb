
require_relative 'ui_generic_editor'

class GenericEditorWidget < Qt::Widget
  attr_reader :fs, :game
  
  slots "item_changed(int)"
  slots "open_icon_chooser()"
  slots "open_color_chooser()"
  
  def initialize(fs, game, item_type, format_doc)
    super()
    @ui = Ui_GenericEditorWidget.new
    @ui.setup_ui(self)
    
    # rbuic4 is bugged and ignores stretch values, so they must be manually set.
    @ui.horizontalLayout.setStretch(0, 3)
    @ui.horizontalLayout.setStretch(1, 5)
    @ui.horizontalLayout.setStretch(2, 8)
    
    @fs = fs
    @game = game
    
    @item_type_name = item_type[:name]
    
    @items = []
    (0..item_type[:count]-1).each do |index|
      item = GenericEditable.new(index, item_type, game, fs)
      @items << item
      @ui.item_list.addItem("%02X %s" % [index, item.name])
    end
    connect(@ui.item_list, SIGNAL("currentRowChanged(int)"), self, SLOT("item_changed(int)"))
    
    @attribute_text_fields = {}
    @items.first.attribute_integers.keys.each_with_index do |attribute_name, i|
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
      elsif attribute_name =~ /color/
        field = Qt::PushButton.new(self)
        field.objectName = attribute_name
        connect(field, SIGNAL("clicked()"), self, SLOT("open_color_chooser()"))
      else
        field = Qt::LineEdit.new(self)
      end
      field.setMaximumSize(80, 16777215)
      form_layout.setWidget(i/2, Qt::FormLayout::FieldRole, field)
      
      @attribute_text_fields[attribute_name] = field
    end
    
    @items.first.attribute_bitfields.each_with_index do |attribute, col|
      attribute_name, bitfield = attribute
      attribute_length = @items.first.attribute_bitfield_lengths[col]
      
      (0..attribute_length*8-1).each do |row|
        tree_row_item = @ui.treeWidget.topLevelItem(row)
        if tree_row_item.nil?
          tree_row_item = Qt::TreeWidgetItem.new(@ui.treeWidget)
        end
        
        @ui.treeWidget.headerItem.setText(col, attribute_name)
        
        tree_row_item.setText(col, bitfield.names[row])
      end
      @ui.treeWidget.setColumnWidth(col, 180)
    end
    if @items.first.attribute_bitfields.empty?
      # If there are no bitfields then blank out the tree widget, otherwise it defaults to showing just a "1".
      @ui.treeWidget.headerItem.setText(0, "")
    end
    
    @ui.format_doc.setPlainText(format_doc)
    
    item_changed(0)
  end
  
  def item_changed(index)
    item = @items[index]
    
    @ui.item_name.setText(item.name)
    @ui.item_pointer.setText("%08X" % item.ram_pointer)
    @ui.item_desc.setPlainText(item.description)
    
    item.attribute_integers.values.each_with_index do |value, i|
      if i.even?
        form_layout = @ui.attribute_layout_left
      else
        form_layout = @ui.attribute_layout_right
      end
      
      attribute_length = item.attribute_integer_lengths[i]
      string_length = attribute_length*2
      
      field = form_layout.itemAt(i/2, Qt::FormLayout::FieldRole).widget
      field.text = "%0#{string_length}X" % value
    end
    
    item.attribute_bitfields.values.each_with_index do |value, col|
      attribute_length = item.attribute_bitfield_lengths[col]
      
      (0..attribute_length*8-1).each do |row|
        tree_row_item = @ui.treeWidget.topLevelItem(row)
        
        if value[row]
          tree_row_item.setCheckState(col, Qt::Checked)
        else
          tree_row_item.setCheckState(col, Qt::Unchecked)
        end
      end
    end
    
    @ui.item_list.setCurrentRow(index)
  end
  
  def save_current_item
    item = @items[@ui.item_list.currentRow]
    
    item.attribute_integers.each do |attribute_name, value|
      item[attribute_name] = @attribute_text_fields[attribute_name].text.to_i(16)
    end
    
    item.attribute_bitfields.keys.each_with_index do |attribute_name, col|
      attribute_length = item.attribute_bitfield_lengths[col]
      
      (0..attribute_length*8-1).each do |row|
        tree_row_item = @ui.treeWidget.topLevelItem(row)
        
        if tree_row_item.checkState(col) == Qt::Checked
          item.attribute_bitfields[attribute_name][row] = true
        else
          item.attribute_bitfields[attribute_name][row] = false
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
  
  def open_color_chooser
    attribute_name = sender.objectName
    color_value = @attribute_text_fields[attribute_name].text.to_i(16)
    
    a = ((color_value & 0xFF000000) >> 24) / 31.0 * 255
    b = ((color_value & 0x00FF0000) >> 16) / 31.0 * 255
    g = ((color_value & 0x0000FF00) >>  8) / 31.0 * 255
    r = ((color_value & 0x000000FF) >>  0) / 31.0 * 255
    
    initial_color = Qt::Color.new(r, g, b, a)
    color = Qt::ColorDialog.getColor(initial_color, self, "Select color", Qt::ColorDialog::ShowAlphaChannel)
    
    unless color.isValid
      # User clicked cancel.
      return
    end
    
    color_value = 0
    color_value |= (color.alpha / 255.0 * 31).round << 24
    color_value |= (color.blue  / 255.0 * 31).round << 16
    color_value |= (color.green / 255.0 * 31).round << 8
    color_value |= (color.red   / 255.0 * 31).round << 0
    
    @attribute_text_fields[attribute_name].text = "%08X" % color_value
  end
end
