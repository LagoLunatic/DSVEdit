require 'Qt'
require 'fileutils'
require 'yaml'

require_relative 'dsvlib'

require_relative 'dsvrandom/randomizer_window'

$qApp = Qt::Application.new(ARGV)
window = RandomizerWindow.new
$qApp.exec
