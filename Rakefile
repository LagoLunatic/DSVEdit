
require 'fileutils'
require 'zip'
require 'pathname'

task :build_ui do
  # Use rbuic4 to compile the ui files into ruby code.
  
  system "rbuic4 dsvedit/main.ui           -o dsvedit/ui_main.rb"
  system "rbuic4 dsvedit/enemy_editor.ui   -o dsvedit/ui_enemy_editor.rb"
  system "rbuic4 dsvedit/text_editor.ui    -o dsvedit/ui_text_editor.rb"
  system "rbuic4 dsvedit/settings.ui       -o dsvedit/ui_settings.rb"
  system "rbuic4 dsvedit/sprite_editor.ui  -o dsvedit/ui_sprite_editor.rb"
  system "rbuic4 dsvedit/item_editor.ui    -o dsvedit/ui_item_editor.rb"
  system "rbuic4 dsvedit/generic_editor.ui -o dsvedit/ui_generic_editor.rb"
  system "rbuic4 dsvedit/entity_search.ui  -o dsvedit/ui_entity_search.rb"
  
  system "rbuic4 dsvrandom/randomizer.ui   -o dsvrandom/ui_randomizer.rb"
end

task :build_installers do
  # Builds the installers for DSVEdit and DSVRandom. Requires OCRA and Inno Setup.
  
  # The gem version of OCRA won't work, it's missing the most recent few commits which fix building the Inno Setup file.
  # Instead you need to use the latest version of OCRA from the source: https://github.com/larsch/ocra/tree/2e7c88fd6ac7ae5f881d838dedd7ad437bda018b
  # The easiest way to do this is to install the latest gem version of OCRA, then go to the folder where OCRA was installed in your Ruby installation and replace the file /bin/ocra with the /bin/ocra from the source.

  system "ocra dsvedit.rb --output DSVEdit.exe --no-lzma --chdir-first --innosetup setup_dsvedit.iss --windows --gem-files ./images/dsvedit_icon.ico --gem-extras README.md --icon ./images/dsvedit_icon.ico"
  system "ocra dsvrandom.rb --output DSVRandom.exe --no-lzma --chdir-first --innosetup setup_dsvrandom.iss --windows --gem-files ./images/dsvrandom_icon.ico --gem-extras README.md --icon ./images/dsvrandom_icon.ico"
end

task :build_releases do
  # Updates the executable builds with any changes to the code, delete unnecessary files, and then pack everything into zip files.
  
  ["DSVania Editor", "DSVania Randomizer"].each do |program_name|
    # Delete unnecessary libraries that bloat the filesize.
    FileUtils.rm_rf "./build/#{program_name}/lib/ruby/gems/2.2.0/gems/qtbindings-4.8.6.2-x86-mingw32/lib/2.0"
    FileUtils.rm_rf "./build/#{program_name}/lib/ruby/gems/2.2.0/gems/qtbindings-4.8.6.2-x86-mingw32/lib/2.1"
    FileUtils.rm_rf "./build/#{program_name}/lib/ruby/gems/2.2.0/gems/qtbindings-qt-4.8.6-x86-mingw32/qtbin/plugins"
    %w(phonon4.dll Qt3Support4.dll QtCLucene4.dll QtDBus4.dll QtDeclarative4.dll QtDesigner4.dll QtDesignerComponents4.dll QtHelp4.dll QtMultimedia4.dll QtScript4.dll QtScriptTools4.dll QtTest4.dll QtWebKit4.dll QtXmlPatterns4.dll).each do |filename|
      FileUtils.rm_f "./build/#{program_name}/lib/ruby/gems/2.2.0/gems/qtbindings-qt-4.8.6-x86-mingw32/qtbin/#{filename}"
    end
    %w(libsmokeqtdeclarative.dll libsmokeqthelp.dll libsmokeqtmultimedia.dll libsmokeqtscript.dll libsmokeqttest.dll libsmokeqtuitools.dll libsmokeqtwebkit.dll libsmokeqtxmlpatterns.dll).each do |filename|
      FileUtils.rm_f "./build/#{program_name}/lib/ruby/gems/2.2.0/gems/qtbindings-4.8.6.2-x86-mingw32/lib/2.2/#{filename}"
    end

    FileUtils.rm_f "./build/#{program_name}.zip"
    FileUtils.rm_rf "./build/#{program_name}/src"
    FileUtils.mkdir "./build/#{program_name}/src"
    
    if program_name == "DSVania Editor"
      FileUtils.cp_r ["./constants", "./dsvedit", "./dsvlib", "./images", "dsvedit.rb", "dsvlib.rb", "README.md"], "./build/#{program_name}/src"
    else
      FileUtils.cp_r ["./constants", "./dsvrandom", "./dsvlib", "./images", "dsvrandom.rb", "dsvlib.rb", "README.md"], "./build/#{program_name}/src"
    end
    
    Zip::File.open("./build/#{program_name}.zip", Zip::File::CREATE) do |zipfile|
      Dir.glob("./build/#{program_name}/**/*.*").each do |file_path|
        relative_path = Pathname.new(file_path).relative_path_from(Pathname.new("./build/#{program_name}"))
        zipfile.add(relative_path, file_path)
      end
    end
  end
end
