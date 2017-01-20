
require_relative 'enemy_editor_dialog'
require_relative 'text_editor_dialog'
require_relative 'settings_dialog'
require_relative 'sprite_editor_dialog'
require_relative 'item_editor_dialog'
require_relative 'entity_search_dialog'
require_relative 'icon_chooser_dialog'
require_relative 'map_editor_dialog'
require_relative 'entity_editor_dialog'
require_relative 'skeleton_editor_dialog'

require_relative 'ui_main'

class DSVEdit < Qt::MainWindow
  attr_reader :game
  
  slots "extract_rom_dialog()"
  slots "open_folder_dialog()"
  slots "save_files()"
  slots "update_visible_view_items()"
  slots "open_enemy_dna_dialog()"
  slots "open_text_editor()"
  slots "open_sprite_editor()"
  slots "open_item_editor()"
  slots "open_entity_search()"
  slots "open_map_editor()"
  slots "open_settings()"
  slots "write_to_rom()"
  slots "build_and_run()"
  
  slots "cancel_write_to_rom_thread()"
  
  slots "area_index_changed(int)"
  slots "sector_index_changed(int)"
  slots "room_index_changed(int)"
  slots "sector_and_room_indexes_changed(int, int)"
  slots "change_room_by_metadata(int)"
  slots "change_room_by_map_x_and_y(int, int, const Qt::MouseButton&)"
  slots "open_in_tiled()"
  slots "import_from_tiled()"
  slots "set_current_room_as_starting_room()"
  slots "copy_room_pointer_to_clipboad()"
  
  def initialize
    super()
    @ui = Ui_MainWindow.new
    @ui.setup_ui(self)
    
    @room_graphics_scene = Qt::GraphicsScene.new
    @ui.room_graphics_view.setScene(@room_graphics_scene)
    @ui.room_graphics_view.setDragMode(Qt::GraphicsView::ScrollHandDrag)
    self.setStyleSheet("QGraphicsView { background-color: transparent; }");
    
    @map_graphics_scene = ClickableGraphicsScene.new
    @map_graphics_scene.setSceneRect(0, 0, 64*4+1, 48*4+1)
    @ui.map_graphics_view.scale(2, 2)
    @ui.map_graphics_view.setScene(@map_graphics_scene)
    connect(@map_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("change_room_by_map_x_and_y(int, int, const Qt::MouseButton&)"))
    
    @tiled = TMXInterface.new
    
    connect(@ui.actionOpen_Folder, SIGNAL("activated()"), self, SLOT("open_folder_dialog()"))
    connect(@ui.actionExtract_ROM, SIGNAL("activated()"), self, SLOT("extract_rom_dialog()"))
    connect(@ui.actionSave, SIGNAL("activated()"), self, SLOT("save_files()"))
    connect(@ui.actionEntities, SIGNAL("activated()"), self, SLOT("update_visible_view_items()"))
    connect(@ui.actionDoors, SIGNAL("activated()"), self, SLOT("update_visible_view_items()"))
    connect(@ui.actionCollision, SIGNAL("activated()"), self, SLOT("update_visible_view_items()"))
    connect(@ui.actionLayers, SIGNAL("activated()"), self, SLOT("update_visible_view_items()"))
    connect(@ui.actionEnemy_Editor, SIGNAL("activated()"), self, SLOT("open_enemy_dna_dialog()"))
    connect(@ui.actionText_Editor, SIGNAL("activated()"), self, SLOT("open_text_editor()"))
    connect(@ui.actionSprite_Editor, SIGNAL("activated()"), self, SLOT("open_sprite_editor()"))
    connect(@ui.actionItem_Editor, SIGNAL("activated()"), self, SLOT("open_item_editor()"))
    connect(@ui.actionEntity_search, SIGNAL("activated()"), self, SLOT("open_entity_search()"))
    connect(@ui.actionSettings, SIGNAL("activated()"), self, SLOT("open_settings()"))
    connect(@ui.actionBuild, SIGNAL("activated()"), self, SLOT("write_to_rom()"))
    connect(@ui.actionBuild_and_Run, SIGNAL("activated()"), self, SLOT("build_and_run()"))
    
    connect(@ui.area, SIGNAL("activated(int)"), self, SLOT("area_index_changed(int)"))
    connect(@ui.sector, SIGNAL("activated(int)"), self, SLOT("sector_index_changed(int)"))
    connect(@ui.room, SIGNAL("activated(int)"), self, SLOT("room_index_changed(int)"))
    connect(@ui.tiled_export, SIGNAL("released()"), self, SLOT("open_in_tiled()"))
    connect(@ui.tiled_import, SIGNAL("released()"), self, SLOT("import_from_tiled()"))
    connect(@ui.set_as_starting_room, SIGNAL("released()"), self, SLOT("set_current_room_as_starting_room()"))
    connect(@ui.copy_room_pointer, SIGNAL("released()"), self, SLOT("copy_room_pointer_to_clipboad()"))
    connect(@ui.edit_map, SIGNAL("released()"), self, SLOT("open_map_editor()"))
    
    load_settings()
    
    self.setWindowState(Qt::WindowMaximized)
    self.setWindowTitle("DSVania Editor #{DSVEDIT_VERSION}")
    
    self.show()
    
    if @settings[:last_used_folder] && File.directory?(@settings[:last_used_folder])
      open_folder(@settings[:last_used_folder])
    end
  end
  
  def extract_rom_dialog
    if game && game.folder
      default_dir = File.dirname(game.folder)
    end
    rom_path = Qt::FileDialog.getOpenFileName(self, "Select ROM", default_dir, "NDS ROM Files (*.nds)")
    return if rom_path.nil?
    folder = File.dirname(rom_path)
    extract_rom(rom_path)
  end
  
  def open_folder_dialog
    if game && game.folder
      default_dir = File.dirname(game.folder)
    end
    folder = Qt::FileDialog.getExistingDirectory(self, "Open folder", default_dir)
    return if folder.nil?
    open_folder(folder)
  end
  
  def extract_rom(rom_path)
    game = Game.new
    game.initialize_from_rom(rom_path, extract_to_hard_drive = true)
    @game = game
    @renderer = Renderer.new(game.fs)
    @cached_enemy_pixmaps = {}
    @cached_special_object_pixmaps = {}
    
    initialize_dropdowns()
    
    @settings[:last_used_folder] = game.folder
  rescue NDSFileSystem::InvalidFileError
    Qt::MessageBox.warning(self, "Invalid file", "Selected file is not a DSVania")
  end
  
  def open_folder(folder_path)
    game = Game.new
    game.initialize_from_folder(folder_path)
    @game = game
    @renderer = Renderer.new(game.fs)
    @cached_enemy_pixmaps = {}
    @cached_special_object_pixmaps = {}
    
    initialize_dropdowns()
    
    @settings[:last_used_folder] = folder_path
  rescue NDSFileSystem::InvalidFileError
    Qt::MessageBox.warning(self, "Invalid file", "Selected file is not a DSVania")
  end
  
  def initialize_dropdowns
    @ui.area.clear()
    @ui.sector.clear()
    @ui.room.clear()
    @ui.area.addItem("Select Area")
    @ui.area.model.item(0).setEnabled(false)
    AREA_INDEX_TO_OVERLAY_INDEX.keys.each do |area_index|
      area_name = AREA_INDEX_TO_AREA_NAME[area_index]
      @ui.area.addItem("%02X %s" % [area_index, area_name])
    end
    area_index_changed(0, force=true)
  end
  
  def area_index_changed(new_area_index, force=false)
    change_area(new_area_index, force)
    sector_index_changed(0, force=true)
  end
  
  def sector_index_changed(new_sector_index, force=false)
    change_sector(new_sector_index, force)
    room_index_changed(0, force=true)
  end
  
  def room_index_changed(new_room_index, force=false)
    change_room(new_room_index, force)
  end
  
  def change_area(new_area_index, force=false)
    if @ui.area.findText("Select Area", flags=Qt::MatchExactly) >= 0
      # Remove the placeholder Select Area text.
      @ui.area.removeItem(0)
      change_area(0, force=true) # Trigger a second call to change_area to select the actual first area.
      return
    end
    
    if new_area_index == @area_index && !force
      return
    end
    
    @area_index = new_area_index
    @area = game.areas[@area_index]
    @ui.area.setCurrentIndex(@area_index)
    @ui.sector.clear()
    AREA_INDEX_TO_OVERLAY_INDEX[@area_index].keys.each do |sector_index|
      overlay_id = AREA_INDEX_TO_OVERLAY_INDEX[@area_index][sector_index]
      if SECTOR_INDEX_TO_SECTOR_NAME[@area_index]
        sector_name = SECTOR_INDEX_TO_SECTOR_NAME[@area_index][sector_index]
        @ui.sector.addItem("%02X %s (Overlay %d)" % [sector_index, sector_name, overlay_id])
      else
        @ui.sector.addItem("%02X (Overlay %d)" % [sector_index, overlay_id])
      end
    end
    
    load_map()
  end
  
  def change_sector(new_sector_index, force=false)
    if new_sector_index == @sector_index && !force
      return
    end
    
    if GAME == "dos" && ([10, 11].include?(new_sector_index) || [10, 11].include?(@sector_index))
      should_load_map = true
    else
      should_load_map = false
    end
    
    @sector_index = new_sector_index
    @sector = @area.sectors[@sector_index]
    @ui.sector.setCurrentIndex(@sector_index)
    @ui.room.clear()
    @sector.rooms.each_with_index do |room, room_index|
      @ui.room.addItem("%02X %08X" % [room_index, room.room_metadata_ram_pointer])
    end
    
    if should_load_map
      load_map()
    end
  end
  
  def change_room(new_room_index, force=false)
    if new_room_index == @room_index && !force
      return
    end
    
    room = @sector.rooms[new_room_index]
    if room.nil?
      Qt::MessageBox.warning(self, "Can't find room", "Failed to find room with room index #{new_room_index} (area: #{@area_index}, sector: #{@sector_index})")
      load_map() # TODO: hack. For some reason when the room index is wrong the map gets somehow messed up, and it needs to be reloaded to work correctly again.
      return
    end
    
    @room_index = new_room_index
    @room = room
    @ui.room.setCurrentIndex(@room_index)
    
    load_room()
  end
  
  def sector_and_room_indexes_changed(new_sector_index, new_room_index)
    change_sector(new_sector_index)
    change_room(new_room_index, force=true)
  end
  
  def change_room_by_metadata(room_metadata_ram_pointer)
    room = game.get_room_by_metadata_pointer(room_metadata_ram_pointer)
    change_area(room.area_index)
    change_sector(room.sector_index, force=true)
    change_room(room.room_index, force=true)
  end
  
  def change_room_by_map_x_and_y(x, y, button)
    x = x / 4
    y = y / 4
    
    tile = @map.tiles.find do |tile|
      tile.x_pos == x && tile.y_pos == y
    end
    
    if tile.nil? || tile.is_blank
      return
    end
    
    sector_and_room_indexes_changed(tile.sector_index, tile.room_index)
  end
  
  def load_room
    @room_graphics_scene.clear()
    @room_graphics_scene = Qt::GraphicsScene.new
    @ui.room_graphics_view.setScene(@room_graphics_scene)
    @room_graphics_scene.setSceneRect(0, 0, @room.max_layer_width*SCREEN_WIDTH_IN_PIXELS, @room.max_layer_height*SCREEN_HEIGHT_IN_PIXELS)
    
    @layers_view_item = Qt::GraphicsRectItem.new
    @room_graphics_scene.addItem(@layers_view_item)
    @room.sector.load_necessary_overlay()
    @renderer.ensure_tilesets_exist("cache/#{GAME}/rooms/", @room)
    @room.layers.each do |layer|
      tileset_filename = "cache/#{GAME}/rooms/#{@room.area_name}/Tilesets/#{layer.tileset_filename}.png"
      tileset = Qt::Image.new(tileset_filename)
      layer_item = Qt::GraphicsRectItem.new
      layer_item.setZValue(-layer.z_index)
      layer_item.setOpacity(layer.opacity/31.0)
      layer_item.setParentItem(@layers_view_item)
      
      load_layer(layer, tileset, layer_item)
    end
    
    @collision_view_item = Qt::GraphicsRectItem.new
    @room_graphics_scene.addItem(@collision_view_item)
    if @room.layers.length > 0
      @renderer.ensure_tilesets_exist("cache/#{GAME}/rooms/", @room, collision=true)
      tileset_filename = "cache/#{GAME}/rooms/#{@room.area_name}/Tilesets/#{@room.layers.first.tileset_filename}_collision.png"
      tileset = Qt::Image.new(tileset_filename)
      layer = @room.layers.first
      load_layer(layer, tileset, @collision_view_item)
    end
    
    @entities_view_item = Qt::GraphicsRectItem.new
    @room_graphics_scene.addItem(@entities_view_item)
    @room.entities.each do |entity|
      if entity.is_enemy?
        enemy_id = entity.subtype
        
        chunky_frame, min_x, min_y = @cached_enemy_pixmaps[enemy_id] ||= begin
          gfx_file_pointers, palette, palette_offset, sprite_file = EnemyDNA.new(enemy_id, @game.fs).get_gfx_and_palette_and_sprite_from_init_ai
          frame_to_render = BEST_SPRITE_FRAME_FOR_ENEMY[enemy_id] || 0
          
          sprite = Sprite.new(sprite_file, game.fs)
          chunky_frames, min_x, min_y = @renderer.render_sprite(gfx_file_pointers, palette, palette_offset, sprite, frame_to_render)
          if chunky_frames.empty?
            next
          end
          
          chunky_frame = chunky_frames.first
          
          [chunky_frame, min_x, min_y]
        rescue
          # Failed to render enemy sprite, put a generic rectangle there instead.
          graphics_item = EntityRectItem.new(entity, self)
          graphics_item.setParentItem(@entities_view_item)
          next
        end
        
        graphics_item = EntityChunkyItem.new(chunky_frame, entity, self)
        
        graphics_item.setPos(entity.x_pos+min_x, entity.y_pos+min_y)
        graphics_item.setParentItem(@entities_view_item)
      elsif entity.is_item?
        item_type = entity.subtype
        item_id = entity.var_b
        chunky_image = @renderer.render_icon(item_type-2, item_id)
        
        graphics_item = EntityChunkyItem.new(chunky_image, entity, self)
        graphics_item.setPos(entity.x_pos-8, entity.y_pos-16)
        graphics_item.setParentItem(@entities_view_item)
      elsif entity.is_glyph?
        glyph_id = entity.var_b
        if glyph_id <= 0x36
          chunky_image = @renderer.render_icon(0, glyph_id-1, mode=:glyph)
        else
          chunky_image = @renderer.render_icon(1, glyph_id-1-0x37, mode=:glyph)
        end
        
        graphics_item = EntityChunkyItem.new(chunky_image, entity, self)
        graphics_item.setPos(entity.x_pos-16, entity.y_pos-16)
        graphics_item.setParentItem(@entities_view_item)
      elsif entity.is_special_object?
        special_object_id = entity.subtype
        chunky_frame, min_x, min_y = @cached_special_object_pixmaps[special_object_id] ||= begin
          gfx_file_pointers, palette, palette_offset, sprite_file = SpecialObjectType.new(special_object_id, game.fs).get_gfx_and_palette_and_sprite_from_create_code
          frame_to_render = BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT[special_object_id] || 0
          
          sprite = Sprite.new(sprite_file, game.fs)
          chunky_frames, min_x, min_y = @renderer.render_sprite(gfx_file_pointers, palette, palette_offset, sprite, frame_to_render)
          if chunky_frames.empty?
            next
          end
          
          chunky_frame = chunky_frames.first
          
          [chunky_frame, min_x, min_y]
        rescue
          # Failed to render object sprite, put a generic rectangle there instead.
          graphics_item = EntityRectItem.new(entity, self)
          graphics_item.setParentItem(@entities_view_item)
          next
        end
        
        graphics_item = EntityChunkyItem.new(chunky_frame, entity, self)
        
        graphics_item.setPos(entity.x_pos+min_x, entity.y_pos+min_y)
        graphics_item.setParentItem(@entities_view_item)
      else
        graphics_item = EntityRectItem.new(entity, self)
        graphics_item.setParentItem(@entities_view_item)
      end
    end
    
    @doors_view_item = Qt::GraphicsRectItem.new
    @room_graphics_scene.addItem(@doors_view_item)
    min_x = 0
    min_y = 0
    max_x = @room.max_layer_width*SCREEN_WIDTH_IN_PIXELS
    max_y = @room.max_layer_height*SCREEN_HEIGHT_IN_PIXELS
    @room.doors.each_with_index do |door, i|
      x = door.x_pos
      y = door.y_pos
      x = -1 if x == 0xFF
      y = -1 if y == 0xFF
      x *= SCREEN_WIDTH_IN_PIXELS
      y *= SCREEN_HEIGHT_IN_PIXELS
      
      min_x = x if x < min_x
      min_y = y if y < min_y
      door_right_x = x + 16*16
      door_bottom_y = y + 12*16
      max_x = door_right_x if door_right_x > max_x
      max_y = door_bottom_y if door_bottom_y > max_y
      
      door_item = DoorItem.new(door, x, y, self)
      door_item.setParentItem(@doors_view_item)
    end
    @room_graphics_scene.setSceneRect(min_x, min_y, max_x-min_x, max_y-min_y)
    
    update_visible_view_items()
  end
  
  def load_layer(layer, tileset, layer_graphics_item)
    layer.tiles.each_with_index do |tile, index_on_level|
      x_on_tileset = tile.index_on_tileset % 16
      y_on_tileset = tile.index_on_tileset / 16
      x_on_level = index_on_level % (layer.width*16)
      y_on_level = index_on_level / (layer.width*16)
      
      tile_gfx = tileset.copy(x_on_tileset*16, y_on_tileset*16, 16, 16)
      
      if tile.horizontal_flip
        tile_gfx = tile_gfx.mirrored(horizontal=true, vertical=false)
      end
      if tile.vertical_flip
        tile_gfx = tile_gfx.mirrored(horizontal=false, vertical=true)
      end
      
      tile_gfx = Qt::Pixmap.from_image(tile_gfx)
      tile_gfx = Qt::GraphicsPixmapItem.new(tile_gfx)
      tile_gfx.setPos(x_on_level*16, y_on_level*16)
      tile_gfx.setParentItem(layer_graphics_item)
    end
  end
  
  def update_visible_view_items
    @entities_view_item.setVisible(@ui.actionEntities.checked)
    @doors_view_item.setVisible(@ui.actionDoors.checked)
    @collision_view_item.setVisible(@ui.actionCollision.checked)
    @layers_view_item.setVisible(@ui.actionLayers.checked)
  end
  
  def load_map()
    @map_graphics_scene.clear()
    
    if GAME == "dos"
      @map = DoSMap.new(@area_index, @sector_index, game.fs)
    else
      @map = Map.new(@area_index, @sector_index, game.fs)
    end
    
    chunky_png_img = @renderer.render_map(@map)
    map_pixmap_item = GraphicsChunkyItem.new(chunky_png_img)
    @map_graphics_scene.addItem(map_pixmap_item)
  end
  
  def open_enemy_dna_dialog
    @enemy_dialog = EnemyEditor.new(self, game.fs)
  end
  
  def open_text_editor
    @text_editor = TextEditor.new(self, game.fs)
  end
  
  def open_sprite_editor
    @sprite_editor = SpriteEditor.new(self, game, @renderer)
  end
    
  def open_item_editor
    @item_editor = ItemEditor.new(self, game.fs)
  end
  
  def open_entity_search
    @entity_search_dialog = EntitySearchDialog.new(self)
  end
  
  def open_map_editor
    @map_editor_dialog = MapEditorDialog.new(self, game.fs, @renderer, @area_index, @sector_index)
  end
  
  def open_entity_editor(entity)
    @entity_editor = EntityEditorDialog.new(self, entity)
  end
  
  def open_settings
    @settings_dialog = SettingsDialog.new(self, @settings)
  end
  
  def load_settings
    @settings_path = "settings.yml"
    if File.exist?(@settings_path)
      @settings = YAML::load_file(@settings_path)
    else
      @settings = {}
    end
  end
  
  def closeEvent(event)
    puts "Close event triggered."
    File.open(@settings_path, "w") do |f|
      f.write(@settings.to_yaml)
    end
  end
  
  def open_in_tiled
    if @room.layers.length == 0
      Qt::MessageBox.warning(self, "Room has no layers", "Cannot edit a room that has no layers.")
      return
    elsif @settings[:tiled_path].nil? || @settings[:tiled_path].empty?
      Qt::MessageBox.warning(self, "Failed to run Tiled", "You must specify where Tiled is installed.")
      return
    elsif !File.file?(@settings[:tiled_path])
      Qt::MessageBox.warning(self, "Failed to run Tiled", "Tiled install path is invalid.")
      return
    end
    folder = "cache/#{GAME}/rooms"
    tmx_path = "#{folder}/#{@room.area_name}/#{@room.filename}.tmx"
    
    @renderer.ensure_tilesets_exist(folder, @room)
    @tiled.create(tmx_path, @room)
    system("start \"#{@settings[:tiled_path]}\" \"#{tmx_path}\"")
  end
  
  def import_from_tiled
    folder = "cache/#{GAME}/rooms"
    tmx_path = "#{folder}/#{@room.area_name}/#{@room.filename}.tmx"
    if !File.exist?(tmx_path) || !File.file?(tmx_path)
      Qt::MessageBox.warning(self, "TMX file doesn't exist", "Can't find the TMX file. You must export to tiled first.")
      return
    end
    
    @tiled.read(tmx_path, @room)
    load_room()
  end
  
  def set_current_room_as_starting_room
    game.set_starting_room(@area_index, @sector_index, @room_index)
  end
  
  def copy_room_pointer_to_clipboad
    $qApp.clipboard.setText("%08X" % @room.room_metadata_ram_pointer)
  end
  
  def save_files
    game.fs.commit_file_changes()
  end
  
  def write_to_rom(launch_emulator = false)
    return if @progress_dialog
    
    @progress_dialog = Qt::ProgressDialog.new
    @progress_dialog.windowTitle = "Building"
    @progress_dialog.labelText = "Writing files to ROM"
    @progress_dialog.maximum = game.fs.files_without_dirs.length
    @progress_dialog.windowModality = Qt::ApplicationModal
    @progress_dialog.windowFlags = Qt::CustomizeWindowHint | Qt::WindowTitleHint
    @progress_dialog.setFixedSize(@progress_dialog.size);
    connect(@progress_dialog, SIGNAL("canceled()"), self, SLOT("cancel_write_to_rom_thread()"))
    @progress_dialog.show
    
    output_rom_path = File.join(game.folder, "built_rom_#{GAME}.nds")
    
    @write_to_rom_thread = Thread.new do
      game.fs.write_to_rom(output_rom_path) do |files_written|
        next unless files_written % 100 == 0 # Only update the UI every 100 files because updating too often is slow.
        
        Qt.execute_in_main_thread do
          @progress_dialog.setValue(files_written) unless @progress_dialog.wasCanceled
        end
      end
      
      Qt.execute_in_main_thread do
        @progress_dialog.setValue(game.fs.files_without_dirs.length) unless @progress_dialog.wasCanceled
        @progress_dialog = nil
        
        if launch_emulator
          if @settings[:emulator_path].nil? || @settings[:emulator_path].empty?
            Qt::MessageBox.warning(self, "Failed to run emulator", "You must specify the emulator path.")
          elsif !File.file?(@settings[:emulator_path])
            Qt::MessageBox.warning(self, "Failed to run emulator", "Emulator path is invalid.")
          else
            system("start \"#{@settings[:emulator_path]}\" \"#{output_rom_path}\"")
          end
        else
          #Qt::MessageBox.information(self, "Done", "All files written to rom.")
        end
      end
    end
  end
  
  def cancel_write_to_rom_thread
    puts "Cancelled."
    @write_to_rom_thread.kill
    @progress_dialog = nil
  end
  
  def build_and_run
    write_to_rom(launch_emulator = true)
  end
