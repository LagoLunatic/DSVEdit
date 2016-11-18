require 'Qt'
require 'fileutils'
require 'yaml'

require_relative 'dsvlib'

require_relative 'dsvrandom/randomizer_window'

if defined?(Ocra)
  exit
end

$qApp = Qt::Application.new(ARGV)
window = RandomizerWindow.new
$qApp.exec
