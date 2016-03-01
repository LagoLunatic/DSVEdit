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
    
    connect(@ui.clean_rom, SIGNAL("editingFinished()"), self, SLOT("update_settings()"))
    connect(@ui.output_folder, SIGNAL("editingFinished()"), self, SLOT("update_settings()"))
    connect(@ui.seed, SIGNAL("editingFinished()"), self, SLOT("update_settings()"))
    
    connect(@ui.randomize_items, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_souls_relics_and_glyphs, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_enemies, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_bosses, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_enemy_drops, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_boss_souls, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_doors, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_starting_room, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    
    connect(@ui.submit, SIGNAL("clicked()"), self, SLOT("randomize()"))
    
    self.show()
  end
  
  def load_settings
    @settings_path = "randomizer_settings.yml"
    if File.exist?(@settings_path)
      @settings = YAML::load_file(@settings_path)
    else
      @settings = {}
    end
    
    @ui.clean_rom.setText(@settings[:clean_rom_path]) if @settings[:clean_rom_path]
    @ui.output_folder.setText(@settings[:output_folder]) if @settings[:output_folder]
    @ui.seed.setText(@settings[:seed]) if @settings[:seed]
    
    @ui.randomize_items.setChecked(@settings[:randomize_items]) unless @settings[:randomize_items].nil?
    @ui.randomize_souls_relics_and_glyphs.setChecked(@settings[:randomize_souls_relics_and_glyphs]) unless @settings[:randomize_souls_relics_and_glyphs].nil?
    @ui.randomize_enemies.setChecked(@settings[:randomize_enemies]) unless @settings[:randomize_enemies].nil?
    @ui.randomize_bosses.setChecked(@settings[:randomize_bosses]) unless @settings[:randomize_bosses].nil?
    @ui.randomize_enemy_drops.setChecked(@settings[:randomize_enemy_drops]) unless @settings[:randomize_enemy_drops].nil?
    @ui.randomize_boss_souls.setChecked(@settings[:randomize_boss_souls]) unless @settings[:randomize_boss_souls].nil?
    @ui.randomize_doors.setChecked(@settings[:randomize_doors]) unless @settings[:randomize_doors].nil?
    @ui.randomize_starting_room.setChecked(@settings[:randomize_starting_room]) unless @settings[:randomize_starting_room].nil?
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
    
    @settings[:randomize_items] = @ui.randomize_items.checked
    @settings[:randomize_souls_relics_and_glyphs] = @ui.randomize_souls_relics_and_glyphs.checked
    @settings[:randomize_enemies] = @ui.randomize_enemies.checked
    @settings[:randomize_bosses] = @ui.randomize_bosses.checked
    @settings[:randomize_enemy_drops] = @ui.randomize_enemy_drops.checked
    @settings[:randomize_boss_souls] = @ui.randomize_boss_souls.checked
    @settings[:randomize_doors] = @ui.randomize_doors.checked
    @settings[:randomize_starting_room] = @ui.randomize_starting_room.checked
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
    
    randomizer = Randomizer.new(seed, game, :randomize_enemies => @ui.randomize_enemies.checked())
    
    game.each_room do |room|
      #puts "%08X" % room.room_metadata_ram_pointer
      randomizer.randomize_room(room)
    end
    
    if @ui.open_world_map.checked()
      game.ooe_open_world_map()
    end
    
    if @ui.randomize_starting_room.checked()
      game.fix_top_screen_on_new_game()
      randomizer.randomize_starting_room()
    end
    
    output_rom_path = File.join(@ui.output_folder.text, "#{GAME} hack.nds")
    game.fs.write_to_rom(output_rom_path)

    Qt::MessageBox.information(self, "Done", "Randomization complete.")
  end
end

$qApp = Qt::Application.new(ARGV)
RandomizerWindow.new
$qApp.exec
