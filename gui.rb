require 'Qt'
require 'fileutils'
require 'yaml'

require_relative 'dsve'
require_relative 'ui_main'
require_relative 'ui_enemy'

class DSVE < Qt::MainWindow
  attr_reader :fs
  
  slots "open_rom_dialog()"
  slots "open_folder_dialog()"
  slots "save_files()"
  slots "open_enemy_dna_dialog()"
  slots "write_to_rom()"
  slots "build_and_run()"
  
  slots "area_index_changed(int)"
  slots "sector_index_changed(int)"
  slots "room_index_changed(int)"
  slots "sector_and_room_indexes_changed(int, int)"
  slots "open_in_tiled()"
  slots "import_from_tiled()"
  
  def initialize
    super()
    @ui = Ui_MainWindow.new
    @ui.setup_ui(self)
    
    @room_graphics_scene = Qt::GraphicsScene.new
    @ui.room_graphics_view.setScene(@room_graphics_scene)
    @ui.room_graphics_view.setDragMode(Qt::GraphicsView::ScrollHandDrag)
    self.setStyleSheet("QGraphicsView { background-color: transparent; }");
    
    @map_graphics_scene = Qt::GraphicsScene.new
    @map_graphics_scene.setSceneRect(0, 0, 64*4+1, 48*4+1)
    @ui.map_graphics_view.scale(2, 2)
    @ui.map_graphics_view.setScene(@map_graphics_scene)
    
    @tiled = TMXInterface.new
    
    connect(@ui.actionOpen, SIGNAL("activated()"), self, SLOT("open_rom_dialog()"))
    connect(@ui.actionOpen_Folder, SIGNAL("activated()"), self, SLOT("open_folder_dialog()"))
    connect(@ui.actionSave, SIGNAL("activated()"), self, SLOT("save_files()"))
    connect(@ui.actionEnemy_Editor, SIGNAL("activated()"), self, SLOT("open_enemy_dna_dialog()"))
    connect(@ui.actionBuild, SIGNAL("activated()"), self, SLOT("write_to_rom()"))
    connect(@ui.actionBuild_and_Run, SIGNAL("activated()"), self, SLOT("build_and_run()"))
    
    connect(@ui.area, SIGNAL("activated(int)"), self, SLOT("area_index_changed(int)"))
    connect(@ui.sector, SIGNAL("activated(int)"), self, SLOT("sector_index_changed(int)"))
    connect(@ui.room, SIGNAL("activated(int)"), self, SLOT("room_index_changed(int)"))
    connect(@ui.tiled_export, SIGNAL("released()"), self, SLOT("open_in_tiled()"))
    connect(@ui.tiled_import, SIGNAL("released()"), self, SLOT("import_from_tiled()"))
    
    load_settings()
    open_folder(@settings[:last_used_folder])
    
    self.setWindowState(Qt::WindowMaximized)
    self.show()
  end
  
  def open_rom_dialog
    rom_path = Qt::FileDialog.getOpenFileName(self, "Select ROM", nil, "NDS ROM Files (*.nds)")
    return if rom_path.nil?
    folder = Qt::FileDialog.getExistingDirectory(self, "Select folder to extract files to")
    return if folder.nil?
    open_rom(rom_path, folder)
  end
  
  def open_folder_dialog
    folder = Qt::FileDialog.getExistingDirectory(self, "Open folder")
    return if folder.nil?
    open_folder(folder)
  end
  
  def open_rom(rom_path, folder)
    unless File.exist?(rom_path) && File.file?(rom_path)
      raise "Not a file"
    end
    
    verify_game_and_load_constants(rom_path)
    
    @fs = NDSFileSystem.new
    folder = File.join(folder, "extracted_files_#{GAME}")
    fs.open_and_extract_rom(rom_path, folder)
    CONSTANT_OVERLAYS.each do |overlay_index|
      fs.load_overlay(overlay_index)
    end
    @renderer = Renderer.new(fs)
    
    initialize_dropdowns()
  end
  
  def open_folder(folder_path)
    unless File.exist?(folder_path) && File.directory?(folder_path)
      raise "Not a directory"
    end
    
    header_path = File.join(folder_path, "ftc", "ndsheader.bin")
    unless File.exist?(header_path) && File.file?(header_path)
      raise "Header file not present"
    end
    
    verify_game_and_load_constants(header_path)
    
    @fs = NDSFileSystem.new
    fs.open_directory(folder_path)
    CONSTANT_OVERLAYS.each do |overlay_index|
      fs.load_overlay(overlay_index)
    end
    @renderer = Renderer.new(fs)
    
    initialize_dropdowns()
  end
  
  def verify_game_and_load_constants(header_path)
    case File.read(header_path, 12)
    when "CASTLEVANIA1"
      require_relative './constants/dos_constants.rb'
    when "CASTLEVANIA2"
      require_relative './constants/por_constants.rb'
    when "CASTLEVANIA3"
      require_relative './constants/ooe_constants.rb'
    else
      Qt::MessageBox.warning(self, "Invalid folder", "Specified game is not a DSVania.")
      return
    end
  end
  
  def initialize_dropdowns
    @ui.area.clear()
    @ui.sector.clear()
    @ui.room.clear()
    @ui.area.addItem("Select Area")
    @ui.area.model.item(0).setEnabled(false)
    AREA_INDEX_TO_OVERLAY_INDEX.keys.each do |area_index|
      area_name = AREA_INDEX_TO_AREA_NAME[area_index]
      @ui.area.addItem("%02d %s" % [area_index, area_name])
    end
    area_index_changed(0)
  end
  
  def area_index_changed(new_area_index)
    if @ui.area.findText("Select Area", flags=Qt::MatchExactly) >= 0
      # Remove the placeholder Select Area text.
      @ui.area.removeItem(0)
      area_index_changed(0) # Trigger a second call to area_index_changed to select the actual first area.
      return
    end
    @area_index = new_area_index
    @area = Area.new(@area_index, fs)
    sector_index_changed(0, force=true)
    @ui.sector.clear()
    AREA_INDEX_TO_OVERLAY_INDEX[@area_index].keys.each do |sector_index|
      if SECTOR_INDEX_TO_SECTOR_NAME[@area_index]
        sector_name = SECTOR_INDEX_TO_SECTOR_NAME[@area_index][sector_index]
        @ui.sector.addItem("%02d %s" % [sector_index, sector_name])
      else
        @ui.sector.addItem("%02d" % sector_index)
      end
    end
    
    load_map()
  end
  
  def sector_index_changed(new_sector_index, force=false)
    if new_sector_index == @sector_index && !force
      return
    end
    @sector_index = new_sector_index
    @sector = @area.sectors[@sector_index]
    room_index_changed(0, force=true)
    @ui.room.clear()
    @sector.rooms.each_with_index do |room, room_index|
      @ui.room.addItem("%02d %08X" % [room_index, room.room_metadata_ram_pointer])
    end
  end
  
  def room_index_changed(new_room_index, force=false)
    if new_room_index == @room_index && !force
      return
    end
    @room_index = new_room_index
    @room = @sector.rooms[@room_index]
    
    load_layers()
  end
  
  def sector_and_room_indexes_changed(new_sector_index, new_room_index)
    puts "sector_and_room_indexes_changed: #{new_sector_index}, #{new_room_index}"
    @ui.sector.setCurrentIndex(new_sector_index)
    sector_index_changed(new_sector_index)
    @ui.room.setCurrentIndex(new_room_index)
    room_index_changed(new_room_index)
  end
  
  def load_layers()
    @room_graphics_scene.clear()
    
    @room.layers.each do |layer|
      tileset_filename = "../Exported #{GAME}/rooms/#{@room.area_name}/Tilesets/#{layer.tileset_filename}.png"
      unless File.exist?(tileset_filename)
        fs.load_overlay(AREA_INDEX_TO_OVERLAY_INDEX[@room.area_index][@room.sector_index])
        @renderer.render_tileset(layer.ram_pointer_to_tileset_for_layer, @room.palette_offset, @room.graphic_tilesets_for_room, layer.colors_per_palette, tileset_filename)
      end
      tileset = Qt::Image.new(tileset_filename)
      layer_item = Qt::GraphicsRectItem.new
      layer_item.setZValue(-layer.z_index)
      layer_item.setOpacity(layer.opacity/31.0)
      @room_graphics_scene.addItem(layer_item)
      
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
        tile_gfx.setParentItem(layer_item)
      end
    end
    
    #@room.doors.each_with_index do |door, i|
    #  x = door.x_pos
    #  y = door.y_pos
    #  x = -1 if x == 0xFF
    #  y = -1 if y == 0xFF
    #  x *= SCREEN_WIDTH_IN_PIXELS
    #  y *= SCREEN_HEIGHT_IN_PIXELS
    #  
    #  rect = Qt::GraphicsRectItem.new(x, y, 16*16, 12*16)
    #  rect.setBrush(Qt::Brush.new(Qt::Color.new(200, 0, 200, 50)))
    #  scene.addItem(rect)
    #end
  end
  
  def load_map()
    @map_graphics_scene.clear()
    
    @area.map.tiles.each do |tile|
      item = GraphicsMapTileItem.new(tile)
      connect(item, SIGNAL("room_clicked(int, int)"), self, SLOT("sector_and_room_indexes_changed(int, int)"))
      @map_graphics_scene.addItem(item)
    end
  end
  
  def open_enemy_dna_dialog
    @enemy_dialog = EnemyEditDialog.new(fs)
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
    File.open(@settings_path, "w") do |f|
      f.write(@settings.to_yaml)
    end
  end
  
  def open_in_tiled
    if @settings[:tiled_path].nil? || !File.exist?(@settings[:tiled_path]) || !File.file?(@settings[:tiled_path])
      Qt::MessageBox.warning(self, "Can't find Tiled", "You must specify where Tiled is installed.")
      return
    end
    folder = "../Exported #{GAME}/rooms"
    tmx_path = "#{folder}/#{@room.area_name}/#{@room.filename}.tmx"
    
    @renderer.ensure_tilesets_exist(folder, @room)
    @tiled.create(tmx_path, @room)
    system("start \"#{@settings[:tiled_path]}\" \"#{tmx_path}\"")
  end
  
  def import_from_tiled
    folder = "../Exported #{GAME}/rooms"
    tmx_path = "#{folder}/#{@room.area_name}/#{@room.filename}.tmx"
    if !File.exist?(tmx_path) || !File.file?(tmx_path)
      Qt::MessageBox.warning(self, "TMX file doesn't exist", "Can't find the TMX file. You must export to tiled first.")
      return
    end
    
    @tiled.read(tmx_path, @room)
    load_layers()
  end
  
  def save_files
    fs.commit_file_changes()
  end
  
  def write_to_rom(launch_emulator = false)
    if fs.has_uncommitted_files?
      answer = Qt::MessageBox.question(self, "Unsaved changes", "Save changed files before building?", Qt::MessageBox::Yes, Qt::MessageBox::No, Qt::MessageBox::Cancel)
      if answer == Qt::MessageBox::Yes
        save_files()
      elsif answer == Qt::MessageBox::Cancel
        return
      end
    end
    
    fs.write_to_rom("../#{GAME} hack.nds")
    
    if launch_emulator
      system("start \"#{@settings[:emulator_path]}\" \"../#{GAME} hack.nds\"")
    end
  end
  
  def build_and_run
    write_to_rom(launch_emulator = true)
  end
