require 'Qt'
require 'fileutils'
require 'yaml'

require_relative 'dsve'

require_relative 'dsvedit_main_window'

$qApp = Qt::Application.new(ARGV)
DSVE.new
$qApp.exec