end

class DoorItem < Qt::GraphicsRectItem
  BRUSH = Qt::Brush.new(Qt::Color.new(200, 0, 200, 50))
  
  def initialize(door, x, y, window)
    super(x, y, 16*16, 12*16)
    
    self.setBrush(BRUSH)
    @door = door
    @window = window
  end
  
  def mousePressEvent(event)
    if event.button == Qt::RightButton
      @window.change_room_by_metadata(@door.destination_room_metadata_ram_pointer)
    else
      super(event)
    end
  end
end

class ClickableGraphicsScene < Qt::GraphicsScene
  signals "clicked(int, int, const Qt::MouseButton&)"
  signals "moved(int, int, const Qt::MouseButton&)"
  
  def mousePressEvent(event)
    x = event.scenePos().x.to_i
    y = event.scenePos().y.to_i
    return unless (0..width-1).include?(x) && (0..height-1).include?(y)
    emit clicked(x, y, event.buttons)
  end
  
  def mouseMoveEvent(event)
    x = event.scenePos().x.to_i
    y = event.scenePos().y.to_i
    return unless (0..width-1).include?(x) && (0..height-1).include?(y)
    emit moved(x, y, event.buttons)
  end
end

class GraphicsChunkyItem < Qt::GraphicsPixmapItem
  def initialize(chunky_image)
    pixmap = Qt::Pixmap.new
    blob = chunky_image.to_blob
    pixmap.loadFromData(blob, blob.length)
    super(pixmap)
  end
