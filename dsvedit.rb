
DEBUG = true

begin
  require 'Qt'
  require 'fileutils'
  require 'yaml'
  require 'logger'

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
    logger = Logger.new("crashlog.txt")
    logger.error e
    
    window.save_settings()
    
    if window.game && window.game.fs.has_uncommitted_changes?
      backup_dir = File.join(window.game.folder, "_dsvedit_backup")
      window.game.fs.commit_changes(base_directory = backup_dir)
      puts "Wrote backup of unsaved files to #{backup_dir}"
    end
    
    raise e
  end
rescue ScriptError, StandardError => e
  puts "Error: #{e.class.name}: #{e.message}"
  puts e.backtrace
  gets unless DEBUG
end
