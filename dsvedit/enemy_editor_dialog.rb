
require_relative 'ui_enemy_editor'

class EnemyEditor < Qt::Dialog
  slots "enemy_changed(int)"
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, fs)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_EnemyDNAEditor.new
    @ui.setup_ui(self)
    
    @fs = fs
    
    @enemies = []
    ENEMY_IDS.each do |enemy_id|
      enemy = EnemyDNA.new(enemy_id, fs)
      @enemies << enemy
      @ui.enemy_list.addItem("%02X %s" % [enemy_id, enemy.name.decoded_string])
    end
    connect(@ui.enemy_list, SIGNAL("currentRowChanged(int)"), self, SLOT("enemy_changed(int)"))
    
    @attribute_text_fields = {}
    @enemies.first.dna_attribute_integers.keys.each_with_index do |attribute_name, i|
      if i.even?
        form_layout = @ui.attribute_layout_left
      else
        form_layout = @ui.attribute_layout_right
      end
      
      label = Qt::Label.new(self)
      label.text = attribute_name
      form_layout.setWidget(i/2, Qt::FormLayout::LabelRole, label)
      
      field = Qt::LineEdit.new(self)
      field.setMaximumSize(80, 16777215)
      form_layout.setWidget(i/2, Qt::FormLayout::FieldRole, field)
      
      @attribute_text_fields[attribute_name] = field
    end
    
    @enemies.first.dna_attribute_bitfields.keys.each_with_index do |attribute_name, col|
      attribute_length = @enemies.first.dna_attribute_bitfield_lengths[col]
      
      (0..attribute_length*8-1).each do |row|
        tree_row_item = @ui.treeWidget.topLevelItem(row)
        if tree_row_item.nil?
          tree_row_item = Qt::TreeWidgetItem.new(@ui.treeWidget)
        end
        
        bitfield_attribute_names = ENEMY_DNA_BITFIELD_ATTRIBUTES[attribute_name]
        
        tree_row_item.setText(col, bitfield_attribute_names[row])
      end
      @ui.treeWidget.setColumnWidth(col, 150)
    end
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_pressed(QAbstractButton*)"))
    
    enemy_changed(0)
    
    self.show()
  end
  
  def enemy_changed(enemy_id)
    enemy = @enemies[enemy_id]
    
    @ui.name.setText(enemy.name.decoded_string)
    @ui.pointer.setText("%08X" % enemy.enemy_dna_ram_pointer)
    @ui.desc.setPlainText(enemy.description.decoded_string)
    
    enemy.dna_attribute_integers.values.each_with_index do |value, i|
      if i.even?
        form_layout = @ui.attribute_layout_left
      else
        form_layout = @ui.attribute_layout_right
      end
      
      attribute_length = enemy.dna_attribute_integer_lengths[i]
      string_length = attribute_length*2
      
      field = form_layout.itemAt(i/2, Qt::FormLayout::FieldRole).widget
      field.text = "%0#{string_length}X" % value
    end
    
    enemy.dna_attribute_bitfields.values.each_with_index do |value, col|
      attribute_length = enemy.dna_attribute_bitfield_lengths[col]
      
      (0..attribute_length*8-1).each do |row|
        tree_row_item = @ui.treeWidget.topLevelItem(row)
        
        if value[row]
          tree_row_item.setCheckState(col, Qt::Checked)
        else
          tree_row_item.setCheckState(col, Qt::Unchecked)
        end
      end
    end
    
    @ui.enemy_list.setCurrentRow(enemy_id)
  end
  
  def button_pressed(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_current_enemy()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_current_enemy()
    end
  end
  
  def save_current_enemy
    enemy = @enemies[@ui.enemy_list.currentRow]
    
    enemy.dna_attribute_integers.each do |attribute_name, value|
      enemy[attribute_name] = @attribute_text_fields[attribute_name].text.to_i(16)
    end
    
    enemy.dna_attribute_bitfields.keys.each_with_index do |attribute_name, col|
      attribute_length = enemy.dna_attribute_bitfield_lengths[col]
      
      (0..attribute_length*8-1).each do |row|
        tree_row_item = @ui.treeWidget.topLevelItem(row)
        
        if tree_row_item.checkState(col) == Qt::Checked
          enemy.dna_attribute_bitfields[attribute_name][row] = true
        else
          enemy.dna_attribute_bitfields[attribute_name][row] = false
        end
      end
    end
    
    enemy.write_to_rom()
  end
end
