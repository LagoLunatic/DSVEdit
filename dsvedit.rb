
DEBUG = true

begin
  require 'Qt'
  require 'fileutils'
  require 'yaml'
  require 'logger'
  require 'pathname'

  require_relative 'dsvlib'

  require_relative 'version'

  require_relative 'dsvedit/main_window'

  if defined?(Ocra)
    exit
  end

  Dir.chdir(File.dirname(__FILE__))

  $qApp = Qt::Application.new(ARGV)
  window = DSVEdit.new

  begin
    $qApp.exec
  rescue StandardError => e
    window.save_settings()
    
    if window.game && window.game.fs && window.game.fs.has_uncommitted_changes?
      backup_dir = File.join(window.game.folder, "_dsvedit_backup")
      window.game.fs.commit_changes(base_directory = backup_dir)
      puts "Wrote backup of unsaved files to #{backup_dir}"
    end
    
    raise e
  end
rescue ScriptError, StandardError => e
  logger = Logger.new("crashlog.txt")
  logger.error e
  
  unless DEBUG
    $qApp = Qt::Application.new(ARGV)
    msg = "DSVEdit has crashed.\nPlease report this bug with a screenshot of this error:\n\n"
    msg << "Error: #{e.class.name}: #{e.message}\n\n"
    msg << e.backtrace.join("\n")
    Qt::MessageBox.critical(window, "Error", msg)
  end
  
  puts "Error: #{e.class.name}: #{e.message}"
  puts e.backtrace
end
