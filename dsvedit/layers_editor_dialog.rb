
require_relative 'ui_layers_editor'

class LayersEditorDialog < Qt::Dialog
  attr_reader :game
  
  slots "layer_changed(int)"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, room, renderer)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_LayersEditor.new
    @ui.setup_ui(self)
    
    @game = main_window.game
    @room = room
    @renderer = renderer
    
    @layer_graphics_scene = Qt::GraphicsScene.new
    @ui.layer_graphics_view.setScene(@layer_graphics_scene)
    @ui.layer_graphics_view.setDragMode(Qt::GraphicsView::ScrollHandDrag)
    self.setStyleSheet("QGraphicsView { background-color: transparent; }");
    
    @room.layers.each_with_index do |layer, i|
      @ui.layer_index.addItem("%02X %08X" % [i, layer.layer_list_entry_ram_pointer])
    end
    
    connect(@ui.layer_index, SIGNAL("activated(int)"), self, SLOT("layer_changed(int)"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    layer_changed(0)
    
    self.show()
  end
  
  def layer_changed(layer_index)
    layer = @room.layers[layer_index]
    
    return if layer.nil?
    
    @ui.width.text = "%02X" % layer.width
    @ui.height.text = "%02X" % layer.height
    
    @layer_graphics_scene.clear()
    @layer_graphics_scene = Qt::GraphicsScene.new
    @ui.layer_graphics_view.setScene(@layer_graphics_scene)
    @layers_view_item = Qt::GraphicsRectItem.new
    @layer_graphics_scene.addItem(@layers_view_item)
    @room.sector.load_necessary_overlay()
    @renderer.ensure_tilesets_exist("cache/#{GAME}/rooms/", @room)
    tileset_filename = "cache/#{GAME}/rooms/#{@room.area_name}/Tilesets/#{layer.tileset_filename}.png"
    layer_item = LayerItem.new(layer, tileset_filename)
    layer_item.setParentItem(@layers_view_item)
  end
  
  def save_layer
    layer = @room.layers[@ui.layer_index.currentIndex]
    layer.width = @ui.width.text.to_i(16)
    layer.height = @ui.height.text.to_i(16)
    layer.write_to_rom()
    
    layer_changed(@ui.layer_index.currentIndex)
  rescue NDSFileSystem::FileExpandError => e
    @room.layers[@ui.layer_index.currentIndex].read_from_rom() # Reload layer
    Qt::MessageBox.warning(self, "Cannot expand layer", e.message)
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_layer()
      parent.load_room()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_layer()
      parent.load_room()
    end
  end
end
