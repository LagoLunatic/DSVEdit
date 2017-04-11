
require_relative 'ui_map_editor'

class MapEditorDialog < Qt::Dialog
  BACKGROUND_BRUSH = Qt::Brush.new(Qt::Color.new(200, 200, 200, 255))
  
  slots "edit_map_tile(int, int, const Qt::MouseButton&)"
  slots "select_tile(int, int, const Qt::MouseButton&)"
  slots "reload_available_tiles(int)"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, game, renderer, area_index, sector_index)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_MapEditor.new
    @ui.setup_ui(self)
    
    @game = game
    @renderer = renderer
    @map = game.get_map(area_index, sector_index)
    @area = game.areas[area_index]
    
    @map_graphics_scene = ClickableGraphicsScene.new
    @map_graphics_scene.setSceneRect(0, 0, 64*4+1, 48*4+1)
    @ui.map_graphics_view.scale(2, 2)
    @ui.map_graphics_view.setScene(@map_graphics_scene)
    @map_graphics_scene.setBackgroundBrush(BACKGROUND_BRUSH)
    connect(@map_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("edit_map_tile(int, int, const Qt::MouseButton&)"))
    connect(@map_graphics_scene, SIGNAL("moved(int, int, const Qt::MouseButton&)"), self, SLOT("edit_map_tile(int, int, const Qt::MouseButton&)"))
    
    @available_tiles_graphics_scene = ClickableGraphicsScene.new
    @ui.available_tiles_graphics_view.scale(3, 3)
    @ui.available_tiles_graphics_view.setScene(@available_tiles_graphics_scene)
    @available_tiles_graphics_scene.setBackgroundBrush(BACKGROUND_BRUSH)
    connect(@available_tiles_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("select_tile(int, int, const Qt::MouseButton&)"))
    
    @selected_tile_graphics_scene = Qt::GraphicsScene.new
    @ui.selected_tile_graphics_view.scale(8, 8)
    @ui.selected_tile_graphics_view.setScene(@selected_tile_graphics_scene)
    @selected_tile_graphics_scene.setBackgroundBrush(BACKGROUND_BRUSH)
    
    load_map()
    
    @available_tiles = []
    case GAME
    when "dos", "aos"
      (0..0xF).each do |line_type|
        tile = DoSMapTile.new(0, line_type, line_type, 16)
        @available_tiles << tile
        
        tile_pixmap_item = create_tile_pixmap_item(tile)
        tile_pixmap_item.setOffset(tile.x_pos*8, tile.y_pos*8)
        @available_tiles_graphics_scene.addItem(tile_pixmap_item)
      end
    else
      (0..0xFF).each do |line_type|
        x = line_type % 16
        y = line_type / 16
        tile = MapTile.new([0, y, x], line_type)
        @available_tiles << tile
        
        tile_pixmap_item = create_tile_pixmap_item(tile)
        tile_pixmap_item.setOffset(tile.x_pos*8, tile.y_pos*8)
        @available_tiles_graphics_scene.addItem(tile_pixmap_item)
      end
    end
    
    @selected_map_tile = @available_tiles.first
    load_selected_map_tile()
    
    connect(@ui.is_save, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles(int)"))
    connect(@ui.is_warp, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles(int)"))
    connect(@ui.is_secret, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles(int)"))
    connect(@ui.is_transition, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles(int)"))
    connect(@ui.is_entrance, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles(int)"))
    connect(@ui.is_blank, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles(int)"))
    
    case GAME
    when "dos", "aos"
      @ui.is_secret.disabled = true
      @ui.is_transition.disabled = true
      @ui.is_entrance.disabled = true
    else
      @ui.is_blank.disabled = true
    end
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    self.show()
  end
  
  def create_tile_pixmap_item(tile)
    fill_tile, lines_tile = @renderer.render_map_tile(tile)
    fill_tile.compose!(lines_tile, 0, 0)
    
    pixmap = Qt::Pixmap.new()
    blob = fill_tile.to_blob
    pixmap.loadFromData(blob, blob.length)
    Qt::GraphicsPixmapItem.new(pixmap)
  end
  
  def load_map
    @map_graphics_scene.clear()
    
    chunky_png_img = @renderer.render_map(@map)
    pixmap = Qt::Pixmap.new
    blob = chunky_png_img.to_blob
    pixmap.loadFromData(blob, blob.length)
    map_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
    @map_graphics_scene.addItem(map_pixmap_item)
  end
  
  def load_selected_map_tile
    @selected_tile_graphics_scene.clear()
    
    tile_pixmap_item = create_tile_pixmap_item(@selected_map_tile)
    @selected_tile_graphics_scene.addItem(tile_pixmap_item)
  end
  
  def reload_available_tiles(checked)
    @available_tiles_graphics_scene.clear()
    
    @available_tiles.each do |tile|
      tile.is_save       = @ui.is_save.checked
      tile.is_warp       = @ui.is_warp.checked
      tile.is_secret     = @ui.is_secret.checked
      tile.is_transition = @ui.is_transition.checked
      tile.is_entrance   = @ui.is_entrance.checked
      tile.is_blank      = @ui.is_blank.checked
      
      tile_pixmap_item = create_tile_pixmap_item(tile)
      tile_pixmap_item.setOffset(tile.x_pos*8, tile.y_pos*8)
      @available_tiles_graphics_scene.addItem(tile_pixmap_item)
    end
    
    load_selected_map_tile()
  end
  
  def edit_map_tile(x, y, button)
    return unless (0..@map_graphics_scene.width-1-5).include?(x) && (0..@map_graphics_scene.height-1-5).include?(y)
    
    x = x / 4
    y = y / 4
    
    return unless (0..255).include?(x) && (0..255).include?(y)
    
    old_tile = @map.tiles.find do |tile|
      tile.x_pos == x && tile.y_pos == y
    end
    
    case button
    when Qt::LeftButton
      if old_tile
        change_map_tile(old_tile)
      else
        add_map_tile(x, y)
      end
    when Qt::RightButton
      if old_tile
        delete_map_tile(old_tile)
      end
    else
      return
    end
    
    load_map()
  end
  
  def add_map_tile(x, y)
    # In PoR/OoE, add a tile where there wasn't one before.
    if @map.tiles.length < @map.number_of_tiles
      new_tile = @selected_map_tile.dup
      new_tile.sector_index, new_tile.room_index = @area.get_sector_and_room_indexes_from_map_x_y(x, y)
      new_tile.y_pos = y
      new_tile.x_pos = x
      @map.tiles << new_tile
    else
      Qt::MessageBox.warning(self, "Can't add more tiles", "Can't add any more tiles to maps in PoR or OoE. Please delete some tiles with right click so you can add more.")
    end
  end
  
  def change_map_tile(old_tile)
    index = @map.tiles.index(old_tile)
    new_tile = @selected_map_tile.dup
    new_tile.sector_index, new_tile.room_index = @area.get_sector_and_room_indexes_from_map_x_y(old_tile.x_pos, old_tile.y_pos)
    new_tile.y_pos = old_tile.y_pos
    new_tile.x_pos = old_tile.x_pos
    @map.tiles[index] = new_tile
  end
  
  def delete_map_tile(old_tile)
    case GAME
    when "dos", "aos"
      index = @map.tiles.index(old_tile)
      new_tile = @available_tiles[0].dup
      new_tile.sector_index = nil
      new_tile.room_index = nil
      new_tile.y_pos = old_tile.y_pos
      new_tile.x_pos = old_tile.x_pos
      new_tile.is_blank = true
      @map.tiles[index] = new_tile
    else
      index = @map.tiles.index(old_tile)
      @map.tiles.delete_at(index)
    end
  end
  
  def select_tile(x, y, button)
    return unless @available_tiles_graphics_scene.sceneRect.contains(x, y)
    i = x/8 + y/8*16
    @selected_map_tile = @available_tiles[i]
    load_selected_map_tile()
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      if @map.tiles.length == @map.number_of_tiles
        @map.write_to_rom()
        parent.load_map()
        self.close()
      else
        Qt::MessageBox.warning(self, "Can't save", "Can't save maps in PoR or OoE unless the number of tiles is the same as the original. Please add more tiles.")
      end
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      if @map.tiles.length == @map.number_of_tiles
        @map.write_to_rom()
        parent.load_map()
      else
        Qt::MessageBox.warning(self, "Can't save", "Can't save maps in PoR or OoE unless the number of tiles is the same as the original. Please add more tiles.")
      end
    end
  end
end
