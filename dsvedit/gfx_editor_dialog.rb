
require_relative 'ui_gfx_editor.rb'

class GfxEditorDialog < Qt::Dialog
  slots "load_gfx_file_and_palette_list()"
  slots "gfx_page_changed(int)"
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
    @gfx_file_graphics_scene.setBackgroundBrush(ClickableGraphicsScene::BACKGROUND_BRUSH)
    @ui.gfx_file_graphics_view.setScene(@gfx_file_graphics_scene)
    
    @palette_graphics_scene = ClickableGraphicsScene.new
    @ui.palette_graphics_view.setScene(@palette_graphics_scene)
    connect(@palette_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("palette_clicked(int, int, const Qt::MouseButton&)"))
    
    connect(@ui.view_button, SIGNAL("clicked()"), self, SLOT("load_gfx_file_and_palette_list()"))
    connect(@ui.gfx_index, SIGNAL("activated(int)"), self, SLOT("gfx_page_changed(int)"))
    connect(@ui.palette_index, SIGNAL("activated(int)"), self, SLOT("palette_changed(int)"))
    connect(@ui.one_dimensional_mode, SIGNAL("stateChanged(int)"), self, SLOT("toggle_one_dimensional_mapping_mode(int)"))
    connect(@ui.export_button, SIGNAL("clicked()"), self, SLOT("export_file()"))
    connect(@ui.import_gfx_button, SIGNAL("clicked()"), self, SLOT("import_gfx()"))
    connect(@ui.import_palette_button, SIGNAL("clicked()"), self, SLOT("import_palette()"))
    connect(@ui.generate_palette_from_files, SIGNAL("clicked()"), self, SLOT("generate_palette_from_multiple_files()"))
    
    if gfx_and_palette_data
      @ui.gfx_file_names.text = gfx_and_palette_data[:gfx_file_names]
      @ui.palette_pointer.text = "%08X" % gfx_and_palette_data[:palette_pointer]
      @ui.one_dimensional_mode.checked = !!gfx_and_palette_data[:one_dimensional_mode]
      load_gfx_file_and_palette_list()
      gfx_page_index = gfx_and_palette_data[:gfx_page_index]
      if (0..@gfx_pages.size-1).include?(gfx_page_index)
        gfx_page_changed(gfx_page_index)
      end
      palette_changed(gfx_and_palette_data[:palette_index])
    end
    
    if SYSTEM == :gba
      @ui.one_dimensional_mode.checked = true
      @ui.label_2.text = "GFX pointer(s)"
    end
    
    self.show()
  end
  
  def load_gfx_file_and_palette_list
    gfx_file_names = @ui.gfx_file_names.text.split(",")
    gfx_pages = []
    
    gfx_file_names.each do |gfx_file_name|
      gfx_file_name = gfx_file_name.strip
      
      if SYSTEM == :nds
        gfx_file = @fs.files_by_path[gfx_file_name]
        if gfx_file.nil?
          possible_asset_pointer = gfx_file_name.to_i(16)
          if @fs.is_pointer?(possible_asset_pointer)
            gfx_file = @fs.assets_by_pointer[possible_asset_pointer]
            if gfx_file.nil?
              possible_gfx_data_pointer = @fs.read(possible_asset_pointer+8, 4).unpack("V").first
              if @fs.is_pointer?(possible_gfx_data_pointer)
                gfx = GfxWrapper.new(possible_asset_pointer, @fs)
                gfx_pages << gfx
                next
              end
            end
          end
        end
        
        if gfx_file.nil?
          Qt::MessageBox.warning(self, "Not a file", "Couldn't find file with path: #{gfx_file_name}")
          return
        end
        
        gfx = GfxWrapper.new(gfx_file[:asset_pointer], @fs)
        gfx_pages << gfx
      else
        gfx_pointer = gfx_file_name.to_i(16)
        gfx = GfxWrapper.new(gfx_pointer, @fs)
        gfx_pages << gfx
      end
    end
    
    success = load_palettes(gfx_pages.first.colors_per_palette)
    return unless success
    
    @palette_index = 0
    @gfx_index = 0
    
    #@gfx = gfx
    @gfx_pages = gfx_pages
    
    @ui.gfx_index.clear()
    @gfx_pages.each_index do |i|
      @ui.gfx_index.addItem("%02X" % i)
    end
    
    @colors_per_palette = @gfx_pages.first.colors_per_palette
    
    load_gfx()
    
    load_palette_image()
    
    @ui.palette_index.clear()
    @palettes.each_index do |i|
      @ui.palette_index.addItem("%02X" % i)
    end
    
    if SYSTEM == :nds
      @ui.gfx_file_names.text = @gfx_pages.map do |gfx|
        if gfx.file
          gfx.file[:file_path]
        else
          "%08X" % gfx.gfx_pointer
        end
      end.join(", ")
    else
      @ui.gfx_file_names.text = @gfx_pages.map{|gfx| "%08X" % gfx.gfx_pointer}.join(", ")
    end
    @ui.palette_pointer.text = "%08X" % @palette_pointer
  rescue StandardError => e
    Qt::MessageBox.warning(self, "Error", "Error loading gfx:\n#{e.message}\n\n#{e.backtrace.join("\n")}")
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
    gfx = @gfx_pages[@gfx_index]
    palette = @palettes[@palette_index]
    
    if @ui.one_dimensional_mode.checked
      chunky_image = @renderer.render_gfx_1_dimensional_mode(gfx, palette)
    else
      chunky_image = @renderer.render_gfx_page(gfx.file, palette, gfx.canvas_width)
    end
    
    pixmap = Qt::Pixmap.new
    blob = chunky_image.to_blob
    pixmap.loadFromData(blob, blob.length)
    gfx_page_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
    @gfx_file_graphics_scene.clear()
    @gfx_file_graphics_scene.addItem(gfx_page_pixmap_item)
    @gfx_file_graphics_scene.setSceneRect(0, 0, gfx.canvas_width*8, gfx.canvas_width*8)
  rescue GBADummyFilesystem::ReadError => e
    message = "There was an error trying to load the GFX asset(s) #{@ui.gfx_file_names.text}.\n"
    message << "Are you sure this is a valid GFX asset?"
    Qt::MessageBox.warning(self,
      "Error loading GFX",
      message
    )
  end
  
  def gfx_page_changed(gfx_index)
    @gfx_index = gfx_index
    
    load_gfx()
    
    @ui.gfx_index.setCurrentIndex(gfx_index)
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
    
    if clicked_palette_index >= @colors_per_palette
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
    @renderer.save_palette(palette, @palette_pointer, @palette_index, @colors_per_palette)
    
    load_palettes(@colors_per_palette)
    load_gfx()
    load_palette_image()
  end
  
  def toggle_one_dimensional_mapping_mode(checked)
    return if @palettes.nil? || @palette_index.nil?
    load_gfx()
  end
  
  def export_file
    return if @palettes.nil? || @palette_index.nil?
    
    palette = @palettes[@palette_index]
    palette_name = "palette_%08X-%02X" % [@palette_pointer, @palette_index]
    
    @gfx_pages.each do |gfx|
      if gfx.file
        gfx_name = gfx.file[:name]
      else
        gfx_name = "%08X" % gfx.gfx_pointer
      end
      
      if @ui.one_dimensional_mode.checked
        chunky_image = @renderer.render_gfx_1_dimensional_mode(gfx, palette)
      else
        chunky_image = @renderer.render_gfx_page(gfx.file, palette, gfx.canvas_width)
      end
      file_basename = File.basename(gfx_name, ".*")
      gfx_file_path = "#{@output_folder}/#{file_basename}_#{palette_name}.png"
      chunky_image.save(gfx_file_path, :fast_rgba)
    end
    
    palette_file_path = "#{@output_folder}/#{palette_name}.png"
    @renderer.export_palette_to_palette_swatches_file(palette, palette_file_path)
    
    @ui.info_label.text = "Exported gfx and palette to folder ./#{@output_folder}"
  end
  
  def import_gfx
    return if @palettes.nil? || @palette_index.nil?
    
    input_images = []
    has_colors_outside_palette = false
    @gfx_pages.each do |gfx|
      if gfx.file
        gfx_name = gfx.file[:name]
      else
        gfx_name = "%08X" % gfx.gfx_pointer
      end
      
      file_basename = File.basename(gfx_name, ".*")
      palette_name = "palette_%08X-%02X" % [@palette_pointer, @palette_index]
      gfx_file_path = "#{@output_folder}/#{file_basename}_#{palette_name}.png"
      unless File.file?(gfx_file_path)
        Qt::MessageBox.warning(self, "No file", "Could not find file #{gfx_file_path} to import.")
        return
      end
      
      input_image = ChunkyPNG::Image.from_file(gfx_file_path)
      input_images << input_image
      
      if !@renderer.check_image_uses_palette(input_image, @palette_pointer, @colors_per_palette, @palette_index)
        has_colors_outside_palette = true
      end
    end
    
    if has_colors_outside_palette
      response = Qt::MessageBox.question(self, "Convert colors", "One or more of the images you're trying to import have colors that aren't in the current palette (%08X-%02X).\n\nWould you like DSVEdit to convert the colors in the image to the closest-looking colors that are in this palette?\nIf not, no images will be imported." % [@palette_pointer, @palette_index],
        Qt::MessageBox::Cancel | Qt::MessageBox::Yes, Qt::MessageBox::Cancel)
      
      if response == Qt::MessageBox::Yes
        should_convert_image_to_palette = true
      elsif response == Qt::MessageBox::Cancel
        return
      end
    else
      should_convert_image_to_palette = false
    end
    
    @gfx_pages.each_with_index do |gfx, i|
      input_image = input_images[i]
      
      if @ui.one_dimensional_mode.checked
        @renderer.save_gfx_page_1_dimensional_mode(input_image, gfx, @palette_pointer, @colors_per_palette, @palette_index, should_convert_image_to_palette: should_convert_image_to_palette)
      else
        @renderer.save_gfx_page(input_image, gfx, @palette_pointer, @colors_per_palette, @palette_index, should_convert_image_to_palette: should_convert_image_to_palette)
      end
    end
    
    load_gfx()
  rescue Renderer::GFXImportError => e
    Qt::MessageBox.warning(self,
      "GFX import error",
      e.message
    )
  rescue GBADummyFilesystem::CompressedDataTooLarge => e
    Qt::MessageBox.warning(self,
      "Compressed write error",
      e.message
    )
  end
  
  def import_palette
    return if @palettes.nil? || @palette_index.nil?
    
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
      return
    end
    
    load_palettes(@colors_per_palette)
    load_gfx()
    load_palette_image()
  end
  
  def generate_palette_from_multiple_files
    return if @palettes.nil? || @palette_index.nil?
    
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
      return
    end
    
    @renderer.save_palette(colors, @palette_pointer, @palette_index, @colors_per_palette)
    
    load_palettes(@colors_per_palette)
    load_gfx()
    load_palette_image()
  end
end
