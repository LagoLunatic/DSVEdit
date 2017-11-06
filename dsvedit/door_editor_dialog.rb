
require_relative 'ui_door_editor'

class DoorEditorDialog < Qt::Dialog
  attr_reader :game
  
  slots "door_changed(int)"
  slots "copy_door_pointer_to_clipboard()"
  slots "button_box_clicked(QAbstractButton*)"
  slots "delete_door()"
  
  def initialize(main_window, renderer, doors, door)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_DoorEditor.new
    @ui.setup_ui(self)
    
    @game = main_window.game
    @renderer = renderer
    
    @dest_room_graphics_scene = Qt::GraphicsScene.new
    @ui.dest_room_graphics_view.scale(0.5, 0.5)
    @ui.dest_room_graphics_view.setScene(@dest_room_graphics_scene)
    @ui.dest_room_graphics_view.setDragMode(Qt::GraphicsView::ScrollHandDrag)
    self.setStyleSheet("QGraphicsView { background-color: transparent; }");
    
    @doors = doors
    @door = door
    if @door.nil?
      @door = @doors.first
    end
    
    @doors.each_with_index do |door, i|
      @ui.door_index.addItem("%02X %08X" % [i, door.door_ram_pointer])
    end
    
    door_index = @doors.index(@door)
    if door_index.nil?
      return
    end
    door_changed(door_index)
    
    connect(@ui.door_index, SIGNAL("activated(int)"), self, SLOT("door_changed(int)"))
    connect(@ui.copy_door_pointer, SIGNAL("released()"), self, SLOT("copy_door_pointer_to_clipboard()"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    connect(@ui.delete_door_button, SIGNAL("released()"), self, SLOT("delete_door()"))
    
    self.show()
  end
  
  def door_changed(door_index)
    @door = @doors[door_index]
    
    @ui.x_pos.text = "%02X" % @door.x_pos
    @ui.y_pos.text = "%02X" % @door.y_pos
    @ui.dest_room.text = "%08X" % @door.destination_room_metadata_ram_pointer
    @ui.dest_x.text = "%04X" % @door.dest_x
    @ui.dest_y.text = "%04X" % @door.dest_y
    if GAME == "hod"
      @ui.dest_x_2.text = "%02X" % @door.dest_x_2
      @ui.dest_y_2.text = "%02X" % @door.dest_y_2
    else
      @ui.dest_x_2.text = "%04X" % @door.dest_x_2
      @ui.dest_y_2.text = "%04X" % @door.dest_y_2
    end
    
    @ui.door_index.setCurrentIndex(door_index)
    
    room = game.get_room_by_metadata_pointer(@door.destination_room_metadata_ram_pointer)
    display_dest_room(room)
  end
  
  def delete_door
    @doors.delete(@door)
    @door.room.write_doors_to_rom()
    parent.load_room()
    self.close()
  end
  
  def display_dest_room(room)
    @dest_room_graphics_scene.clear()
    @dest_room_graphics_scene = Qt::GraphicsScene.new
    @ui.dest_room_graphics_view.setScene(@dest_room_graphics_scene)
    @layers_view_item = Qt::GraphicsRectItem.new
    @dest_room_graphics_scene.addItem(@layers_view_item)
    room.sector.load_necessary_overlay()
    @renderer.ensure_tilesets_exist("cache/#{GAME}/rooms/", room)
    room.layers.each do |layer|
      tileset_filename = "cache/#{GAME}/rooms/#{room.area_name}/Tilesets/#{layer.tileset_filename}.png"
      layer_item = LayerItem.new(layer, tileset_filename)
      layer_item.setParentItem(@layers_view_item)
    end
    
    @doors_view_item = Qt::GraphicsRectItem.new
    @dest_room_graphics_scene.addItem(@doors_view_item)
    door_dest_marker_item = DoorDestinationMarkerItem.new(@door, self)
    door_dest_marker_item.setParentItem(@doors_view_item)
  rescue StandardError => e
    Qt::MessageBox.warning(self,
      "Failed to display room",
      "Failed to display room %08X.\n#{e.message}\n\n#{e.backtrace.join("\n")}" % room.room_metadata_ram_pointer
    )
  end
  
  def update_dest_x_and_y_fields(x, y)
    @ui.dest_x.text = "%04X" % [x].pack("s").unpack("v").first
    @ui.dest_y.text = "%04X" % [y].pack("s").unpack("v").first
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
  
  def copy_door_pointer_to_clipboard
    door = @doors[@ui.door_index.currentIndex]
    
    if door
      $qApp.clipboard.setText("%08X" % door.door_ram_pointer)
    else
      $qApp.clipboard.setText("")
    end
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
  
  def inspect; to_s; end
end
