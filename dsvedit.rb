require 'Qt'
require 'fileutils'
require 'yaml'

require_relative 'dsvlib'

require_relative 'dsvedit/main_window'

if defined?(Ocra)
  exit
end

Dir.chdir(File.dirname(__FILE__))

$qApp = Qt::Application.new(ARGV)
window = DSVEdit.new
$qApp.exec
