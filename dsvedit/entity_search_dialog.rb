
require_relative 'ui_entity_search'

class EntitySearchDialog < Qt::Dialog
  slots "execute_search()"
  slots "room_changed(int)"
  
  def initialize(main_window)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_EntitySearch.new
    @ui.setup_ui(self)
    
    connect(@ui.find_button, SIGNAL("clicked()"), self, SLOT("execute_search()"))
    connect(@ui.room_list, SIGNAL("currentRowChanged(int)"), self, SLOT("room_changed(int)"))
    
    self.show()
  end
  
  def execute_search
    @rooms = []
    @ui.room_list.clear()
    
    byte_5 = @ui.byte_5.text =~ /^\h+$/ ? @ui.byte_5.text.to_i(16) : nil
    type = @ui.type.text =~ /^\h+$/ ? @ui.type.text.to_i(16) : nil
    subtype = @ui.subtype.text =~ /^\h+$/ ? @ui.subtype.text.to_i(16) : nil
    byte_8 = @ui.byte_8.text =~ /^\h+$/ ? @ui.byte_8.text.to_i(16) : nil
    var_a = @ui.var_a.text =~ /^\h+$/ ? @ui.var_a.text.to_i(16) : nil
    var_b = @ui.var_b.text =~ /^\h+$/ ? @ui.var_b.text.to_i(16) : nil
    
    if !byte_5 && !type && !subtype && !byte_8 && !var_a && !var_b
      return
    end
    
    rooms = []
    parent.game.each_room do |room|
      room.entities.each do |entity|
        next if byte_5 && byte_5 != entity.byte_5
        next if type && type != entity.type
        next if subtype && subtype != entity.subtype
        next if byte_8 && byte_8 != entity.byte_8
        next if var_a && var_a != entity.var_a
        next if var_b && var_b != entity.var_b
        
        @rooms << room.room_metadata_ram_pointer
        @ui.room_list.addItem("%08X" % room.room_metadata_ram_pointer)
        break # Only need to add each room to the list once
      end
    end
  end
  
  def room_changed(index)
    return if index == -1
    room_metadata = @rooms[index]
    parent.change_room_by_metadata(room_metadata)
  end
end
