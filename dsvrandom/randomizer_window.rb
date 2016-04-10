
require_relative 'ui_randomizer'
require_relative 'randomizer'

class RandomizerWindow < Qt::Dialog
  slots "update_settings()"
  slots "randomize()"
  slots "cancel_write_to_rom_thread()"
  
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
    connect(@ui.randomize_enemy_ai, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    
    connect(@ui.remove_events, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.fix_first_ability_soul, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.open_world_map, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    
    connect(@ui.submit, SIGNAL("clicked()"), self, SLOT("randomize()"))
    
    self.setWindowFlags(Qt::MSWindowsFixedSizeDialogHint)
    
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
    @ui.randomize_enemy_ai.setChecked(@settings[:randomize_enemy_ai]) unless @settings[:randomize_enemy_ai].nil?
    
    @ui.remove_events.setChecked(@settings[:remove_events]) unless @settings[:remove_events].nil?
    @ui.fix_first_ability_soul.setChecked(@settings[:fix_first_ability_soul]) unless @settings[:fix_first_ability_soul].nil?
    @ui.open_world_map.setChecked(@settings[:open_world_map]) unless @settings[:open_world_map].nil?
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
    @settings[:randomize_enemy_ai] = @ui.randomize_enemy_ai.checked
    
    @settings[:remove_events] = @ui.remove_events.checked
    @settings[:fix_first_ability_soul] = @ui.fix_first_ability_soul.checked
    @settings[:open_world_map] = @ui.open_world_map.checked
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
    game.initialize_from_rom(@ui.clean_rom.text, extract_to_hard_drive = false)
    
    randomizer = Randomizer.new(seed, game,
      :randomize_items => @ui.randomize_items.checked(),
      :randomize_souls_relics_and_glyphs => @ui.randomize_souls_relics_and_glyphs.checked(),
      :randomize_enemies => @ui.randomize_enemies.checked(),
      :randomize_bosses => @ui.randomize_bosses.checked(),
      :randomize_enemy_drops => @ui.randomize_enemy_drops.checked(),
      :randomize_boss_souls => @ui.randomize_boss_souls.checked(),
      :randomize_doors => @ui.randomize_doors.checked(),
      :randomize_starting_room => @ui.randomize_starting_room.checked(),
      :randomize_enemy_ai => @ui.randomize_enemy_ai.checked(),
      :remove_events => @ui.remove_events.checked()
    )
    randomizer.randomize()
    
    if @ui.fix_first_ability_soul.checked()
      game.dos_fix_first_ability_soul()
    end
    
    if @ui.open_world_map.checked()
      game.ooe_open_world_map()
    end
    
    game.fix_unnamed_skills()
    game.dos_boss_doors_skip_seal()
    game.ooe_enter_any_wall()
    
    write_to_rom(game)
  end
  
  def write_to_rom(game)
    @progress_dialog = Qt::ProgressDialog.new
    @progress_dialog.windowTitle = "Building"
    @progress_dialog.labelText = "Writing files to ROM"
    @progress_dialog.maximum = game.fs.files_without_dirs.length
    @progress_dialog.windowModality = Qt::ApplicationModal
    @progress_dialog.windowFlags = Qt::CustomizeWindowHint | Qt::WindowTitleHint
    @progress_dialog.setFixedSize(@progress_dialog.size);
    connect(@progress_dialog, SIGNAL("canceled()"), self, SLOT("cancel_write_to_rom_thread()"))
    @progress_dialog.show
    
    output_rom_path = File.join(@ui.output_folder.text, "#{GAME} hack.nds")
    
    @write_to_rom_thread = Thread.new do
      game.fs.write_to_rom(output_rom_path) do |files_written|
        next unless files_written % 100 == 0 # Only update the UI every 100 files because updating too often is slow.
        
        Qt.execute_in_main_thread do
          @progress_dialog.setValue(files_written) unless @progress_dialog.wasCanceled
        end
      end
      
      Qt.execute_in_main_thread do
        @progress_dialog.setValue(game.fs.files_without_dirs.length) unless @progress_dialog.wasCanceled
        @progress_dialog = nil
        Qt::MessageBox.information(self, "Done", "Randomization complete.")
      end
    end
  end
  
  def cancel_write_to_rom_thread
    puts "Cancelled."
    @write_to_rom_thread.kill
    @progress_dialog = nil
  end
end
