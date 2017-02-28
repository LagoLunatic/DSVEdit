
require_relative 'dsvlib/nds_file_system'
require_relative 'dsvlib/bitfield'

require_relative 'dsvlib/game'
require_relative 'dsvlib/area'
require_relative 'dsvlib/sector'
require_relative 'dsvlib/room'
require_relative 'dsvlib/layer'
require_relative 'dsvlib/tileset'
require_relative 'dsvlib/entity'
require_relative 'dsvlib/door'
require_relative 'dsvlib/map'
require_relative 'dsvlib/enemy_dna'
require_relative 'dsvlib/text'
require_relative 'dsvlib/text_database'
require_relative 'dsvlib/sprite'
require_relative 'dsvlib/item'
require_relative 'dsvlib/special_object_type'
require_relative 'dsvlib/sprite_info_extractor'
require_relative 'dsvlib/sprite_skeleton'
require_relative 'dsvlib/weapon_gfx'
require_relative 'dsvlib/skill_gfx'
require_relative 'dsvlib/item_pool'

require_relative 'dsvlib/renderer'
require_relative 'dsvlib/tmx_interface'

require_relative 'constants/shared_constants'

if defined?(Ocra)
  orig_verbosity = $VERBOSE
  $VERBOSE = nil
  require_relative 'constants/dos_constants'
  require_relative 'constants/por_constants'
  require_relative 'constants/ooe_constants'
  $VERBOSE = orig_verbosity
end
