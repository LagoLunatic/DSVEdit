
require_relative 'ui_gfx_editor.rb'

class GfxEditorDialog < Qt::Dialog
  slots "load_gfx_file_and_palette_list()"
  slots "palette_changed(int)"
  slots "export_file()"
  slots "import_gfx()"
  slots "import_palette()"
  slots "generate_palette_from_multiple_files()"
  
  def initialize(parent, fs, renderer)
    super(parent, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    
    @fs = fs
    @renderer = renderer
    
    @output_folder = "gfx"
    FileUtils.mkdir_p(@output_folder)
    
    @ui = Ui_GfxEditor.new
    @ui.setup_ui(self)
    
    @gfx_file_graphics_scene = Qt::GraphicsScene.new
    @ui.gfx_file_graphics_view.setScene(@gfx_file_graphics_scene)
    
    connect(@ui.view_button, SIGNAL("clicked()"), self, SLOT("load_gfx_file_and_palette_list()"))
    connect(@ui.palette_index, SIGNAL("activated(int)"), self, SLOT("palette_changed(int)"))
    connect(@ui.export_button, SIGNAL("clicked()"), self, SLOT("export_file()"))
    connect(@ui.import_gfx_button, SIGNAL("clicked()"), self, SLOT("import_gfx()"))
    connect(@ui.import_palette_button, SIGNAL("clicked()"), self, SLOT("import_palette()"))
    connect(@ui.generate_palette_from_files, SIGNAL("clicked()"), self, SLOT("generate_palette_from_multiple_files()"))
    
    self.show()
  end
  
  def load_gfx_file_and_palette_list
    gfx_file = @fs.files_by_path[@ui.gfx_file_name.text.strip]
    if gfx_file.nil?
      Qt::MessageBox.warning(self, "Not a file", "Couldn't find file with path: #{@ui.gfx_file_name.text}")
      return
    end
    
    _, render_mode, canvas_width, _ = @fs.read(gfx_file[:ram_start_offset], 4).unpack("C*")
    if render_mode == 1
      colors_per_palette = 16
    else
      colors_per_palette = 256
    end
    
    success = load_palettes(colors_per_palette)
    return unless success
    
    @palette_index = 0
    
    @gfx_file = gfx_file
    @colors_per_palette = colors_per_palette
    @canvas_width = canvas_width
    
    load_gfx()
    
    @ui.palette_index.clear()
    @palettes.each_index do |i|
      @ui.palette_index.addItem("%02X" % i)
    end
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
    chunky_image = @renderer.render_gfx_page(@gfx_file, @palettes[@palette_index], @canvas_width)
    
    pixmap = Qt::Pixmap.new
    blob = chunky_image.to_blob
    pixmap.loadFromData(blob, blob.length)
    gfx_page_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
    @gfx_file_graphics_scene.clear()
    @gfx_file_graphics_scene.addItem(gfx_page_pixmap_item)
  end
  
  def palette_changed(palette_index)
    @palette_index = palette_index
    
    load_gfx()
    
    @ui.palette_index.setCurrentIndex(palette_index)
  end
  
  def export_file
    return if @gfx_file.nil? || @palettes.nil? || @palette_index.nil?
    
    chunky_image = @renderer.render_gfx_page(@gfx_file, @palettes[@palette_index], @canvas_width)
    file_basename = File.basename(@gfx_file[:name], ".*")
    gfx_file_path = "#{@output_folder}/#{file_basename}.png"
    chunky_image.save(gfx_file_path)
    palette_file_path = "#{@output_folder}/palette_%08X-%02X.png" % [@palette_pointer, @palette_index]
    @renderer.export_palette_to_palette_swatches_file(@palettes[@palette_index], palette_file_path)
    
    @ui.info_label.text = "Exported gfx and palette to folder ./#{@output_folder}"
  end
  
  def import_gfx
    return if @gfx_file.nil? || @palettes.nil? || @palette_index.nil?
    
    file_basename = File.basename(@gfx_file[:name], ".*")
    file_path = "#{@output_folder}/#{file_basename}.png"
    unless File.file?(file_path)
      Qt::MessageBox.warning(self, "No file", "Could not find file #{file_path} to import.")
      return
    end
    
    begin
      @renderer.import_gfx_page(file_path, @gfx_file, @palette_pointer, @colors_per_palette, @palette_index)
    rescue Renderer::GFXImportError => e
      Qt::MessageBox.warning(self,
        "GFX import error",
        e.message
      )
    end
    
    load_palettes(@colors_per_palette)
    load_gfx()
  end
  
  def import_palette
    return if @gfx_file.nil? || @palettes.nil? || @palette_index.nil?
    
    palette_file_path = "#{@output_folder}/palette_%08X-%02X.png" % [@palette_pointer, @palette_index]
    unless File.file?(palette_file_path)
      Qt::MessageBox.warning(self, "No file", "Could not find file #{palette_file_path} to import.")
      return
    end
    
    begin
      colors = @renderer.import_palette_from_palette_swatches_file(palette_file_path, @colors_per_palette)
      @renderer.save_palette(colors, @palette_pointer, @palette_index, @colors_per_palette)
    rescue Renderer::GFXImportError => e
      Qt::MessageBox.warning(self,
        "Palette generation error",
        e.message
      )
    end
    
    load_palettes(@colors_per_palette)
    load_gfx()
  end
  
  def generate_palette_from_multiple_files
    return if @gfx_file.nil? || @palettes.nil? || @palette_index.nil?
    
    default_dir = @output_folder
    filenames = Qt::FileDialog.getOpenFileNames(self, "Select gfx file(s)", default_dir, "PNG Files (*.png)")
    return if filenames.empty?
    
    begin
      colors = @renderer.import_palette_from_multiple_files(filenames, @colors_per_palette)
    rescue Renderer::GFXImportError => e
      Qt::MessageBox.warning(self,
        "Palette generation error",
        e.message
      )
    end
    
    @renderer.save_palette(colors, @palette_pointer, @palette_index, @colors_per_palette)
    
    load_palettes(@colors_per_palette)
    load_gfx()
  end
end