end

class GraphicsMapTileItem < Qt::GraphicsObject
  attr_reader :map_tile
  
  signals "room_clicked(int, int)"
  
  def initialize(map_tile)
    super(nil)
    
    @map_tile = map_tile
    
    @normal_fill_brush   = Qt::Brush.new(Qt::Color.new(*MAP_FILL_COLOR))
    @save_fill_brush     = Qt::Brush.new(Qt::Color.new(*MAP_SAVE_FILL_COLOR))
    @warp_fill_brush     = Qt::Brush.new(Qt::Color.new(*MAP_WARP_FILL_COLOR))
    @entrance_fill_brush = Qt::Brush.new(Qt::Color.new(*MAP_ENTRANCE_FILL_COLOR))
    @line_color          = Qt::Color.new(*MAP_LINE_COLOR)
    @door_color          = Qt::Color.new(*MAP_DOOR_COLOR)
    @door_center_color   = Qt::Color.new(*MAP_DOOR_CENTER_PIXEL_COLOR)
  end
  
  def pixel_x
    map_tile.x_pos*4
  end
  
  def pixel_y
    map_tile.y_pos*4
  end
  
  def boundingRect()
    return Qt::RectF.new(pixel_x, pixel_y, 5, 5)
  end
  
  def paint(painter, option, widget)
    painter.setPen(@line_color)
    x = pixel_x
    y = pixel_y
    
    if map_tile.is_blank
      # do nothing
    elsif map_tile.is_entrance
      painter.fillRect(x, y, 5, 5, @entrance_fill_brush)
    elsif map_tile.is_warp
      painter.fillRect(x, y, 5, 5, @warp_fill_brush)
    elsif map_tile.is_save
      painter.fillRect(x, y, 5, 5, @save_fill_brush)
    else
      painter.fillRect(x, y, 5, 5, @normal_fill_brush)
    end
    
    if map_tile.left_door
      painter.setPen(@door_color)
      painter.drawLine(x, y, x, y+1)
      painter.drawLine(x, y+3, x, y+4)
      painter.setPen(@door_center_color)
      painter.drawLine(x, y+2, x, y+2)
      painter.setPen(@line_color)
    elsif map_tile.left_wall
      painter.drawLine(x, y, x, y+4)
    end
    
    if map_tile.right_door # Never used in game because it would always get overwritten by the tile to the right.
      painter.setPen(@door_color)
      painter.drawLine(x+4, y, x+4, y+1)
      painter.drawLine(x+4, y+3, x+4, y+4)
      painter.setPen(@door_center_color)
      painter.drawLine(x+4, y+2, x+4, y+2)
      painter.setPen(@line_color)
    elsif map_tile.right_wall
      painter.drawLine(x+4, y, x+4, y+4)
    end
    
    if map_tile.top_door
      painter.setPen(@door_color)
      painter.drawLine(x, y, x+1, y)
      painter.drawLine(x+3, y, x+4, y)
      painter.setPen(@door_center_color)
      painter.drawLine(x+2, y, x+2, y)
      painter.setPen(@line_color)
    elsif map_tile.top_wall
      painter.drawLine(x, y, x+4, y)
    end
    
    if map_tile.bottom_door # Never used in game because it would always get overwritten by the tile below.
      painter.setPen(@door_color)
      painter.drawLine(x, y+4, x+1, y+4)
      painter.drawLine(x+3, y+4, x+4, y+4)
      painter.setPen(@door_center_color)
      painter.drawLine(x+2, y+4, x+2, y+4)
      painter.setPen(@line_color)
    elsif map_tile.bottom_wall
      painter.drawLine(x, y+4, x+4, y+4)
    end
  end
  
  def mousePressEvent(event)
    return if map_tile.is_blank
    emit room_clicked(map_tile.sector_index, map_tile.room_index)
  end
