
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
require_relative 'layers_editor_dialog'
require_relative 'item_pool_editor_dialog'
require_relative 'gfx_editor_dialog'
require_relative 'music_editor_dialog'
require_relative 'tileset_editor_dialog'
require_relative 'player_editor_dialog'

require_relative 'ui_main'

class DSVEdit < Qt::MainWindow
  attr_reader :game
  
  slots "extract_rom_dialog()"
  slots "open_folder_dialog()"
  slots "save_files()"
  slots "edit_layers()"
  slots "open_entity_editor()"
  slots "add_new_layer()"
  slots "add_new_entity()"
  slots "update_visible_view_items()"
  slots "open_enemy_dna_dialog()"
  slots "open_text_editor()"
  slots "open_sprite_editor()"
  slots "open_item_editor()"
  slots "open_gfx_editor()"
  slots "open_music_editor()"
  slots "open_item_pool_editor()"
  slots "open_tileset_editor()"
  slots "open_entity_search()"
  slots "open_map_editor()"
  slots "open_player_editor()"
  slots "open_settings()"
  slots "write_to_rom()"
  slots "build_and_run()"
  slots "open_about()"
  
  slots "cancel_write_to_rom_thread()"
  
  slots "area_index_changed(int)"
  slots "sector_index_changed(int)"
  slots "room_index_changed(int)"
  slots "sector_and_room_indexes_changed(int, int)"
  slots "change_room_by_metadata(int)"
  slots "room_clicked(int, int, const Qt::MouseButton&)"
  slots "change_room_by_map_x_and_y(int, int, const Qt::MouseButton&)"
  slots "open_in_tiled()"
  slots "import_from_tiled()"
  slots "set_current_room_as_starting_room()"
  slots "copy_room_pointer_to_clipboard()"
  slots "toggle_hide_map()"
  
  def initialize
    super()
    @ui = Ui_MainWindow.new
    @ui.setup_ui(self)
    
    @room_graphics_scene = ClickableGraphicsScene.new
    @ui.room_graphics_view.setScene(@room_graphics_scene)
    @ui.room_graphics_view.setDragMode(Qt::GraphicsView::ScrollHandDrag)
    self.setStyleSheet("QGraphicsView { background-color: transparent; }");
    connect(@room_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("room_clicked(int, int, const Qt::MouseButton&)"))
    
    @map_graphics_scene = ClickableGraphicsScene.new
    @map_graphics_scene.setSceneRect(0, 0, 64*4+1, 48*4+1)
    @ui.map_graphics_view.scale(2, 2)
    @ui.map_graphics_view.setScene(@map_graphics_scene)
    connect(@map_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("change_room_by_map_x_and_y(int, int, const Qt::MouseButton&)"))
    
    @tiled = TMXInterface.new
    
    connect(@ui.actionOpen_Folder, SIGNAL("activated()"), self, SLOT("open_folder_dialog()"))
    connect(@ui.actionExtract_ROM, SIGNAL("activated()"), self, SLOT("extract_rom_dialog()"))
    connect(@ui.actionSave, SIGNAL("activated()"), self, SLOT("save_files()"))
    connect(@ui.actionEdit_Layers, SIGNAL("activated()"), self, SLOT("edit_layers()"))
    connect(@ui.actionEdit_Entities, SIGNAL("activated()"), self, SLOT("open_entity_editor()"))
    connect(@ui.actionAdd_New_Layer, SIGNAL("activated()"), self, SLOT("add_new_layer()"))
    connect(@ui.actionAdd_Entity, SIGNAL("activated()"), self, SLOT("add_new_entity()"))
    connect(@ui.actionEntities, SIGNAL("activated()"), self, SLOT("update_visible_view_items()"))
    connect(@ui.actionDoors, SIGNAL("activated()"), self, SLOT("update_visible_view_items()"))
    connect(@ui.actionCollision, SIGNAL("activated()"), self, SLOT("update_visible_view_items()"))
    connect(@ui.actionLayers, SIGNAL("activated()"), self, SLOT("update_visible_view_items()"))
    connect(@ui.actionEnemy_Editor, SIGNAL("activated()"), self, SLOT("open_enemy_dna_dialog()"))
    connect(@ui.actionText_Editor, SIGNAL("activated()"), self, SLOT("open_text_editor()"))
    connect(@ui.actionSprite_Editor, SIGNAL("activated()"), self, SLOT("open_sprite_editor()"))
    connect(@ui.actionItem_Editor, SIGNAL("activated()"), self, SLOT("open_item_editor()"))
    connect(@ui.actionGFX_Editor, SIGNAL("activated()"), self, SLOT("open_gfx_editor()"))
    connect(@ui.actionMusic_Editor, SIGNAL("activated()"), self, SLOT("open_music_editor()"))
    connect(@ui.actionItem_Pool_Editor, SIGNAL("activated()"), self, SLOT("open_item_pool_editor()"))
    connect(@ui.actionTileset_Editor, SIGNAL("activated()"), self, SLOT("open_tileset_editor()"))
    connect(@ui.actionMap_Editor, SIGNAL("activated()"), self, SLOT("open_map_editor()"))
    connect(@ui.actionPlayer_Editor, SIGNAL("activated()"), self, SLOT("open_player_editor()"))
    connect(@ui.actionEntity_Search, SIGNAL("activated()"), self, SLOT("open_entity_search()"))
    connect(@ui.actionSettings, SIGNAL("activated()"), self, SLOT("open_settings()"))
    connect(@ui.actionBuild, SIGNAL("activated()"), self, SLOT("write_to_rom()"))
    connect(@ui.actionBuild_and_Run, SIGNAL("activated()"), self, SLOT("build_and_run()"))
    connect(@ui.actionAbout, SIGNAL("activated()"), self, SLOT("open_about()"))
    
    connect(@ui.area, SIGNAL("activated(int)"), self, SLOT("area_index_changed(int)"))
    connect(@ui.sector, SIGNAL("activated(int)"), self, SLOT("sector_index_changed(int)"))
    connect(@ui.room, SIGNAL("activated(int)"), self, SLOT("room_index_changed(int)"))
    connect(@ui.tiled_export, SIGNAL("released()"), self, SLOT("open_in_tiled()"))
    connect(@ui.tiled_import, SIGNAL("released()"), self, SLOT("import_from_tiled()"))
    connect(@ui.set_as_starting_room, SIGNAL("released()"), self, SLOT("set_current_room_as_starting_room()"))
    connect(@ui.copy_room_pointer, SIGNAL("released()"), self, SLOT("copy_room_pointer_to_clipboard()"))
    connect(@ui.edit_map, SIGNAL("released()"), self, SLOT("open_map_editor()"))
    connect(@ui.toggle_hide_map, SIGNAL("released()"), self, SLOT("toggle_hide_map()"))
    
    load_settings()
    
    if @settings[:hide_map]
      toggle_hide_map()
    end
    
    self.setWindowState(Qt::WindowMaximized)
    self.setWindowTitle("DSVania Editor #{DSVEDIT_VERSION}")
    
    disable_menu_actions()
    
    clear_cache()
    
    self.show()
    
    if @settings[:last_used_folder] && File.directory?(@settings[:last_used_folder])
      open_folder(@settings[:last_used_folder])
    end
  end
  
  def disable_menu_actions
    @ui.actionSave.setEnabled(false);
    @ui.actionEdit_Layers.setEnabled(false);
    @ui.actionEdit_Entities.setEnabled(false);
    @ui.actionAdd_New_Layer.setEnabled(false);
    @ui.actionEntities.setEnabled(false);
    @ui.actionDoors.setEnabled(false);
    @ui.actionCollision.setEnabled(false);
    @ui.actionLayers.setEnabled(false);
    @ui.actionEnemy_Editor.setEnabled(false);
    @ui.actionText_Editor.setEnabled(false);
    @ui.actionSprite_Editor.setEnabled(false);
    @ui.actionItem_Editor.setEnabled(false);
    @ui.actionGFX_Editor.setEnabled(false);
    @ui.actionMusic_Editor.setEnabled(false);
    @ui.actionItem_Pool_Editor.setEnabled(false);
    @ui.actionTileset_Editor.setEnabled(false);
    @ui.actionMap_Editor.setEnabled(false);
    @ui.actionPlayer_Editor.setEnabled(false);
    @ui.actionEntity_Search.setEnabled(false);
    @ui.actionBuild.setEnabled(false);
    @ui.actionBuild_and_Run.setEnabled(false);
  end
  
  def enable_menu_actions
    @ui.actionSave.setEnabled(true);
    @ui.actionEdit_Layers.setEnabled(true);
    @ui.actionEdit_Entities.setEnabled(true);
    @ui.actionAdd_New_Layer.setEnabled(true);
    @ui.actionEntities.setEnabled(true);
    @ui.actionDoors.setEnabled(true);
    @ui.actionCollision.setEnabled(true);
    @ui.actionLayers.setEnabled(true);
    @ui.actionEnemy_Editor.setEnabled(true);
    @ui.actionText_Editor.setEnabled(true);
    @ui.actionSprite_Editor.setEnabled(true);
    @ui.actionItem_Editor.setEnabled(true);
    @ui.actionGFX_Editor.setEnabled(true);
    @ui.actionMusic_Editor.setEnabled(true);
    @ui.actionItem_Pool_Editor.setEnabled(true);
    @ui.actionTileset_Editor.setEnabled(true);
    @ui.actionMap_Editor.setEnabled(true);
    @ui.actionPlayer_Editor.setEnabled(true);
    @ui.actionEntity_Search.setEnabled(true);
    @ui.actionBuild.setEnabled(true);
    @ui.actionBuild_and_Run.setEnabled(true);
  end
  
  def close_open_dialogs
    @edit_layers_dialog.close() if @edit_layers_dialog
    @enemy_dialog.close() if @enemy_dialog
    @text_editor.close() if @text_editor
    @sprite_editor.close() if @sprite_editor
    @gfx_editor.close() if @gfx_editor
    @music_editor.close() if @music_editor
    @item_editor.close() if @item_editor
    @item_pool_editor.close() if @item_pool_editor
    @tileset_editor.close() if @tileset_editor
    @map_editor_dialog.close() if @map_editor_dialog
    @player_editor_dialog.close() if @player_editor_dialog
    @entity_search_dialog.close() if @entity_search_dialog
    @entity_editor.close() if @entity_editor
    @settings_dialog.close() if @settings_dialog
  end
  
  def clear_cache
    Dir.glob("./cache/**/*.{png,tmx}").each do |file_path|
      if File.exist?(file_path)
        FileUtils.rm(file_path)
      end
    end
  rescue StandardError => e
    # do nothing
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
    cancelled = confirm_discard_changes()
    return if cancelled
    
    cancelled = confirm_overwrite_folder(rom_path)
    return if cancelled
    
    close_open_dialogs()
    
    game = Game.new
    game.initialize_from_rom(rom_path, extract_to_hard_drive = true)
    @game = game
    @renderer = Renderer.new(game.fs)
    
    enable_menu_actions()
    
    initialize_dropdowns()
    
    @settings[:last_used_folder] = game.folder
  rescue Game::InvalidFileError, NDSFileSystem::InvalidFileError
    Qt::MessageBox.warning(self, "Invalid file", "Selected ROM file is not a DSVania or is not the North American version.")
  end
  
  def open_folder(folder_path)
    cancelled = confirm_discard_changes()
    return if cancelled
    
    close_open_dialogs()
    
    game = Game.new
    game.initialize_from_folder(folder_path)
    @game = game
    @renderer = Renderer.new(game.fs)
    
    enable_menu_actions()
    
    initialize_dropdowns()
    
    @settings[:last_used_folder] = folder_path
  rescue Game::InvalidFileError, NDSFileSystem::InvalidFileError
    Qt::MessageBox.warning(self, "Invalid file", "Selected folder is not a DSVania.")
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
    
    update_room_position_indicator()
    
    load_room()
  end
  
  def update_room_position_indicator
    @position_indicator.setPos(@room.room_xpos_on_map*4 + 2.25, @room.room_ypos_on_map*4 + 2.25)
    if @room.layers.length > 0
      @position_indicator.setRect(-2, -2, 4*@room.main_layer_width, 4*@room.main_layer_height)
    else
      @position_indicator.setRect(-2, -2, 4, 4)
    end
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
  rescue Game::RoomFindError => e
    Qt::MessageBox.warning(self,
      "Could not find room",
      "Could not find any room with pointer %08X" % room_metadata_ram_pointer
    )
  end
  
  def room_clicked(x, y, button)
    return unless button == Qt::RightButton
    
    item = @room_graphics_scene.itemAt(x, y)
    if item && (item.is_a?(EntityChunkyItem) || item.is_a?(EntityRectItem))
      open_entity_editor(item.entity)
    elsif item && item.is_a?(DoorItem)
      change_room_by_metadata(item.door.destination_room_metadata_ram_pointer)
    end
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
    @room_graphics_scene = ClickableGraphicsScene.new
    @ui.room_graphics_view.setScene(@room_graphics_scene)
    connect(@room_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("room_clicked(int, int, const Qt::MouseButton&)"))
    
    @layers_view_item = Qt::GraphicsRectItem.new
    @room_graphics_scene.addItem(@layers_view_item)
    @room.sector.load_necessary_overlay()
    @renderer.ensure_tilesets_exist("cache/#{GAME}/rooms/", @room)
    @room.layers.each do |layer|
      tileset_filename = "cache/#{GAME}/rooms/#{@room.area_name}/Tilesets/#{layer.tileset_filename}.png"
      tileset = Qt::Pixmap.new(tileset_filename)
      layer_item = Qt::GraphicsRectItem.new
      layer_item.setZValue(-layer.z_index)
      layer_item.setOpacity(layer.opacity/31.0)
      layer_item.setParentItem(@layers_view_item)
      
      load_layer(layer, tileset, layer_item)
    end
    
    load_room_collision_tileset()
    
    @entities_view_item = Qt::GraphicsRectItem.new
    @room_graphics_scene.addItem(@entities_view_item)
    @room.entities.each do |entity|
      add_graphics_item_for_entity(entity)
    end
    
    @doors_view_item = Qt::GraphicsRectItem.new
    @room_graphics_scene.addItem(@doors_view_item)
    @room.doors.each_with_index do |door, i|
      x = door.x_pos
      y = door.y_pos
      x = -1 if x == 0xFF
      y = -1 if y == 0xFF
      x *= SCREEN_WIDTH_IN_PIXELS
      y *= SCREEN_HEIGHT_IN_PIXELS
      
      door_item = DoorItem.new(door, x, y, self)
      door_item.setParentItem(@doors_view_item)
    end
    
    update_room_bounding_rect()
    
    update_visible_view_items()
  end
  
  def update_room_bounding_rect
    @room_graphics_scene.setSceneRect(@room_graphics_scene.itemsBoundingRect)
  end
  
  def load_room_collision_tileset
    @collision_view_item = Qt::GraphicsRectItem.new
    @room_graphics_scene.addItem(@collision_view_item)
    if @room.layers.length > 0
      @renderer.ensure_tilesets_exist("cache/#{GAME}/rooms/", @room, collision=true)
      tileset_filename = "cache/#{GAME}/rooms/#{@room.area_name}/Tilesets/#{@room.layers.first.tileset_filename}_collision.png"
      tileset = Qt::Pixmap.new(tileset_filename)
      layer = @room.layers.first
      load_layer(layer, tileset, @collision_view_item)
    end
  rescue StandardError => e
    Qt::MessageBox.warning(self,
      "Collision tileset loading failed",
      "Failed to load collision tileset.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
    )
  end
  
  def add_graphics_item_for_entity(entity)
    if entity.is_enemy?
      enemy_id = entity.subtype
      sprite_info = EnemyDNA.new(enemy_id, @game.fs).extract_gfx_and_palette_and_sprite_from_init_ai
      add_sprite_item_for_entity(entity, sprite_info, BEST_SPRITE_FRAME_FOR_ENEMY[enemy_id])
    elsif GAME == "dos" && entity.is_special_object? && entity.subtype == 0x01 && entity.var_a == 0 # soul candle
      pointer = OTHER_SPRITES.find{|spr| spr[:desc] == "Destructibles 0"}[:pointer]
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(pointer, game.fs, nil, {})
      add_sprite_item_for_entity(entity, sprite_info, 0)
    elsif GAME == "ooe" && entity.is_special_object? && entity.subtype == 0x02 && entity.var_a == 0 # glyph statue
      pointer = OTHER_SPRITES.find{|spr| spr[:desc] == "Glyph statue"}[:pointer]
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(pointer, game.fs, nil, {})
      add_sprite_item_for_entity(entity, sprite_info, 0)
    elsif entity.is_special_object?
      special_object_id = entity.subtype
      sprite_info = SpecialObjectType.new(special_object_id, game.fs).extract_gfx_and_palette_and_sprite_from_create_code
      add_sprite_item_for_entity(entity, sprite_info, BEST_SPRITE_FRAME_FOR_SPECIAL_OBJECT[special_object_id])
    elsif entity.is_candle?
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(OTHER_SPRITES[0][:pointer], game.fs, OTHER_SPRITES[0][:overlay], OTHER_SPRITES[0])
      add_sprite_item_for_entity(entity, sprite_info, 0xDB)
    elsif entity.is_magic_seal?
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(OTHER_SPRITES[0][:pointer], game.fs, OTHER_SPRITES[0][:overlay], OTHER_SPRITES[0])
      add_sprite_item_for_entity(entity, sprite_info, 0xCE)
    elsif entity.is_item? || entity.is_hidden_item?
      if GAME == "ooe"
        item_global_id = entity.var_b - 1
        chunky_image = @renderer.render_icon_by_global_id(item_global_id)
        
        if chunky_image.nil?
          graphics_item = EntityRectItem.new(entity, self)
          graphics_item.setParentItem(@entities_view_item)
          return
        end
        
        graphics_item = EntityChunkyItem.new(chunky_image, entity, self)
        graphics_item.setOffset(-8, -16)
        graphics_item.setPos(entity.x_pos, entity.y_pos)
        graphics_item.setParentItem(@entities_view_item)
      else
        item_type = entity.subtype
        item_id = entity.var_b
        chunky_image = @renderer.render_icon_by_item_type(item_type-2, item_id)
        
        if chunky_image.nil?
          graphics_item = EntityRectItem.new(entity, self)
          graphics_item.setParentItem(@entities_view_item)
          return
        end
        
        graphics_item = EntityChunkyItem.new(chunky_image, entity, self)
        graphics_item.setOffset(-8, -16)
        graphics_item.setPos(entity.x_pos, entity.y_pos)
        graphics_item.setParentItem(@entities_view_item)
      end
    elsif entity.is_heart? || entity.is_hidden_heart?
      case GAME
      when "dos"
        frame_id = 0xDA
      when "por", "ooe"
        frame_id = 0x11D
      end
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(OTHER_SPRITES[0][:pointer], game.fs, OTHER_SPRITES[0][:overlay], OTHER_SPRITES[0])
      add_sprite_item_for_entity(entity, sprite_info, frame_id)
    elsif entity.is_money_bag? || entity.is_hidden_money_bag?
      sprite_info = SpriteInfo.extract_gfx_and_palette_and_sprite_from_create_code(OTHER_SPRITES[0][:pointer], game.fs, OTHER_SPRITES[0][:overlay], OTHER_SPRITES[0])
      add_sprite_item_for_entity(entity, sprite_info, 0xEF)
    elsif (entity.is_skill? || entity.is_hidden_skill?) && GAME == "por"
      case entity.var_b
      when 0x00..0x26
        chunky_image = @renderer.render_icon(64 + 0, 0)
      when 0x27..0x50
        chunky_image = @renderer.render_icon(64 + 2, 2)
      when 0x51..0x5B
        chunky_image = @renderer.render_icon(64 + 1, 0)
      else
        chunky_image = @renderer.render_icon(64 + 3, 0)
      end
      
      if chunky_image.nil?
        graphics_item = EntityRectItem.new(entity, self)
        graphics_item.setParentItem(@entities_view_item)
        return
      end
      
      graphics_item = EntityChunkyItem.new(chunky_image, entity, self)
      graphics_item.setOffset(-8, -16)
      graphics_item.setPos(entity.x_pos, entity.y_pos)
      graphics_item.setParentItem(@entities_view_item)
    elsif (entity.is_glyph? || entity.is_hidden_glyph?) && entity.var_b > 0
      glyph_id = entity.var_b - 1
      if glyph_id <= 0x36
        chunky_image = @renderer.render_icon_by_item_type(0, glyph_id, mode=:glyph)
      else
        chunky_image = @renderer.render_icon_by_item_type(1, glyph_id-0x37, mode=:glyph)
      end
      
      if chunky_image.nil?
        graphics_item = EntityRectItem.new(entity, self)
        graphics_item.setParentItem(@entities_view_item)
        return
      end
      
      graphics_item = EntityChunkyItem.new(chunky_image, entity, self)
      graphics_item.setOffset(-16, -16)
      graphics_item.setPos(entity.x_pos, entity.y_pos)
      graphics_item.setParentItem(@entities_view_item)
    else
      graphics_item = EntityRectItem.new(entity, self)
      graphics_item.setParentItem(@entities_view_item)
    end
  rescue StandardError => e
    graphics_item = EntityRectItem.new(entity, self)
    graphics_item.setParentItem(@entities_view_item)
  end
  
  def add_sprite_item_for_entity(entity, sprite_info, frame_to_render)
    if frame_to_render == -1
      # Don't show this entity's sprite in the editor.
      graphics_item = EntityRectItem.new(entity, self)
      graphics_item.setParentItem(@entities_view_item)
      return
    end
    
    frame_to_render ||= 0
    
    sprite_filename = @renderer.ensure_sprite_exists("cache/#{GAME}/sprites/", sprite_info, frame_to_render)
    chunky_frame = ChunkyPNG::Image.from_file(sprite_filename)
    
    graphics_item = EntityChunkyItem.new(chunky_frame, entity, self)
    
    graphics_item.setOffset(sprite_info.sprite.min_x, sprite_info.sprite.min_y)
    graphics_item.setPos(entity.x_pos, entity.y_pos)
    graphics_item.setParentItem(@entities_view_item)
  end
  
  def load_layer(layer, tileset, layer_graphics_item)
    layer.tiles.each_with_index do |tile, index_on_level|
      next if tile.index_on_tileset == 0
      
      x_on_tileset = tile.index_on_tileset % 16
      y_on_tileset = tile.index_on_tileset / 16
      x_on_level = index_on_level % (layer.width*16)
      y_on_level = index_on_level / (layer.width*16)
      
      if (0..tileset.width-1).include?(x_on_tileset*16) && (0..tileset.height-1).include?(y_on_tileset*16)
        tile_gfx = tileset.copy(x_on_tileset*16, y_on_tileset*16, 16, 16)
      else
        # Coordinates are outside the bounds of the tileset, put a red tile there instead.
        tile_gfx = Qt::Pixmap.new(16, 16)
        tile_gfx.fill(Qt::Color.new(Qt::red))
      end
      
      tile_item = Qt::GraphicsPixmapItem.new(tile_gfx)
      tile_item.setPos(x_on_level*16, y_on_level*16)
      if tile.horizontal_flip && tile.vertical_flip
        tile_item.setTransform(Qt::Transform::fromScale(-1, -1))
        tile_item.x += 16
        tile_item.y += 16
      elsif tile.horizontal_flip
        tile_item.setTransform(Qt::Transform::fromScale(-1, 1))
        tile_item.x += 16
      elsif tile.vertical_flip
        tile_item.setTransform(Qt::Transform::fromScale(1, -1))
        tile_item.y += 16
      end
      tile_item.setParentItem(layer_graphics_item)
    end
  end
  
  def edit_layers
    return if @edit_layers_dialog && @edit_layers_dialog.visible?
    @edit_layers_dialog = LayersEditorDialog.new(self, @room, @renderer)
  end
  
  def add_new_layer
    if @room.layers.size >= 4
      Qt::MessageBox.warning(self, "Can't add layer", "Can't add any more layers to this room, it already has the maximum of 4 layers.")
      return
    end
    
    @room.add_new_layer()
    load_room()
    
    Qt::MessageBox.warning(self, "Layer added", "Successfully added a new layer to room %08X." % @room.room_metadata_ram_pointer)
  rescue NDSFileSystem::FileExpandError => e
    Qt::MessageBox.warning(self, "Cannot add layer", e.message)
  end
  
  def add_new_entity
    entity = Entity.new(@room, game.fs)
    scene_pos = @ui.room_graphics_view.mapToScene(@ui.room_graphics_view.mapFromGlobal(Qt::Cursor.pos))
    if @room_graphics_scene.sceneRect.contains(scene_pos)
      entity.x_pos = scene_pos.x
      entity.y_pos = scene_pos.y
    end
    entity.type = 1
    @room.entities << entity
    @room.write_entities_to_rom()
    
    load_room()
    
    open_entity_editor(entity)
  rescue NDSFileSystem::FileExpandError => e
    @room.read_from_rom() # Reload room to get rid of the failed changes.
    load_room()
    Qt::MessageBox.warning(self, "Cannot add entity", e.message)
  rescue Room::WriteError => e
    @room.read_from_rom() # Reload room to get rid of the failed changes.
    load_room()
    Qt::MessageBox.warning(self, "Cannot add entity", e.message)
  end
  
  def update_visible_view_items
    @entities_view_item.setVisible(@ui.actionEntities.checked)
    @doors_view_item.setVisible(@ui.actionDoors.checked)
    @collision_view_item.setVisible(@ui.actionCollision.checked)
    @layers_view_item.setVisible(@ui.actionLayers.checked)
  end
  
  def load_map()
    @map_graphics_scene.clear()
    
    @map = game.get_map(@area_index, @sector_index)
    
    chunky_png_img = @renderer.render_map(@map)
    map_pixmap_item = GraphicsChunkyItem.new(chunky_png_img)
    @map_graphics_scene.addItem(map_pixmap_item)
    
    @position_indicator = @map_graphics_scene.addRect(-2, -2, 4, 4, Qt::Pen.new(Qt::NoPen), Qt::Brush.new(Qt::Color.new(255, 255, 128, 128)))
    if @room
      update_room_position_indicator()
    end
  end
  
  def open_enemy_dna_dialog
    return if @enemy_dialog && @enemy_dialog.visible?
    @enemy_dialog = EnemyEditor.new(self, game.fs)
  end
  
  def open_text_editor
    return if @text_editor && @text_editor.visible?
    @text_editor = TextEditor.new(self, game.fs)
  end
  
  def open_sprite_editor
    return if @sprite_editor && @sprite_editor.visible?
    @sprite_editor = SpriteEditor.new(self, game, @renderer)
  end
    
  def open_item_editor
    return if @item_editor && @item_editor.visible?
    @item_editor = ItemEditor.new(self, game.fs)
  end
  
  def open_gfx_editor
    return if @gfx_editor && @gfx_editor.visible?
    @gfx_editor = GfxEditorDialog.new(self, game.fs, @renderer)
  end
  
  def open_music_editor
    return if @music_editor && @music_editor.visible?
    @music_editor = MusicEditor.new(self, game)
  end
  
  def open_item_pool_editor
    return if @item_pool_editor && @item_pool_editor.visible?
    if GAME == "ooe"
      @item_pool_editor = ItemPoolEditor.new(self, game)
    else
      Qt::MessageBox.warning(self, "Can't edit item pools", "DoS and PoR have no random chest item pools to edit.")
    end
  end
  
  def open_tileset_editor
    return if @tileset_editor && @tileset_editor.visible?
    @tileset_editor = TilesetEditorDialog.new(self, game.fs, @renderer, @room)
  end
  
  def open_entity_search
    return if @entity_search_dialog && @entity_search_dialog.visible?
    @entity_search_dialog = EntitySearchDialog.new(self)
  end
  
  def open_map_editor
    return if @map_editor_dialog && @map_editor_dialog.visible?
    @map_editor_dialog = MapEditorDialog.new(self, game, @renderer, @area_index, @sector_index)
  end
  
  def open_player_editor
    return if @player_editor_dialog && @player_editor_dialog.visible?
    @player_editor_dialog = PlayerEditor.new(self, game.fs)
  end
  
  def open_entity_editor(entity = nil)
    return if @entity_editor && @entity_editor.visible?
    if @room.entities.empty?
      Qt::MessageBox.warning(self, "No entities to edit", "This room has no entities.\nYou can add one by going to Edit -> Add Entity or pressing A.")
      return
    end
    @entity_editor = EntityEditorDialog.new(self, @room.entities, entity)
  end
  
  def open_settings
    return if @settings_dialog && @settings_dialog.visible?
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
  
  def save_settings
    File.open(@settings_path, "w") do |f|
      f.write(@settings.to_yaml)
    end
  end
  
  def closeEvent(event)
    cancelled = confirm_discard_changes()
    if cancelled
      event.ignore()
      return
    end
    
    puts "Close event triggered."
    save_settings()
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
  rescue NDSFileSystem::FileExpandError => e
    @room.read_from_rom() # Reload room to get rid of the failed changes.
    load_room()
    Qt::MessageBox.warning(self, "Cannot add layer", e.message)
  rescue TMXInterface::ImportError => e
    @room.read_from_rom() # Reload room to get rid of the failed changes.
    load_room()
    Qt::MessageBox.warning(self, "Error importing from Tiled", e.message)
  end
  
  def set_current_room_as_starting_room
    game.set_starting_room(@area_index, @sector_index, @room_index)
  end
  
  def copy_room_pointer_to_clipboard
    $qApp.clipboard.setText("%08X" % @room.room_metadata_ram_pointer)
  end
  
  def toggle_hide_map
    if !@ui.map_graphics_view.isHidden
      @ui.map_graphics_view.hide()
      @ui.toggle_hide_map.text = "Show map"
      @settings[:hide_map] = true
    else
      @ui.map_graphics_view.show()
      @ui.toggle_hide_map.text = "Hide map"
      @settings[:hide_map] = false
    end
  end
  
  def save_files
    game.fs.commit_file_changes()
  end
  
  def confirm_discard_changes
    if game && game.fs.has_uncommitted_files?
      response = Qt::MessageBox.question(self, "Save changes", "There are files with unsaved changes. Save them now?",
        Qt::MessageBox::Cancel | Qt::MessageBox::No | Qt::MessageBox::Yes, Qt::MessageBox::Cancel)
      if response == Qt::MessageBox::Cancel
        return true
      elsif response == Qt::MessageBox::Yes
        save_files()
      end
    end
    return false
  end
  
  def confirm_overwrite_folder(rom_path)
    folder = File.dirname(rom_path)
    rom_name = File.basename(rom_path, ".*")
    folder = File.join(folder, "Extracted files #{rom_name}")
    if File.directory?(folder)
      response = Qt::MessageBox.question(self, "Confirm overwrite", "Folder \"#{File.basename(folder)}\" already exists.\nAre you sure you want to overwrite the files in this folder?",
        Qt::MessageBox::No | Qt::MessageBox::Yes, Qt::MessageBox::No)
      if response == Qt::MessageBox::No
        return true
      end
    end
    return false
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
  
  def open_about
    @about_dialog = Qt::MessageBox::about(self, "DSVania Editor", "DSVania Editor Version #{DSVEDIT_VERSION}\n\nCreated by LagoLunatic\n\nSource code:\nhttps://github.com/LagoLunatic/DSVEdit\n\nReport issues here:\nhttps://github.com/LagoLunatic/DSVEdit/issues")
  end
  
  def inspect
    # When an error occurs, Ruby tries to call inspect on the object causing the error and print that.
    # That includes calling inspect on all of the object's instance variables recursively. This takes a long time.
    # We define inspect as just to_s so it skips recursively examining every object in the whole program and errors don't take so long.
    to_s
  end
