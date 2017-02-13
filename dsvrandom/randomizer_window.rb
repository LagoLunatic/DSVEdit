
require_relative 'ui_randomizer'
require_relative 'randomizer'

class RandomizerWindow < Qt::Dialog
  slots "update_settings()"
  slots "browse_for_clean_rom()"
  slots "browse_for_output_folder()"
  slots "randomize()"
  slots "cancel_write_to_rom_thread()"
  slots "open_about()"
  
  def initialize
    super()
    @ui = Ui_Randomizer.new
    @ui.setup_ui(self)
    
    load_settings()
    
    connect(@ui.clean_rom, SIGNAL("editingFinished()"), self, SLOT("update_settings()"))
    connect(@ui.clean_rom_browse_button, SIGNAL("clicked()"), self, SLOT("browse_for_clean_rom()"))
    connect(@ui.output_folder, SIGNAL("editingFinished()"), self, SLOT("update_settings()"))
    connect(@ui.output_folder_browse_button, SIGNAL("clicked()"), self, SLOT("browse_for_output_folder()"))
    connect(@ui.seed, SIGNAL("editingFinished()"), self, SLOT("update_settings()"))
    
    connect(@ui.randomize_items, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_souls_relics_and_glyphs, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_enemies, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_bosses, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_enemy_drops, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_boss_souls, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_area_connections, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_room_connections, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_starting_room, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.randomize_enemy_ai, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    
    connect(@ui.remove_events, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.fix_first_ability_soul, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    connect(@ui.open_world_map, SIGNAL("stateChanged(int)"), self, SLOT("update_settings()"))
    
    connect(@ui.randomize_button, SIGNAL("clicked()"), self, SLOT("randomize()"))
    connect(@ui.about_button, SIGNAL("clicked()"), self, SLOT("open_about()"))
    
    self.setWindowFlags(Qt::MSWindowsFixedSizeDialogHint)
    self.setWindowTitle("DSVania Randomizer #{DSVRANDOM_VERSION}")
    
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
    @ui.randomize_area_connections.setChecked(@settings[:randomize_area_connections]) unless @settings[:randomize_area_connections].nil?
    @ui.randomize_room_connections.setChecked(@settings[:randomize_room_connections]) unless @settings[:randomize_room_connections].nil?
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
  
  def browse_for_clean_rom
    clean_rom_path = Qt::FileDialog.getOpenFileName(self, "Select ROM", nil, "NDS ROM Files (*.nds)")
    return if clean_rom_path.nil?
    @ui.clean_rom.text = clean_rom_path
  end
  
  def browse_for_output_folder
    output_folder_path = Qt::FileDialog.getExistingDirectory(self, "Select output folder", nil)
    return if output_folder_path.nil?
    @ui.output_folder.text = output_folder_path
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
    @settings[:randomize_area_connections] = @ui.randomize_area_connections.checked
    @settings[:randomize_room_connections] = @ui.randomize_room_connections.checked
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
      seed = rand(0..999_999_999)
      @settings[:seed] = seed.to_s
      @ui.seed.text = @settings[:seed]
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
      :randomize_area_connections => @ui.randomize_area_connections.checked(),
      :randomize_room_connections => @ui.randomize_room_connections.checked(),
      :randomize_starting_room => @ui.randomize_starting_room.checked(),
      :randomize_enemy_ai => @ui.randomize_enemy_ai.checked(),
      :remove_events => @ui.remove_events.checked()
    )
    randomizer.randomize()
    
    if @ui.fix_first_ability_soul.checked()
      game.apply_armips_patch("dos_fix_first_ability_soul")
    end
    
    if @ui.open_world_map.checked()
      game.apply_armips_patch("ooe_open_world_map")
    end
    
    game.fix_unnamed_skills()
    
    #game.apply_armips_patch("dos_boss_doors_skip_seal")
    #game.apply_armips_patch("ooe_enter_any_wall")
    #game.apply_armips_patch("dos_use_what_you_see_souls")
    
    write_to_rom(game)
  rescue StandardError => e
    Qt::MessageBox.critical(self, "Randomization Failed", "Randomization failed with error:\n#{e.message}\n\n#{e.backtrace.join("\n")}")
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
    
    FileUtils.mkdir_p(@ui.output_folder.text)
    output_rom_path = File.join(@ui.output_folder.text, "#{GAME} Random #{@ui.seed.text.to_i}.nds")
    
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
  
  def open_about
    @about_dialog = Qt::MessageBox::about(self, "DSVania Randomizer", "DSVania Randomizer Version #{DSVRANDOM_VERSION}\n\nCreated by LagoLunatic\n\nSource code:\nhttps://github.com/LagoLunatic/DSVEdit\n\nReport issues here:\nhttps://github.com/LagoLunatic/DSVEdit/issues")
  end
end
