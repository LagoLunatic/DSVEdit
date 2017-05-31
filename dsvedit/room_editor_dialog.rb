
require_relative 'ui_room_editor'

class RoomEditorDialog < Qt::Dialog
  MAP_BACKGROUND_BRUSH = Qt::Brush.new(Qt::Color.new(200, 200, 200, 255))
  
  attr_reader :game
  
  slots "reposition_room_on_map(int, int, const Qt::MouseButton&)"
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
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    if SYSTEM == :nds
      @ui.color_effects.hide()
      @ui.label_5.hide()
    end
    
    read_room()
    
    self.show()
  end
  
  def read_room
    @ui.layer_list.text = "%08X" % @room.layer_list_ram_pointer
    @ui.gfx_page_list.text = "%08X" % @room.gfx_list_pointer
    @ui.palette_page_list.text = "%08X" % @room.palette_wrapper_pointer
    @ui.entity_list.text = "%08X" % @room.entity_list_ram_pointer
    @ui.door_list.text = "%08X" % @room.door_list_ram_pointer
    @ui.color_effects.text = "%04X" % @room.color_effects if SYSTEM == :gba
    
    @map_graphics_scene.clear()
    
    @map = game.get_map(@room.area_index, @room.sector_index)
    
    chunky_png_img = @renderer.render_map(@map)
    map_pixmap_item = GraphicsChunkyItem.new(chunky_png_img)
    @map_graphics_scene.addItem(map_pixmap_item)
    
    @position_indicator = @map_graphics_scene.addRect(-2, -2, 4, 4, Qt::Pen.new(Qt::NoPen), Qt::Brush.new(Qt::Color.new(255, 255, 128, 128)))
    update_room_position_indicator()
  end
  
  def update_room_position_indicator
    @position_indicator.setPos(@room.room_xpos_on_map*4 + 2.25, @room.room_ypos_on_map*4 + 2.25)
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
    
    @room.room_xpos_on_map = x
    @room.room_ypos_on_map = y
    
    update_room_position_indicator()
  end
  
  def save_room
    @room.layer_list_ram_pointer = @ui.layer_list.text.to_i(16)
    @room.gfx_list_pointer = @ui.gfx_page_list.text.to_i(16)
    @room.palette_wrapper_pointer = @ui.palette_page_list.text.to_i(16)
    @room.entity_list_ram_pointer = @ui.entity_list.text.to_i(16)
    @room.door_list_ram_pointer = @ui.door_list.text.to_i(16)
    @room.color_effects = @ui.color_effects.text.to_i(16) if SYSTEM == :gba
    
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