end

class DoorItem < Qt::GraphicsRectItem
  BRUSH = Qt::Brush.new(Qt::Color.new(200, 0, 200, 50))
  
  attr_reader :door
  
  def initialize(door, x, y, main_window)
    super(0, 0, 16*16, 12*16)
    setPos(x, y)
    
    @main_window = main_window
    @door = door
    
    self.setBrush(BRUSH)
    
    #setFlag(Qt::GraphicsItem::ItemIsMovable)
    #setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges)
  end
  
  def itemChange(change, value)
    if change == ItemPositionChange && scene()
      new_pos = value.toPointF()
      x = (new_pos.x / SCREEN_WIDTH_IN_PIXELS).round
      y = (new_pos.y / SCREEN_HEIGHT_IN_PIXELS).round
      x = [x, 0x7F].min
      x = [x, -1].max
      y = [y, 0x7F].min
      y = [y, -1].max
      new_pos.setX(x*SCREEN_WIDTH_IN_PIXELS)
      new_pos.setY(y*SCREEN_HEIGHT_IN_PIXELS)
      
      @door.x_pos = x
      @door.y_pos = y
      @door.write_to_rom()
      
      return super(change, Qt::Variant.new(new_pos))
    end
    
    return super(change, value)
  end

  def mouseReleaseEvent(event)
    @main_window.update_room_bounding_rect()
    super(event)
  end
