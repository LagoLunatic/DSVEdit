
require_relative 'ui_music_editor'

class MusicEditor < Qt::Dialog
  slots "area_changed(int)"
  slots "sector_changed(int)"
  slots "bgm_changed(int)"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, game)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_MusicEditor.new
    @ui.setup_ui(self)
    
    @game = game
    
    AREA_INDEX_TO_AREA_NAME.each do |area_index, area_name|
      @ui.area_index.addItem("%02X %s" % [area_index, area_name])
    end
    if GAME == "hod"
      HOD_UNIQUE_SECTOR_NAMES_FOR_MUSIC.each_with_index do |sector_name, sector_index|
        @ui.sector_index.addItem("%02X %s" % [sector_index, sector_name])
      end
    else
      SECTOR_INDEX_TO_SECTOR_NAME[0].each do |sector_index, sector_name|
        sector = game.areas[0].sectors[sector_index]
        break if sector.is_hardcoded # For the Boss Rush sector in AoS
        
        @ui.sector_index.addItem("%02X %s" % [sector_index, sector_name])
      end
    end
    
    SONG_INDEX_TO_TEXT_INDEX.each_with_index do |text_index, song_index|
      if text_index.is_a?(Integer)
        song_name = game.text_database.text_list[text_index].decoded_string.strip
        song_name = song_name.strip.gsub("\\n", "")
      else
        song_name = text_index # No string for this song name, so this is a manually specified name.
      end
      
      if GAME == "por"
        @ui.song_for_bgm_index.addItem("%02X %s" % [song_index, song_name])
      else
        @ui.song_for_area.addItem("%02X %s" % [song_index, song_name])
        @ui.song_for_sector.addItem("%02X %s" % [song_index, song_name])
      end
    end
    
    if GAME == "por"
      (0..16-1).each do |bgm_index|
        @ui.song_for_area.addItem("BGM %02X (See below)" % bgm_index)
        @ui.song_for_sector.addItem("BGM %02X (See below)" % bgm_index)
        @ui.bgm_index.addItem("BGM %02X" % bgm_index)
      end
    else
      @ui.bgm_container.hide()
    end
    
    connect(@ui.area_index, SIGNAL("activated(int)"), self, SLOT("area_changed(int)"))
    connect(@ui.sector_index, SIGNAL("activated(int)"), self, SLOT("sector_changed(int)"))
    connect(@ui.bgm_index, SIGNAL("activated(int)"), self, SLOT("bgm_changed(int)"))
    connect(@ui.song_for_area, SIGNAL("activated(int)"), self, SLOT("bgm_changed(int)"))
    connect(@ui.song_for_sector, SIGNAL("activated(int)"), self, SLOT("bgm_changed(int)"))
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    area_changed(0)
    sector_changed(0)
    
    self.show()
  end
  
  def area_changed(area_index)
    song_index_for_area = @game.read_song_index_by_area_and_sector(area_index, 0)
    
    if area_index == 0
      @ui.song_for_area.setEnabled(false)
      @ui.sector_index.setEnabled(true)
      @ui.song_for_sector.setEnabled(true)
      
      if GAME == "por"
        sector_changed(@ui.sector_index.currentIndex)
      end
    else
      @ui.song_for_area.setEnabled(true)
      @ui.sector_index.setEnabled(false)
      @ui.song_for_sector.setEnabled(false)
      
      if GAME == "por"
        bgm_changed(song_index_for_area)
      end
    end
    
    @ui.song_for_area.setCurrentIndex(song_index_for_area)
    @ui.area_index.setCurrentIndex(area_index)
  end
  
  def sector_changed(sector_index)
    song_index_for_sector = @game.read_song_index_by_area_and_sector(0, sector_index)
    
    if GAME == "por"
      bgm_changed(song_index_for_sector)
    end
    
    @ui.song_for_sector.setCurrentIndex(song_index_for_sector)
    @ui.sector_index.setCurrentIndex(sector_index)
  end
  
  def bgm_changed(bgm_index)
    if GAME == "por"
      song_index_for_bgm_index = @game.read_song_index_by_bgm_index(bgm_index)
      
      @ui.song_for_bgm_index.setCurrentIndex(song_index_for_bgm_index)
      @ui.bgm_index.setCurrentIndex(bgm_index)
    end
  end
  
  def save_changes
    if @ui.area_index.currentIndex == 0
      @game.write_song_index_by_area_and_sector(@ui.song_for_sector.currentIndex, 0, @ui.sector_index.currentIndex)
    else
      @game.write_song_index_by_area_and_sector(@ui.song_for_area.currentIndex, @ui.area_index.currentIndex, 0)
    end
    
    if GAME == "por"
      @game.write_song_index_by_bgm_index(@ui.song_for_bgm_index.currentIndex, @ui.bgm_index.currentIndex)
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
