require 'Qt'
require 'fileutils'
require 'yaml'

require_relative 'dsvlib'

require_relative 'dsvedit/dsvedit_main_window'

$qApp = Qt::Application.new(ARGV)
window = DSVEdit.new
$qApp.exec
