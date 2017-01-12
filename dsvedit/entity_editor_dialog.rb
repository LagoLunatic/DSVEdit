
require_relative 'ui_entity_editor'

class EntityEditorDialog < Qt::Dialog
  ENTITY_TYPE_DESCRIPTIONS = {
    0 => "Nothing",
    1 => "Enemy",
    2 => "Special Object",
    3 => "Candle",
    4 => "Pickup",
    5 => "???",
    6 => "???",
    7 => "???",
    8 => "???",
    9 => "???",
  }
  
  attr_reader :game
  
  slots "type_changed(int)"
  slots "subtype_changed(int)"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, entity)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_EntityEditor.new
    @ui.setup_ui(self)
    
    @game = main_window.game
    
    (0..0xFF).each do |i|
      description = ENTITY_TYPE_DESCRIPTIONS[i] || "Unused"
      @ui.type.addItem("%02X %s" % [i, description])
    end
    
    @entity = entity
    
    @ui.pointer.text = "%08X" % entity.entity_ram_pointer
    @ui.x_pos.text = "%04X" % [entity.x_pos].pack("s").unpack("v").first
    @ui.y_pos.text = "%04X" % [entity.y_pos].pack("s").unpack("v").first
    @ui.byte_5.text = "%02X" % entity.byte_5
    @ui.type.setCurrentIndex(entity.type)
    type_changed(entity.type)
    @ui.byte_8.text = "%02X" % entity.byte_8
    subtype_changed(entity.subtype)
    @ui.var_a.text = "%04X" % entity.var_a
    @ui.var_b.text = "%04X" % entity.var_b
    
    connect(@ui.type, SIGNAL("activated(int)"), self, SLOT("type_changed(int)"))
    connect(@ui.subtype, SIGNAL("activated(int)"), self, SLOT("subtype_changed(int)"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    self.show()
  end
  
  def type_changed(type)
    @ui.subtype.clear()
    
    (0..0xFF).each do |subtype|
      subtype_name = ""
      
      case type
      when 1
        if subtype < @game.enemy_dnas.length
         subtype_name = @game.enemy_dnas[subtype].name.decoded_string
        end
      when 2
        subtype_name = (game.special_object_docs[subtype] || " ").lines.first.strip[0..100]
      when 4
        if subtype == 0
          subtype_name = "Heart"
        elsif subtype == 1
          subtype_name = "Money"
        elsif PICKUP_SUBTYPES_FOR_ITEMS.include?(subtype)
          subtype_name = ITEM_TYPES[subtype-2][:name]
        elsif PICKUP_SUBTYPES_FOR_SKILLS.include?(subtype)
          subtype_name = "Skill"
        end
      end
      
      @ui.subtype.addItem("%02X %s" % [subtype, subtype_name])
    end
    
    @ui.subtype.setCurrentIndex(@entity.subtype)
    subtype_changed(@entity.subtype)
  end
  
  def subtype_changed(subtype)
    case @ui.type.currentIndex
    when 1
      @ui.entity_doc.setPlainText(game.enemy_docs[subtype])
    when 2
      @ui.entity_doc.setPlainText(game.special_object_docs[subtype])
    else
      @ui.entity_doc.setPlainText("")
    end
  end
  
  def save_entity
    @entity.x_pos   = [@ui.x_pos.text.to_i(16)].pack("v").unpack("s").first
    @entity.y_pos   = [@ui.y_pos.text.to_i(16)].pack("v").unpack("s").first
    @entity.byte_5  = @ui.byte_5.text.to_i(16)
    @entity.type    = @ui.type.currentIndex
    @entity.subtype = @ui.subtype.currentIndex
    @entity.byte_8  = @ui.byte_8.text.to_i(16)
    @entity.var_a   = @ui.var_a.text.to_i(16)
    @entity.var_b   = @ui.var_b.text.to_i(16)
    @entity.write_to_rom()
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_entity()
      parent.load_room()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_entity()
      parent.load_room()
    end
  end
end