end

class EntityChunkyItem < GraphicsChunkyItem
  def initialize(chunky_image, entity, window)
    super(chunky_image)
    
    @entity = entity
    @window = window
  end
  
  def mousePressEvent(event)
    if event.button == Qt::RightButton
      @window.open_entity_editor(@entity)
    else
      super(event)
    end
  end
end

class EntityRectItem < Qt::GraphicsRectItem
  NOTHING_BRUSH        = Qt::Brush.new(Qt::Color.new(200, 200, 200, 150))
  ENEMY_BRUSH          = Qt::Brush.new(Qt::Color.new(200, 0, 0, 150))
  SPECIAL_OBJECT_BRUSH = Qt::Brush.new(Qt::Color.new(0, 0, 200, 150))
  CANDLE_BRUSH         = Qt::Brush.new(Qt::Color.new(200, 200, 0, 150))
  OTHER_BRUSH          = Qt::Brush.new(Qt::Color.new(200, 0, 200, 150))
  
  def initialize(entity, window)
    super(entity.x_pos-8, entity.y_pos-8, 16, 16)
    
    case entity.type
    when 0
      self.setBrush(NOTHING_BRUSH)
    when 1
      self.setBrush(ENEMY_BRUSH)
    when 2
      self.setBrush(SPECIAL_OBJECT_BRUSH)
    when 3
      self.setBrush(CANDLE_BRUSH)
    else
      self.setBrush(OTHER_BRUSH)
    end
    @entity = entity
    @window = window
  end
  
  def mousePressEvent(event)
    if event.button == Qt::RightButton
      @window.open_entity_editor(@entity)
    else
      super(event)
    end
  end
end
