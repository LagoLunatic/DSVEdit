require 'Qt'
require 'fileutils'
require 'yaml'

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
  require 'logger'
  logger = Logger.new("crashlog.txt")
  logger.error e
  
  window.save_settings()
  
  if window.game.fs.has_uncommitted_files?
    backup_dir = File.join(window.game.folder, "backup")
    window.game.fs.commit_file_changes(base_directory = backup_dir)
    puts "Wrote backup of unsaved files to #{backup_dir}"
  end
  
  raise e
end
