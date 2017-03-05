
require_relative 'ui_music_editor'

class MusicEditor < Qt::Dialog
  slots "area_changed(int)"
  slots "sector_changed(int)"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, game)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_MusicEditor.new
    @ui.setup_ui(self)
    
    @game = game
    
    AREA_INDEX_TO_AREA_NAME.each do |area_index, area_name|
      @ui.area_index.addItem("%02X %s" % [area_index, area_name])
    end
    SECTOR_INDEX_TO_SECTOR_NAME[0].each do |sector_index, sector_name|
      @ui.sector_index.addItem("%02X %s" % [sector_index, sector_name])
    end
    (0..NUMBER_OF_SONGS-1).each do |song_index|
      text_index = SONG_INDEX_TO_TEXT_INDEX[song_index]
      if text_index.is_a?(Integer)
        song_name = game.text_database.text_list[text_index].decoded_string.strip
      else
        song_name = text_index # No string for this song name, so this is a manually specified name.
      end
      @ui.song_for_area.addItem("%02X %s" % [song_index, song_name])
      @ui.song_for_sector.addItem("%02X %s" % [song_index, song_name])
    end
    
    connect(@ui.area_index, SIGNAL("activated(int)"), self, SLOT("area_changed(int)"))
    connect(@ui.sector_index, SIGNAL("activated(int)"), self, SLOT("sector_changed(int)"))
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    area_changed(0)
    sector_changed(0)
    
    self.show()
  end
  
  def area_changed(area_index)
    if area_index == 0
      @ui.song_for_area.setEnabled(false)
      @ui.sector_index.setEnabled(true)
      @ui.song_for_sector.setEnabled(true)
    else
      @ui.song_for_area.setEnabled(true)
      @ui.sector_index.setEnabled(false)
      @ui.song_for_sector.setEnabled(false)
    end
    
    song_index_for_area = @game.read_song_index_by_area_and_sector(area_index, 0)
    
    @ui.song_for_area.setCurrentIndex(song_index_for_area)
  end
  
  def sector_changed(sector_index)
    song_index_for_sector = @game.read_song_index_by_area_and_sector(0, sector_index)
    
    @ui.song_for_sector.setCurrentIndex(song_index_for_sector)
  end
  
  def save_changes
    if @ui.area_index.currentIndex == 0
      @game.write_song_index_by_area_and_sector(@ui.song_for_sector.currentIndex, 0, @ui.sector_index.currentIndex)
    else
      @game.write_song_index_by_area_and_sector(@ui.song_for_area.currentIndex, @ui.area_index.currentIndex, 0)
    end
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_changes()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_changes()
    end
  end
end
