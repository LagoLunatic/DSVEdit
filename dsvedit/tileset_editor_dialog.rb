
require_relative 'ui_tileset_editor'

class TilesetEditorDialog < Qt::Dialog
  BACKGROUND_BRUSH = Qt::Brush.new(Qt::Color.new(200, 200, 200, 255))
  RED_PEN_COLOR = Qt::Pen.new(Qt::Color.new(255, 0, 0))
  
  slots "select_tile_by_x_y(int, int, const Qt::MouseButton&)"
  slots "select_tile_index_on_gfx_page(int, int, const Qt::MouseButton&)"
  slots "gfx_page_changed(int)"
  slots "palette_changed(int)"
  slots "toggle_flips(int)"
  slots "load_tileset()"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, fs, renderer, room)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_TilesetEditor.new
    @ui.setup_ui(self)
    
    @fs = fs
    @renderer = renderer
    
    @tileset_graphics_scene = ClickableGraphicsScene.new
    @ui.tileset_graphics_view.setScene(@tileset_graphics_scene)
    @tileset_graphics_scene.setBackgroundBrush(BACKGROUND_BRUSH)
    connect(@tileset_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("select_tile_by_x_y(int, int, const Qt::MouseButton&)"))
    connect(@tileset_graphics_scene, SIGNAL("moved(int, int, const Qt::MouseButton&)"), self, SLOT("select_tile_by_x_y(int, int, const Qt::MouseButton&)"))
    
    @gfx_page_graphics_scene = ClickableGraphicsScene.new
    @ui.gfx_page_graphics_view.scale(3, 3)
    @ui.gfx_page_graphics_view.setScene(@gfx_page_graphics_scene)
    @gfx_page_graphics_scene.setBackgroundBrush(BACKGROUND_BRUSH)
    connect(@gfx_page_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("select_tile_index_on_gfx_page(int, int, const Qt::MouseButton&)"))
    connect(@gfx_page_graphics_scene, SIGNAL("moved(int, int, const Qt::MouseButton&)"), self, SLOT("select_tile_index_on_gfx_page(int, int, const Qt::MouseButton&)"))
    
    @selected_tile_graphics_scene = Qt::GraphicsScene.new
    @ui.selected_tile_graphics_view.scale(3, 3)
    @ui.selected_tile_graphics_view.setScene(@selected_tile_graphics_scene)
    @selected_tile_graphics_scene.setBackgroundBrush(BACKGROUND_BRUSH)
    
    connect(@ui.gfx_page_index, SIGNAL("activated(int)"), self, SLOT("gfx_page_changed(int)"))
    connect(@ui.palette_index, SIGNAL("activated(int)"), self, SLOT("palette_changed(int)"))
    connect(@ui.horizontal_flip, SIGNAL("stateChanged(int)"), self, SLOT("toggle_flips(int)"))
    connect(@ui.vertical_flip, SIGNAL("stateChanged(int)"), self, SLOT("toggle_flips(int)"))
    connect(@ui.reload_button, SIGNAL("released()"), self, SLOT("load_tileset()"))
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    self.show()
    
    @room = room
    
    if room.palette_pages.empty?
      Qt::MessageBox.warning(self, "No palette", "The current room has no palette pages.")
      return
    end
    
    layer = room.layers.first
    if layer
      @ui.tileset_pointer.text = "%08X" % layer.tileset_pointer
    end
    @ui.gfx_list_pointer.text = "%08X" % room.gfx_list_pointer
    @ui.palette_list_pointer.text = "%08X" % room.palette_pages.first.palette_list_pointer
    load_tileset()
  end
  
  def load_tileset
    @tileset_graphics_scene.clear()
    
    @tileset_pointer = @ui.tileset_pointer.text.to_i(16)
    @gfx_list_pointer = @ui.gfx_list_pointer.text.to_i(16)
    @palette_list_pointer = @ui.palette_list_pointer.text.to_i(16)
    
    return if @tileset_pointer == 0 || @gfx_list_pointer == 0 || @palette_list_pointer == 0
    
    @tileset = Tileset.new(@tileset_pointer, @fs)
    
    @gfx_pages = GfxWrapper.from_gfx_list_pointer(@gfx_list_pointer, @fs)
    
    @palettes = @renderer.generate_palettes(@palette_list_pointer, 16)
    if @gfx_pages.any?{|gfx| gfx.colors_per_palette == 256}
      @palettes_256 = @renderer.generate_palettes(@palette_list_pointer, 256)
    end
    
    @ui.gfx_page_index.clear()
    @gfx_pages.each_with_index do |gfx_page, i|
      if gfx_page.colors_per_palette == 16
        @ui.gfx_page_index.addItem("%02X" % i)
      else
        @ui.gfx_page_index.addItem("%02X (256 colors)" % i)
      end
    end
    @ui.gfx_page_index.setCurrentIndex(0)
    
    @ui.palette_index.clear()
    @palettes.each_with_index do |palette, i|
      @ui.palette_index.addItem("%02X" % i)
    end
    
    render_tileset()
    
    select_tile(0)
    
    palette_changed(0)
  end
  
  def render_tileset
    @tileset_graphics_scene.clear()
    
    @tileset_pixmap_items = []
    @tileset.tiles.each_with_index do |tile, index_on_tileset|
      if index_on_tileset == 0
        @tileset_pixmap_items << nil
        next
      end
      
      tile_pixmap_item = Qt::GraphicsPixmapItem.new
      @tileset_pixmap_items << tile_pixmap_item
      
      render_tile_on_tileset(index_on_tileset)
      
      x_on_tileset = index_on_tileset % 16
      y_on_tileset = index_on_tileset / 16
      tile_pixmap_item.setPos(x_on_tileset*16 + 8, y_on_tileset*16 + 8)
      
      @tileset_graphics_scene.addItem(tile_pixmap_item)
    end
  end
  
  def render_tile_on_tileset(tile_index)
    tile = @tileset.tiles[tile_index]
    
    if tile.is_blank
      return
    end
    
    tile_pixmap_item = @tileset_pixmap_items[tile_index]
    if tile_pixmap_item.nil?
      return
    end
    
    render_tile(tile, tile_pixmap_item)
  end
  
  def render_tile(tile, tile_pixmap_item)
    gfx = @gfx_pages[tile.tile_page]
    if gfx.nil?
      return # TODO: figure out why this sometimes happens.
    end
    
    if tile.palette_index == 0xFF # TODO. 255 seems to have some special meaning besides an actual palette index.
      puts "Palette index is 0xFF, tileset %08X" % @tileset_pointer
      return
    end
    
    if gfx.colors_per_palette == 16
      palette = @palettes[tile.palette_index]
    else
      palette = @palettes_256[tile.palette_index]
    end
    if palette.nil?
      puts "Palette index #{tile.palette_index} out of range, tileset %08X" % @tileset_pointer
      return # TODO: figure out why this sometimes happens.
    end
    
    chunky_tile = @renderer.render_graphic_tile(gfx.file, palette, tile.index_on_tile_page)
    
    pixmap = Qt::Pixmap.new
    blob = chunky_tile.to_blob
    pixmap.loadFromData(blob, blob.length)
    tile_pixmap_item.pixmap = pixmap
    
    xscale = 1
    yscale = 1
    if tile.horizontal_flip
      xscale = -1
    end
    if tile.vertical_flip
      yscale = -1
    end
    tile_pixmap_item.setOffset(-8, -8)
    tile_pixmap_item.setTransform(Qt::Transform::fromScale(xscale, yscale))
  end
  
  def load_selected_tile
    @selected_tile_graphics_scene.clear()
    
    @ui.horizontal_flip.checked = @selected_tile.horizontal_flip
    @ui.vertical_flip.checked = @selected_tile.vertical_flip
    
    selected_tile_pixmap_item = Qt::GraphicsPixmapItem.new
    render_tile(@selected_tile, selected_tile_pixmap_item)
    @selected_tile_graphics_scene.addItem(selected_tile_pixmap_item)
    
    tile_x_pos_on_page = @selected_tile.index_on_tile_page % 8
    tile_y_pos_on_page = @selected_tile.index_on_tile_page / 8
    
    @gfx_page_graphics_scene.removeItem(@selection_rectangle) if @selection_rectangle
    @selection_rectangle = Qt::GraphicsRectItem.new
    @selection_rectangle.setPen(RED_PEN_COLOR)
    @selection_rectangle.setRect(0, 0, 16, 16)
    @selection_rectangle.setPos(tile_x_pos_on_page*16, tile_y_pos_on_page*16)
    @gfx_page_graphics_scene.addItem(@selection_rectangle)
  end
  
  def gfx_page_changed(gfx_page_index)
    @selected_tile.tile_page = gfx_page_index
    
    @gfx_page_graphics_scene.clear()
    
    gfx = @gfx_pages[@selected_tile.tile_page]
    @ui.gfx_file.text = gfx.file[:file_path]
    if gfx.colors_per_palette == 16
      palette = @palettes[@selected_tile.palette_index]
    else
      palette = @palettes_256[@selected_tile.palette_index]
    end
    
    chunky_image = @renderer.render_gfx_page(gfx.file, palette)
    
    pixmap = Qt::Pixmap.new()
    blob = chunky_image.to_blob
    pixmap.loadFromData(blob, blob.length)
    gfx_page_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
    @gfx_page_graphics_scene.addItem(gfx_page_pixmap_item)
    
    @selection_rectangle = Qt::GraphicsRectItem.new
    @selection_rectangle.setPen(RED_PEN_COLOR)
    @selection_rectangle.setRect(0, 0, 16, 16)
    @gfx_page_graphics_scene.addItem(@selection_rectangle)
    
    load_selected_tile()
    render_tile_on_tileset(@selected_tile_index)
  end
  
  def palette_changed(palette_index)
    @selected_tile.palette_index = palette_index
    gfx_page_changed(@selected_tile.tile_page || 0)
    load_selected_tile()
    render_tile_on_tileset(@selected_tile_index)
  end
  
  def select_tile_by_x_y(x, y, button)
    return unless (0..255).include?(x) && (0..1023).include?(y)
    return unless button == Qt::LeftButton
    
    i = x/16 + y/16*16
    
    select_tile(i)
  end
  
  def select_tile(tile_index)
    old_selected_tile = @selected_tile
    
    @selected_tile_index = tile_index
    @selected_tile = @tileset.tiles[tile_index]
    
    @ui.gfx_page_index.setCurrentIndex(@selected_tile.tile_page)
    @ui.palette_index.setCurrentIndex(@selected_tile.palette_index)
    
    if old_selected_tile.nil? || old_selected_tile.tile_page != @selected_tile.tile_page || old_selected_tile.palette_index != @selected_tile.palette_index
      gfx_page_changed(@selected_tile.tile_page)
      palette_changed(@selected_tile.palette_index)
    end
    
    load_selected_tile()
  end
  
  def select_tile_index_on_gfx_page(x, y, button)
    return unless (0..127).include?(x) && (0..127).include?(y)
    
    i = x/16 + y/16*8
    @selected_tile.index_on_tile_page = i
    
    load_selected_tile()
    render_tile_on_tileset(@selected_tile_index)
  end
  
  def toggle_flips(checked)
    @selected_tile.horizontal_flip = @ui.horizontal_flip.checked
    @selected_tile.vertical_flip = @ui.vertical_flip.checked
    load_selected_tile()
    render_tile_on_tileset(@selected_tile_index)
  end
  
  def save_tileset
    @tileset.write_to_rom()
    
    # Clear the tileset cache so the changes show up in the editor.
    parent.clear_cache()
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_tileset()
      parent.load_room()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_tileset()
      parent.load_room()
    end
  end
end
