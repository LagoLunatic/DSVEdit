require 'Qt'
require 'fileutils'
require 'yaml'

require_relative 'dsvlib'

require_relative 'dsvedit/main_window'

$qApp = Qt::Application.new(ARGV)
window = DSVEdit.new
$qApp.exec
