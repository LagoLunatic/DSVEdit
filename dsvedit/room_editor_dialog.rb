
require_relative 'ui_room_editor'

class RoomEditorDialog < Qt::Dialog
  MAP_BACKGROUND_BRUSH = Qt::Brush.new(Qt::Color.new(200, 200, 200, 255))
  
  attr_reader :game
  
  slots "reposition_room_on_map(int, int, const Qt::MouseButton&)"
  slots "open_tileset_chooser()"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, room, renderer)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_RoomEditor.new
    @ui.setup_ui(self)
    
    @game = main_window.game
    @room = room
    @renderer = renderer
    
    @map_graphics_scene = ClickableGraphicsScene.new
    @map_graphics_scene.setSceneRect(0, 0, 64*4+1, 48*4+1)
    @ui.map_graphics_view.scale(2, 2)
    @ui.map_graphics_view.setScene(@map_graphics_scene)
    @map_graphics_scene.setBackgroundBrush(MAP_BACKGROUND_BRUSH)
    connect(@map_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("reposition_room_on_map(int, int, const Qt::MouseButton&)"))
    connect(@map_graphics_scene, SIGNAL("moved(int, int, const Qt::MouseButton&)"), self, SLOT("reposition_room_on_map(int, int, const Qt::MouseButton&)"))
    
    connect(@ui.select_tileset_button, SIGNAL("clicked()"), self, SLOT("open_tileset_chooser()"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    if GAME != "hod"
      @ui.label_12.hide()
      @ui.alternate_state_event_flag.hide()
      @ui.label_13.hide()
      @ui.alternate_state_room_pointer.hide()
      @ui.horizontalLayout_3.removeItem(@ui.horizontalSpacer_2)
      
      @ui.label_15.hide()
      @ui.palette_shift_func.hide()
      @ui.label_16.hide()
      @ui.palette_shift_index.hide()
      @ui.horizontalLayout_4.removeItem(@ui.horizontalSpacer_3)
      
      @ui.is_castle_b.hide()
      @ui.has_breakable_wall.hide()
      
      @ui.label_14.hide()
      @ui.entity_gfx_page_list.hide()
      label_item = @ui.formLayout.itemAt(5, Qt::FormLayout::LabelRole)
      @ui.formLayout.removeItem(label_item)
      field_item = @ui.formLayout.itemAt(5, Qt::FormLayout::FieldRole)
      @ui.formLayout.removeItem(field_item)
    end
    if SYSTEM == :nds
      @ui.lcd_control.hide()
      @ui.label_9.hide()
      label_item = @ui.formLayout.itemAt(4, Qt::FormLayout::LabelRole)
      @ui.formLayout.removeItem(label_item)
      field_item = @ui.formLayout.itemAt(4, Qt::FormLayout::FieldRole)
      @ui.formLayout.removeItem(field_item)
    end
    if GAME != "aos"
      @ui.color_effects.hide()
      @ui.label_5.hide()
      label_item = @ui.formLayout.itemAt(3, Qt::FormLayout::LabelRole)
      @ui.formLayout.removeItem(label_item)
      field_item = @ui.formLayout.itemAt(3, Qt::FormLayout::FieldRole)
      @ui.formLayout.removeItem(field_item)
    end
    
    if !["por", "ooe"].include?(GAME)
      @ui.palette_page_index.enabled = false
    end
    
    read_room()
    
    self.show()
  end
  
  def read_room
    @ui.layer_list.text = "%08X" % @room.layer_list_ram_pointer
    @ui.entity_list.text = "%08X" % @room.entity_list_ram_pointer
    @ui.door_list.text = "%08X" % @room.door_list_ram_pointer
    @ui.color_effects.text = "%04X" % @room.color_effects if GAME == "aos"
    @ui.lcd_control.text = "%04X" % @room.lcd_control if SYSTEM == :gba
    
    @ui.entity_gfx_page_list.text = "%08X" % @room.entity_gfx_list_pointer if GAME == "hod"
    @ui.alternate_state_event_flag.text = "%04X" % @room.state_swap_event_flag if GAME == "hod"
    @ui.alternate_state_room_pointer.text = "%08X" % @room.alternate_room_state_pointer if GAME == "hod"
    
    @ui.palette_shift_func.text = "%02X" % @room.palette_shift_func if GAME == "hod"
    @ui.palette_shift_index.text = "%02X" % @room.palette_shift_index if GAME == "hod"
    
    @ui.is_castle_b.checked = @room.is_castle_b == 0 ? false : true if GAME == "hod"
    @ui.has_breakable_wall.checked = @room.has_breakable_wall == 0 ? false : true if GAME == "hod"
    
    @ui.gfx_page_list.text = "%08X" % @room.gfx_list_pointer
    @ui.palette_page_list.text = "%08X" % @room.palette_wrapper_pointer
    @ui.palette_page_index.text = "%02X" % @room.palette_page_index
    
    @ui.map_x_pos.text = "%04X" % @room.room_xpos_on_map
    @ui.map_y_pos.text = "%04X" % @room.room_ypos_on_map
    
    @map_graphics_scene.clear()
    
    @map = game.get_map(@room.area_index, @room.sector_index)
    
    chunky_png_img = @renderer.render_map(@map)
    map_pixmap_item = GraphicsChunkyItem.new(chunky_png_img)
    @map_graphics_scene.addItem(map_pixmap_item)
    
    @position_indicator = @map_graphics_scene.addRect(-2, -2, 4, 4, Qt::Pen.new(Qt::NoPen), Qt::Brush.new(Qt::Color.new(255, 255, 128, 128)))
    update_room_position_indicator()
  end
  
  def update_room_position_indicator
    x = @ui.map_x_pos.text.to_i(16)
    y = @ui.map_y_pos.text.to_i(16)
    @position_indicator.setPos(x*4 + 2.25, y*4 + 2.25)
    if @room.layers.length > 0
      @position_indicator.setRect(-2, -2, 4*@room.main_layer_width, 4*@room.main_layer_height)
    else
      @position_indicator.setRect(-2, -2, 4, 4)
    end
  end
  
  def reposition_room_on_map(x, y, button)
    return unless (0..@map_graphics_scene.width-1-5).include?(x) && (0..@map_graphics_scene.height-1-5).include?(y)
    
    x = x / 4
    y = y / 4
    
    @ui.map_x_pos.text = "%04X" % x
    @ui.map_y_pos.text = "%04X" % y
    
    update_room_position_indicator()
  end
  
  def save_room
    @room.layer_list_ram_pointer = @ui.layer_list.text.to_i(16)
    @room.entity_list_ram_pointer = @ui.entity_list.text.to_i(16)
    @room.door_list_ram_pointer = @ui.door_list.text.to_i(16)
    @room.color_effects = @ui.color_effects.text.to_i(16) if GAME == "aos"
    @room.lcd_control = @ui.lcd_control.text.to_i(16) if SYSTEM == :gba
    
    @room.entity_gfx_list_pointer = @ui.entity_gfx_page_list.text.to_i(16) if GAME == "hod"
    @room.state_swap_event_flag = @ui.alternate_state_event_flag.text.to_i(16) if GAME == "hod"
    @room.alternate_room_state_pointer = @ui.alternate_state_room_pointer.text.to_i(16) if GAME == "hod"
    
    @room.palette_shift_func = @ui.palette_shift_func.text.to_i(16) if GAME == "hod"
    @room.palette_shift_index = @ui.palette_shift_index.text.to_i(16) if GAME == "hod"
    
    @room.is_castle_b = @ui.is_castle_b.checked ? 1 : 0 if GAME == "hod"
    @room.has_breakable_wall = @ui.has_breakable_wall.checked ? 1 : 0 if GAME == "hod"
    
    @room.gfx_list_pointer = @ui.gfx_page_list.text.to_i(16)
    @room.palette_wrapper_pointer = @ui.palette_page_list.text.to_i(16)
    if ["por", "ooe"].include?(GAME)
      @room.palette_page_index = @ui.palette_page_index.text.to_i(16)
    end
    
    @room.room_xpos_on_map = @ui.map_x_pos.text.to_i(16)
    @room.room_ypos_on_map = @ui.map_y_pos.text.to_i(16)
    
    @room.write_to_rom()
    
    @game.fix_map_sector_and_room_indexes(@room.area_index, @room.sector_index)
    
    read_room()
    parent.load_room_and_states()
  end
  
  def open_tileset_chooser
    @tileset_chooser = TilesetChooserDialog.new(self, @game, @room.sector, @renderer)
  end
  
  def set_tileset(tileset_name)
    tileset_name =~ /^(\h{8})-(\h{8})_(\h{8})-(\h{2})_(\h{8})$/
    
    @ui.gfx_page_list.text = $5
    @ui.palette_page_list.text = $3
    @ui.palette_page_index.text = $4
    
    tileset_pointer = $1.to_i(16)
    collision_tileset_pointer = $2.to_i(16)
    @room.layers.each do |layer|
      if layer.layer_metadata_ram_pointer == 0
        # No need to set the tileset pointers for empty layers. That'll just wastefully allocate free space for the empty tiles.
        next
      end
      
      layer.tileset_pointer = tileset_pointer
      layer.collision_tileset_pointer = collision_tileset_pointer
      layer.write_to_rom()
    end
    
    save_room()
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_room()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_room()
    end
  end
  
  def closeEvent(event)
    if @tileset_chooser
      @tileset_chooser.close()
    end
  end
end
