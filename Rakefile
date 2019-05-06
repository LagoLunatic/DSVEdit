
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
  
  Dir.glob("dsvedit/*.ui").each do |file_path|
    base_name = File.basename(file_path, ".*")
    output_path = "dsvedit/ui_%s.rb" % base_name
    system "rbuic4 dsvedit/#{base_name}.ui -o #{output_path}"
  end
  
  if defined?(DSVRANDOM_VERSION)
    Dir.glob("dsvrandom/*.ui").each do |file_path|
      base_name = File.basename(file_path, ".*")
      output_path = "dsvrandom/ui_%s.rb" % base_name
      system "rbuic4 dsvrandom/#{base_name}.ui -o #{output_path}"
    end
  end
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
  
  build_dir = "../build"
  root_dir = "."
  dsvrandom_dir = "#{root_dir}/dsvrandom"
  docs_dir = "#{root_dir}/docs"
  
  ["DSVania Editor", "DSVania Randomizer", "DSVania Editor x64", "DSVania Randomizer x64"].each do |program_name|
    next if program_name.include?("DSVania Randomizer") && !defined?(DSVRANDOM_VERSION)
    
    out_dir = File.join(build_dir, program_name)
    
    FileUtils.rm_f [
      "#{out_dir}/armips",
      "#{out_dir}/asm",
      "#{out_dir}/constants",
      "#{out_dir}/dsvlib",
      "#{out_dir}/images",
      "#{out_dir}/dsvlib.rb",
      "#{out_dir}/version.rb"
    ]
    FileUtils.cp_r [
      "#{root_dir}/armips",
      "#{root_dir}/asm",
      "#{root_dir}/constants",
      "#{root_dir}/dsvlib",
      "#{root_dir}/dsvlib.rb"
    ], "#{out_dir}"
    
    FileUtils.rm_rf "#{out_dir}/docs"
    
    if program_name.include?("DSVania Editor")
      FileUtils.mkdir "#{out_dir}/docs"
      FileUtils.cp_r [
        "#{docs_dir}/formats",
        "#{docs_dir}/lists",
        "#{docs_dir}/asm"
      ], "#{out_dir}/docs"
      Dir.glob("#{docs_dir}/*.txt").each do |file_path|
        FileUtils.cp file_path, "#{out_dir}/docs"
      end
      
      FileUtils.rm_f [
        "#{out_dir}/dsvedit",
        "#{out_dir}/dsvedit.rb"
      ]
      FileUtils.cp_r [
        "#{root_dir}/dsvedit",
        "#{root_dir}/dsvedit.rb"
      ], "#{out_dir}"
      FileUtils.cp_r [
        "#{root_dir}/images",
        "#{root_dir}/version.rb",
        "#{root_dir}/LICENSE.txt"
      ], "#{out_dir}"
      FileUtils.cp_r "#{root_dir}/README.md", "#{out_dir}/README.txt"
      FileUtils.rm_f "#{out_dir}/images/dsvrandom_icon.ico"
      FileUtils.rm_f "#{out_dir}/settings.yml"
      
      # Automatically set the debug variable to false.
      code = File.read("#{out_dir}/dsvedit.rb")
      code.gsub!(/DEBUG = true/, "DEBUG = false")
      File.write("#{out_dir}/dsvedit.rb", code)
    else
      FileUtils.rm_f [
        "#{out_dir}/dsvrandom",
        "#{out_dir}/dsvrandom.rb"
      ]
      Dir.glob("#{dsvrandom_dir}/*.rb").each do |file_path|
        FileUtils.cp file_path, "#{out_dir}/dsvrandom"
      end
      FileUtils.cp_r [
        "#{dsvrandom_dir}/seedgen_adjectives.txt",
        "#{dsvrandom_dir}/seedgen_nouns.txt",
        "#{dsvrandom_dir}/progressreqs",
        "#{dsvrandom_dir}/assets",
        "#{dsvrandom_dir}/roomedits",
        "#{dsvrandom_dir}/images",
        "#{dsvrandom_dir}/randomizers",
        "#{dsvrandom_dir}/constants"
      ], "#{out_dir}/dsvrandom"
      FileUtils.cp_r "#{dsvrandom_dir}/LICENSE.txt", "#{out_dir}"
      FileUtils.cp_r "#{dsvrandom_dir}/README.md", "#{out_dir}/README.txt"
      FileUtils.rm_f [
        "#{out_dir}/dsvrandom/README.txt",
        "#{out_dir}/dsvrandom/LICENSE.txt"
      ]
      FileUtils.rm_f "#{out_dir}/images/dsvedit_icon.ico"
      FileUtils.rm_f "#{out_dir}/randomizer_settings.yml"
      FileUtils.rm_rf "#{out_dir}/dsvrandom/roomedits/Tilesets"
    end
    
    FileUtils.rm_rf "#{out_dir}/cache"
    FileUtils.rm_f "#{out_dir}/crashlog.txt"
    
    zip_path = "#{build_dir}/"
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
      Dir.glob("#{out_dir}/**/*.*").each do |file_path|
        relative_path = Pathname.new(file_path).relative_path_from(Pathname.new("#{out_dir}"))
        zipfile.add(relative_path, file_path)
      end
    end
  end
end
