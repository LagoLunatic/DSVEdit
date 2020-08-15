
require_relative 'clickable_graphics_scene'
require_relative 'room_view'
require_relative 'custom_graphics_items'
require_relative 'layer_item'
require_relative 'entity_layer_item'

require_relative 'enemy_editor_dialog'
require_relative 'text_editor_dialog'
require_relative 'settings_dialog'
require_relative 'sprite_editor_dialog'
require_relative 'item_editor_dialog'
require_relative 'entity_search_dialog'
require_relative 'address_converter_dialog'
require_relative 'save_file_fixer_dialog'
require_relative 'icon_chooser_dialog'
require_relative 'map_editor_dialog'
require_relative 'entity_editor_dialog'
require_relative 'skeleton_editor_dialog'
require_relative 'room_editor_dialog'
require_relative 'layers_editor_dialog'
require_relative 'item_pool_editor_dialog'
require_relative 'gfx_editor_dialog'
require_relative 'music_editor_dialog'
require_relative 'tileset_editor_dialog'
require_relative 'player_editor_dialog'
require_relative 'special_object_editor_dialog'
require_relative 'weapon_synth_editor_dialog'
require_relative 'shop_editor_dialog'
require_relative 'quest_editor_dialog'
require_relative 'tileset_chooser_dialog'
require_relative 'door_editor_dialog'
require_relative 'magic_seal_editor_dialog'
require_relative 'player_state_anims_editor_dialog'
require_relative 'armips_patcher_dialog'
require_relative 'color_effects_editor_dialog'
require_relative 'menu_editor_dialog'

require_relative 'ui_main'

NO_FREE_SPACE_MESSAGE = "Refer to the \"Adding a free space overlay\" section of the README for an explanation of how to create free space that can be used by DSVEdit."

