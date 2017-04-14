
require_relative 'ui_icon_chooser.rb'

class IconChooserDialog < Qt::Dialog
  RED_PEN_COLOR = Qt::Pen.new(Qt::Color.new(255, 0, 0))
  
  slots "gfx_page_changed(int)"
  slots "palette_changed(int)"
  slots "icon_changed(int)"
  slots "change_icon_by_page_x_and_y(int, int, const Qt::MouseButton&)"
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(parent, fs, mode=:item, icon_data=0)
    super(parent, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    
    @fs = fs
    @renderer = Renderer.new(@fs)
    @mode = mode
    
    @ui = Ui_IconChooser.new
    @ui.setup_ui(self)
    
    @gfx_file_graphics_scene = ClickableGraphicsScene.new
    @ui.gfx_file_graphics_view.setScene(@gfx_file_graphics_scene)
    
    connect(@ui.gfx_page_index, SIGNAL("activated(int)"), self, SLOT("gfx_page_changed(int)"))
    connect(@ui.palette_index, SIGNAL("activated(int)"), self, SLOT("palette_changed(int)"))
    connect(@ui.icon_index, SIGNAL("activated(int)"), self, SLOT("icon_changed(int)"))
    connect(@gfx_file_graphics_scene, SIGNAL("clicked(int, int, const Qt::MouseButton&)"), self, SLOT("change_icon_by_page_x_and_y(int, int, const Qt::MouseButton&)"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_pressed(QAbstractButton*)"))
    
    if mode == :item
      initial_icon_index, initial_palette_index = GenericEditable.extract_icon_index_and_palette_index(icon_data)
      @ui.palette_index.setEnabled(true)
    else
      initial_icon_index = icon_data
      initial_palette_index = 2
      @ui.palette_index.setEnabled(false)
    end
    
    @icon_width = mode == :item ? 16 : 32
    @icon_height = @icon_width
    @icons_per_row = 128 / @icon_width
    @icons_per_column = 128 / @icon_height
    @icons_per_page = 128*128 / @icon_width / @icon_width
    
    filename = mode == :item ? "item" : "rune"
    @gfx_pages = @renderer.icon_gfx_pages(mode)
    @palette_pointer = mode == :item ? ITEM_ICONS_PALETTE_POINTER : GLYPH_ICONS_PALETTE_POINTER
    
    @palettes = @renderer.generate_palettes(@palette_pointer, 16)
    
    @gfx_page_pixmaps_by_palette = {}
    
    @ui.gfx_page_index.clear()
    @gfx_pages.each_with_index do |gfx_page, i|
      @ui.gfx_page_index.addItem(i.to_s)
    end
    @ui.gfx_page_index.setCurrentIndex(0)
    
    @ui.palette_pointer.text = "%08X" % @palette_pointer
    
    @ui.palette_index.clear()
    @palettes.each_with_index do |palette, i|
      @ui.palette_index.addItem("%02X" % i)
    end
    palette_changed(initial_palette_index, force=true)
    
    @ui.icon_index.clear()
    number_of_icons = @gfx_pages.length*@icons_per_page
    (0..number_of_icons-1).each do |i|
      @ui.icon_index.addItem("%02X" % i)
    end
    icon_changed(initial_icon_index)
    
    self.show()
  end
  
  def load_gfx_pages(palette_index)
    @gfx_page_pixmaps_by_palette[palette_index] ||= @gfx_pages.map do |gfx_page|
      if gfx_page.nil?
        nil
      else
        if @mode == :item
          chunky_image = @renderer.render_gfx_1_dimensional_mode(gfx_page, @palettes[palette_index])
        else
          chunky_image = @renderer.render_gfx_page(gfx_page.file, @palettes[palette_index])
        end
        
        pixmap = Qt::Pixmap.new
        blob = chunky_image.to_blob
        pixmap.loadFromData(blob, blob.length)
        gfx_page_pixmap_item = Qt::GraphicsPixmapItem.new(pixmap)
        gfx_page_pixmap_item
      end
    end
  end
  
  def gfx_page_changed(i)
    @gfx_file_graphics_scene.items.each do |item|
      @gfx_file_graphics_scene.removeItem(item)
    end
    
    pixmap = @gfx_page_pixmaps_by_palette[@palette_index][i]
    if pixmap.nil?
      @ui.gfx_file_name.text = "Invalid"
    else
      @gfx_file_graphics_scene.addItem(pixmap)
      gfx_page = @gfx_pages[i]
      if SYSTEM == :nds
        @ui.gfx_file_name.text = gfx_page.file[:file_path]
      else
        @ui.gfx_file_name.text = "%08X" % gfx_page.gfx_pointer
      end
    end
    
    @ui.gfx_page_index.setCurrentIndex(i)
    
    @selection_rectangle = Qt::GraphicsRectItem.new
    @selection_rectangle.setPen(RED_PEN_COLOR)
    @gfx_file_graphics_scene.addItem(@selection_rectangle)
  end
  
  def palette_changed(palette_index, force=false)
    if palette_index == @palette_index && !force
      return
    end
    @palette_index = palette_index
    
    old_gfx_page_index = @ui.gfx_page_index.currentIndex
    old_gfx_page_index = 0 if old_gfx_page_index == -1
    old_icon_index = @ui.icon_index.currentIndex
    old_icon_index = 0 if old_icon_index == -1
    load_gfx_pages(palette_index)
    gfx_page_changed(old_gfx_page_index)
    icon_changed(old_icon_index)
    
    @ui.palette_index.setCurrentIndex(palette_index)
  end
  
  def icon_changed(icon_index)
    gfx_page_changed(icon_index / @icons_per_page)
    @ui.icon_index.setCurrentIndex(icon_index)
    
    icon_index_on_page = icon_index % @icons_per_page
    x = (icon_index_on_page % @icons_per_row) * @icon_width
    y = (icon_index_on_page / @icons_per_row) * @icon_height
    @selection_rectangle.setRect(x, y, @icon_width, @icon_height)
  end
  
  def change_icon_by_page_x_and_y(x, y, button)
    return unless (0..127).include?(x) && (0..127).include?(y)
    new_icon_index = @ui.gfx_page_index.currentIndex*@icons_per_page + (y / @icon_height)*@icons_per_row + (x / @icon_width)
    icon_changed(new_icon_index)
  end
  
  def save_icon
    icon_index = @ui.icon_index.currentIndex
    palette_index = @ui.palette_index.currentIndex
    
    if @mode == :item
      new_icon_data = GenericEditable.pack_icon_index_and_palette_index(icon_index, palette_index)
    else
      new_icon_data = icon_index
    end
    
    parent.set_icon(new_icon_data)
  end
  
  def button_pressed(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_icon()
    end
  end
end
