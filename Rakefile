
require 'fileutils'
require 'zip'
require 'pathname'

require_relative 'version'

task :build_ui do
  # Use rbuic4 to compile the ui files into ruby code.
  
  Dir.glob("dsvedit/*.ui").each do |file_path|
    base_name = File.basename(file_path, ".*")
    output_path = "dsvedit/ui_%s.rb" % base_name
    system "rbuic4 dsvedit/#{base_name}.ui -o #{output_path}"
  end
end

task :build_installers do
  # Builds the installers, which are just an intermediary step to building the portable zips. Requires OCRA and Inno Setup.
  
  # But OCRA has a bug that causes Inno Setup installer builds to fail, so this must be fixed manually.
  # Install OCRA gem version 1.3.10, then go to the folder where OCRA was installed in your Ruby installation and edit the file /bin/ocra so that line 26 is `@path = path` instead of `@path = path && path.encode('UTF-8')`.
  
  # Also, OCRA normally places all the source files in the /src directory. In order to make it place them in the base directory, edit /bin/ocra at line 204 to change `SRCDIR = Pathname.new('src')` to `SRCDIR = Pathname.new('.')`.
  
  system "C:/Ruby24/bin/ruby ocra-1.3.10/bin/ocra dsvedit.rb --output DSVEdit.exe --no-lzma --chdir-first --innosetup setup_dsvedit.iss --icon ./images/dsvedit_icon.ico"
  system "C:/Ruby24-x64/bin/ruby ocra-1.3.10/bin/ocra dsvedit.rb --output DSVEdit_x64.exe --no-lzma --chdir-first --innosetup setup_dsvedit_x64.iss --icon ./images/dsvedit_icon.ico"
end

task :build_releases do
  # Updates the executable builds with any changes to the code, delete unnecessary files, and then pack everything into zip files.
  
  build_dir = "../build"
  root_dir = "."
  docs_dir = "#{root_dir}/docs"
  
  ["DSVania Editor", "DSVania Editor x64"].each do |program_name|
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
    FileUtils.rm_f "#{out_dir}/settings.yml"
    
    # Automatically set the debug variable to false.
    code = File.read("#{out_dir}/dsvedit.rb")
    code.gsub!(/DEBUG = true/, "DEBUG = false")
    File.write("#{out_dir}/dsvedit.rb", code)
    
    FileUtils.rm_rf "#{out_dir}/cache"
    FileUtils.rm_f "#{out_dir}/crashlog.txt"
    
    zip_path = "#{build_dir}/"
    zip_path << "DSVania_Editor_#{DSVEDIT_VERSION}"
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