end

class ClickableGraphicsScene < Qt::GraphicsScene
  signals "clicked(int, int, const Qt::MouseButton&)"
  signals "moved(int, int, const Qt::MouseButton&)"
  signals "released(int, int, const Qt::MouseButton&)"
  
  def mousePressEvent(event)
    x = event.scenePos().x.to_i
    y = event.scenePos().y.to_i
    emit clicked(x, y, event.buttons)
    
    super(event)
  end
  
  def mouseMoveEvent(event)
    x = event.scenePos().x.to_i
    y = event.scenePos().y.to_i
    emit moved(x, y, event.buttons)
    
    super(event)
  end
  
  def mouseReleaseEvent(event)
    x = event.scenePos().x.to_i
    y = event.scenePos().y.to_i
    emit released(x, y, event.buttons)
    
    super(event)
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
  attr_reader :entity
  
  def initialize(chunky_image, entity, main_window)
    super(chunky_image)
    
    @main_window = main_window
    @entity = entity
    
    #setFlag(Qt::GraphicsItem::ItemIsMovable)
    #setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges)
  end
  
  def itemChange(change, value)
    if change == ItemPositionChange && scene()
      new_pos = value.toPointF()
      x = new_pos.x
      y = new_pos.y
      
      if $qApp.keyboardModifiers & Qt::ControlModifier == 0
        x = (x / 16).round * 16
        y = (y / 16).round * 16
        new_pos.setX(x)
        new_pos.setY(y)
      end
      
      @entity.x_pos = x
      @entity.y_pos = y
      @entity.write_to_rom()
      
      return super(change, Qt::Variant.new(new_pos))
    end
    
    return super(change, value)
  end

  def mouseReleaseEvent(event)
    @main_window.update_room_bounding_rect()
    super(event)
  end
