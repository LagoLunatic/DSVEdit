
require_relative 'ui_tileset_editor'

class TilesetEditorDialog < Qt::Dialog
  BACKGROUND_BRUSH = Qt::Brush.new(Qt::Color.new(200, 200, 200, 255))
  RED_PEN_COLOR = Qt::Pen.new(Qt::Color.new(255, 0, 0))
  
  slots "select_tile_by_x_y(int, int, const Qt::MouseButton&)"
  slots "select_tile_index_on_gfx_page(int, int, const Qt::MouseButton&)"
  slots "gfx_page_changed(int)"
  slots "palette_changed(int)"
  slots "toggle_flips(bool)"
  slots "update_collision(bool)"
  slots "block_shape_changed(int)"
  slots "load_tileset()"
  slots "toggle_display_collision(bool)"
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
    @selected_tile_collision_graphics_scene = Qt::GraphicsScene.new
    @ui.selected_tile_collision_graphics_view.scale(3, 3)
    @ui.selected_tile_collision_graphics_view.setScene(@selected_tile_collision_graphics_scene)
    @selected_tile_collision_graphics_scene.setBackgroundBrush(BACKGROUND_BRUSH)
    
    [
      "Full block",
      "???",
      "Top half",
      "Bottom half",
      "Slope",
      "???",
      "???",
      "???",
      "1/2 slope",
      "???",
      "2/2 slope",
      "???",
      "1/4 slope",
      "2/4 slope",
      "3/4 slope",
      "4/4 slope",
    ].each_with_index do |block_shape, i|
      @ui.block_shape.addItem("%02X %s" % [i, block_shape])
    end
    
    connect(@ui.gfx_page_index, SIGNAL("activated(int)"), self, SLOT("gfx_page_changed(int)"))
    connect(@ui.palette_index, SIGNAL("activated(int)"), self, SLOT("palette_changed(int)"))
    connect(@ui.horizontal_flip, SIGNAL("clicked(bool)"), self, SLOT("toggle_flips(bool)"))
    connect(@ui.vertical_flip, SIGNAL("clicked(bool)"), self, SLOT("toggle_flips(bool)"))
    connect(@ui.reload_button, SIGNAL("released()"), self, SLOT("load_tileset()"))
    connect(@ui.display_collision, SIGNAL("clicked(bool)"), self, SLOT("toggle_display_collision(bool)"))
    
    connect(@ui.has_top, SIGNAL("clicked(bool)"), self, SLOT("update_collision(bool)"))
    connect(@ui.is_water, SIGNAL("clicked(bool)"), self, SLOT("update_collision(bool)"))
    connect(@ui.has_sides_and_bottom, SIGNAL("clicked(bool)"), self, SLOT("update_collision(bool)"))
    connect(@ui.has_effect, SIGNAL("clicked(bool)"), self, SLOT("update_collision(bool)"))
    connect(@ui.coll_vertical_flip, SIGNAL("clicked(bool)"), self, SLOT("update_collision(bool)"))
    connect(@ui.coll_horizontal_flip, SIGNAL("clicked(bool)"), self, SLOT("update_collision(bool)"))
    connect(@ui.block_shape, SIGNAL("activated(int)"), self, SLOT("block_shape_changed(int)"))
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    @collision_mode = false
    
    self.show()
    
    @room = room
    
    if room.palette_pages.empty?
      Qt::MessageBox.warning(self, "No palette", "The current room has no palette pages.")
      return
    end
    
    if SYSTEM == :nds
      @tile_width = @tile_height = 16
      @tiles_per_row = 16
      @tiles_per_gfx_page_row = 8
    else
      @tile_width = @tile_height = 8
      @tiles_per_row = 16*4
      @tiles_per_gfx_page_row = 16
    end
    
    layer = room.layers.first
    if layer
      @ui.tileset_pointer.text = "%08X" % layer.tileset_pointer
      @ui.collision_tileset_pointer.text = "%08X" % layer.collision_tileset_pointer
      @ui.tileset_type.text = "%04X" % layer.tileset_type
    end
    @ui.gfx_list_pointer.text = "%08X" % room.gfx_list_pointer
    @ui.palette_list_pointer.text = "%08X" % room.palette_pages.first.palette_list_pointer
    load_tileset()
  end
  
  def load_tileset
    @tileset_graphics_scene.clear()
    
    @tileset_pointer = @ui.tileset_pointer.text.to_i(16)
    @tileset_type = @ui.tileset_type.text.to_i(16)
    @gfx_list_pointer = @ui.gfx_list_pointer.text.to_i(16)
    @palette_list_pointer = @ui.palette_list_pointer.text.to_i(16)
    @collision_tileset_pointer = @ui.collision_tileset_pointer.text.to_i(16)
    
    return if @tileset_pointer == 0 || @gfx_list_pointer == 0 || @palette_list_pointer == 0
    
    @tileset = Tileset.new(@tileset_pointer, @tileset_type, @fs)
    @collision_tileset = CollisionTileset.new(@collision_tileset_pointer, @fs)
    
    if SYSTEM == :nds
      @tiles = @tileset.tiles
      @collision_tiles = @collision_tileset.tiles
    else
      @tiles = []
      @tileset.tiles.each_slice(16) do |row_of_tiles|
        row_of_tiles.each do |tile|
          @tiles += tile.minitiles[0,4]
        end
        row_of_tiles.each do |tile|
          @tiles += tile.minitiles[4,4]
        end
        row_of_tiles.each do |tile|
          @tiles += tile.minitiles[8,4]
        end
        row_of_tiles.each do |tile|
          @tiles += tile.minitiles[12,4]
        end
      end
      @collision_tiles = @collision_tileset.tiles
    end
    
    @gfx_pages = GfxWrapper.from_gfx_list_pointer(@gfx_list_pointer, @fs)
    
    if SYSTEM == :nds
      @palettes = @renderer.generate_palettes(@palette_list_pointer, 16)
      if @gfx_pages.any?{|gfx| gfx.colors_per_palette == 256}
        @palettes_256 = @renderer.generate_palettes(@palette_list_pointer, 256)
      end
    else
      @palettes = []
      @room.palette_pages.each do |palette_page|
        pals_for_page = @renderer.generate_palettes(palette_page.palette_list_pointer, 16)
        
        @palettes[palette_page.palette_load_offset, palette_page.num_palettes] = pals_for_page[palette_page.palette_index, palette_page.num_palettes]
      end
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
    @tiles.each_with_index do |tile, index_on_tileset|
      if index_on_tileset == 0
        @tileset_pixmap_items << nil
        next
      end
      
      tile_pixmap_item = Qt::GraphicsPixmapItem.new
      @tileset_pixmap_items << tile_pixmap_item
      
      render_tile_on_tileset(index_on_tileset)
      
      x_on_tileset = index_on_tileset % @tiles_per_row
      y_on_tileset = index_on_tileset / @tiles_per_row
      tile_pixmap_item.setPos(x_on_tileset*@tile_width + @tile_width/2, y_on_tileset*@tile_height + @tile_height/2)
      
      @tileset_graphics_scene.addItem(tile_pixmap_item)
    end
  end
  
  def render_tile_on_tileset(tile_index)
    tile = @tiles[tile_index]
    
    if tile.is_blank
      return
    end
    
    tile_pixmap_item = @tileset_pixmap_items[tile_index]
    if tile_pixmap_item.nil?
      return
    end
    
    if @collision_mode
      coll_tile = @collision_tiles[tile_index]
      chunky_coll_tile = @renderer.render_collision_tile(coll_tile)
      
      pixmap = Qt::Pixmap.new
      blob = chunky_coll_tile.to_blob
      pixmap.loadFromData(blob, blob.length)
      tile_pixmap_item.pixmap = pixmap
      
      tile_pixmap_item.setOffset(-@tile_width/2, -@tile_height/2)
    else
      render_tile(tile, tile_pixmap_item)
    end
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
    
    if SYSTEM == :nds
      chunky_tile = @renderer.render_graphic_tile(gfx.file, palette, tile.index_on_tile_page)
    else
      chunky_tile = @renderer.render_1_dimensional_minitile(gfx, palette, tile.index_on_tile_page)
    end
    
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
    tile_pixmap_item.setOffset(-@tile_width/2, -@tile_height/2)
    tile_pixmap_item.setTransform(Qt::Transform::fromScale(xscale, yscale))
  end
  
  def load_selected_tile
    @selected_tile_graphics_scene.clear()
    @selected_tile_collision_graphics_scene.clear()
    
    @ui.horizontal_flip.checked = @selected_tile.horizontal_flip
    @ui.vertical_flip.checked = @selected_tile.vertical_flip
    
    selected_tile_pixmap_item = Qt::GraphicsPixmapItem.new
    render_tile(@selected_tile, selected_tile_pixmap_item)
    @selected_tile_graphics_scene.addItem(selected_tile_pixmap_item)
    
    tile_x_pos_on_page = @selected_tile.index_on_tile_page % @tiles_per_gfx_page_row
    tile_y_pos_on_page = @selected_tile.index_on_tile_page / @tiles_per_gfx_page_row
    
    @gfx_page_graphics_scene.removeItem(@gfx_selection_rectangle) if @gfx_selection_rectangle
    @gfx_selection_rectangle = Qt::GraphicsRectItem.new
    @gfx_selection_rectangle.setPen(RED_PEN_COLOR)
    @gfx_selection_rectangle.setRect(0, 0, @tile_width, @tile_height)
    @gfx_selection_rectangle.setPos(tile_x_pos_on_page*@tile_width, tile_y_pos_on_page*@tile_height)
    @gfx_page_graphics_scene.addItem(@gfx_selection_rectangle)
    
    @tileset_graphics_scene.removeItem(@selected_tile_selection_rectangle) if @selected_tile_selection_rectangle
    @selected_tile_selection_rectangle = Qt::GraphicsRectItem.new
    @selected_tile_selection_rectangle.setPen(RED_PEN_COLOR)
    @selected_tile_selection_rectangle.setRect(0, 0, @tile_width, @tile_height)
    tile_x_pos_on_tileset = @selected_tile_index % @tiles_per_row
    tile_y_pos_on_tileset = @selected_tile_index / @tiles_per_row
    @selected_tile_selection_rectangle.setPos(tile_x_pos_on_tileset*@tile_width, tile_y_pos_on_tileset*@tile_height)
    @tileset_graphics_scene.addItem(@selected_tile_selection_rectangle)
    
    return if SYSTEM == :gba
    
    @ui.has_top.checked = @selected_collision_tile.has_top
    @ui.is_water.checked = @selected_collision_tile.is_water
    if @selected_collision_tile.block_shape >= 4
      @ui.has_sides_and_bottom.enabled = @ui.has_sides_and_bottom.checked = false
      @ui.has_effect.enabled = @ui.has_effect.checked = false
      @ui.coll_vertical_flip.enabled = true
      @ui.coll_horizontal_flip.enabled = true
      @ui.coll_vertical_flip.checked = @selected_collision_tile.vertical_flip
      @ui.coll_horizontal_flip.checked = @selected_collision_tile.horizontal_flip
    else
      @ui.has_sides_and_bottom.enabled = true
      @ui.has_effect.enabled = true
      @ui.coll_vertical_flip.enabled = @ui.coll_vertical_flip.checked = false
      @ui.coll_horizontal_flip.enabled = @ui.coll_horizontal_flip.checked = false
      @ui.has_sides_and_bottom.checked = @selected_collision_tile.has_sides_and_bottom
      @ui.has_effect.checked = @selected_collision_tile.has_effect
    end
    @ui.block_shape.setCurrentIndex(@selected_collision_tile.block_shape)
    
    chunky_coll_tile = @renderer.render_collision_tile(@selected_collision_tile)
    selected_tile_coll_pixmap_item = Qt::GraphicsPixmapItem.new
    pixmap = Qt::Pixmap.new
    blob = chunky_coll_tile.to_blob
    pixmap.loadFromData(blob, blob.length)
    selected_tile_coll_pixmap_item.pixmap = pixmap
    @selected_tile_collision_graphics_scene.addItem(selected_tile_coll_pixmap_item)
  end
  
  def gfx_page_changed(gfx_page_index)
    @selected_tile.tile_page = gfx_page_index
    
    @gfx_page_graphics_scene.clear()
    
    gfx = @gfx_pages[@selected_tile.tile_page]
    
    if gfx.nil?
      @ui.gfx_file.text = "Invalid (gfx page index %02X)" % gfx_page_index
      return
    end
    
    if gfx.colors_per_palette == 16
      palette = @palettes[@selected_tile.palette_index]
    else
      palette = @palettes_256[@selected_tile.palette_index]
    end
    
    if SYSTEM == :nds
      @ui.gfx_file.text = gfx.file[:file_path]
      chunky_image = @renderer.render_gfx_page(gfx.file, palette)
    else
      @ui.gfx_file.text = ""
      chunky_image = @renderer.render_gfx_1_dimensional_mode(gfx, palette)
    end
    
    pixmap = Qt::Pixmap.new()
    blob = chunky_image.to_blob
    pixmap.loadFromData(blob, blob.length)
    gfx_page_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
    @gfx_page_graphics_scene.addItem(gfx_page_pixmap_item)
    
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
    return unless (0..@tile_width*@tiles_per_row-1).include?(x) && (0..1023).include?(y)
    return unless button == Qt::LeftButton
    
    i = x/@tile_width + y/@tile_width*@tiles_per_row
    
    select_tile(i)
  end
  
  def select_tile(tile_index)
    old_selected_tile = @selected_tile
    
    @selected_tile_index = tile_index
    @selected_tile = @tiles[tile_index]
    @selected_collision_tile = @collision_tiles[tile_index]
    
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
    
    i = x/@tile_width + y/@tile_width*@tiles_per_gfx_page_row
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
  
  def update_collision(checked)
    return if SYSTEM == :gba
    
    @selected_collision_tile.has_top = @ui.has_top.checked
    @selected_collision_tile.is_water = @ui.is_water.checked
    @selected_collision_tile.has_sides_and_bottom = @ui.has_sides_and_bottom.checked
    @selected_collision_tile.has_effect = @ui.has_effect.checked
    @selected_collision_tile.vertical_flip = @ui.coll_vertical_flip.checked
    @selected_collision_tile.horizontal_flip = @ui.coll_horizontal_flip.checked
    
    load_selected_tile()
    render_tile_on_tileset(@selected_tile_index)
  end
  
  def block_shape_changed(block_shape)
    return if SYSTEM == :gba
    
    @selected_collision_tile.block_shape = block_shape
    
    load_selected_tile()
    render_tile_on_tileset(@selected_tile_index)
  end
  
  def toggle_display_collision(checked)
    @collision_mode = checked
    render_tileset()
  end
  
  def save_tileset
    @tileset.write_to_rom()
    @collision_tileset.write_to_rom() unless SYSTEM == :gba
    
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
  
  def inspect; to_s; end
end
