
require 'nokogiri'

class TMXInterface
  class ImportError < StandardError ; end
  
  def read(filename, room)
    tiled_room = File.read(filename)
    xml = Nokogiri::XML(tiled_room)
    
    room_props = extract_properties(xml)
    validate_properties(room_props, "Room", %w(map_x map_y))
    room.room_xpos_on_map = room_props["map_x"]
    room.room_ypos_on_map = room_props["map_y"]
    room.write_extra_data_to_rom()
    
    all_tilesets_for_room = room.layers.map{|layer| layer.tileset_filename}.uniq.compact
    
    tiled_layers = xml.css("layer")
    tiled_layers.each do |tmx_layer|
      props = extract_properties(tmx_layer)
      validate_properties(props, "Layer", %w(layer_width layer_height tileset collision_tileset z_index scroll_mode main_gfx_page_index))
      
      if tmx_layer.attr("name") =~ /^layer (\h{8})$/
        layer_list_entry_ram_pointer = $1.to_i(16)
        possible_layers = room.layers.select{|layer| layer.layer_list_entry_ram_pointer == layer_list_entry_ram_pointer}
        if possible_layers.length == 0
          raise ImportError.new("Could not find layer: %08X" % layer_list_entry_ram_pointer)
        elsif possible_layers.length > 1
          raise ImportError.new("%08X could be too many possible layers" % layer_list_entry_ram_pointer)
        end
        game_layer = possible_layers.first
      elsif tmx_layer.attr("name") =~ /^layer (\h{1,2})$/
        layer_index = $1.to_i(16)
        game_layer = room.layers[layer_index]
        if game_layer.nil?
          if SYSTEM == :nds && layer_index < Room.max_number_of_layers
            # Add new layers automatically.
            num_layers_to_add = layer_index - room.layers.length + 1
            num_layers_to_add.times do
              room.add_new_layer()
            end
            game_layer = room.layers[layer_index]
          else
            raise ImportError.new("Layer name \"#{tmx_layer.attr("name")}\" has an invalid layer index")
          end
        end
      else
        raise ImportError.new("Don't know how to parse layer name: \"#{tmx_layer.attr("name")}\"")
      end
      
      game_layer.width  = props["layer_width"]
      game_layer.height = props["layer_height"]
      game_layer.tileset_pointer = props["tileset"]
      game_layer.collision_tileset_pointer = props["collision_tileset"]
      game_layer.z_index = props["z_index"]
      game_layer.scroll_mode = props["scroll_mode"]
      game_layer.opacity = ((tmx_layer.attr("opacity")||1.0).to_f*31).to_i if SYSTEM == :nds
      game_layer.main_gfx_page_index = props["main_gfx_page_index"]
      game_layer.tiles = from_tmx_level_data(tmx_layer.css("data").text)
      
      game_layer.write_to_rom()
    end
    
    tiled_entities = xml.css("objectgroup[name='Entities'] object")
    room.entities = []
    tiled_entities.each do |tmx_entity|
      props = extract_properties(tmx_entity)
      validate_properties(props, "Entity", ["05 (unique_id)", "06 (type)", "07 (subtype)", "08", "09 (var_a)", "11 (var_b)"])
      validate_properties(props, "Entity", ["offset_up"]) if GAME == "hod"
      
      entity = Entity.new(room, room.fs)
      
      entity.x_pos = tmx_entity["x"].to_i
      entity.y_pos = tmx_entity["y"].to_i
      entity.unique_id = props["05 (unique_id)"]
      entity.type = props["06 (type)"]
      entity.subtype = props["07 (subtype)"]
      entity.byte_8 = props["08"]
      entity.var_a = props["09 (var_a)"]
      entity.var_b = props["11 (var_b)"]
      entity.offset_up = props["offset_up"] if GAME == "hod"
      
      room.entities << entity
    end
    room.write_entities_to_rom()
    
    tiled_doors = xml.css("objectgroup[name='Doors'] object")
    room.doors = []
    tiled_doors.each do |tiled_door|
      props = extract_properties(tiled_door)
      validate_properties(props, "Door", %w(dest_x dest_y dest_x_2 dest_y_2 destination_room))
      
      door = Door.new(room, room.game)
      
      x = tiled_door["x"].to_i / SCREEN_WIDTH_IN_PIXELS
      y = tiled_door["y"].to_i / SCREEN_HEIGHT_IN_PIXELS
      
      x = 0xFF if x < 0
      y = 0xFF if y < 0
      
      door.x_pos = x
      door.y_pos = y
      door.dest_x = props["dest_x"]
      door.dest_y = props["dest_y"]
      door.dest_x_2 = props["dest_x_2"]
      door.dest_y_2 = props["dest_y_2"]
      door.destination_room_metadata_ram_pointer = props["destination_room"]
      
      room.doors << door
    end
    room.write_doors_to_rom()
    
    puts "Read tmx file #{filename} and saved to rom"
  end
  
  def create(filename, room)
    all_tilesets_for_room = room.layers.map{|layer| layer.tileset_filename}.uniq.compact
    room_width_in_blocks = room.max_layer_width * SCREEN_WIDTH_IN_TILES
    room_height_in_blocks = room.max_layer_height * SCREEN_HEIGHT_IN_TILES
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.map(:version => "1.0", 
              :orientation => "orthogonal", 
              :renderorder => "right-down", 
              :width => room_width_in_blocks, :height => room_height_in_blocks, 
              :tilewidth => TILE_WIDTH, :tileheight => TILE_HEIGHT, 
              :nextobjectid => 1) {
        xml.properties {
          xml.property(:name => "map_x", :value => "%02X" % room.room_xpos_on_map)
          xml.property(:name => "map_y", :value => "%02X" % room.room_ypos_on_map)
        }
        
        all_tilesets_for_room.each do |tileset|
          xml.tileset(:firstgid => get_block_offset_for_tileset(tileset, all_tilesets_for_room),
                      :name => tileset,
                      :tilewidth => TILE_WIDTH, :tileheight => TILE_HEIGHT) {
            xml.image(:source => "./Tilesets/#{tileset}",
                      :width => TILESET_WIDTH_IN_TILES*TILE_WIDTH,
                      :height => TILESET_HEIGHT_IN_TILES*TILE_HEIGHT)
          }
        end
        
        room.z_ordered_layers.each do |layer|
          layer_name = "layer %08X" % layer.layer_list_entry_ram_pointer
          xml.layer(:name => layer_name,
                    :width => layer.width*SCREEN_WIDTH_IN_TILES, :height => layer.height*SCREEN_HEIGHT_IN_TILES,
                    :opacity => layer.opacity/31.0) {
            
            xml.properties {
              xml.property(:name => "layer_width",         :value => "%02X" % layer.width)
              xml.property(:name => "layer_height",        :value => "%02X" % layer.height)
              xml.property(:name => "z_index",             :value => "%02X" % layer.z_index)
              xml.property(:name => "colors_per_palette",  :value => "%02X" % layer.colors_per_palette)
              xml.property(:name => "main_gfx_page_index", :value => "%02X" % layer.main_gfx_page_index)
              xml.property(:name => "scroll_mode",         :value => "%02X" % layer.scroll_mode)
              xml.property(:name => "tileset",             :value => "%08X" % layer.tileset_pointer)
              xml.property(:name => "collision_tileset",   :value => "%08X" % layer.collision_tileset_pointer)
            }
            
            tileset_filename = layer.tileset_filename
            
            if tileset_filename.nil?
              # Empty GBA layer with no tileset specified.
              # Default to using the first tileset in the room since it doesn't actually matter which tileset it uses when all the tiles are blank anyway.
              block_offset = 1
            else
              block_offset = get_block_offset_for_tileset(tileset_filename, all_tilesets_for_room)
            end
            
            xml.data(to_tmx_level_data(layer.tiles, layer.width, block_offset), :encoding => "csv")
          }
        end
        
        xml.objectgroup(:name => "Doors",
                        :color => "purple") {
          room.doors.each_with_index do |door, i|
            x = door.x_pos
            y = door.y_pos
            x = -1 if x == 0xFF
            y = -1 if y == 0xFF
            x *= SCREEN_WIDTH_IN_PIXELS
            y *= SCREEN_HEIGHT_IN_PIXELS
            
            xml.object(:id => i+1,
                       :x => x,
                       :y => y,
                       :width => SCREEN_WIDTH_IN_PIXELS,
                       :height => SCREEN_HEIGHT_IN_PIXELS) {
              
              if GAME == "hod"
                dest_x_2 = "%02X" % door.dest_x_2
                dest_y_2 = "%02X" % door.dest_y_2
              else
                dest_x_2 = "%04X" % door.dest_x_2
                dest_y_2 = "%04X" % door.dest_y_2
              end
              xml.properties {
                xml.property(:name => "door_ram_pointer", :value => "%08X" % door.door_ram_pointer)
                xml.property(:name => "destination_room", :value => "%08X" % door.destination_room_metadata_ram_pointer)
                xml.property(:name => "dest_x", :value => "%04X" % door.dest_x)
                xml.property(:name => "dest_y", :value => "%04X" % door.dest_y)
                xml.property(:name => "dest_x_2", :value => dest_x_2)
                xml.property(:name => "dest_y_2", :value => dest_y_2)
              }
              
            }
          end
        }
        
        xml.objectgroup(:name => "Entities") {
          room.entities.each_with_index do |entity, i|
            xml.object(:id => i+1,
                       :x => entity.x_pos,
                       :y => entity.y_pos) {
              xml.properties {
                xml.property(:name => "entity_ram_pointer", :value => "%08X" % entity.entity_ram_pointer)
                xml.property(:name => "05 (unique_id)", :value => "%02X" % entity.unique_id)
                xml.property(:name => "06 (type)", :value => "%02X" % entity.type)
                xml.property(:name => "07 (subtype)", :value => "%02X" % entity.subtype)
                xml.property(:name => "08", :value => "%02X" % entity.byte_8)
                xml.property(:name => "09 (var_a)", :value => "%04X" % entity.var_a)
                xml.property(:name => "11 (var_b)", :value => "%04X" % entity.var_b)
                xml.property(:name => "offset_up", :value => "%02X" % entity.offset_up) if GAME == "hod"
              }
            }
          end
        }
      }
    end
    
    FileUtils::mkdir_p(File.dirname(filename))
    File.open(filename, "w") do |f|
      f.write(builder.to_xml)
    end
  end
  
  def to_tmx_level_data(tiles, layer_width, block_offset)
    tmx_level_data = tiles.map do |tile|
      if tile.index_on_tileset == 0
        tmx_tile_number = 0
      else
        tmx_tile_number = tile.index_on_tileset + block_offset
      end
      tmx_tile_number |= 0x80000000 if tile.horizontal_flip
      tmx_tile_number |= 0x40000000 if tile.vertical_flip
      tmx_tile_number
    end
    
    tmx_level_data = tmx_level_data.each_slice(layer_width*16)
    tmx_level_data = tmx_level_data.map{|row| row.join(",")}
    tmx_level_data = "\n" + tmx_level_data.join(",\n") + "\n"
    tmx_level_data
  end
  
  def get_block_offset_for_tileset(tileset, all_tilesets_for_room)
    block_offset = 1
    tileset_index = all_tilesets_for_room.index(tileset)
    block_offset += NUM_BLOCKS_IN_TILESET_IMAGE * tileset_index # 1024/512 blocks in each tileset (NDS/GBA)
    block_offset
  end
  
  def from_tmx_level_data(tile_data_string)
    tmx_tiles = tile_data_string.scan(/\d+/).map{|str| str.to_i}
    
    game_tiles = []
    
    tmx_tiles.each do |block|
      block = 1 if block == 0
      horizontal_flip  = (block & 0x80000000) != 0
      vertical_flip    = (block & 0x40000000) != 0
      index_on_tileset = (block & ~(0x80000000 | 0x40000000 | 0x20000000))
      index_on_tileset -= 1 # TMX indexes start at 1 instead of 0.
      index_on_tileset = index_on_tileset % NUM_BLOCKS_IN_TILESET_IMAGE # Account for the block offset for different tilesets. 1024/512 blocks in each tileset (NDS/GBA).
      
      tile = LayerTile.new
      tile.index_on_tileset = index_on_tileset
      tile.horizontal_flip = horizontal_flip
      tile.vertical_flip = vertical_flip
      game_tiles << tile
    end
    
    return game_tiles
  end
  
private
  
  def extract_properties(object_xml)
    props = {}
    object_xml.css("property").each do |prop_xml|
      name = prop_xml["name"]
      value = prop_xml["value"].to_i(16)
      props[name] = value
    end
    
    return props
  end
  
  def validate_properties(props, object_name, required_props)
    required_props.each do |required_prop|
      if props[required_prop].nil?
        raise ImportError.new("Import error: #{object_name} is missing required property '#{required_prop}'.")
      end
    end
  end
end
