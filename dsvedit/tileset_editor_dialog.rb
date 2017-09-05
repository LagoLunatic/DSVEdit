
require_relative 'ui_tileset_editor'

class TilesetEditorDialog < Qt::Dialog
  BACKGROUND_BRUSH = Qt::Brush.new(Qt::Color.new(200, 200, 200, 255))
  RED_PEN_COLOR = Qt::Pen.new(Qt::Color.new(255, 0, 0))
  
  slots "mouse_clicked_on_tileset(int, int, const Qt::MouseButton&)"
  slots "mouse_moved_on_tileset(int, int, const Qt::MouseButton&)"
  slots "mouse_released_on_tileset(int, int, const Qt::MouseButton&)"
  slots "mouse_clicked_on_gfx_page(int, int, const Qt::MouseButton&)"
  slots "mouse_moved_on_gfx_page(int, int, const Qt::MouseButton&)"
  slots "mouse_released_on_gfx_page(int, int, const Qt::MouseButton&)"
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
    @ui.tileset_graphics_view.setMouseTracking(true) # Detect mouse move even when not clicking
    @tileset_graphics_scene.setBackgroundBrush(BACKGROUND_BRUSH)
    connect(@tileset_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("mouse_clicked_on_tileset(int, int, const Qt::MouseButton&)"))
    connect(@tileset_graphics_scene, SIGNAL("moved(int, int, const Qt::MouseButton&)"), self, SLOT("mouse_moved_on_tileset(int, int, const Qt::MouseButton&)"))
    connect(@tileset_graphics_scene, SIGNAL("released(int, int, const Qt::MouseButton&)"), self, SLOT("mouse_released_on_tileset(int, int, const Qt::MouseButton&)"))
    
    @gfx_page_graphics_scene = ClickableGraphicsScene.new
    @ui.gfx_page_graphics_view.scale(2, 2)
    @ui.gfx_page_graphics_view.setScene(@gfx_page_graphics_scene)
    @gfx_page_graphics_scene.setBackgroundBrush(BACKGROUND_BRUSH)
    connect(@gfx_page_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("mouse_clicked_on_gfx_page(int, int, const Qt::MouseButton&)"))
    connect(@gfx_page_graphics_scene, SIGNAL("moved(int, int, const Qt::MouseButton&)"), self, SLOT("mouse_moved_on_gfx_page(int, int, const Qt::MouseButton&)"))
    connect(@gfx_page_graphics_scene, SIGNAL("released(int, int, const Qt::MouseButton&)"), self, SLOT("mouse_released_on_gfx_page(int, int, const Qt::MouseButton&)"))
    
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
    @ui.edit_collision_group.hide()
    
    @selected_tile = nil
    @selected_tiles = []
    @selection_x = 0
    @selection_y = 0
    @selection_width = 0
    @selection_height = 0
    
    self.show()
    
    @room = room
    
    if room.palette_pages.empty?
      Qt::MessageBox.warning(self, "No palette", "The current room has no palette pages.")
      return
    end
    
    if SYSTEM == :nds
      @tile_width = @tile_height = 16
      @tileset_width = 16
      @tileset_height = 64
      @tiles_per_gfx_page_row = 8
    else
      @tile_width = @tile_height = 8
      @tileset_width = 16*4
      @tileset_height = 64
      @tiles_per_gfx_page_row = 16
    end
    @tileset_graphics_scene.setSceneRect(0, 0, @tileset_width*@tile_width, @tileset_height*@tile_height)
    
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
    
    begin
      @tileset = Tileset.new(@tileset_pointer, @tileset_type, @fs)
    rescue GBALZ77::DecompressionError => e
      Qt::MessageBox.warning(self,
        "Decompression error",
        "The tileset data doesn't appear to be compressed.\nThe Tileset Type may be incorrect."
      )
    end
    begin
      @collision_tileset = CollisionTileset.new(@collision_tileset_pointer, @fs)
    rescue GBALZ77::DecompressionError => e
      Qt::MessageBox.warning(self,
        "Decompression error",
        "The collision tileset data doesn't appear to be compressed.\nThe Tileset Type may be incorrect."
      )
    end
    
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
      @collision_tiles = []
      @collision_tileset.tiles.each_slice(256) do |row_of_big_tiles|
        row_of_big_tiles.each_slice(16) do |big_tile|
          @collision_tiles += big_tile[0,4]
        end
        row_of_big_tiles.each_slice(16) do |big_tile|
          @collision_tiles += big_tile[4,4]
        end
        row_of_big_tiles.each_slice(16) do |big_tile|
          @collision_tiles += big_tile[8,4]
        end
        row_of_big_tiles.each_slice(16) do |big_tile|
          @collision_tiles += big_tile[12,4]
        end
      end
    end
    
    @gfx_pages = RoomGfxPage.from_room_gfx_page_list(@gfx_list_pointer, @fs)
    @gfx_wrappers = @gfx_pages.map{|page| page.gfx_wrapper}
    
    @gfx_chunks = []
    @gfx_pages.each_with_index do |gfx_page, gfx_wrapper_index|
      gfx_page.num_chunks.times do |i|
        @gfx_chunks[gfx_page.gfx_load_offset+i] = [gfx_wrapper_index, gfx_page.first_chunk_index+i]
      end
    end
    
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
      if @gfx_pages.any?{|gfx| gfx.colors_per_palette == 256}
        @palettes_256 = []
        @room.palette_pages.each do |palette_page|
          pals_for_page = @renderer.generate_palettes(palette_page.palette_list_pointer, 256)
          
          @palettes_256[palette_page.palette_load_offset, palette_page.num_palettes] = pals_for_page[palette_page.palette_index, palette_page.num_palettes]
        end
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
    
    @cursor_item = Qt::GraphicsPixmapItem.new
    @cursor_item.setZValue(10)
    @tileset_graphics_scene.addItem(@cursor_item)
    render_selected_tiles_to_cursor_item()
    
    @tileset_pixmap_items = []
    @tiles.each_with_index do |tile, index_on_tileset|
      if index_on_tileset == 0
        @tileset_pixmap_items << nil
        next
      end
      
      tile_pixmap_item = Qt::GraphicsPixmapItem.new
      @tileset_pixmap_items << tile_pixmap_item
      
      render_tile_on_tileset(index_on_tileset)
      
      x_on_tileset = index_on_tileset % @tileset_width
      y_on_tileset = index_on_tileset / @tileset_width
      tile_pixmap_item.setPos(x_on_tileset*@tile_width, y_on_tileset*@tile_height)
      
      @tileset_graphics_scene.addItem(tile_pixmap_item)
    end
    
    load_selected_tile()
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
    else
      render_tile_to_pixmap_item(tile, tile_pixmap_item)
    end
  end
  
  def render_tile(tile)
    gfx = @gfx_pages[tile.tile_page]
    if gfx.nil?
      # Invalid gfx page index
      return ChunkyPNG::Image.new(@tile_width, @tile_height)
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
      # TODO: figure out why this sometimes happens.
      puts "Palette index #{tile.palette_index} out of range, tileset %08X" % @tileset_pointer
      palette = @renderer.generate_palettes(nil, 16).first # Dummy red palette
    end
    
    if SYSTEM == :nds
      chunky_tile = @renderer.render_graphic_tile(gfx.gfx_wrapper.file, palette, tile.index_on_tile_page)
    else
      gfx_chunk_index_on_page = (tile.index_on_tile_page & 0xC0) >> 6
      gfx_chunk_index = tile.tile_page*4 + gfx_chunk_index_on_page
      gfx_chunk_index += 0x10 if gfx.colors_per_palette == 16
      gfx_chunk_index = gfx_chunk_index_on_page if gfx.colors_per_palette == 256
      gfx_wrapper_index, chunk_offset = @gfx_chunks[gfx_chunk_index]
      minitile_index_on_page = tile.index_on_tile_page & 0x3F
      minitile_index_on_page += chunk_offset * 0x40
      
      gfx_wrapper = @gfx_wrappers[gfx_wrapper_index]
      
      chunky_tile = @renderer.render_1_dimensional_minitile(gfx_wrapper, palette, minitile_index_on_page)
    end
    
    if tile.horizontal_flip
      chunky_tile.flip_vertically! # Flips it horizontally despite the name
    end
    if tile.vertical_flip
      chunky_tile.flip_horizontally! # Flips it vertically despite the name
    end
    
    return chunky_tile
  end
  
  def render_tile_to_pixmap_item(tile, tile_pixmap_item)
    chunky_tile = render_tile(tile)
    return if chunky_tile.nil?
    
    pixmap = Qt::Pixmap.new
    blob = chunky_tile.to_blob
    pixmap.loadFromData(blob, blob.length)
    tile_pixmap_item.pixmap = pixmap
  end
  
  def render_selected_tiles_to_cursor_item
    if @selection_width == 0 || @selection_height == 0
      # No cursor to render, just use a blank pixmap to avoid libpng warnings in the console.
      @selection_tiles_pixmaps = []
      @cursor_item.pixmap = Qt::Pixmap.new
      return
    end
    
    chunky_tiles_rect = ChunkyPNG::Image.new(@selection_width*@tile_width, @selection_height*@tile_height)
    
    @selection_tiles_pixmaps = []
    @selected_tiles.each_with_index do |tile, i|
      if @collision_mode
        chunky_tile = @renderer.render_collision_tile(tile)
      else
        chunky_tile = render_tile(tile)
      end
      
      pixmap = Qt::Pixmap.new
      blob = chunky_tile.to_blob
      pixmap.loadFromData(blob, blob.length)
      @selection_tiles_pixmaps << pixmap
      
      x = i % @selection_width
      y = i / @selection_width
      
      chunky_tiles_rect.compose!(chunky_tile, x*@tile_width, y*@tile_height)
    end
    
    pixmap = Qt::Pixmap.new
    blob = chunky_tiles_rect.to_blob
    pixmap.loadFromData(blob, blob.length)
    @cursor_item.pixmap = pixmap
  end
  
  def load_selected_tile
    return if @selected_tile.nil?
    
    @selected_tile_graphics_scene.clear()
    @selected_tile_collision_graphics_scene.clear()
    
    @ui.horizontal_flip.checked = @selected_tile.horizontal_flip
    @ui.vertical_flip.checked = @selected_tile.vertical_flip
    
    selected_tile_pixmap_item = Qt::GraphicsPixmapItem.new
    render_tile_to_pixmap_item(@selected_tile, selected_tile_pixmap_item)
    @selected_tile_graphics_scene.addItem(selected_tile_pixmap_item)
    
    tile_x_pos_on_page = @selected_tile.index_on_tile_page % @tiles_per_gfx_page_row
    tile_y_pos_on_page = @selected_tile.index_on_tile_page / @tiles_per_gfx_page_row
    
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
    
    if SYSTEM == :nds
      gfx_wrapper = @gfx_wrappers[@selected_tile.tile_page]
      
      if gfx_wrapper.nil?
        @ui.gfx_file.text = "Invalid (gfx page index %02X)" % @selected_tile.tile_page
        return
      end
      
      if gfx_wrapper.colors_per_palette == 16
        palette = @palettes[@selected_tile.palette_index]
      else
        palette = @palettes_256[@selected_tile.palette_index]
      end
      
      @ui.gfx_file.text = gfx_wrapper.file[:file_path]
      chunky_image = @renderer.render_gfx_page(gfx_wrapper.file, palette)
    else
      chunky_image = ChunkyPNG::Image.new(128, 128, ChunkyPNG::Color::TRANSPARENT)
      4.times do |i|
        gfx_chunk_index = @selected_tile.tile_page*4 + i
        # HACKY TODO
        gfx = @gfx_pages[@selected_tile.tile_page]
        
        if gfx.nil?
          @ui.gfx_file.text = "Invalid (gfx page index %02X)" % @selected_tile.tile_page
          return
        end
        
        gfx_chunk_index += 0x10 if gfx.colors_per_palette == 16
        gfx_chunk_index = 0 if gfx.colors_per_palette == 256
        gfx_wrapper_index, chunk_offset = @gfx_chunks[gfx_chunk_index]
        gfx_wrapper = @gfx_wrappers[gfx_wrapper_index]
        
        if gfx_wrapper.colors_per_palette == 16
          palette = @palettes[@selected_tile.palette_index]
        else
          palette = @palettes_256[@selected_tile.palette_index]
        end
        
        chunky_chunk_image = @renderer.render_gfx_1_dimensional_mode(gfx_wrapper, palette, first_minitile_index: chunk_offset*64, max_num_minitiles: 64)
        chunky_image.compose!(chunky_chunk_image, 0, i*32)
      end
      
      @ui.gfx_file.text = ""
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
    
    unless @collision_mode
      @selected_tiles.each do |tile|
        tile.palette_index = palette_index
      end
      if @cursor_item
        render_selected_tiles_to_cursor_item()
      end
    end
  end
  
  def change_tiles_by_x_y(mouse_x, mouse_y)
    return if @selected_tiles.nil?
    
    @selection_height.times do |y_off|
      @selection_width.times do |x_off|
        x = mouse_x/@tile_width + x_off
        y = mouse_y/@tile_height + y_off
        
        next if x < 0
        break if x >= @tileset_width
        next if y < 0
        break if y >= @tileset_height
        
        # Blank tile at the start of the tileset
        if SYSTEM == :nds && x == 0 && y == 0
          next
        elsif SYSTEM == :gba && x < 4 && y < 4
          next
        end
        
        i_in_selection = x_off + y_off*@selection_width
        new_tile = @selected_tiles[i_in_selection]
        
        i_on_tileset = x + y*@tileset_width
        if @collision_mode
          coll_tile = @collision_tiles[i_on_tileset]
          coll_tile.has_top = new_tile.has_top
          coll_tile.vertical_flip = new_tile.vertical_flip
          coll_tile.horizontal_flip = new_tile.horizontal_flip
          coll_tile.has_sides_and_bottom = new_tile.has_sides_and_bottom
          coll_tile.has_effect = new_tile.has_effect
          coll_tile.is_water = new_tile.is_water
          coll_tile.block_shape = new_tile.block_shape
        else
          tile = @tiles[i_on_tileset]
          tile.index_on_tile_page = new_tile.index_on_tile_page
          tile.tile_page = new_tile.tile_page
          tile.horizontal_flip = new_tile.horizontal_flip
          tile.vertical_flip = new_tile.vertical_flip
          tile.palette_index = new_tile.palette_index
        end
        
        pixmap = @selection_tiles_pixmaps[i_in_selection]
        tile_pixmap_item = @tileset_pixmap_items[i_on_tileset]
        tile_pixmap_item.pixmap = pixmap
      end
    end
  end
  
  def mouse_clicked_on_tileset(x, y, button)
    return unless (0..@tileset_width*@tile_width-1).include?(x) && (0..@tileset_height*@tile_height-1).include?(y)
    
    case button
    when Qt::LeftButton
      change_tiles_by_x_y(x, y)
    when Qt::RightButton
      right_mouse_clicked_on_tileset(x, y)
    end
  end
  
  def mouse_moved_on_tileset(x, y, button)
    update_tileset_cursor(x, y, button)
    
    if button & Qt::RightButton != 0
      right_mouse_moved_on_tileset(x, y)
    elsif button & Qt::LeftButton != 0
      change_tiles_by_x_y(x, y)
    end
  end
  
  def right_mouse_clicked_on_tileset(mouse_x, mouse_y)
    i = mouse_x/@tile_width + mouse_y/@tile_width*@tileset_width
    
    select_tile(i)
    
    @selection_origin = Qt::Point.new(mouse_x/@tile_width, mouse_y/@tile_height)
    
    @selection_rectangle = Qt::GraphicsRectItem.new
    @selection_rectangle.setPen(RED_PEN_COLOR)
    @selection_rectangle.setRect(0, 0, @tile_width, @tile_height)
    @tileset_graphics_scene.addItem(@selection_rectangle)
    
    update_selection_on_tileset(mouse_x, mouse_y)
  end
  
  def right_mouse_moved_on_tileset(x, y)
    update_selection_on_tileset(x, y)
  end
  
  def mouse_released_on_tileset(x, y, button)
    case button
    when Qt::RightButton
      stop_selecting_on_tileset()
    end
  end
  
  def keyPressEvent(event)
    case event.key
    when Qt::Key_X
      # Flip selection horizontally.
      if @selected_tiles
        new_selected_tiles = []
        
        @selection_height.times do |y|
          @selection_width.times.reverse_each do |x|
            i = x + y*@selection_width
            tile = @selected_tiles[i]
            tile.horizontal_flip = !tile.horizontal_flip
            new_selected_tiles << tile
          end
        end
        
        @selected_tiles = new_selected_tiles
        render_selected_tiles_to_cursor_item()
        
        if @selected_tiles.size > 0
          if @collision_mode
            @selected_collision_tile = @selected_tiles.first
          else
            @selected_tile = @selected_tiles.first
          end
          load_selected_tile()
        end
      end
    when Qt::Key_Y
      # Flip selection vertically.
      if @selected_tiles
        new_selected_tiles = []
        
        @selection_height.times.reverse_each do |y|
          @selection_width.times do |x|
            i = x + y*@selection_width
            tile = @selected_tiles[i]
            tile.vertical_flip = !tile.vertical_flip
            new_selected_tiles << tile
          end
        end
        
        @selected_tiles = new_selected_tiles
        render_selected_tiles_to_cursor_item()
        
        if @selected_tiles.size > 0
          if @collision_mode
            @selected_collision_tile = @selected_tiles.first
          else
            @selected_tile = @selected_tiles.first
          end
          load_selected_tile()
        end
      end
      
      load_selected_tile()
    end
    
    super(event)
  end
  
  def update_tileset_cursor(x, y, button)
    return if @cursor_item.nil?
    
    if (0..@tileset_width*@tile_width-1).include?(x) && (0..@tileset_height*@tile_height-1).include?(y)
      @cursor_item.show()
    else
      @cursor_item.hide()
    end
    
    x = x/@tile_width*@tile_width
    y = y/@tile_height*@tile_height
    @cursor_item.setPos(x, y)
  end
  
  def select_tile(tile_index)
    old_selected_tile = @selected_tile
    
    @selected_tile_index = tile_index
    @selected_tile = @tiles[tile_index].dup
    @selected_collision_tile = @collision_tiles[tile_index].dup
    
    @ui.gfx_page_index.setCurrentIndex(@selected_tile.tile_page)
    @ui.palette_index.setCurrentIndex(@selected_tile.palette_index)
    
    unless @collision_mode
      if old_selected_tile.nil? || old_selected_tile.tile_page != @selected_tile.tile_page || old_selected_tile.palette_index != @selected_tile.palette_index
        gfx_page_changed(@selected_tile.tile_page)
        palette_changed(@selected_tile.palette_index)
      end
    end
    
    load_selected_tile()
  end
  
  def update_selection_rectangle(mouse_x, mouse_y, max_w, max_h)
    mouse_x = [mouse_x, 0].max
    mouse_y = [mouse_y, 0].max
    mouse_x = [mouse_x, max_w].min
    mouse_y = [mouse_y, max_h].min
    mouse_x = mouse_x/@tile_width
    mouse_y = mouse_y/@tile_height
    
    @selection_x = [mouse_x, @selection_origin.x].min
    @selection_y = [mouse_y, @selection_origin.y].min
    selection_right_x = [mouse_x, @selection_origin.x].max
    selection_bottom_y = [mouse_y, @selection_origin.y].max
    @selection_width = selection_right_x - @selection_x + 1
    @selection_height = selection_bottom_y - @selection_y + 1
    
    @selection_rectangle.setRect(@selection_x*@tile_width, @selection_y*@tile_height, @selection_width*@tile_width, @selection_height*@tile_height)
  end
  
  def update_selection_on_tileset(mouse_x, mouse_y)
    return unless @selection_origin
    
    max_w = @tileset_width*@tile_width - 1
    max_h = @tileset_height*@tile_height - 1
    update_selection_rectangle(mouse_x, mouse_y, max_w, max_h)
    
    @selected_tiles = []
    @selection_height.times do |y_off|
      @selection_width.times do |x_off|
        curr_x = @selection_x + x_off
        curr_y = @selection_y + y_off
        i = curr_x + curr_y*@tileset_width
        if @collision_mode
          tile = @collision_tiles[i].dup
        else
          tile = @tiles[i].dup
        end
        @selected_tiles << tile
      end
    end
  end
  
  def stop_selecting_on_tileset
    @selection_origin = nil
    
    render_selected_tiles_to_cursor_item()
    
    @tileset_graphics_scene.removeItem(@selection_rectangle) if @selection_rectangle
  end
  
  def update_selection_on_gfx_page(mouse_x, mouse_y)
    return unless @selection_origin
    
    max_w = (@gfx_page_graphics_scene.width-1).to_i
    max_h = (@gfx_page_graphics_scene.height-1).to_i
    update_selection_rectangle(mouse_x, mouse_y, max_w, max_h)
    
    @selected_tiles = []
    @selection_height.times do |y_off|
      @selection_width.times do |x_off|
        curr_x = @selection_x + x_off
        curr_y = @selection_y + y_off
        if @collision_mode
          i = curr_x + curr_y*16
          tile = @available_collision_tiles[i].dup
        else
          i = curr_x + curr_y*@tiles_per_gfx_page_row
          tile = @selected_tile.dup
          tile.index_on_tile_page = i
        end
        @selected_tiles << tile
      end
    end
  end
  
  def stop_selecting_on_gfx_page
    @selection_origin = nil
    
    render_selected_tiles_to_cursor_item()
    
    @gfx_page_graphics_scene.removeItem(@selection_rectangle) if @selection_rectangle
  end
  
  def mouse_clicked_on_gfx_page(mouse_x, mouse_y, button)
    return unless (0..@gfx_page_graphics_scene.width-1).include?(mouse_x) && (0..@gfx_page_graphics_scene.height-1).include?(mouse_y)
    
    if @collision_mode
      i = mouse_x/@tile_width + mouse_y/@tile_width*16
      @selected_collision_tile = @available_collision_tiles[i].dup
    else
      i = mouse_x/@tile_width + mouse_y/@tile_width*@tiles_per_gfx_page_row
      @selected_tile.index_on_tile_page = i
    end
    
    load_selected_tile()
    
    
    if !@cursor_item
      @cursor_item = Qt::GraphicsPixmapItem.new
      @tileset_graphics_scene.addItem(@cursor_item)
    end
    
    @selection_origin = Qt::Point.new(mouse_x/@tile_width, mouse_y/@tile_height)
    
    @selection_rectangle = Qt::GraphicsRectItem.new
    @selection_rectangle.setPen(RED_PEN_COLOR)
    @selection_rectangle.setRect(0, 0, @tile_width, @tile_height)
    @gfx_page_graphics_scene.addItem(@selection_rectangle)
    
    update_selection_on_gfx_page(mouse_x, mouse_y)
  end
  
  def mouse_moved_on_gfx_page(mouse_x, mouse_y, button)
    update_selection_on_gfx_page(mouse_x, mouse_y)
  end
  
  def mouse_released_on_gfx_page(mouse_x, mouse_y, button)
    stop_selecting_on_gfx_page()
  end
  
  def toggle_flips(checked)
    @selected_tile.horizontal_flip = @ui.horizontal_flip.checked
    @selected_tile.vertical_flip = @ui.vertical_flip.checked
    load_selected_tile()
    render_tile_on_tileset(@selected_tile_index)
  end
  
  def update_collision(checked)
    @selected_collision_tile.has_top = @ui.has_top.checked
    @selected_collision_tile.is_water = @ui.is_water.checked
    @selected_collision_tile.has_sides_and_bottom = @ui.has_sides_and_bottom.checked
    @selected_collision_tile.has_effect = @ui.has_effect.checked
    @selected_collision_tile.vertical_flip = @ui.coll_vertical_flip.checked
    @selected_collision_tile.horizontal_flip = @ui.coll_horizontal_flip.checked
    
    if @collision_mode
      @selected_tiles.each do |tile|
        tile.has_top = @ui.has_top.checked
        tile.is_water = @ui.is_water.checked
        tile.has_sides_and_bottom = @ui.has_sides_and_bottom.checked
        tile.has_effect = @ui.has_effect.checked
        tile.vertical_flip = @ui.coll_vertical_flip.checked
        tile.horizontal_flip = @ui.coll_horizontal_flip.checked
      end
      if @cursor_item
        render_selected_tiles_to_cursor_item()
      end
    end
    
    load_selected_tile()
    render_tile_on_tileset(@selected_tile_index)
  end
  
  def block_shape_changed(block_shape)
    @selected_collision_tile.block_shape = block_shape
    
    if @collision_mode
      @selected_tiles.each do |tile|
        tile.block_shape = block_shape
      end
      if @cursor_item
        render_selected_tiles_to_cursor_item()
      end
    end
    
    load_selected_tile()
    render_tile_on_tileset(@selected_tile_index)
  end
  
  def toggle_display_collision(checked)
    @collision_mode = checked
    
    @selected_tiles = []
    @selection_x = 0
    @selection_y = 0
    @selection_width = 0
    @selection_height = 0
    
    render_tileset()
    
    select_tile(0)
    
    if @collision_mode
      @ui.edit_graphics_group.hide()
      @ui.edit_collision_group.show()
      
      @gfx_page_graphics_scene.clear()
      
      @gfx_page_graphics_scene.setSceneRect(0, 0, 16*@tile_width, 16*@tile_height)
      
      @available_collision_tiles = []
      16.times do |y|
        16.times do |x|
          tile_data = (x << 4) | y
          coll_tile = CollisionTile.new([tile_data].pack("V"))
          @available_collision_tiles << coll_tile
          
          chunky_coll_tile = @renderer.render_collision_tile(coll_tile)
          
          pixmap = Qt::Pixmap.new
          blob = chunky_coll_tile.to_blob
          pixmap.loadFromData(blob, blob.length)
          tile_pixmap_item = Qt::GraphicsPixmapItem.new
          tile_pixmap_item.pixmap = pixmap
          tile_pixmap_item.setPos(x*@tile_width, y*@tile_height)
          @gfx_page_graphics_scene.addItem(tile_pixmap_item)
        end
      end
    else
      @ui.edit_collision_group.hide()
      @ui.edit_graphics_group.show()
      
      @gfx_page_graphics_scene.setSceneRect(0, 0, 128, 128)
      gfx_page_changed(@selected_tile.tile_page || 0)
    end
  end
  
  def save_tileset
    @tileset.write_to_rom()
    @collision_tileset.write_to_rom()
    
    # Clear the tileset cache so the changes show up in the editor.
    parent.clear_cache()
  rescue GBADummyFilesystem::CompressedDataTooLarge => e
    Qt::MessageBox.warning(self,
      "Compressed write error",
      e.message
    )
    return
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
