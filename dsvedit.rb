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
  
  raise e
end
