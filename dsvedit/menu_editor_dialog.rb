
require_relative 'ui_menu_editor'

class MenuEditorDialog < Qt::Dialog
  slots "menu_changed(int)"
  slots "open_in_gfx_editor()"
  slots "open_in_tiled()"
  slots "import_from_tiled()"
  slots "load_menu()"
  
  def initialize(main_window, fs, renderer)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_MenuEditor.new
    @ui.setup_ui(self)
    
    @fs = fs
    @renderer = renderer
    
    @layer_graphics_scene = Qt::GraphicsScene.new
    @ui.layer_graphics_view.setScene(@layer_graphics_scene)
    @ui.layer_graphics_view.setDragMode(Qt::GraphicsView::ScrollHandDrag)
    self.setStyleSheet("QGraphicsView { background-color: transparent; }");
    
    MENU_BG_LAYER_INFOS.each do |menu_info|
      @ui.menu_list.addItem(menu_info[:name])
    end
    
    connect(@ui.menu_list, SIGNAL("currentRowChanged(int)"), self, SLOT("menu_changed(int)"))
    connect(@ui.open_in_gfx_editor, SIGNAL("clicked()"), self, SLOT("open_in_gfx_editor()"))
    connect(@ui.tiled_export, SIGNAL("clicked()"), self, SLOT("open_in_tiled()"))
    connect(@ui.tiled_import, SIGNAL("clicked()"), self, SLOT("import_from_tiled()"))
    connect(@ui.reload_button, SIGNAL("released()"), self, SLOT("load_menu()"))
    
    load_blank_menu()
    
    self.show()
  end
  
  def load_blank_menu
    @is_menu_loaded = false
    
    @layer_metadata_pointer = nil
    @gfx_list_pointer       = nil
    @gfx_file_pointer       = nil
    @palette_list_pointer   = nil
  end
  
  def menu_changed(menu_index)
    menu_info = MENU_BG_LAYER_INFOS[menu_index]
    
    layer_metadata_pointer = menu_info[:layer_metadata_pointer]
    gfx_list_pointer       = menu_info[:gfx_list_pointer] || 0
    gfx_file_pointer       = menu_info[:gfx_file_pointer] || 0
    palette_list_pointer   = menu_info[:palette_list_pointer]
    
    @ui.bg_layer_pointer.text     = "%08X" % layer_metadata_pointer
    @ui.gfx_list_pointer.text     = "%08X" % gfx_list_pointer
    @ui.gfx_file_pointer.text     = "%08X" % gfx_file_pointer
    @ui.palette_list_pointer.text = "%08X" % palette_list_pointer
    
    load_menu()
  end
  
  def load_menu
    @layer_graphics_scene.clear()
    
    @layer_metadata_pointer = @ui.bg_layer_pointer.text.to_i(16)
    @gfx_list_pointer       = @ui.gfx_list_pointer.text.to_i(16)
    @gfx_file_pointer       = @ui.gfx_file_pointer.text.to_i(16)
    @palette_list_pointer   = @ui.palette_list_pointer.text.to_i(16)
    
    @gfx_list_pointer = nil if @gfx_list_pointer == 0
    @gfx_file_pointer = nil if @gfx_file_pointer == 0
    
    if (@gfx_list_pointer || @gfx_file_pointer) && @layer_metadata_pointer && @palette_list_pointer
      @is_menu_loaded = true
    else
      load_blank_menu()
      return
    end
    
    @bg_layer = BGLayer.new(@layer_metadata_pointer, @fs)
    @bg_layer.read_from_rom()
    
    if @gfx_list_pointer
      @tileset_path = @renderer.render_tileset_for_bg_layer_by_gfx_list(@bg_layer, @gfx_list_pointer, @palette_list_pointer)
    else
      @tileset_path = @renderer.render_tileset_for_bg_layer_by_gfx_asset(@bg_layer, @gfx_file_pointer, @palette_list_pointer)
    end
    
    layer_item = LayerItem.new(@bg_layer, @tileset_path)
    @layer_graphics_scene.addItem(layer_item)
  rescue StandardError => e
    load_blank_menu()
    Qt::MessageBox.warning(self,
      "Failed to render menu",
      "Failed to render menu.\n#{e.message}\n\n#{e.backtrace.join("\n")}"
    )
    return
  end
  
  def open_in_gfx_editor
    return unless @is_menu_loaded
    
    gfx_and_palette_data = {}
    
    if @gfx_list_pointer
      gfx_wrappers = GfxWrapper.from_gfx_list_pointer(@gfx_list_pointer, @fs)
    elsif @gfx_file_pointer
      gfx_wrappers = [GfxWrapper.new(@gfx_file_pointer, @fs)]
    else
      return
    end
    gfx_and_palette_data[:gfx_file_names] = gfx_wrappers.map{|gfx| "%08X" % gfx.gfx_pointer}.join(", ")
    
    gfx_and_palette_data[:palette_pointer] = @palette_list_pointer
    
    gfx_and_palette_data[:one_dimensional_mode] = true
    
    parent.open_gfx_editor(gfx_and_palette_data)
  end
  
  def open_in_tiled
    return unless @is_menu_loaded
    
    invalid = parent.check_invalid_tiled_path()
    return if invalid
    
    folder = "cache/#{GAME}/menus"
    tmx_path = "#{folder}/%08X.tmx" % @bg_layer.layer_metadata_ram_pointer
    
    parent.tiled.export_tmx_menu_bg_layer(tmx_path, @bg_layer, @tileset_path)
    
    system("start \"#{parent.settings[:tiled_path]}\" \"#{tmx_path}\"")
  rescue StandardError => e
    Qt::MessageBox.warning(self,
      "Failed to export to Tiled",
      "Failed to export to Tiled:\n#{e.message}\n\n#{e.backtrace.join("\n")}"
    )
  end
  
  def import_from_tiled
    return unless @is_menu_loaded
    
    folder = "cache/#{GAME}/menus"
    tmx_path = "#{folder}/%08X.tmx" % @bg_layer.layer_metadata_ram_pointer
    
    parent.tiled.import_tmx_menu_bg_layer(tmx_path, @bg_layer)
    
    load_menu()
  rescue FreeSpaceManager::FreeSpaceFindError => e
    load_blank_menu()
    Qt::MessageBox.warning(self,
      "Failed to find free space",
      "Failed to find free space to put the expanded layer.\n\n#{NO_FREE_SPACE_MESSAGE}"
    )
  rescue TMXInterface::ImportError => e
    load_blank_menu()
    Qt::MessageBox.warning(self, "Error importing from Tiled", e.message)
  end
  
  def inspect; to_s; end
end
