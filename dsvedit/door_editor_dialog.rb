
require_relative 'ui_door_editor'

class DoorEditorDialog < Qt::Dialog
  attr_reader :game
  
  slots "door_changed(int)"
  slots "button_box_clicked(QAbstractButton*)"
  slots "delete_door()"
  
  def initialize(main_window, doors, door)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_DoorEditor.new
    @ui.setup_ui(self)
    
    @game = main_window.game
    
    @doors = doors
    @door = door
    if @door.nil?
      @door = @doors.first
    end
    
    @doors.each_index do |i|
      @ui.door_index.addItem("%02X" % i)
    end
    
    door_index = @doors.index(@door)
    if door_index.nil?
      return
    end
    door_changed(door_index)
    
    connect(@ui.door_index, SIGNAL("activated(int)"), self, SLOT("door_changed(int)"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    connect(@ui.delete_door_button, SIGNAL("released()"), self, SLOT("delete_door()"))
    
    self.show()
  end
  
  def door_changed(door_index)
    @door = @doors[door_index]
    
    @ui.pointer.text = "%08X" % @door.door_ram_pointer
    @ui.x_pos.text = "%02X" % @door.x_pos
    @ui.y_pos.text = "%02X" % @door.y_pos
    @ui.dest_room.text = "%08X" % @door.destination_room_metadata_ram_pointer
    if GAME == "hod"
      @ui.dest_x.text = "%02X" % @door.dest_x
      @ui.dest_y.text = "%02X" % @door.dest_y
    else
      @ui.dest_x.text = "%04X" % @door.dest_x
      @ui.dest_y.text = "%04X" % @door.dest_y
    end
    @ui.dest_x_2.text = "%04X" % @door.dest_x_2
    @ui.dest_y_2.text = "%04X" % @door.dest_y_2
    
    @ui.door_index.setCurrentIndex(door_index)
  end
  
  def delete_door
    @doors.delete(@door)
    @door.room.write_doors_to_rom()
    parent.load_room()
    self.close()
  end
  
  def save_door
    @door.x_pos = @ui.x_pos.text.to_i(16)
    @door.y_pos = @ui.y_pos.text.to_i(16)
    @door.destination_room_metadata_ram_pointer = @ui.dest_room.text.to_i(16)
    @door.dest_x = @ui.dest_x.text.to_i(16)
    @door.dest_y = @ui.dest_y.text.to_i(16)
    @door.dest_x_2 = @ui.dest_x_2.text.to_i(16)
    @door.dest_y_2 = @ui.dest_y_2.text.to_i(16)
    @door.write_to_rom()
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_door()
      parent.load_room()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_door()
      parent.load_room()
    end
  end
end
