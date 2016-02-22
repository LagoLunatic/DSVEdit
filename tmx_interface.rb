
require 'nokogiri'

class TMXInterface
  def read(filename, room)
    match = File.basename(filename).match(/^room_a\d+-\d+-\d+_(\h+)_x\d+_y\d+_w\d+_h\d+\.tmx$/)
    room_metadata_ram_pointer = match[1].to_i(16)
    
    tiled_room = File.read(filename)
    xml = Nokogiri::XML(tiled_room)
    tiled_layers = xml.css("layer")
    tiled_layers.each do |tmx_layer|
      layer_metadata_ram_pointer = tmx_layer.attr("name").match(/^layer (\h+)$/)[1].to_i(16)
      possible_layers = room.layers.select{|layer| layer.layer_metadata_ram_pointer == layer_metadata_ram_pointer}
      if possible_layers.length != 1
        raise "%08X could be too many possible layers (or not enough)" % layer_metadata_ram_pointer
      end
      game_layer = possible_layers.first
      game_layer.width = tmx_layer.attr("width").to_i / 16
      game_layer.height = tmx_layer.attr("height").to_i / 12
      from_tmx_level_data(tmx_layer.css("data").text, game_layer.tiles)
      game_layer.write_to_rom()
    end
    
    tiled_entities = xml.css("objectgroup[name='Entities'] object")
    tiled_entities.each do |tmx_entity|
      props = extract_properties(tmx_entity)
      
      entity = room.entities.find{|e| e.entity_ram_pointer == props["entity_ram_pointer"]}
      if entity.nil?
        raise "Couldn't find entity at %08X" % tmx_entity.entity_ram_pointer
      end
      
      entity.x_pos = tmx_entity["x"].to_i
      entity.y_pos = tmx_entity["y"].to_i
      entity.byte_5 = props["05"]
      entity.type = props["06 (type)"]
      entity.subtype = props["07 (subtype)"]
      entity.byte_8 = props["08"]
      entity.var_a = props["var_a"]
      entity.var_b = props["var_b"]
      entity.write_to_rom()
    end
    
    tiled_doors = xml.css("objectgroup[name='Doors'] object")
    tiled_doors.each do |tiled_door|
      props = extract_properties(tiled_door)
      
      door = room.doors.find{|d| d.door_ram_pointer == props["door_ram_pointer"]}
      if door.nil?
        raise "Couldn't find door at %08X" % door.door_ram_pointer
      end
      
      x = tiled_door["x"].to_i / SCREEN_WIDTH_IN_PIXELS
      y = tiled_door["y"].to_i / SCREEN_HEIGHT_IN_PIXELS
      
      x = 0xFF if x < 0
      y = 0xFF if y < 0
      
      door.x_pos = x
      door.y_pos = y
      door.dest_x = props["dest_x"]
      door.dest_y = props["dest_y"]
      door.destination_room_metadata_ram_pointer = props["destination_room"]
      door.write_to_rom()
    end
    
    puts "Read tmx file #{filename} and saved to rom"
  end
  
  def create(filename, room)
    all_tilesets_for_room = room.layers.map{|layer| layer.tileset_filename}.uniq
    room_width_in_blocks = room.layers.last.width * 16
    room_height_in_blocks = room.layers.last.height * 12
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.map(:version => "1.0", 
              :orientation => "orthogonal", 
              :renderorder => "right-down", 
              :width => room_width_in_blocks, :height => room_height_in_blocks, 
              :tilewidth => 16, :tileheight => 16, 
              :nextobjectid => 1) {
        xml.properties {
          xml.property(:name => "map_x", :value => room.room_xpos_on_map)
          xml.property(:name => "map_y", :value => room.room_ypos_on_map)
        }
        
        all_tilesets_for_room.each do |tileset|
          xml.tileset(:firstgid => get_block_offset_for_tileset(tileset, all_tilesets_for_room),
                      :name => tileset,
                      :tilewidth => 16, :tileheight => 16) {
            xml.image(:source => "./Tilesets/#{tileset}",
                      :width => 256,
                      :height => 1024)
          }
        end
        
        room.z_ordered_layers.each do |layer|
          layer_name = "layer %08X" % layer.layer_metadata_ram_pointer
          xml.layer(:name => layer_name,
                    :width => layer.width*16, :height => layer.height*12,
                    :opacity => layer.opacity/31.0,
                    :z_index => layer.z_index,
                    :colors_per_palette => layer.colors_per_palette) {
            xml.data(to_tmx_level_data(layer.tiles, layer.width, get_block_offset_for_tileset(layer.tileset_filename, all_tilesets_for_room)), :encoding => "csv")
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
                       :width => 16*16,
                       :height => 16*12) {
              
              xml.properties {
                xml.property(:name => "door_ram_pointer", :value => "%08X" % door.door_ram_pointer)
                xml.property(:name => "destination_room", :value => "%08X" % door.destination_room_metadata_ram_pointer)
                xml.property(:name => "dest_x", :value => "%04X" % door.dest_x)
                xml.property(:name => "dest_y", :value => "%04X" % door.dest_y)
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
                xml.property(:name => "05", :value => "%02X" % entity.byte_5)
                xml.property(:name => "06 (type)", :value => "%02X" % entity.type)
                xml.property(:name => "07 (subtype)", :value => "%02X" % entity.subtype)
                xml.property(:name => "08", :value => "%02X" % entity.byte_8)
                xml.property(:name => "var_a", :value => "%02X" % entity.var_a)
                xml.property(:name => "var_b", :value => "%02X" % entity.var_b)
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
      tmx_tile_number = tile.index_on_tileset + block_offset
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
    block_offset += 1024 * tileset_index # 1024 blocks in each tileset
    block_offset
  end
  
  def from_tmx_level_data(tile_data_string, game_tiles)
    tile_data = tile_data_string.scan(/\d+/).map{|str| str.to_i}
    
    i = 0
    tile_data = tile_data.map do |block|
      block = 1 if block == 0
      horizontal_flip  = (block & 0x80000000) != 0
      vertical_flip    = (block & 0x40000000) != 0
      index_on_tileset = (block & ~(0x80000000 | 0x40000000 | 0x20000000))
      
      game_tiles[i].index_on_tileset = index_on_tileset - 1
      game_tiles[i].horizontal_flip = horizontal_flip
      game_tiles[i].vertical_flip = vertical_flip
      
      i += 1
    end
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
end
