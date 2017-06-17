
require 'fileutils'
require 'zip'
require 'pathname'

require_relative 'version'
begin
  require_relative 'dsvrandom/version'
rescue LoadError
  # Swallow
end

task :build_ui do
  # Use rbuic4 to compile the ui files into ruby code.
  
  system "rbuic4 dsvedit/main.ui                   -o dsvedit/ui_main.rb"
  system "rbuic4 dsvedit/enemy_editor.ui           -o dsvedit/ui_enemy_editor.rb"
  system "rbuic4 dsvedit/text_editor.ui            -o dsvedit/ui_text_editor.rb"
  system "rbuic4 dsvedit/settings.ui               -o dsvedit/ui_settings.rb"
  system "rbuic4 dsvedit/sprite_editor.ui          -o dsvedit/ui_sprite_editor.rb"
  system "rbuic4 dsvedit/item_editor.ui            -o dsvedit/ui_item_editor.rb"
  system "rbuic4 dsvedit/generic_editor.ui         -o dsvedit/ui_generic_editor.rb"
  system "rbuic4 dsvedit/entity_search.ui          -o dsvedit/ui_entity_search.rb"
  system "rbuic4 dsvedit/icon_chooser.ui           -o dsvedit/ui_icon_chooser.rb"
  system "rbuic4 dsvedit/map_editor.ui             -o dsvedit/ui_map_editor.rb"
  system "rbuic4 dsvedit/entity_editor.ui          -o dsvedit/ui_entity_editor.rb"
  system "rbuic4 dsvedit/skeleton_editor.ui        -o dsvedit/ui_skeleton_editor.rb"
  system "rbuic4 dsvedit/room_editor.ui            -o dsvedit/ui_room_editor.rb"
  system "rbuic4 dsvedit/layers_editor.ui          -o dsvedit/ui_layers_editor.rb"
  system "rbuic4 dsvedit/item_pool_editor.ui       -o dsvedit/ui_item_pool_editor.rb"
  system "rbuic4 dsvedit/gfx_editor.ui             -o dsvedit/ui_gfx_editor.rb"
  system "rbuic4 dsvedit/music_editor.ui           -o dsvedit/ui_music_editor.rb"
  system "rbuic4 dsvedit/tileset_editor.ui         -o dsvedit/ui_tileset_editor.rb"
  system "rbuic4 dsvedit/player_editor.ui          -o dsvedit/ui_player_editor.rb"
  system "rbuic4 dsvedit/special_object_editor.ui  -o dsvedit/ui_special_object_editor.rb"
  system "rbuic4 dsvedit/weapon_synth_editor.ui    -o dsvedit/ui_weapon_synth_editor.rb"
  system "rbuic4 dsvedit/shop_editor.ui            -o dsvedit/ui_shop_editor.rb"
  
  system "rbuic4 dsvrandom/randomizer.ui           -o dsvrandom/ui_randomizer.rb" if defined?(DSVRANDOM_VERSION)
end

task :build_installers do
  # Builds the installers for DSVEdit and DSVRandom. Requires OCRA and Inno Setup.
  
  # The gem version of OCRA won't work, it's missing the most recent few commits which fix building the Inno Setup file.
  # Instead you need to use the latest version of OCRA from the source: https://github.com/larsch/ocra/tree/2e7c88fd6ac7ae5f881d838dedd7ad437bda018b
  # The easiest way to do this is to install the latest gem version of OCRA, then go to the folder where OCRA was installed in your Ruby installation and replace the file /bin/ocra with the /bin/ocra from the source.
  
  # OCRA normally places all the source files in the /src directory. In order to make it place them in the base directory open up /bin/ocra and change line 204 from SRCDIR = Pathname.new('src') to SRCDIR = Pathname.new('.').

  system "C:/Ruby23/bin/ruby ocra-1.3.6/bin/ocra dsvedit.rb --output DSVEdit.exe --no-lzma --chdir-first --innosetup setup_dsvedit.iss --icon ./images/dsvedit_icon.ico"
  system "C:/Ruby23-x64/bin/ruby ocra-1.3.6/bin/ocra dsvedit.rb --output DSVEdit_x64.exe --no-lzma --chdir-first --innosetup setup_dsvedit_x64.iss --icon ./images/dsvedit_icon.ico"
  if defined?(DSVRANDOM_VERSION)
    system "C:/Ruby23/bin/ruby ocra-1.3.6/bin/ocra dsvrandom/dsvrandom.rb --output DSVRandom.exe --no-lzma --chdir-first --innosetup setup_dsvrandom.iss --windows --icon ./dsvrandom/images/dsvrandom_icon.ico"
    system "C:/Ruby23-x64/bin/ruby ocra-1.3.6/bin/ocra dsvrandom/dsvrandom.rb --output DSVRandom_x64.exe --no-lzma --chdir-first --innosetup setup_dsvrandom_x64.iss --windows --icon ./dsvrandom/images/dsvrandom_icon.ico"
  end
