
require_relative 'ui_room_editor'

class RoomEditorDialog < Qt::Dialog
  attr_reader :game
  
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, room, renderer)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_RoomEditor.new
    @ui.setup_ui(self)
    
    @game = main_window.game
    @room = room
    @renderer = renderer
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    read_room()
    
    self.show()
  end
  
  def read_room
    @ui.layer_list.text = "%08X" % @room.layer_list_ram_pointer
    @ui.gfx_page_list.text = "%08X" % @room.gfx_list_pointer
    @ui.palette_page_list.text = "%08X" % @room.palette_wrapper_pointer
    @ui.entity_list.text = "%08X" % @room.entity_list_ram_pointer
    @ui.door_list.text = "%08X" % @room.door_list_ram_pointer
  end
  
  def save_room
    @room.layer_list_ram_pointer = @ui.layer_list.text.to_i(16)
    @room.gfx_list_pointer = @ui.gfx_page_list.text.to_i(16)
    @room.palette_wrapper_pointer = @ui.palette_page_list.text.to_i(16)
    @room.entity_list_ram_pointer = @ui.entity_list.text.to_i(16)
    @room.door_list_ram_pointer = @ui.door_list.text.to_i(16)
    
    @room.write_to_rom()
    
    @game.fix_map_sector_and_room_indexes(@room.area_index, @room.sector_index)
    
    read_room()
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_room()
      parent.load_room()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_room()
      parent.load_room()
    end
  end
end
