require 'Qt'
require 'fileutils'
require 'yaml'

require_relative 'dsve'
require_relative 'ui_randomizer'

class RandomizerWindow < Qt::Dialog
  slots "update_settings()"
  slots "randomize()"
  
  def initialize
    super()
    @ui = Ui_Randomizer.new
    @ui.setup_ui(self)
    
    load_settings()
    
    if @settings[:clean_rom_path]
      @ui.clean_rom.setText(@settings[:clean_rom_path])
    end
    if @settings[:output_folder]
      @ui.output_folder.setText(@settings[:output_folder])
    end
    if @settings[:seed]
      @ui.seed.setText(@settings[:seed])
    end
    
    connect(@ui.clean_rom, SIGNAL("editingFinished()"), self, SLOT("update_settings()"))
    connect(@ui.output_folder, SIGNAL("editingFinished()"), self, SLOT("update_settings()"))
    connect(@ui.seed, SIGNAL("editingFinished()"), self, SLOT("update_settings()"))
    connect(@ui.submit, SIGNAL("clicked()"), self, SLOT("randomize()"))
    
    self.show()
    
    #settings = YAML::load_file("settings.yml")
    #open_rom(settings[:input_rom_paths]["dos"])
  end
  
  def load_settings
    @settings_path = "randomizer_settings.yml"
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
  
  def update_settings
    @settings[:clean_rom_path] = @ui.clean_rom.text
    @settings[:output_folder] = @ui.output_folder.text
    @settings[:seed] = @ui.seed.text
  end
  
  def randomize
    if @settings[:seed] =~ /^\d+$/
      seed = @settings[:seed].to_i
    elsif @settings[:seed] =~ /^\s*$/
      seed = nil
    else
      Qt::MessageBox.warning(self, "Invalid seed", "Seed must be an integer.")
      return
    end
    
    game = Game.new
    rom_name = File.basename(@ui.clean_rom.text, ".*")
    folder = File.dirname(@ui.clean_rom.text)
    folder = File.join(folder, "Extracted files #{rom_name}")
    if File.directory?(folder)
      game.initialize_from_folder(folder)
    else
      game.initialize_from_rom(@ui.clean_rom.text)
    end
    
    randomizer = Randomizer.new(seed, :randomize_enemies => @ui.randomize_enemies.checked())
    
    game.each_room do |room|
      #puts "%08X" % room.room_metadata_ram_pointer
      randomizer.randomize_room(room)
    end
    
    if @ui.open_world_map.checked()
      game.ooe_open_world_map()
    end
    
    if @ui.randomize_starting_room.checked()
      game.fix_top_screen_on_new_game()
      randomizer.randomize_starting_room(game)
    end
    
    output_rom_path = File.join(@ui.output_folder.text, "#{GAME} hack.nds")
    game.fs.commit_file_changes()
    game.fs.write_to_rom(output_rom_path)

    Qt::MessageBox.information(self, "Done", "Randomization complete.")
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
end

$qApp = Qt::Application.new(ARGV)
RandomizerWindow.new
$qApp.exec