end

task :build_releases do
  # Updates the executable builds with any changes to the code, delete unnecessary files, and then pack everything into zip files.
  
  ["DSVania Editor", "DSVania Randomizer", "DSVania Editor x64", "DSVania Randomizer x64"].each do |program_name|
    next if program_name.include?("DSVania Randomizer") && !defined?(DSVRANDOM_VERSION)
    
    FileUtils.rm_f ["../build/#{program_name}/armips", "../build/#{program_name}/asm", "../build/#{program_name}/constants", "../build/#{program_name}/dsvlib", "../build/#{program_name}/images", "../build/#{program_name}/dsvlib.rb", "../build/#{program_name}/version.rb"]
    FileUtils.cp_r ["./armips", "./asm", "./constants", "./dsvlib", "dsvlib.rb"], "../build/#{program_name}"
    
    FileUtils.rm_rf "../build/#{program_name}/docs"
    
    if program_name.include?("DSVania Editor")
      FileUtils.mkdir "../build/#{program_name}/docs"
      FileUtils.cp_r ["./docs/formats", "./docs/lists", "./docs/asm"], "../build/#{program_name}/docs"
      FileUtils.cp_r ["./docs/PoR RAM Map.txt"], "../build/#{program_name}/docs"
      
      FileUtils.rm_f ["../build/#{program_name}/dsvedit", "../build/#{program_name}/dsvedit.rb"]
      FileUtils.cp_r ["./dsvedit", "dsvedit.rb"], "../build/#{program_name}"
      FileUtils.cp_r ["./images", "version.rb", "README.txt", "LICENSE.txt"], "../build/#{program_name}"
      FileUtils.rm_f "../build/#{program_name}/images/dsvrandom_icon.ico"
      FileUtils.rm_f "../build/#{program_name}/settings.yml"
    else
      FileUtils.rm_f ["../build/#{program_name}/dsvrandom", "../build/#{program_name}/dsvrandom.rb"]
      FileUtils.cp_r [
        "./dsvrandom/dsvrandom.rb",
        "./dsvrandom/completability_checker.rb",
        "./dsvrandom/randomizer.rb",
        "./dsvrandom/randomizer_window.rb",
        "./dsvrandom/ui_randomizer.rb",
        "./dsvrandom/version.rb",
        "./dsvrandom/progressreqs",
        "./dsvrandom/images",
        "./dsvrandom/randomizers",
        "./dsvrandom/constants"
      ], "../build/#{program_name}/dsvrandom"
      FileUtils.cp_r ["./dsvrandom/README.txt", "./dsvrandom/LICENSE.txt"], "../build/#{program_name}"
      FileUtils.rm_f ["../build/#{program_name}/dsvrandom/README.txt", "../build/#{program_name}/dsvrandom/LICENSE.txt"]
      FileUtils.rm_f "../build/#{program_name}/images/dsvedit_icon.ico"
      FileUtils.rm_f "../build/#{program_name}/randomizer_settings.yml"
    end
    
    FileUtils.rm_rf "../build/#{program_name}/cache"
    FileUtils.rm_f "../build/#{program_name}/crashlog.txt"
    
    zip_path = "../build/"
    if program_name.include?("DSVania Editor")
      zip_path << "DSVania_Editor_#{DSVEDIT_VERSION}"
    else
      zip_path << "DSVania_Randomizer_#{DSVRANDOM_VERSION}"
    end
    if program_name.include?("x64")
      zip_path << "_x64"
    end
    zip_path << ".zip"
    zip_path = zip_path.tr(" ", "_")
    
    FileUtils.rm_f zip_path
    
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      Dir.glob("../build/#{program_name}/**/*.*").each do |file_path|
        relative_path = Pathname.new(file_path).relative_path_from(Pathname.new("../build/#{program_name}"))
        zipfile.add(relative_path, file_path)
      end
    end
  end
end
