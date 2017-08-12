
require_relative 'ui_gfx_editor.rb'

class GfxEditorDialog < Qt::Dialog
  slots "load_gfx_file_and_palette_list()"
  slots "palette_changed(int)"
  slots "toggle_one_dimensional_mapping_mode(int)"
  slots "export_file()"
  slots "import_gfx()"
  slots "import_palette()"
  slots "palette_clicked(int, int, const Qt::MouseButton&)"
  slots "generate_palette_from_multiple_files()"
  
  def initialize(parent, fs, renderer, gfx_and_palette_data=nil)
    super(parent, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    
    @fs = fs
    @renderer = renderer
    
    @output_folder = "gfx"
    FileUtils.mkdir_p(@output_folder)
    
    @ui = Ui_GfxEditor.new
    @ui.setup_ui(self)
    
    @gfx_file_graphics_scene = Qt::GraphicsScene.new
    @ui.gfx_file_graphics_view.setScene(@gfx_file_graphics_scene)
    
    @palette_graphics_scene = ClickableGraphicsScene.new
    @ui.palette_graphics_view.setScene(@palette_graphics_scene)
    connect(@palette_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("palette_clicked(int, int, const Qt::MouseButton&)"))
    
    connect(@ui.view_button, SIGNAL("clicked()"), self, SLOT("load_gfx_file_and_palette_list()"))
    connect(@ui.palette_index, SIGNAL("activated(int)"), self, SLOT("palette_changed(int)"))
    connect(@ui.one_dimensional_mode, SIGNAL("stateChanged(int)"), self, SLOT("toggle_one_dimensional_mapping_mode(int)"))
    connect(@ui.export_button, SIGNAL("clicked()"), self, SLOT("export_file()"))
    connect(@ui.import_gfx_button, SIGNAL("clicked()"), self, SLOT("import_gfx()"))
    connect(@ui.import_palette_button, SIGNAL("clicked()"), self, SLOT("import_palette()"))
    connect(@ui.generate_palette_from_files, SIGNAL("clicked()"), self, SLOT("generate_palette_from_multiple_files()"))
    
    if SYSTEM == :gba
      @ui.one_dimensional_mode.checked = true
      @ui.label_2.text = "GFX pointer"
    end
    
    if gfx_and_palette_data
      @ui.gfx_file_name.text = gfx_and_palette_data[:gfx_file_name]
      @ui.palette_pointer.text = "%08X" % gfx_and_palette_data[:palette_pointer]
      load_gfx_file_and_palette_list()
      palette_changed(gfx_and_palette_data[:palette_index])
    end
    
    self.show()
  end
  
  def load_gfx_file_and_palette_list
    if SYSTEM == :nds
      gfx_file = @fs.files_by_path[@ui.gfx_file_name.text.strip]
      if gfx_file.nil?
        possible_asset_pointer = @ui.gfx_file_name.text.to_i(16)
        if @fs.is_pointer?(possible_asset_pointer)
          gfx_file = @fs.assets_by_pointer[possible_asset_pointer]
        end
      end
      if gfx_file.nil?
        Qt::MessageBox.warning(self, "Not a file", "Couldn't find file with path: #{@ui.gfx_file_name.text}")
        return
      end
      
      gfx = GfxWrapper.new(gfx_file[:asset_pointer], @fs)
      
      @gfx_path = gfx.file[:file_path]
      @gfx_name = gfx.file[:name]
    else
      gfx_pointer = @ui.gfx_file_name.text.to_i(16)
      gfx = GfxWrapper.new(gfx_pointer, @fs)
      
      @gfx_path = "%08X" % gfx.gfx_pointer
      @gfx_name = @gfx_path
    end
    
    success = load_palettes(gfx.colors_per_palette)
    return unless success
    
    @palette_index = 0
    
    @gfx = gfx
    
    load_gfx()
    
    load_palette_image()
    
    @ui.palette_index.clear()
    @palettes.each_index do |i|
      @ui.palette_index.addItem("%02X" % i)
    end
    
    @ui.gfx_file_name.text = @gfx_path
    @ui.palette_pointer.text = "%08X" % @palette_pointer
  end
  
  def load_palettes(colors_per_palette)
    palette_pointer = @ui.palette_pointer.text.to_i(16)
    
    begin
      palettes = @renderer.generate_palettes(palette_pointer, colors_per_palette)
    rescue NDSFileSystem::ConversionError => e
      Qt::MessageBox.warning(self, "Invalid pointer", "Palette list pointer is invalid.")
      return false
    end
    if palettes.empty?
      Qt::MessageBox.warning(self, "Invalid pointer", "Palette list pointer is invalid.")
      return false
    end
    
    @palette_pointer = palette_pointer
    @palettes = palettes
    return true
  end
  
  def load_gfx
    if @ui.one_dimensional_mode.checked
      chunky_image = @renderer.render_gfx_1_dimensional_mode(@gfx, @palettes[@palette_index])
    else
      chunky_image = @renderer.render_gfx_page(@gfx.file, @palettes[@palette_index], @gfx.canvas_width)
    end
    
    pixmap = Qt::Pixmap.new
    blob = chunky_image.to_blob
    pixmap.loadFromData(blob, blob.length)
    gfx_page_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
    @gfx_file_graphics_scene.clear()
    @gfx_file_graphics_scene.addItem(gfx_page_pixmap_item)
    @gfx_file_graphics_scene.setSceneRect(0, 0, @gfx.canvas_width*8, @gfx.canvas_width*8)
  rescue GBADummyFilesystem::ReadError => e
    message = "There was an error trying to load the GFX asset #{@ui.gfx_file_name.text}.\n"
    message << "Are you sure this is a valid GFX asset?"
    if SYSTEM == :gba
      message << "\n\nNote that the GFX editor does not yet support displaying Aria of Sorrow's weapon GFX."
    end
    Qt::MessageBox.warning(self,
      "Error loading GFX",
      message
    )
  end
  
  def palette_changed(palette_index)
    @palette_index = palette_index
    
    load_gfx()
    
    load_palette_image()
    
    @ui.palette_index.setCurrentIndex(palette_index)
  end
  
  def load_palette_image
    palette = @palettes[@palette_index]
    palette_image = @renderer.convert_palette_to_palette_swatches_image(palette)
    
    pixmap = Qt::Pixmap.new
    blob = palette_image.to_blob
    pixmap.loadFromData(blob, blob.length)
    palette_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
    @palette_graphics_scene.clear()
    @palette_graphics_scene.addItem(palette_pixmap_item)
    @palette_graphics_scene.setSceneRect(0, 0, 256, 256)
  end
  
  def palette_clicked(x, y, button)
    return unless (0..@palette_graphics_scene.width-1).include?(x) && (0..@palette_graphics_scene.height-1).include?(y)
    
    clicked_palette_index = (x/16) + (y/16) * 16
    
    if clicked_palette_index >= @gfx.colors_per_palette
      return
    end
    
    palette = @palettes[@palette_index]
    initial_chunky_color = palette[clicked_palette_index]
    r, g, b = ChunkyPNG::Color.to_truecolor_bytes(initial_chunky_color)
    initial_color = Qt::Color.new(r, g, b)
    color = Qt::ColorDialog.getColor(initial_color, self, "Select color")
    
    unless color.isValid
      # User clicked cancel.
      return
    end
    
    new_chunky_color = ChunkyPNG::Color.rgb(color.red, color.green, color.blue)
    palette[clicked_palette_index] = new_chunky_color
    @renderer.save_palette(palette, @palette_pointer, @palette_index, @gfx.colors_per_palette)
    
    load_palettes(@gfx.colors_per_palette)
    load_gfx()
    load_palette_image()
  end
  
  def toggle_one_dimensional_mapping_mode(checked)
    return if @gfx.nil? || @palettes.nil? || @palette_index.nil?
    load_gfx()
  end
  
  def export_file
    return if @gfx.nil? || @palettes.nil? || @palette_index.nil?
    
    if @ui.one_dimensional_mode.checked
      chunky_image = @renderer.render_gfx_1_dimensional_mode(@gfx, @palettes[@palette_index])
    else
      chunky_image = @renderer.render_gfx_page(@gfx.file, @palettes[@palette_index], @gfx.canvas_width)
    end
    file_basename = File.basename(@gfx_name, ".*")
    palette_name = "palette_%08X-%02X" % [@palette_pointer, @palette_index]
    gfx_file_path = "#{@output_folder}/#{file_basename}_#{palette_name}.png"
    chunky_image.save(gfx_file_path)
    palette_file_path = "#{@output_folder}/#{palette_name}.png"
    @renderer.export_palette_to_palette_swatches_file(@palettes[@palette_index], palette_file_path)
    
    @ui.info_label.text = "Exported gfx and palette to folder ./#{@output_folder}"
  end
  
  def import_gfx
    return if @gfx.nil? || @palettes.nil? || @palette_index.nil?
    
    file_basename = File.basename(@gfx_name, ".*")
    palette_name = "palette_%08X-%02X" % [@palette_pointer, @palette_index]
    gfx_file_path = "#{@output_folder}/#{file_basename}_#{palette_name}.png"
    unless File.file?(gfx_file_path)
      Qt::MessageBox.warning(self, "No file", "Could not find file #{gfx_file_path} to import.")
      return
    end
    
    begin
      if @ui.one_dimensional_mode.checked
        @renderer.import_gfx_page_1_dimensional_mode(gfx_file_path, @gfx, @palette_pointer, @gfx.colors_per_palette, @palette_index)
      else
        @renderer.import_gfx_page(gfx_file_path, @gfx, @palette_pointer, @gfx.colors_per_palette, @palette_index)
      end
    rescue Renderer::GFXImportError => e
      Qt::MessageBox.warning(self,
        "GFX import error",
        e.message
      )
      return
    end
    
    load_gfx()
  end
  
  def import_palette
    return if @gfx.nil? || @palettes.nil? || @palette_index.nil?
    
    palette_file_path = "#{@output_folder}/palette_%08X-%02X.png" % [@palette_pointer, @palette_index]
    unless File.file?(palette_file_path)
      Qt::MessageBox.warning(self, "No file", "Could not find file #{palette_file_path} to import.")
      return
    end
    
    begin
      colors = @renderer.import_palette_from_palette_swatches_file(palette_file_path, @gfx.colors_per_palette)
      @renderer.save_palette(colors, @palette_pointer, @palette_index, @gfx.colors_per_palette)
    rescue Renderer::GFXImportError => e
      Qt::MessageBox.warning(self,
        "Palette generation error",
        e.message
      )
      return
    end
    
    load_palettes(@gfx.colors_per_palette)
    load_gfx()
    load_palette_image()
  end
  
  def generate_palette_from_multiple_files
    return if @gfx.nil? || @palettes.nil? || @palette_index.nil?
    
    default_dir = @output_folder
    filenames = Qt::FileDialog.getOpenFileNames(self, "Select gfx file(s)", default_dir, "PNG Files (*.png)")
    return if filenames.empty?
    
    begin
      colors = @renderer.import_palette_from_multiple_files(filenames, @gfx.colors_per_palette)
    rescue Renderer::GFXImportError => e
      Qt::MessageBox.warning(self,
        "Palette generation error",
        e.message
      )
      return
    end
    
    @renderer.save_palette(colors, @palette_pointer, @palette_index, @gfx.colors_per_palette)
    
    load_palettes(@gfx.colors_per_palette)
    load_gfx()
    load_palette_image()
  end
end
