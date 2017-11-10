
require_relative 'ui_entity_editor'

class EntityEditorDialog < Qt::Dialog
  attr_reader :game
  
  slots "entity_changed(int)"
  slots "type_changed(int)"
  slots "subtype_changed(int)"
  slots "button_box_clicked(QAbstractButton*)"
  slots "delete_entity()"
  
  def initialize(main_window, room, entity)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_EntityEditor.new
    @ui.setup_ui(self)
    
    @game = main_window.game
    
    if GAME == "hod"
      max_type = 3
    else
      max_type = 0xFF
    end
    (0..max_type).each do |i|
      description = ENTITY_TYPE_DESCRIPTIONS[i] || "Unused"
      @ui.type.addItem("%02X %s" % [i, description])
    end
    
    @room = room
    @entity = entity
    if @entity.nil?
      @entity = @room.entities.first
    end
    
    connect(@ui.entity_index, SIGNAL("activated(int)"), self, SLOT("entity_changed(int)"))
    connect(@ui.type, SIGNAL("activated(int)"), self, SLOT("type_changed(int)"))
    connect(@ui.subtype, SIGNAL("activated(int)"), self, SLOT("subtype_changed(int)"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    connect(@ui.delete_entity_button, SIGNAL("released()"), self, SLOT("delete_entity()"))
    
    initialize_entity_list()
    
    self.show()
  end
  
  def initialize_entity_list
    @ui.entity_index.clear()
    @room.entities.each_index do |i|
      @ui.entity_index.addItem("%02X" % i)
    end
    
    entity_index = @room.entities.index(@entity)
    entity_changed(entity_index)
  end
  
  def entity_changed(entity_index)
    @entity = @room.entities[entity_index]
    
    @ui.pointer.text = "%08X" % @entity.entity_ram_pointer
    @ui.x_pos.text = "%04X" % [@entity.x_pos].pack("s").unpack("v").first
    @ui.y_pos.text = "%04X" % [@entity.y_pos].pack("s").unpack("v").first
    @ui.byte_5.text = "%02X" % @entity.byte_5
    @ui.type.setCurrentIndex(@entity.type)
    type_changed(@entity.type)
    @ui.byte_8.text = "%02X" % @entity.byte_8
    subtype_changed(@entity.subtype)
    @ui.var_a.text = "%04X" % @entity.var_a
    @ui.var_b.text = "%04X" % @entity.var_b
    
    @ui.entity_index.setCurrentIndex(entity_index)
  end
  
  def type_changed(type)
    @ui.subtype.clear()
    
    (0..0xFF).each do |subtype|
      subtype_name = ""
      
      if type == ENEMY_ENTITY_TYPE
        if subtype < @game.enemy_dnas.length
          subtype_name = @game.enemy_dnas[subtype].name
        end
      elsif type == SPECIAL_OBJECT_ENTITY_TYPE
        subtype_name = (game.special_object_docs[subtype] || " ").lines.first.strip[0..100]
      elsif type == PICKUP_ENTITY_TYPE || (type == 7 && ["por", "ooe"].include?(GAME)) || (type == 6 && GAME == "por")
        if GAME == "hod"
          if PICKUP_SUBTYPES_FOR_ITEMS.include?(subtype)
            subtype_name = ITEM_TYPES[subtype-3][:name]
          elsif subtype == 9
            subtype_name = "Max up"
          else
            subtype_name = "Crash"
          end
        elsif subtype == 0
          subtype_name = "Heart"
        elsif subtype == 1
          subtype_name = "Money"
        elsif PICKUP_SUBTYPES_FOR_ITEMS.include?(subtype)
          if GAME == "ooe"
            subtype_name = "Item"
          else
            subtype_name = ITEM_TYPES[subtype-2][:name]
          end
        elsif PICKUP_SUBTYPES_FOR_SKILLS.include?(subtype)
          subtype_name = "Skill"
        else
          subtype_name = "Crash"
        end
      elsif type == CANDLE_ENTITY_TYPE && GAME == "hod"
        case subtype
        when 0
          subtype_name = "Drops heart"
        when 1
          subtype_name = "Drops money"
        when 2
          subtype_name = "Drops subweapon"
        when 3
          subtype_name = "Drops item"
        end
      end
      
      @ui.subtype.addItem("%02X %s" % [subtype, subtype_name])
    end
    
    @ui.subtype.setCurrentIndex(@entity.subtype)
    subtype_changed(@entity.subtype)
  end
  
  def subtype_changed(subtype)
    case @ui.type.currentIndex
    when ENEMY_ENTITY_TYPE
      @ui.entity_doc.setPlainText(game.enemy_docs[subtype])
    when SPECIAL_OBJECT_ENTITY_TYPE
      @ui.entity_doc.setPlainText(game.special_object_docs[subtype])
    else
      @ui.entity_doc.setPlainText(game.entity_type_docs[@ui.type.currentIndex])
    end
  end
  
  def delete_entity
    @room.entities.delete(@entity)
    @entity.room.write_entities_to_rom()
    parent.load_room()
    self.close()
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
    
    initialize_entity_list() # Need to reload the list in case it was reordered by the logic that sorts the list to make entities work on GBA.
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
