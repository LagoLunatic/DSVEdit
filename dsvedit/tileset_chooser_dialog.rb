
require_relative 'ui_tileset_chooser.rb'

class TilesetChooserDialog < Qt::Dialog
  slots "tileset_changed(int)"
  slots "tileset_double_clicked(QListWidgetItem*)"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(parent, game, sector, renderer)
    super(parent, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    
    @game = game
    @sector = sector
    @renderer = renderer
    
    @ui = Ui_TilesetChooser.new
    @ui.setup_ui(self)
    
    connect(@ui.tileset_list, SIGNAL("currentRowChanged(int)"), self, SLOT("tileset_changed(int)"))
    connect(@ui.tileset_list, SIGNAL("itemDoubleClicked(QListWidgetItem*)"), self, SLOT("tileset_double_clicked(QListWidgetItem*)"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    load_tilesets()
    
    self.show()
  end
  
  def load_tilesets
    @sector.load_necessary_overlay()
    @all_tileset_names = []
    @sector.rooms.each do |room|
      @renderer.ensure_tilesets_exist("cache/#{GAME}/rooms/", room)
      room.layers.each do |layer|
        next if layer.layer_metadata_ram_pointer == 0 # Empty layer
        @all_tileset_names << layer.tileset_filename
      end
    end
    @all_tileset_names.uniq!
    
    @all_tileset_names.each do |filename|
      file_path = "cache/#{GAME}/rooms/#{@sector.name}/Tilesets/#{filename}.png"
      item = Qt::ListWidgetItem.new(Qt::Icon.new(file_path), filename)
      @ui.tileset_list.addItem(item)
    end
  rescue StandardError => e
    msg = "Failed to load tilesets.\n"
    msg += "#{e.message}\n\n#{e.backtrace.join("\n")}"
    Qt::MessageBox.warning(self,
      "Failed to load tilesets",
      msg
    )
    self.close()
  end
  
  def tileset_changed(tileset_index)
    @tileset_index = tileset_index
    @tileset_name = @all_tileset_names[tileset_index]
  end
  
  def tileset_double_clicked(item)
    save_tileset()
    self.close()
  end
  
  def save_tileset
    parent.set_tileset(@tileset_name)
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_tileset()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    end
  end
end