class DSVEdit < Qt::MainWindow
  attr_reader :game,
              :tiled
  
  attr_accessor :settings
  
  slots "extract_rom_dialog()"
  slots "open_folder_dialog()"
  slots "save_files()"
  
  slots "files_changed_on_hard_drive(QString)"
  
  slots "edit_room_data()"
  slots "edit_layers()"
  slots "open_entity_editor()"
  slots "open_door_editor()"
  slots "add_new_entity()"
  slots "add_new_door()"
  slots "add_new_room()"
  slots "clear_room_contents()"
  
  slots "update_visible_view_items()"
  
  slots "open_enemy_dna_dialog()"
  slots "open_text_editor()"
  slots "open_sprite_editor()"
  slots "open_item_editor()"
  slots "open_gfx_editor()"
  slots "open_music_editor()"
  slots "open_item_pool_editor()"
  slots "open_tileset_editor()"
  slots "open_menu_editor()"
  slots "open_entity_search()"
  slots "open_address_converter()"
  slots "open_save_file_fixer()"
  slots "open_map_editor()"
  slots "open_player_editor()"
  slots "open_player_state_anims_editor()"
  slots "open_special_object_editor()"
  slots "open_weapon_synth_editor()"
  slots "open_shop_editor()"
  slots "open_quest_editor()"
  slots "open_magic_seal_editor()"
  slots "open_armips_patcher()"
  slots "add_new_overlay()"
  slots "open_settings()"
  
  slots "write_to_rom()"
  slots "build_and_run()"
  slots "build_and_test()"
  
  slots "open_about()"
  
  slots "cancel_write_to_rom_thread()"
  
  slots "area_index_changed(int)"
  slots "sector_index_changed(int)"
  slots "room_index_changed(int)"
  slots "room_state_index_changed(int)"
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
    @ui.room_graphics_view.setFocus()
    connect(@room_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("room_clicked(int, int, const Qt::MouseButton&)"))
    
    @map_graphics_scene = ClickableGraphicsScene.new
    @map_graphics_scene.setSceneRect(0, 0, 64*4+1, 48*4+1)
    @ui.map_graphics_view.scale(2, 2)
    @ui.map_graphics_view.setScene(@map_graphics_scene)
    @map_graphics_scene.setBackgroundBrush(MapEditorDialog::BACKGROUND_BRUSH)
    connect(@map_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("change_room_by_map_x_and_y(int, int, const Qt::MouseButton&)"))
    
    @tiled = TMXInterface.new
    
    @open_dialogs = []
    
    @filesystem_watcher = Qt::FileSystemWatcher.new
    connect(@filesystem_watcher, SIGNAL("fileChanged(QString)"), self, SLOT("files_changed_on_hard_drive(QString)"))
    
    connect(@ui.actionOpen_Folder, SIGNAL("activated()"), self, SLOT("open_folder_dialog()"))
    connect(@ui.actionExtract_ROM, SIGNAL("activated()"), self, SLOT("extract_rom_dialog()"))
    connect(@ui.actionSave, SIGNAL("activated()"), self, SLOT("save_files()"))
    connect(@ui.actionEdit_Room_Props, SIGNAL("activated()"), self, SLOT("edit_room_data()"))
    connect(@ui.actionEdit_Layers, SIGNAL("activated()"), self, SLOT("edit_layers()"))
    connect(@ui.actionEdit_Entities, SIGNAL("activated()"), self, SLOT("open_entity_editor()"))
    connect(@ui.actionEdit_Doors, SIGNAL("activated()"), self, SLOT("open_door_editor()"))
    connect(@ui.actionAdd_Entity, SIGNAL("activated()"), self, SLOT("add_new_entity()"))
    connect(@ui.actionAdd_Door, SIGNAL("activated()"), self, SLOT("add_new_door()"))
    connect(@ui.actionAdd_Room, SIGNAL("activated()"), self, SLOT("add_new_room()"))
    connect(@ui.actionClear_Room_Contents, SIGNAL("activated()"), self, SLOT("clear_room_contents()"))
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
    connect(@ui.actionMenu_Editor, SIGNAL("activated()"), self, SLOT("open_menu_editor()"))
    connect(@ui.actionMap_Editor, SIGNAL("activated()"), self, SLOT("open_map_editor()"))
    connect(@ui.actionPlayer_Editor, SIGNAL("activated()"), self, SLOT("open_player_editor()"))
    connect(@ui.actionPlayer_State_Anims_Editor, SIGNAL("activated()"), self, SLOT("open_player_state_anims_editor()"))
    connect(@ui.actionSpecial_Object_Editor, SIGNAL("activated()"), self, SLOT("open_special_object_editor()"))
    connect(@ui.actionWeapon_Synth_Editor, SIGNAL("activated()"), self, SLOT("open_weapon_synth_editor()"))
    connect(@ui.actionShop_Editor, SIGNAL("activated()"), self, SLOT("open_shop_editor()"))
    connect(@ui.actionQuest_Editor, SIGNAL("activated()"), self, SLOT("open_quest_editor()"))
    connect(@ui.actionMagic_Seal_Editor, SIGNAL("activated()"), self, SLOT("open_magic_seal_editor()"))
    connect(@ui.actionApply_ARMIPS_Patch, SIGNAL("activated()"), self, SLOT("open_armips_patcher()"))
    connect(@ui.actionAdd_Overlay, SIGNAL("activated()"), self, SLOT("add_new_overlay()"))
    connect(@ui.actionEntity_Search, SIGNAL("activated()"), self, SLOT("open_entity_search()"))
    connect(@ui.actionAddress_Converter, SIGNAL("activated()"), self, SLOT("open_address_converter()"))
    connect(@ui.actionFix_Save_Files, SIGNAL("activated()"), self, SLOT("open_save_file_fixer()"))
    connect(@ui.actionSettings, SIGNAL("activated()"), self, SLOT("open_settings()"))
    connect(@ui.actionBuild, SIGNAL("activated()"), self, SLOT("write_to_rom()"))
    connect(@ui.actionBuild_and_Run, SIGNAL("activated()"), self, SLOT("build_and_run()"))
    connect(@ui.actionBuild_and_Test, SIGNAL("activated()"), self, SLOT("build_and_test()"))
    connect(@ui.actionAbout, SIGNAL("activated()"), self, SLOT("open_about()"))
    
    connect(@ui.area, SIGNAL("activated(int)"), self, SLOT("area_index_changed(int)"))
    connect(@ui.sector, SIGNAL("activated(int)"), self, SLOT("sector_index_changed(int)"))
    connect(@ui.room, SIGNAL("activated(int)"), self, SLOT("room_index_changed(int)"))
    connect(@ui.room_state, SIGNAL("activated(int)"), self, SLOT("room_state_index_changed(int)"))
    connect(@ui.tiled_export, SIGNAL("released()"), self, SLOT("open_in_tiled()"))
    connect(@ui.tiled_import, SIGNAL("released()"), self, SLOT("import_from_tiled()"))
    connect(@ui.set_as_starting_room, SIGNAL("released()"), self, SLOT("set_current_room_as_starting_room()"))
    connect(@ui.copy_room_pointer, SIGNAL("released()"), self, SLOT("copy_room_pointer_to_clipboard()"))
    connect(@ui.edit_map, SIGNAL("released()"), self, SLOT("open_map_editor()"))
    connect(@ui.toggle_hide_map, SIGNAL("released()"), self, SLOT("toggle_hide_map()"))
    
    @ui.label_4.hide()
    @ui.room_state.hide()
    
    load_settings()
    
    if @settings[:hide_map]
      toggle_hide_map()
    end
    
    # Temporarily hide unfinished features.
    @ui.menuTools.removeAction(@ui.actionFix_Save_Files)
    
    self.setWindowState(Qt::WindowMaximized)
    self.setWindowTitle("DSVania Editor #{DSVEDIT_VERSION}")
    
    disable_menu_actions()
    
    self.show()
    
    if @settings[:last_used_folder] && File.directory?(@settings[:last_used_folder])
      open_folder(@settings[:last_used_folder])
    end
  end
  
  def disable_menu_actions
    @ui.actionSave.setEnabled(false);
    @ui.actionEdit_Room_Props.setEnabled(false);
    @ui.actionEdit_Layers.setEnabled(false);
    @ui.actionEdit_Entities.setEnabled(false);
    @ui.actionEdit_Doors.setEnabled(false);
    @ui.actionAdd_Entity.setEnabled(false);
    @ui.actionAdd_Door.setEnabled(false);
    @ui.actionAdd_Room.setEnabled(false);
    @ui.actionClear_Room_Contents.setEnabled(false);
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
    @ui.actionMenu_Editor.setEnabled(false);
    @ui.actionMap_Editor.setEnabled(false);
    @ui.actionPlayer_Editor.setEnabled(false);
    @ui.actionPlayer_State_Anims_Editor.setEnabled(false);
    @ui.actionSpecial_Object_Editor.setEnabled(false);
    @ui.actionWeapon_Synth_Editor.setEnabled(false);
    @ui.actionShop_Editor.setEnabled(false);
    @ui.actionQuest_Editor.setEnabled(false);
    @ui.actionMagic_Seal_Editor.setEnabled(false);
    @ui.actionApply_ARMIPS_Patch.setEnabled(false);
    @ui.actionAdd_Overlay.setEnabled(false);
    @ui.actionEntity_Search.setEnabled(false);
    @ui.actionAddress_Converter.setEnabled(false);
    @ui.actionFix_Save_Files.setEnabled(false);
    @ui.actionBuild.setEnabled(false);
    @ui.actionBuild_and_Run.setEnabled(false);
    @ui.actionBuild_and_Test.setEnabled(false);
  end
  
  def enable_menu_actions
    @ui.actionSave.setEnabled(true);
    @ui.actionEdit_Room_Props.setEnabled(true);
    @ui.actionEdit_Layers.setEnabled(true);
    @ui.actionEdit_Entities.setEnabled(true);
    @ui.actionEdit_Doors.setEnabled(true);
    @ui.actionAdd_Entity.setEnabled(true);
    @ui.actionAdd_Door.setEnabled(true);
    @ui.actionAdd_Room.setEnabled(true);
    @ui.actionClear_Room_Contents.setEnabled(true);
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
    @ui.actionMenu_Editor.setEnabled(true);
    @ui.actionMap_Editor.setEnabled(true);
    @ui.actionPlayer_Editor.setEnabled(true);
    @ui.actionPlayer_State_Anims_Editor.setEnabled(true);
    @ui.actionSpecial_Object_Editor.setEnabled(true);
    @ui.actionWeapon_Synth_Editor.setEnabled(true);
    @ui.actionShop_Editor.setEnabled(true);
    @ui.actionQuest_Editor.setEnabled(true);
    @ui.actionMagic_Seal_Editor.setEnabled(true);
    @ui.actionApply_ARMIPS_Patch.setEnabled(true);
    @ui.actionAdd_Overlay.setEnabled(true);
    @ui.actionEntity_Search.setEnabled(true);
    @ui.actionAddress_Converter.setEnabled(true);
    @ui.actionFix_Save_Files.setEnabled(true);
    @ui.actionBuild.setEnabled(true);
    @ui.actionBuild_and_Run.setEnabled(true);
    @ui.actionBuild_and_Test.setEnabled(true);
  end
  
  def close_open_dialogs
    @open_dialogs.each do |dialog|
      dialog.close()
    end
    @open_dialogs = []
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
    rom_path = Qt::FileDialog.getOpenFileName(self, "Select ROM", default_dir, "NDS and GBA ROM Files (*.nds *.gba)")
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
    
    clear_cache()
    
    empty_filesystem_watcher() # Turn off the filesystem watcher so it doesn't watch for all the files we extract.
    
    game = Game.new
    
    max_val = 100
    @progress_dialog = ProgressDialog.new("Extracting", "Extracting files from ROM", max_val)
    @progress_dialog.setCancelButton(nil) # Don't give an option to cancel extracting
    
    @progress_dialog.execute do
      begin
        game.initialize_from_rom(rom_path, extract_to_hard_drive = true) do |percentage_written|
          next unless percentage_written % 10 == 0 # Only update the UI every 100 files because updating too often is slow.
          break if @progress_dialog.nil?
          
          Qt.execute_in_main_thread do
            if @progress_dialog && !@progress_dialog.wasCanceled
              @progress_dialog.setValue(percentage_written)
            end
          end
        end
      rescue StandardError => e
        Qt.execute_in_main_thread do
          if @progress_dialog
            @progress_dialog.setValue(max_val) unless @progress_dialog.wasCanceled
            @progress_dialog.close()
            @progress_dialog = nil
          end
          
          Qt::MessageBox.critical(self, "ROM Extraction failed", "Failed to extract ROM with error:\n#{e.message}\n\n#{e.backtrace.join("\n")}")
        end
        update_filesystem_watcher()
        return
      end
      
      Qt.execute_in_main_thread do
        if @progress_dialog
          @progress_dialog.setValue(@progress_dialog.maximum) unless @progress_dialog.wasCanceled
          @progress_dialog.close()
          @progress_dialog = nil
        end
        
        @game = game
        @renderer = Renderer.new(game.fs)
        
        update_filesystem_watcher()
        
        enable_menu_actions()
        
        initialize_dropdowns()
        
        @settings[:last_used_folder] = game.folder
        
        folder_name = File.basename(game.folder)
        self.setWindowTitle("DSVania Editor #{DSVEDIT_VERSION} - #{folder_name}")
        
        check_for_incompatible_overlay()
        
        save_settings()
      end
    end
  rescue Game::InvalidFileError, NDSFileSystem::InvalidFileError
    Qt::MessageBox.warning(self, "Invalid file", "Selected ROM file is not a DSVania or is not a supported region.")
  rescue NDSFileSystem::InvalidRevisionError => e
    Qt::MessageBox.warning(self, "Invalid revision", e.message)
  end
  
  def open_folder(folder_path)
    cancelled = confirm_discard_changes()
    return if cancelled
    
    close_open_dialogs()
    
    clear_cache()
    
    game = Game.new
    game.initialize_from_folder(folder_path)
    @game = game
    @renderer = Renderer.new(game.fs)
    
    update_filesystem_watcher()
    
    enable_menu_actions()
    
    initialize_dropdowns()
    
    @settings[:last_used_folder] = folder_path
    
    folder_name = File.basename(game.folder)
    self.setWindowTitle("DSVania Editor #{DSVEDIT_VERSION} - #{folder_name}")
    
    check_for_incompatible_overlay()
    
    save_settings()
  rescue Game::InvalidFileError, NDSFileSystem::InvalidFileError
    Qt::MessageBox.warning(self, "Invalid file", "Selected folder is not a DSVania.")
  rescue NDSFileSystem::InvalidRevisionError => e
    Qt::MessageBox.warning(self, "Invalid revision", e.message)
  end
  
  def empty_filesystem_watcher
    paths_to_remove = @filesystem_watcher.files + @filesystem_watcher.directories
    if paths_to_remove.any?
      @filesystem_watcher.removePaths(paths_to_remove)
    end
  end
  
  def update_filesystem_watcher
    empty_filesystem_watcher()
    
    # Then watch all paths for the current project.
    base_directory = game.folder
    game.fs.all_files.each do |file|
      next unless file[:type] == :file
      
      full_path = File.join(base_directory, file[:file_path])
      @filesystem_watcher.addPath(full_path)
    end
  end
  
  def files_changed_on_hard_drive(full_path)
    # Reload a file from the disk if it was changed.
    # Note that files that the user currently has uncommitted changes in will not be reloaded.
    base_dir_path = Pathname.new(@settings[:last_used_folder])
    absolute_path = Pathname.new(full_path)
    relative_path = "/" + absolute_path.relative_path_from(base_dir_path).to_s
    game.fs.reload_file_from_disk(relative_path)
  end
  
  def initialize_dropdowns
    @ui.area.clear()
    @ui.sector.clear()
    @ui.room.clear()
    @ui.room_state.clear()
    @ui.area.addItem("Select Area")
    @ui.area.model.item(0).setEnabled(false)
    AREA_INDEX_TO_OVERLAY_INDEX.keys.each do |area_index|
      area_name = AREA_INDEX_TO_AREA_NAME[area_index]
      @ui.area.addItem("%02X %s" % [area_index, area_name])
    end
    area_index_changed(0, force=true)
    
    if GAME == "hod"
      @ui.label_4.show()
      @ui.room_state.show()
    else
      @ui.label_4.hide()
      @ui.room_state.hide()
    end
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
      if @area.sectors[sector_index].is_hardcoded
        sector_text = "Hardcoded rooms"
      else
        sector_text = "%02X" % sector_index
        if SECTOR_INDEX_TO_SECTOR_NAME[@area_index]
          sector_name = SECTOR_INDEX_TO_SECTOR_NAME[@area_index][sector_index]
          sector_text << " #{sector_name}"
        end
      end
      
      overlay_id = AREA_INDEX_TO_OVERLAY_INDEX[@area_index][sector_index]
      if overlay_id
        sector_text << " (Overlay #{overlay_id})"
      end
      @ui.sector.addItem(sector_text)
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
    
    @room_state_index = 0
    load_room_and_states()
  end
  
  def room_state_index_changed(new_room_state_index)
    @room_state_index = new_room_state_index
    @room = @room_states[new_room_state_index]
    load_room()
    @ui.room_state.setCurrentIndex(new_room_state_index)
  end
  
  def update_room_position_indicator
    @position_indicator.setPos(@room.room_xpos_on_map*4 + 2.25 + @map_offset_x, @room.room_ypos_on_map*4 + 2.25 + @map_offset_y)
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
  
  def change_room_by_room_object(room)
    change_area(room.area_index)
    change_sector(room.sector_index, force=true)
    change_room(room.room_index, force=true)
    
    if GAME == "hod"
      room_state_index = @room_states.index(room)
      room_state_index_changed(room_state_index)
    end
  end
  
  def room_clicked(x, y, button)
    return unless button == Qt::RightButton
    
    item = @room_graphics_scene.itemAt(x, y)
    return if item.nil?
    
    if item.is_a?(EntityChunkyItem) || item.is_a?(EntityRectItem)
      open_entity_editor(item.entity)
    elsif item.is_a?(DoorItem)
      if $qApp.keyboardModifiers & Qt::ShiftModifier == 0
        # Enter the door if shift is not held down.
        change_room_by_metadata(item.door.destination_room_metadata_ram_pointer)
      else
        # Edit the entity if shift is held down.
        open_door_editor(item.door)
      end
    end
  end
  
  def change_room_by_map_x_and_y(x, y, button)
    x -= @map_offset_x
    y -= @map_offset_y
    x = x / 4
    y = y / 4
    
    if GAME == "hod"
      tile = @map.tiles.find do |tile|
        tile.x_pos == x && tile.y_pos == y
      end
      
      
      if tile.nil? || tile.is_blank
        return
      end
      
      # In HoD the map tile doesn't have the sector/room indexes so we need to search through all rooms in the game to find a matching one.
      in_castle_b = @sector_index.odd?
      matched_room = nil
      game.each_room do |room|
        next if room.sector_index.odd? != in_castle_b # We only want to check rooms in the same castle the user in already in.
        
        if (room.room_xpos_on_map..room.room_xpos_on_map+room.width-1).include?(x) && (room.room_ypos_on_map..room.room_ypos_on_map+room.height-1).include?(y)
          matched_room = room
          break
        end
      end
      
      if matched_room.nil?
        return
      end
      
      sector_and_room_indexes_changed(matched_room.sector_index, matched_room.room_index)
    else
      tile = @map.tiles.find do |tile|
        tile.x_pos == x && tile.y_pos == y
      end
      
      if tile.nil? || tile.is_blank
        return
      end
      
      sector_and_room_indexes_changed(tile.sector_index, tile.room_index)
    end
  end
  
  def load_room_and_states
    # First initializes the room states if in HoD. Then loads the room as normally.
    
    @ui.room_state.clear()
    @room_states = @room.room_states
    @room_states.each_with_index do |room_state, state_index|
      if state_index == 0
        condition = "Default"
      else
        condition = "Event flag: %04X" % @room_states[state_index-1].state_swap_event_flag
      end
      @ui.room_state.addItem("%02X %08X (#{condition})" % [state_index, room_state.room_metadata_ram_pointer])
    end
    @ui.room_state.setCurrentIndex(@room_state_index)
    
    load_room()
  end
  
  def load_room
    @room_graphics_scene.clear()
    
    @layers_view_item = Qt::GraphicsRectItem.new
    @room_graphics_scene.addItem(@layers_view_item)
    @room.sector.load_necessary_overlay()
    load_layers()
    main_layer_border_rect = Qt::GraphicsRectItem.new(0, 0, SCREEN_WIDTH_IN_PIXELS*@room.width-1, SCREEN_HEIGHT_IN_PIXELS*@room.height-1)
    main_layer_border_rect.setZValue(-1)
    @room_graphics_scene.addItem(main_layer_border_rect)
    
    load_room_collision_tileset()
    
    @doors_view_item = Qt::GraphicsRectItem.new
    @room_graphics_scene.addItem(@doors_view_item)
    @room.doors.each_with_index do |door, i|
      door_item = DoorItem.new(door, i, self)
      door_item.setParentItem(@doors_view_item)
    end
    
    @entities_view_item = EntityLayerItem.new(@room.entities, self, game, @renderer)
    @room_graphics_scene.addItem(@entities_view_item)
    
    update_room_bounding_rect()
    
    update_visible_view_items()
    
    update_room_position_indicator()
  rescue StandardError => e
    msg = "Failed to load room %08X.\n" % @room.room_metadata_ram_pointer
    msg += "#{e.message}\n\n#{e.backtrace.join("\n")}"
    Qt::MessageBox.warning(self,
      "Failed to load room",
      msg
    )
  end
  
  def load_layers
    @renderer.ensure_tilesets_exist("cache/#{GAME}/rooms/", @room)
    @room.layers.each do |layer|
      load_layer(layer)
    end
  rescue StandardError => e
    msg = "Failed to load layers for room %08X.\n" % @room.room_metadata_ram_pointer
    msg += "#{e.message}\n\n#{e.backtrace.join("\n")}"
    Qt::MessageBox.warning(self,
      "Failed to load layers",
      msg
    )
  end
  
  def load_layer(layer)
    return if layer.tileset_pointer == 0
    
    tileset_filename = "cache/#{GAME}/rooms/#{@room.area_name}/Tilesets/#{layer.tileset_filename}.png"
    layer_item = LayerItem.new(layer, tileset_filename)
    layer_item.setParentItem(@layers_view_item)
  rescue StandardError => e
    msg = "Failed to load layer %08X.\n" % layer.layer_list_entry_ram_pointer
    msg += "#{e.message}\n\n#{e.backtrace.join("\n")}"
    Qt::MessageBox.warning(self,
      "Failed to load layer",
      msg
    )
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
      layer = @room.layers.first
      layer_item = LayerItem.new(layer, tileset_filename, collision=true)
      layer_item.setParentItem(@collision_view_item)
    end
  rescue StandardError => e
    Qt::MessageBox.warning(self,
      "Collision tileset loading failed",
      "Failed to load collision tileset.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
    )
  end
  
  def edit_room_data
    @open_dialogs << RoomEditorDialog.new(self, @room, @renderer)
  end
  
  def edit_layers
    @open_dialogs << LayersEditorDialog.new(self, @room, @renderer)
  end
  
  def add_new_entity
    entity = Entity.new(@room, game.fs)
    scene_pos = @ui.room_graphics_view.mapToScene(@ui.room_graphics_view.mapFromGlobal(Qt::Cursor.pos))
    if @room_graphics_scene.sceneRect.contains(scene_pos)
      entity.x_pos = scene_pos.x
      entity.y_pos = scene_pos.y
    end
    entity.type = ENEMY_ENTITY_TYPE
    @room.entities << entity
    @room.write_entities_to_rom()
    
    load_room()
    
    open_entity_editor(entity)
  rescue FreeSpaceManager::FreeSpaceFindError => e
    @room.read_from_rom() # Reload room to get rid of the failed changes.
    load_room()
    Qt::MessageBox.warning(self,
      "Failed to find free space",
      "Failed to find free space to put the new entity.\n\n#{NO_FREE_SPACE_MESSAGE}"
    )
  rescue Room::WriteError => e
    @room.read_from_rom() # Reload room to get rid of the failed changes.
    load_room()
    Qt::MessageBox.warning(self, "Cannot add entity", e.message)
  end
  
  def add_new_door
    door = Door.new(@room, game)
    scene_pos = @ui.room_graphics_view.mapToScene(@ui.room_graphics_view.mapFromGlobal(Qt::Cursor.pos))
    if @room_graphics_scene.sceneRect.contains(scene_pos)
      door.x_pos = scene_pos.x.to_i / SCREEN_WIDTH_IN_PIXELS
      door.y_pos = scene_pos.y.to_i / SCREEN_HEIGHT_IN_PIXELS
    end
    @room.doors << door
    @room.write_doors_to_rom()
    
    load_room()
    
    open_door_editor(door)
  rescue FreeSpaceManager::FreeSpaceFindError => e
    @room.read_from_rom() # Reload room to get rid of the failed changes.
    load_room()
    Qt::MessageBox.warning(self,
      "Failed to find free space",
      "Failed to find free space to put the new door.\n\n#{NO_FREE_SPACE_MESSAGE}"
    )
  rescue Room::WriteError => e
    @room.read_from_rom() # Reload room to get rid of the failed changes.
    load_room()
    Qt::MessageBox.warning(self, "Cannot add door", e.message)
  end
  
  def add_new_room
    if @sector.is_hardcoded
      Qt::MessageBox.warning(self, "Can't add new room", "This isn't a real sector, DSVEdit just uses this fake sector to display hardcoded rooms not contained in any sector.\nTherefore, you cannot add new rooms to this sector. Choose a different one.")
      return
    end
    
    @sector.add_new_room()
    room = @sector.rooms[-1]
    
    # Need to reload the sector so the room shows up in the list.
    change_sector(@sector_index, force=true)
    
    change_room(@sector.rooms.length-1, true)
  rescue FreeSpaceManager::FreeSpaceFindError => e
    Qt::MessageBox.warning(self,
      "Failed to find free space",
      "Failed to find free space to put the new room.\n\n#{NO_FREE_SPACE_MESSAGE}"
    )
  end
  
  def clear_room_contents
    msg = "This option will delete everything inside the current room, from entities to doors to tiles, freeing up most of the space it uses and leaving it empty as a blank slate to be edited. (The room itself is not deleted.)\n\n"
    msg << "Are you sure you want to delete everything in this room?"
    response = Qt::MessageBox.question(self, "Clear room contents", msg, Qt::MessageBox::No | Qt::MessageBox::Yes, Qt::MessageBox::No)
    
    if response == Qt::MessageBox::No
      return
    end
    
    # Clear contents starting at the default room state, since starting at a child state won't properly clear everything.
    @room.room_states[0].clear_contents()
    
    # Reload the room, switching to the default room state since the others are deleted.
    change_room(@room_index, force=true)
  end
  
  def update_visible_view_items
    @entities_view_item.setVisible(@ui.actionEntities.checked)
    @doors_view_item.setVisible(@ui.actionDoors.checked)
    @collision_view_item.setVisible(@ui.actionCollision.checked)
    @layers_view_item.setVisible(@ui.actionLayers.checked)
  end
  
  def load_map()
    @map_graphics_scene.clear()
    
    if GAME == "ooe"
      # Display the map background.
      other_sprite = OTHER_SPRITES.find{|spr| spr[:desc] == "Map"}
      sprite_info = SpriteInfo.new(other_sprite[:gfx_files], other_sprite[:palette], 0, other_sprite[:sprite], nil, game.fs)
      frames, min_x, min_y = @renderer.render_sprite(sprite_info, frame_to_render: 0, one_dimensional_mode: other_sprite[:one_dimensional_mode])
      map_background_frame = frames[0].trim!
      background_item = GraphicsChunkyItem.new(map_background_frame)
      @map_graphics_scene.addItem(background_item)
    end
    
    @map = game.get_map(@area_index, @sector_index)
    
    if GAME == "dos" || GAME == "aos"
      chunky_png_img = @renderer.render_map(@map, scale=1, hardcoded_transition_rooms=game.get_transition_rooms())
    else
      chunky_png_img = @renderer.render_map(@map)
    end
    map_pixmap_item = GraphicsChunkyItem.new(chunky_png_img)
    @map_offset_x, @map_offset_y = @map.draw_x_offset*4, @map.draw_y_offset*4
    map_pixmap_item.setOffset(@map_offset_x, @map_offset_y)
    @map_graphics_scene.addItem(map_pixmap_item)
    
    @position_indicator = @map_graphics_scene.addRect(-2, -2, 4, 4, Qt::Pen.new(Qt::NoPen), Qt::Brush.new(Qt::Color.new(255, 255, 128, 128)))
    if @room
      update_room_position_indicator()
    end
  end
  
  def open_enemy_dna_dialog
    @open_dialogs << EnemyEditor.new(self, game)
  end
  
  def open_text_editor
    @open_dialogs << TextEditor.new(self, game.fs)
  end
  
  def open_sprite_editor
    @open_dialogs << SpriteEditor.new(self, game, @renderer)
  end
    
  def open_item_editor
    @open_dialogs << ItemEditor.new(self, game)
  end
  
  def open_gfx_editor(gfx_and_palette_data=nil)
    @open_dialogs << GfxEditorDialog.new(self, game.fs, @renderer, gfx_and_palette_data)
  end
  
  def open_music_editor
    @open_dialogs << MusicEditor.new(self, game)
  end
  
  def open_item_pool_editor
    if GAME == "ooe"
      @open_dialogs << ItemPoolEditor.new(self, game)
    else
      Qt::MessageBox.warning(self, "Can't edit item pools", "Only OoE has random chest item pools.")
    end
  end
  
  def open_tileset_editor(tileset_data=nil, menu_editor=nil, room: nil, layer: nil)
    if tileset_data.nil?
      tileset_data = {}
      
      if room.nil?
        room = @room
      end
      room.sector.load_necessary_overlay()
      
      if room.palette_pages.empty?
        Qt::MessageBox.warning(self, "No palette", "The current room has no palette pages.")
        return
      end
      
      tileset_data[:room_gfx_list_pointer]   = room.gfx_list_pointer
      tileset_data[:palette_wrapper_pointer] = room.palette_wrapper_pointer
      tileset_data[:palette_page_index]      = room.palette_page_index
      
      if layer.nil?
        layer = room.layers.first
      end
      if layer
        tileset_data[:tileset_pointer]           = layer.tileset_pointer
        tileset_data[:collision_tileset_pointer] = layer.collision_tileset_pointer
        tileset_data[:tileset_type]              = layer.tileset_type
        tileset_data[:gfx_base_block]            = layer.gfx_base_block
      end
      
      tileset_data[:one_dimensional_mode] = (SYSTEM == :gba)
    end
    
    @open_dialogs << TilesetEditorDialog.new(self, game.fs, @renderer, tileset_data, menu_editor=menu_editor)
  end
  
  def open_menu_editor
    if GAME == "ooe"
      Qt::MessageBox.warning(self, "No menus to edit", "OoE's menus can be edited from the sprite editor instead of the menu editor.")
      return
    end
    
    @open_dialogs << MenuEditorDialog.new(self, game.fs, @renderer)
  end
  
  def open_entity_search
    @open_dialogs << EntitySearchDialog.new(self)
  end
  
  def open_address_converter
    if SYSTEM == :gba
      Qt::MessageBox.warning(self, "Can't convert addresses", "The address converter only works for the NDS games.\nGBA games do not load files into RAM, so converting addresses isn't needed.")
      return
    end
    
    @open_dialogs << AddressConverterDialog.new(self)
  end
  
  def open_save_file_fixer
    if GAME != "por"
      Qt::MessageBox.warning(self, "Game not supported", "The save file fixer currently only supports Portrait of Ruin.")
      return
    end
    
    @open_dialogs << SaveFileFixerDialog.new(self)
  end
  
  def open_map_editor
    @open_dialogs << MapEditorDialog.new(self, game, @renderer, @area_index, @sector_index)
  end
  
  def open_player_editor
    if SYSTEM == :gba
      Qt::MessageBox.warning(self, "Can't edit players", "Players are hardcoded in AoS and HoD and cannot be edited with this tool.")
      return
    end
    
    @open_dialogs << PlayerEditor.new(self, game)
  end
  
  def open_player_state_anims_editor
    if SYSTEM == :gba
      Qt::MessageBox.warning(self, "Can't edit players", "Players are hardcoded in AoS and HoD and cannot be edited with this tool.")
      return
    end
    
    @open_dialogs << PlayerStateAnimsEditor.new(self, game, @renderer)
  end
  
  def open_special_object_editor
    @open_dialogs << SpecialObjectEditor.new(self, game)
  end
  
  def open_weapon_synth_editor
    if GAME == "dos"
      @open_dialogs << WeaponSynthEditor.new(self, game)
    else
      Qt::MessageBox.warning(self, "Can't edit weapon synths", "Only DoS has weapon synths.")
    end
  end
  
  def open_shop_editor
    @open_dialogs << ShopEditor.new(self, game)
  end
  
  def open_quest_editor
    if ["por", "ooe"].include?(GAME)
      @open_dialogs << QuestEditor.new(self, game)
    else
      Qt::MessageBox.warning(self, "Can't edit quests", "Only PoR and OoE have quests.")
    end
  end
  
  def open_magic_seal_editor
    if GAME == "dos"
      @open_dialogs << MagicSealEditorDialog.new(self, @renderer)
    else
      Qt::MessageBox.warning(self, "Can't edit magic seals", "Only DoS has magic seals.")
    end
  end
  
  def open_armips_patcher
    @open_dialogs << ArmipsPatcherDialog.new(self, game)
  end
  
  def add_new_overlay
    if SYSTEM == :gba
      msg = "Can't add an overlay to a GBA game."
      Qt::MessageBox.warning(self, "Can't add overlay", msg)
      return
    end
    
    if game.fs.overlays[NEW_OVERLAY_ID]
      msg = "You have already added an overlay to this project.\n"
      msg << "DSVEdit only supports adding one new overlay to each project.\n\n"
      msg << "The new overlay is /ftc/overlay9_#{NEW_OVERLAY_ID}, it's loaded at %08X in RAM, and its maximum size is %08X bytes." % [NEW_OVERLAY_FREE_SPACE_START, NEW_OVERLAY_FREE_SPACE_MAX_SIZE]
      Qt::MessageBox.warning(self, "Can't add more overlays", msg)
      return
    end
    
    msg = "This option will add a new empty (free space) overlay file to the game. You can put whatever code or data you want in this file.\n"
    msg << "DSVEdit will also modify the game's code so that this new overlay gets loaded into the game's RAM.\n\n"
    msg << "Are you sure you want to add a new overlay?"
    response = Qt::MessageBox.question(self, "Add new overlay", msg, Qt::MessageBox::No | Qt::MessageBox::Yes, Qt::MessageBox::No)
    
    if response == Qt::MessageBox::No
      return
    end
    
    game.add_new_overlay()
    
    #new_overlay_path = "/ftc/overlay9_#{NEW_OVERLAY_ID}"
    #new_overlay_file = game.fs.files_by_path[new_overlay_path]
    #new_overlay_size = new_overlay_file[:size]
    #game.fs.mark_space_unused(new_overlay_path, new_overlay_size, NEW_OVERLAY_FREE_SPACE_MAX_SIZE-new_overlay_size)
    
    msg = "Successfully added new overlay /ftc/overlay9_#{NEW_OVERLAY_ID}.\n\n"
    msg << "This overlay will be loaded at %08X in RAM. The maximum size you can make this overlay is %08X bytes.\n\n" % [NEW_OVERLAY_FREE_SPACE_START, NEW_OVERLAY_FREE_SPACE_MAX_SIZE]
    msg << "If you are going to manually modify this file in a hex editor, only do so while DSVEdit is closed. DSVEdit may not notice files changed while it's open."
    Qt::MessageBox.warning(self, "Added new overlay #{NEW_OVERLAY_ID}", msg)
  end
  
  def check_for_incompatible_overlay
    return if SYSTEM == :gba
    
    overlay = game.fs.overlays[NEW_OVERLAY_ID]
    
    return if overlay.nil?
    
    return if overlay[:ram_start_offset] == NEW_OVERLAY_FREE_SPACE_START
    
    old_overlay_start = overlay[:ram_start_offset]
    
    msg = "This project has an overlay added by a previous version of DSVEdit. Due to a bug in previous versions, this overlay needs to be moved to a different location in RAM.\n\n"
    msg << "However, note that any custom code located in the overlay will no longer work correctly after the move.\n"
    msg << "In order to fix this, you will need to update your ASM patches to use the new overlay address, and then re-apply those ASM patches.\n"
    msg << "Old address: %08X\n" % old_overlay_start
    msg << "New address: %08X\n\n" % NEW_OVERLAY_FREE_SPACE_START
    msg << "Once you have done that, click OK."
    Qt::MessageBox.warning(self, "Incompatible overlay detected", msg)
    
    game.fs.fix_free_space_overlay_start_address()
    
    msg = "The overlay was successfully relocated.\n\n"
    msg << "If you re-applied the ASM patches as explained earlier, everything should work correctly now.\n\n"
    msg << "If you haven't updated them yet, please do so now. Change the old overlay address (%08X) to the new one (%08X) and reapply your patches." % [old_overlay_start, NEW_OVERLAY_FREE_SPACE_START]
    Qt::MessageBox.warning(self, "Overlay relocated", msg)
  end
  
  def open_entity_editor(entity = nil)
    if @room.entities.empty?
      Qt::MessageBox.warning(self, "No entities to edit", "This room has no entities.\nYou can add one by going to Edit -> Add Entity or pressing A.")
      return
    end
    @open_dialogs << EntityEditorDialog.new(self, @room, entity)
  end
  
  def open_door_editor(door = nil)
    if @room.doors.empty?
      Qt::MessageBox.warning(self, "No doors to edit", "This room has no doors.\nYou can add one by going to Edit -> Add Door or pressing D.")
      return
    end
    @open_dialogs << DoorEditorDialog.new(self, @renderer, @room.doors, door)
  end
  
  def open_settings
    @open_dialogs << SettingsDialog.new(self, @settings)
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
    
    save_settings()
  end
  
  def open_in_tiled
    if @room.layers.length == 0
      Qt::MessageBox.warning(self, "Room has no layers", "Cannot edit a room that has no layers. Open the layers editor in order to create a layer list for this room.")
      return
    elsif check_invalid_tiled_path()
      return
    end
    folder = "cache/#{GAME}/rooms"
    tmx_path = "#{folder}/#{@room.area_name}/#{@room.filename}.tmx"
    
    @renderer.ensure_tilesets_exist(folder, @room)
    @tiled.export_tmx_map(tmx_path, @room)
    system("start \"#{@settings[:tiled_path]}\" \"#{tmx_path}\"")
  rescue StandardError => e
    Qt::MessageBox.warning(self,
      "Failed to export to Tiled",
      "Failed to export to Tiled:\n#{e.message}\n\n#{e.backtrace.join("\n")}"
    )
  end
  
  def import_from_tiled
    if @room.layers.length == 0
      Qt::MessageBox.warning(self, "Room has no layers", "Cannot edit a room that has no layers. Open the layers editor in order to create a layer list for this room.")
      return
    end
    
    folder = "cache/#{GAME}/rooms"
    tmx_path = "#{folder}/#{@room.area_name}/#{@room.filename}.tmx"
    if !File.exist?(tmx_path) || !File.file?(tmx_path)
      Qt::MessageBox.warning(self, "TMX file doesn't exist", "Can't find the TMX file. You must export to tiled first.")
      return
    end
    
    @tiled.import_tmx_map(tmx_path, @room)
    game.fix_map_sector_and_room_indexes(@area_index, @sector_index)
    
    load_room()
  rescue FreeSpaceManager::FreeSpaceFindError => e
    @room.read_from_rom() # Reload room to get rid of the failed changes.
    load_room()
    Qt::MessageBox.warning(self,
      "Failed to find free space",
      "Failed to find free space to put the new layers/entities/doors.\n\n#{NO_FREE_SPACE_MESSAGE}"
    )
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
    game.fs.commit_changes()
  end
  
  def confirm_discard_changes
    if game && game.fs.has_uncommitted_changes?
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
  
  def check_invalid_tiled_path
    if @settings[:tiled_path].nil? || @settings[:tiled_path].empty?
      Qt::MessageBox.warning(self, "Failed to run Tiled", "You must specify where Tiled is installed.")
      return true
    elsif !File.file?(@settings[:tiled_path])
      Qt::MessageBox.warning(self, "Failed to run Tiled", "Tiled install path is invalid.")
      return true
    end
    return false
  end
  
  def write_to_rom(launch_emulator = false)
    return if @progress_dialog && @progress_dialog.visible()
    
    # These two lines are for the room test.
    # We preserve a reference to the game's current test room fs, then revert the game's fs to the normal one.
    # This lets us build a rom for the test room while ensuring the game doesn't get stuck with the test room fs if the build fails/is canceled.
    fs = game.fs
    game.end_test_room()
    
    
    output_rom_path = File.join(game.folder, "built_rom_#{GAME}.#{fs.rom_file_extension}")
    max_val = fs.files_without_dirs.length
    @progress_dialog = ProgressDialog.new("Building", "Writing files to ROM", max_val)
    @progress_dialog.execute do
      begin
        fs.write_to_rom(output_rom_path) do |files_written|
          next unless files_written % 100 == 0 # Only update the UI every 100 files because updating too often is slow.
          break if @progress_dialog.nil?
          
          Qt.execute_in_main_thread do
            if @progress_dialog && !@progress_dialog.wasCanceled
              @progress_dialog.setValue(files_written)
            end
          end
        end
      rescue StandardError => e
        Qt.execute_in_main_thread do
          if @progress_dialog
            @progress_dialog.setValue(max_val) unless @progress_dialog.wasCanceled
            @progress_dialog.close()
            @progress_dialog = nil
          end
          
          Qt::MessageBox.critical(self, "Building ROM failed", "Failed to build ROM with error:\n#{e.message}\n\n#{e.backtrace.join("\n")}")
        end
        return
      end
      
      Qt.execute_in_main_thread do
        if @progress_dialog
          @progress_dialog.setValue(@progress_dialog.maximum) unless @progress_dialog.wasCanceled
          @progress_dialog.close()
          @progress_dialog = nil
        end
        
        symbol_file_out_path = File.join(File.dirname(output_rom_path), "built_rom_#{GAME}.sym")
        FileUtils.cp("./docs/asm/#{GAME} Functions.txt", symbol_file_out_path)
        
        if launch_emulator
          if SYSTEM == :nds
            emulator_path = @settings[:emulator_path]
          else
            emulator_path = @settings[:gba_emulator_path]
          end
          
          if emulator_path.nil? || emulator_path.empty?
            Qt::MessageBox.warning(self, "Failed to run emulator", "You must specify the emulator path.")
          elsif !File.file?(emulator_path)
            Qt::MessageBox.warning(self, "Failed to run emulator", "Emulator path is invalid.")
          else
            output_rom_path = output_rom_path.gsub(File::SEPARATOR, File::ALT_SEPARATOR)
            system("start \"\" \"#{emulator_path}\" \"#{output_rom_path}\"")
          end
        else
          #Qt::MessageBox.information(self, "Done", "All files written to rom.")
        end
      end
    end
  end
  
  def build_and_run
    write_to_rom(launch_emulator = true)
  end
  
  def build_and_test
    save_file_index = @settings[:test_room_save_file_index] || 0
    scene_pos = @ui.room_graphics_view.mapToScene(@ui.room_graphics_view.mapFromGlobal(Qt::Cursor.pos))
    x_pos = scene_pos.x
    y_pos = scene_pos.y
    game.start_test_room(save_file_index, @area_index, @sector_index, @room_index, @room.room_metadata_ram_pointer, x_pos, y_pos)
    
    write_to_rom(launch_emulator = true)
  rescue StandardError => e
    Qt::MessageBox.warning(self,
      "Error",
      "Test room failed with error:\n#{e.message}\n\n#{e.backtrace.join("\n")}"
    )
  end
  
  def open_about
    @about_dialog = Qt::MessageBox.new
    @about_dialog.setTextFormat(Qt::RichText)
    @about_dialog.setWindowTitle("DSVania Editor")
    text = "DSVania Editor Version #{DSVEDIT_VERSION}<br><br>" + 
      "Created by LagoLunatic<br><br>" + 
      "Report issues here:<br><a href=\"https://github.com/LagoLunatic/DSVEdit/issues\">https://github.com/LagoLunatic/DSVEdit/issues</a><br><br>" +
      "Source code:<br><a href=\"https://github.com/LagoLunatic/DSVEdit\">https://github.com/LagoLunatic/DSVEdit</a>"
    @about_dialog.setText(text)
    @about_dialog.windowIcon = self.windowIcon
    @about_dialog.show()
  end
  
  def inspect
    # When an error occurs, Ruby tries to call inspect on the object causing the error and print that.
    # That includes calling inspect on all of the object's instance variables recursively. This takes a long time.
    # We define inspect as just to_s so it skips recursively examining every object in the whole program and errors don't take so long.
    to_s
  end
end

class ProgressDialog < Qt::ProgressDialog
  slots "cancel_thread()"
  
  def initialize(title, description, max_val)
    super()
    self.windowTitle = title
    self.labelText = description
    self.maximum = max_val
    self.windowModality = Qt::ApplicationModal
    self.windowFlags = Qt::CustomizeWindowHint | Qt::WindowTitleHint
    self.setFixedSize(self.size);
    self.autoReset = false
    connect(self, SIGNAL("canceled()"), self, SLOT("cancel_thread()"))
    self.show
  end
  
  def execute(&block)
    @thread = Thread.new do
      yield
    end
  end
  
  def cancel_thread
    puts "Cancelled."
    @thread.kill
    self.close()
  end
end
