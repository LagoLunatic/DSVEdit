
require 'fileutils'
require 'zip'
require 'pathname'

require_relative 'version'

task :build_ui do
  # Use rbuic4 to compile the ui files into ruby code.
  
  system "rbuic4 dsvedit/main.ui                -o dsvedit/ui_main.rb"
  system "rbuic4 dsvedit/enemy_editor.ui        -o dsvedit/ui_enemy_editor.rb"
  system "rbuic4 dsvedit/text_editor.ui         -o dsvedit/ui_text_editor.rb"
  system "rbuic4 dsvedit/settings.ui            -o dsvedit/ui_settings.rb"
  system "rbuic4 dsvedit/sprite_editor.ui       -o dsvedit/ui_sprite_editor.rb"
  system "rbuic4 dsvedit/item_editor.ui         -o dsvedit/ui_item_editor.rb"
  system "rbuic4 dsvedit/generic_editor.ui      -o dsvedit/ui_generic_editor.rb"
  system "rbuic4 dsvedit/entity_search.ui       -o dsvedit/ui_entity_search.rb"
  system "rbuic4 dsvedit/icon_chooser.ui        -o dsvedit/ui_icon_chooser.rb"
  system "rbuic4 dsvedit/map_editor.ui          -o dsvedit/ui_map_editor.rb"
  system "rbuic4 dsvedit/entity_editor.ui       -o dsvedit/ui_entity_editor.rb"
  system "rbuic4 dsvedit/skeleton_editor.ui     -o dsvedit/ui_skeleton_editor.rb"
  system "rbuic4 dsvedit/layers_editor.ui       -o dsvedit/ui_layers_editor.rb"
  system "rbuic4 dsvedit/item_pool_editor.ui    -o dsvedit/ui_item_pool_editor.rb"
  system "rbuic4 dsvedit/gfx_editor.ui          -o dsvedit/ui_gfx_editor.rb"
  system "rbuic4 dsvedit/music_editor.ui        -o dsvedit/ui_music_editor.rb"
  system "rbuic4 dsvedit/tileset_editor.ui      -o dsvedit/ui_tileset_editor.rb"
  system "rbuic4 dsvedit/player_editor.ui       -o dsvedit/ui_player_editor.rb"
  
  system "rbuic4 dsvrandom/randomizer.ui        -o dsvrandom/ui_randomizer.rb"
end

task :build_installers do
  # Builds the installers for DSVEdit and DSVRandom. Requires OCRA and Inno Setup.
  
  # The gem version of OCRA won't work, it's missing the most recent few commits which fix building the Inno Setup file.
  # Instead you need to use the latest version of OCRA from the source: https://github.com/larsch/ocra/tree/2e7c88fd6ac7ae5f881d838dedd7ad437bda018b
  # The easiest way to do this is to install the latest gem version of OCRA, then go to the folder where OCRA was installed in your Ruby installation and replace the file /bin/ocra with the /bin/ocra from the source.
  
  # OCRA normally places all the source files in the /src directory. In order to make it place them in the base directory open up /bin/ocra and change line 204 from SRCDIR = Pathname.new('src') to SRCDIR = Pathname.new('.').

  system "ruby ocra-1.3.6/bin/ocra dsvedit.rb --output DSVEdit.exe --no-lzma --chdir-first --innosetup setup_dsvedit.iss --icon ./images/dsvedit_icon.ico"
  system "ruby ocra-1.3.6/bin/ocra dsvrandom.rb --output DSVRandom.exe --no-lzma --chdir-first --innosetup setup_dsvrandom.iss --icon ./images/dsvrandom_icon.ico"
end

task :build_releases do
  # Updates the executable builds with any changes to the code, delete unnecessary files, and then pack everything into zip files.
  
  ["DSVania Editor", "DSVania Randomizer"].each do |program_name|
    FileUtils.rm_f ["../build/#{program_name}/armips", "../build/#{program_name}/asm", "../build/#{program_name}/constants", "../build/#{program_name}/dsvlib", "../build/#{program_name}/images", "../build/#{program_name}/dsvlib.rb", "../build/#{program_name}/version.rb"]
    FileUtils.cp_r ["./armips", "./asm", "./constants", "./dsvlib", "./images", "dsvlib.rb", "version.rb", "LICENSE.txt"], "../build/#{program_name}"
    
    if program_name == "DSVania Editor"
      FileUtils.rm_f ["../build/#{program_name}/dsvedit", "../build/#{program_name}/dsvedit.rb"]
      FileUtils.cp_r ["./dsvedit", "dsvedit.rb"], "../build/#{program_name}"
      FileUtils.cp "README.txt", "../build/#{program_name}/README.txt"
      FileUtils.cp "images/dsvedit_icon.ico", "../build/#{program_name}/images/dsvedit_icon.ico"
      FileUtils.rm_f "../build/#{program_name}/images/dsvrandom_icon.ico"
      FileUtils.rm_f "../build/#{program_name}/settings.yml"
    else
      FileUtils.rm_f ["../build/#{program_name}/dsvrandom", "../build/#{program_name}/dsvrandom.rb"]
      FileUtils.cp_r ["./dsvrandom", "dsvrandom.rb"], "../build/#{program_name}"
      FileUtils.cp "README_RANDOMIZER.txt", "../build/#{program_name}/README.txt"
      FileUtils.cp "images/dsvrandom_icon.ico", "../build/#{program_name}/images/dsvrandom_icon.ico"
      FileUtils.rm_f "../build/#{program_name}/images/dsvedit_icon.ico"
      FileUtils.rm_f "../build/#{program_name}/randomizer_settings.yml"
    end
    
    FileUtils.rm_rf "../build/#{program_name}/cache"
    
    FileUtils.rm_rf "../build/#{program_name}/docs"
    FileUtils.mkdir "../build/#{program_name}/docs"
    FileUtils.cp_r ["./docs/formats", "./docs/lists"], "../build/#{program_name}/docs"
    
    version = program_name == "DSVania Editor" ? DSVEDIT_VERSION : DSVRANDOM_VERSION
    
    zip_path = "../build/#{program_name}_#{version}.zip".tr(" ", "_")
    
    FileUtils.rm_f zip_path
    
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      Dir.glob("../build/#{program_name}/**/*.*").each do |file_path|
        relative_path = Pathname.new(file_path).relative_path_from(Pathname.new("../build/#{program_name}"))
        zipfile.add(relative_path, file_path)
      end
    end
  end
end
