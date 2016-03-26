
require_relative 'nds_file_system'

require_relative 'game'
require_relative 'area'
require_relative 'sector'
require_relative 'room'
require_relative 'layer'
require_relative 'tileset'
require_relative 'entity'
require_relative 'door'
require_relative 'map'
require_relative 'enemy_dna'
require_relative 'text'
require_relative 'text_database'
require_relative 'animation'

require_relative 'randomizer'

require_relative 'constants/shared_constants'

require_relative 'renderer'
require_relative 'tmx_interface'

if defined?(Ocra)
  require_relative 'constants/dos_constants'
  require_relative 'constants/por_constants'
  require_relative 'constants/ooe_constants'
end
