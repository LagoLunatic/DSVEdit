
require_relative 'ui_layers_editor'

class LayersEditorDialog < Qt::Dialog
  attr_reader :game
  
  slots "layer_changed(int)"
  slots "copy_layer_pointer_to_clipboard()"
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
    connect(@ui.copy_layer_pointer, SIGNAL("released()"), self, SLOT("copy_layer_pointer_to_clipboard()"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    if SYSTEM == :nds
      @ui.bg_control.hide()
      @ui.label_11.hide()
    end
    if SYSTEM == :gba
      @ui.opacity.hide()
      @ui.label_5.hide()
      @ui.gridLayout.addWidget(@ui.bg_control, 2, 3)
      @ui.gridLayout.addWidget(@ui.label_11, 2, 2)
    end
    if GAME == "hod"
      @ui.scroll_mode.hide()
      @ui.label_10.hide()
      @ui.gridLayout.addWidget(@ui.visual_effect, 2, 1)
      @ui.gridLayout.addWidget(@ui.label_12, 2, 0)
      @ui.label_6.hide()
      @ui.main_gfx_page_index.hide()
    else
      @ui.visual_effect.hide()
      @ui.label_12.hide()
    end
    
    layer_changed(0)
    
    self.show()
  end
  
  def layer_changed(layer_index)
    layer = @room.layers[layer_index]
    
    return if layer.nil?
    
    @ui.width.text = "%02X" % layer.width
    @ui.height.text = "%02X" % layer.height
    @ui.z_index.text = "%02X" % layer.z_index
    @ui.scroll_mode.text = "%02X" % layer.scroll_mode
    @ui.bg_control.text = "%04X" % layer.bg_control if SYSTEM == :gba
    @ui.visual_effect.text = "%02X" % layer.visual_effect if GAME == "hod"
    @ui.opacity.value = layer.opacity
    @ui.tileset_type.text = "%04X" % layer.tileset_type
    @ui.tileset.text = "%08X" % layer.tileset_pointer
    @ui.collision_tileset.text = "%08X" % layer.collision_tileset_pointer
    
    unless GAME == "hod"
      @ui.main_gfx_page_index.clear()
      @room.gfx_pages.each_with_index do |gfx_page, index|
        @ui.main_gfx_page_index.addItem("%02X (%d colors)" % [index, gfx_page.colors_per_palette])
      end
      @ui.main_gfx_page_index.setCurrentIndex(layer.main_gfx_page_index)
    end
    
    display_layer(layer)
  end
  
  def display_layer(layer)
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
  rescue StandardError => e
    Qt::MessageBox.warning(self,
      "Failed to display layer",
      "Failed to display layer %08X.\n#{e.message}\n\n#{e.backtrace.join("\n")}" % layer.layer_list_entry_ram_pointer
    )
  end
  
  def save_layer
    layer = @room.layers[@ui.layer_index.currentIndex]
    
    return if layer.nil?
    
    layer.width = @ui.width.text.to_i(16)
    layer.height = @ui.height.text.to_i(16)
    layer.z_index = @ui.z_index.text.to_i(16)
    layer.scroll_mode = @ui.scroll_mode.text.to_i(16)
    layer.bg_control = @ui.bg_control.text.to_i(16) if SYSTEM == :gba
    layer.visual_effect = @ui.visual_effect.text.to_i(16) if GAME == "hod"
    layer.opacity = @ui.opacity.value if SYSTEM == :nds
    layer.tileset_type = @ui.tileset_type.text.to_i(16)
    layer.tileset_pointer = @ui.tileset.text.to_i(16)
    layer.collision_tileset_pointer = @ui.collision_tileset.text.to_i(16)
    layer.main_gfx_page_index = @ui.main_gfx_page_index.currentIndex unless GAME == "hod"
    
    layer.write_to_rom()
    
    @game.fix_map_sector_and_room_indexes(@room.area_index, @room.sector_index)
    
    layer_changed(@ui.layer_index.currentIndex)
  rescue FreeSpaceManager::FreeSpaceFindError => e
    @room.layers[@ui.layer_index.currentIndex].read_from_rom() # Reload layer
    Qt::MessageBox.warning(self,
      "Failed to find free space",
      "Failed to find free space to put the expanded layer.\n\n#{NO_FREE_SPACE_MESSAGE}"
    )
  end
  
  def copy_layer_pointer_to_clipboard
    layer = @room.layers[@ui.layer_index.currentIndex]
    
    if layer
      $qApp.clipboard.setText("%08X" % layer.layer_list_entry_ram_pointer)
    else
      $qApp.clipboard.setText("")
    end
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
