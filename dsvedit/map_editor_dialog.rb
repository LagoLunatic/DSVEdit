
require_relative 'ui_map_editor'

class MapEditorDialog < Qt::Dialog
  BACKGROUND_BRUSH = Qt::Brush.new(Qt::Color.new(200, 200, 200, 255))
  
  slots "edit_map_tile(int, int, const Qt::MouseButton&)"
  slots "select_tile(int, int, const Qt::MouseButton&)"
  slots "reload_available_tiles()"
  slots "reload_map_and_available_tiles()"
  slots "toggle_edit_warps()"
  slots "warp_name_changed(int)"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, game, renderer, area_index, sector_index)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_MapEditor.new
    @ui.setup_ui(self)
    
    @game = game
    @renderer = renderer
    @area = game.areas[area_index]
    
    if GAME == "dos" || GAME == "aos" || GAME == "hod"
      @map = DoSMap.new(area_index, sector_index, game)
    else
      @map = Map.new(area_index, sector_index, game)
    end
    
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
    when "dos", "aos", "hod"
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
    
    connect(@ui.is_save, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles()"))
    connect(@ui.is_warp, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles()"))
    connect(@ui.is_castle_b_warp, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles()"))
    connect(@ui.is_secret, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles()"))
    connect(@ui.is_transition, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles()"))
    connect(@ui.is_entrance, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles()"))
    connect(@ui.is_blank, SIGNAL("stateChanged(int)"), self, SLOT("reload_available_tiles()"))
    connect(@ui.region_index, SIGNAL("activated(int)"), self, SLOT("reload_available_tiles()"))
    
    if !["por", "ooe"].include?(GAME)
      @ui.used_tiles_label.hide()
      @ui.used_tiles_number.hide()
    end
    
    if GAME == "hod"
      [
        "Entrance",
        "Marble Corridor",
        "Shrine of the Apostates",
        "Castle Top Floor",
        "Skeleton Cave",
        "Luminous Cavern",
        "Aqueduct of Dragons",
        "Sky Walkway",
        "Clock Tower",
        "Castle Treasury",
        "Room of Illusion",
        "The Wailing Way",
        "Chapel of Dissonance",
      ].each_with_index do |region_name, i|
        @ui.region_index.addItem("%02X #{region_name}" % i)
      end
    else
      @ui.label.hide()
      @ui.region_index.hide()
      @ui.color_code_regions.hide()
    end
    
    case GAME
    when "dos", "aos"
      @ui.is_secret.hide()
      @ui.is_transition.hide()
      @ui.is_entrance.hide()
      @ui.is_castle_b_warp.hide()
    when "hod"
      @ui.is_secret.hide()
      @ui.is_transition.hide()
      @ui.is_entrance.hide()
      @ui.is_warp.text = "Warp (Castle A)"
    else
      @ui.is_blank.hide()
      @ui.is_castle_b_warp.hide()
    end
    
    @edit_warps_mode = false
    if GAME == "dos"
      warp_names = [
        "The Lost Village",
        "Wizardry Lab",
        "Garden of Madness",
        "The Dark Chapel",
        "Demon Guest House",
        "Condemned Tower",
        "Mine of Judgment",
        "Cursed Clock Tower",
        "Subterranean Hell",
        "Silenced Ruins",
        "The Pinnacle",
        "The Abyss",
      ]
      warp_names.each do |area_name|
        @ui.warp_name.addItem(area_name)
      end
    end
    @ui.warp_name_label.hide()
    @ui.warp_name.hide()
    connect(@ui.edit_warps_button, SIGNAL("released()"), self, SLOT("toggle_edit_warps()"))
    connect(@ui.warp_name, SIGNAL("activated(int)"), self, SLOT("warp_name_changed(int)"))
    
    connect(@ui.color_code_regions, SIGNAL("stateChanged(int)"), self, SLOT("reload_map_and_available_tiles()"))
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    self.show()
  end
  
  def create_tile_pixmap_item(tile)
    fill_tile, lines_tile = @renderer.render_map_tile(tile, color_code_regions: @ui.color_code_regions.checked)
    fill_tile.compose!(lines_tile, 0, 0)
    
    pixmap = Qt::Pixmap.new()
    blob = fill_tile.to_blob
    pixmap.loadFromData(blob, blob.length)
    Qt::GraphicsPixmapItem.new(pixmap)
  end
  
  def load_map
    @map_graphics_scene.clear()
    
    chunky_png_img = @renderer.render_map(@map, color_code_regions: @ui.color_code_regions.checked)
    pixmap = Qt::Pixmap.new
    blob = chunky_png_img.to_blob
    pixmap.loadFromData(blob, blob.length)
    map_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
    @map_graphics_scene.addItem(map_pixmap_item)
    
    update_used_tiles_number()
  end
  
  def load_selected_map_tile
    @selected_tile_graphics_scene.clear()
    
    tile_pixmap_item = create_tile_pixmap_item(@selected_map_tile)
    @selected_tile_graphics_scene.addItem(tile_pixmap_item)
  end
  
  def reload_available_tiles
    @available_tiles_graphics_scene.clear()
    
    @available_tiles.each do |tile|
      tile.is_save          = @ui.is_save.checked
      tile.is_warp          = @ui.is_warp.checked
      tile.is_castle_b_warp = @ui.is_castle_b_warp.checked
      tile.is_secret        = @ui.is_secret.checked
      tile.is_transition    = @ui.is_transition.checked
      tile.is_entrance      = @ui.is_entrance.checked
      tile.is_blank         = @ui.is_blank.checked
      
      if GAME == "hod"
        tile.region_index = @ui.region_index.currentIndex
      end
      
      tile_pixmap_item = create_tile_pixmap_item(tile)
      tile_pixmap_item.setOffset(tile.x_pos*8, tile.y_pos*8)
      @available_tiles_graphics_scene.addItem(tile_pixmap_item)
    end
    
    load_selected_map_tile()
  end
  
  def reload_map_and_available_tiles
    reload_available_tiles()
    load_map()
  end
  
  def edit_map_tile(x, y, button)
    return if @edit_warps_mode
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
      elsif @map.is_a?(DoSMap)
        # Do nothing.
      else # PoR/OoE
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
      new_tile.sector_index, new_tile.room_index = @area.get_sector_and_room_indexes_from_map_x_y(x, y, abyss=@map.is_abyss) || [0, 0]
      new_tile.y_pos = y
      new_tile.x_pos = x
      @map.tiles << new_tile
      
      update_used_tiles_number()
    else
      Qt::MessageBox.warning(self, "Can't add more tiles", "Can't add any more tiles to maps in PoR or OoE.\nPlease delete some tiles with right click so you can add more.")
    end
  end
  
  def change_map_tile(old_tile)
    index = @map.tiles.index(old_tile)
    new_tile = @selected_map_tile.dup
    new_tile.sector_index, new_tile.room_index = @area.get_sector_and_room_indexes_from_map_x_y(old_tile.x_pos, old_tile.y_pos, abyss=@map.is_abyss) || [0, 0]
    new_tile.y_pos = old_tile.y_pos
    new_tile.x_pos = old_tile.x_pos
    @map.tiles[index] = new_tile
  end
  
  def delete_map_tile(old_tile)
    case GAME
    when "dos", "aos", "hod"
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
      
      update_used_tiles_number()
    end
  end
  
  def select_tile(x, y, button)
    return unless @available_tiles_graphics_scene.sceneRect.contains(x, y)
    i = x/8 + y/8*16
    @selected_map_tile = @available_tiles[i]
    load_selected_map_tile()
  end
  
  def toggle_edit_warps
    if GAME == "por" || GAME == "ooe"
      Qt::MessageBox.warning(self, "Can't edit warps", "PoR and OoE automatically determine warp point position from the map. Warp rooms don't need to be placed manually.")
      return
    end
    
    @edit_warps_mode = !@edit_warps_mode
    
    if @edit_warps_mode
      @position_indicator_timeline = Qt::TimeLine.new
      @position_indicator_timeline.updateInterval = 1
      @position_indicator_timeline.duration = 40.0/60.0 * 1000.0
      @position_indicator_timeline.curveShape = Qt::TimeLine::LinearCurve
      @position_indicator_timeline.loopCount = 0
      @position_indicator_timeline.start
      
      @position_indicators = []
      @map.warp_rooms.each do |warp_room|
        position_indicator = WarpPositionIndicator.new(warp_room, @position_indicator_timeline, self)
        @map_graphics_scene.addItem(position_indicator)
        @position_indicators << position_indicator
      end
      
      @selected_warp_room = @map.warp_rooms.first
      
      selected_warp_room_changed(@selected_warp_room, @position_indicators.first)
      
      @ui.edit_warps_button.text = "Edit Map"
      
      if GAME == "dos"
        @ui.warp_name_label.show()
        @ui.warp_name.show()
      end
    else
      @position_indicator_timeline.stop()
      @position_indicator_timeline = nil
      @position_indicators.each do |position_indicator|
        @map_graphics_scene.removeItem(position_indicator)
      end
      @position_indicators = nil
      
      @ui.edit_warps_button.text = "Edit Warps"
      
      @ui.warp_name_label.hide()
      @ui.warp_name.hide()
    end
  end
  
  def warp_name_changed(warp_name_index)
    @selected_warp_room.area_name_index = warp_name_index
  end
  
  def selected_warp_room_changed(warp_room, selected_position_indicator)
    @selected_warp_room = warp_room
    
    if GAME == "dos"
      warp_name_index = @selected_warp_room.area_name_index
      @ui.warp_name.setCurrentIndex(warp_name_index)
    end
    
    @position_indicators.each do |position_indicator|
      position_indicator.setBrush(Qt::Brush.new(Qt::Color.new(255, 255, 255, 127)))
    end
    selected_position_indicator.setBrush(Qt::Brush.new(Qt::Color.new(255, 255, 255, 255)))
  end
  
  def update_used_tiles_number
    @ui.used_tiles_number.text = "#{@map.tiles.length}/#{@map.number_of_tiles}"
  end
  
  def save_changes
    @map.write_to_rom()
    @game.clear_map_cache()
    parent.load_map()
    return true
  rescue FreeSpaceManager::FreeSpaceFindError => e
    Qt::MessageBox.warning(self,
      "Failed to find free space",
      "Failed to find free space to put the expanded map height.\n\n#{NO_FREE_SPACE_MESSAGE}"
    )
    return false
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      if @map.tiles.length == @map.number_of_tiles
        success = save_changes()
        self.close() if success
      else
        Qt::MessageBox.warning(self, "Can't save", "Can't save maps in PoR or OoE unless the number of tiles is the same as the original. Please add more tiles.")
      end
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      if @map.tiles.length == @map.number_of_tiles
        save_changes()
      else
        Qt::MessageBox.warning(self, "Can't save", "Can't save maps in PoR or OoE unless the number of tiles is the same as the original. Please add more tiles.")
      end
    end
  end
end

class WarpPositionIndicator < Qt::GraphicsEllipseItem
  RADIUS = 6
  
  attr_reader :warp_room
  
  def initialize(warp_room, position_indicator_timeline, map_editor)
    super(-RADIUS, -RADIUS, RADIUS*2, RADIUS*2)
    setPen(Qt::Pen.new(Qt::NoPen))
    setBrush(Qt::Brush.new(Qt::white))
    
    @warp_room = warp_room
    @map_editor = map_editor
    
    setPos(warp_room.x_pos_in_tiles*4 + 2.25, warp_room.y_pos_in_tiles*4 + 2.25)
    setFlag(Qt::GraphicsItem::ItemIsMovable)
    setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges)
    
    @animation = Qt::GraphicsItemAnimation.new(@map_graphics_view) do |anim|
      anim.item = self
      anim.setTimeLine(position_indicator_timeline)
      anim.setScaleAt(1, 0.0, 0.0)
    end
  end
  
  def itemChange(change, value)
    if change == ItemPositionChange && scene()
      new_pos = value.toPointF()
      x = new_pos.x - 2.25
      y = new_pos.y - 2.25
      
      x = (x / 4).round
      y = (y / 4).round
      max_x = (scene.width-1-5)/4
      max_y = (scene.height-1-5)/4
      x = [x, max_x].min
      x = [x, 0].max
      y = [y, max_y].min
      y = [y, 0].max
      new_pos.setX(x*4 + 2.25)
      new_pos.setY(y*4 + 2.25)
      
      @warp_room.x_pos_in_tiles = x
      @warp_room.y_pos_in_tiles = y
      
      return super(change, Qt::Variant.new(new_pos))
    end
    
    return super(change, value)
  end
  
  def mouseReleaseEvent(event)
    @map_editor.selected_warp_room_changed(@warp_room, self)
    super(event)
  end
end
