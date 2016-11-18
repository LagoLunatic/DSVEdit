
require 'fileutils'
require 'zip'
require 'pathname'

task :build_ui do
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