end

class EntityRectItem < Qt::GraphicsRectItem
  NOTHING_BRUSH        = Qt::Brush.new(Qt::Color.new(200, 200, 200, 150))
  ENEMY_BRUSH          = Qt::Brush.new(Qt::Color.new(200, 0, 0, 150))
  SPECIAL_OBJECT_BRUSH = Qt::Brush.new(Qt::Color.new(0, 0, 200, 150))
  CANDLE_BRUSH         = Qt::Brush.new(Qt::Color.new(200, 200, 0, 150))
  OTHER_BRUSH          = Qt::Brush.new(Qt::Color.new(200, 0, 200, 150))
  
  attr_reader :entity
  
  def initialize(entity, main_window)
    super(-8, -8, 16, 16)
    setPos(entity.x_pos, entity.y_pos)
    
    @main_window = main_window
    
    #setFlag(Qt::GraphicsItem::ItemIsMovable)
    #setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges)
    
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
  end
  
  def itemChange(change, value)
    if change == ItemPositionChange && scene()
      new_pos = value.toPointF()
      x = new_pos.x
      y = new_pos.y
      
      if $qApp.keyboardModifiers & Qt::ControlModifier == 0
        x = (x / 16).round * 16
        y = (y / 16).round * 16
        new_pos.setX(x)
        new_pos.setY(y)
      end
      
      @entity.x_pos = x
      @entity.y_pos = y
      @entity.write_to_rom()
      
      return super(change, Qt::Variant.new(new_pos))
    end
    
    return super(change, value)
  end

  def mouseReleaseEvent(event)
    @main_window.update_room_bounding_rect()
    super(event)
  end
end