end

class EnemyEditDialog < Qt::Dialog
  slots "enemy_changed(int)"
  slots "weakness_button_pressed()"
  slots "resistance_button_pressed()"
  
  def initialize(fs)
    super()
    @ui = Ui_EnemyDNAEditor.new
    @ui.setup_ui(self)
    
    @fs = fs
    
    @enemies = []
    ENEMY_IDS.each do |enemy_id|
      enemy = EnemyDNA.new(enemy_id, fs)
      @enemies << enemy
      @ui.enemy_list.addItem("%03d %s" % [enemy_id+1, enemy.name])
    end
    connect(@ui.enemy_list, SIGNAL("currentRowChanged(int)"), self, SLOT("enemy_changed(int)"))
    
    self.setWindowFlags(Qt::MSWindowsFixedSizeDialogHint);
    
    self.show()
  end
  
  def enemy_changed(enemy_id)
    enemy = @enemies[enemy_id]
    
    @ui.name.setText(enemy.name.to_s)
    @ui.desc.setPlainText(enemy.description.to_s)
    
    @ui.item_1.setText(enemy.item1.to_s)
    @ui.item_2.setText(enemy.item2.to_s)
    @ui.hp.setText(enemy.max_hp.to_s)
    @ui.mp.setText(enemy.max_mp.to_s)
    @ui.attack.setText(enemy.attack.to_s)
    @ui.defense.setText(enemy.defense.to_s)
    @ui.soul.setText(enemy.soul.to_s)
    @ui.soul_chance.setText(enemy.soul_drop_chance.to_s)
    @ui.item_chance.setText(enemy.item_drop_chance.to_s)
    @ui.exp.setText(enemy.exp.to_s)
    #@ui.exp.setText(enemy.enemy_gfx_file[:file_path].to_s)
    @ui.init_ai.setText("%08X" % enemy.init_ai_ram_pointer)
    @ui.running_ai.setText("%08X" % enemy.running_ai_ram_pointer)
  end
end

$qApp = Qt::Application.new(ARGV)
DSVE.new
$qApp.exec
