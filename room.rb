
class Room
  class RoomReadError < StandardError ; end
  
  attr_reader :room_metadata_ram_pointer,
              :sector,
              :layers,
              :number_of_doors,
              :tileset_wrapper_A_ram_pointer,
              :entity_list_ram_pointer,
              :door_list_ram_pointer,
              :graphic_tilesets_for_room,
              :palette_pages,
              :palette_page_index,
              :area_index,
              :sector_index,
              :room_index,
              :fs,
              :game
  attr_accessor :room_xpos_on_map,
                :room_ypos_on_map,
                :entities,
                :doors

  def initialize(sector, room_metadata_ram_pointer, area_index, sector_index, room_index, game)
    @room_metadata_ram_pointer = room_metadata_ram_pointer
    @sector = sector
    @area_index = area_index
    @sector_index = sector_index
    @room_index = room_index
    @fs = game.fs
    @game = game
    read_from_rom()
  end
  
  def read_from_rom
    room_metadata = fs.read(room_metadata_ram_pointer, 32).unpack("V*")
    layer_list_ram_pointer = room_metadata[2]
    @tileset_wrapper_A_ram_pointer = room_metadata[3]
    palette_wrapper_ram_pointer = room_metadata[4]
    @entity_list_ram_pointer = room_metadata[5]
    @door_list_ram_pointer = room_metadata[6]
    last_4_bytes = room_metadata[7]
    
    read_last_4_bytes_from_rom(last_4_bytes)
    read_layer_list_from_rom(layer_list_ram_pointer)
    read_graphic_tilesets_from_rom(tileset_wrapper_A_ram_pointer)
    read_palette_pages_from_rom(palette_wrapper_ram_pointer)
    read_entity_list_from_rom(entity_list_ram_pointer)
    read_door_list_from_rom(door_list_ram_pointer)
  end
  
  def read_layer_list_from_rom(layer_list_ram_pointer)
    @layers = []
    i = 0
    while true
      is_a_pointer_check = fs.read(layer_list_ram_pointer + i*16 + 15).unpack("C*").first
      break if i == 4 # maximum 4 layers per room. TODO: check if this is also true in dos and por
      if is_a_pointer_check != 0x02
        break
      end
      
      @layers << Layer.new(self, layer_list_ram_pointer + i*16, fs)
      
      i += 1
    end

    if @layers.length == 0
      raise RoomReadError.new("Couldn't find any layers")
    end
  end
  
  def read_graphic_tilesets_from_rom(tileset_wrapper_A_ram_pointer)
    if tileset_wrapper_A_ram_pointer > (0x02000000+ARM9_LENGTH) && tileset_wrapper_A_ram_pointer < fs.overlays[0][:ram_start_offset]
      # When this pointer is like this (e.g. 0x02195984), it just points to 00s instead of actual data.
      # What this means is that the room doesn't load a tileset. Instead it just keeps whatever tileset the previous room had loaded.
      @graphic_tilesets_for_room = nil
    else
      i = 0
      @graphic_tilesets_for_room = []
      while true
        tileset_wrapper_B_ram_pointer = fs.read(tileset_wrapper_A_ram_pointer + i*8, 4).unpack("V*").first # we're not going to actually follow tileset wrapper b pointer. we're just using it to identify the tileset.
        unknown_data = fs.read(tileset_wrapper_A_ram_pointer + i*8 + 4, 4).unpack("V*").first
        #puts "u%08X" % unknown_data
        break if tileset_wrapper_B_ram_pointer == 0
        #unknown_data2 = rom[tileset_wrapper_B_pointer, 4].unpack("V*").first # TODO
        #unknown_data3 = rom[tileset_wrapper_B_pointer+4, 4].unpack("V*").first
        #puts "u%08X" % unknown_data2
        #puts "u%08X" % unknown_data3
        file = fs.files.values.find{|file| file[:ram_start_offset] == tileset_wrapper_B_ram_pointer}
        if file.nil?
          puts "Couldn't find tileset. Possible transition room? wrapper B ram %08X. wrapper A ram: %08X" % [tileset_wrapper_B_ram_pointer, tileset_wrapper_A_ram_pointer]
          break
        end
        @graphic_tilesets_for_room << file
        i += 1
      end
    end
  end
  
  def read_palette_pages_from_rom(palette_wrapper_ram_pointer)
    if palette_wrapper_ram_pointer > (0x02000000+ARM9_LENGTH) && palette_wrapper_ram_pointer < fs.overlays[0][:ram_start_offset]
      # When this pointer is like this (e.g. 0x02195984), it just points to 00s instead of actual data.
      # What this means is that the room doesn't load a palette. Instead it just keeps whatever palette the previous room had loaded.
      @palette_pages = [nil]
    else
      i = 0
      @palette_pages = []
      while true
        palette_ram_pointer = fs.read(palette_wrapper_ram_pointer + i*8,4).unpack("V*").first
        unknown_data = fs.read(palette_wrapper_ram_pointer + i*8 + 4,4).unpack("V*").first # TODO
        
        break if palette_ram_pointer == 0
        
        @palette_pages << palette_ram_pointer
        
        i += 1
      end
    end
  end
  
  def read_entity_list_from_rom(entity_list_ram_pointer)
    i = 0
    @entities = []
    while true
      entity_pointer = entity_list_ram_pointer + i*12
      if fs.read(entity_pointer, 12) == "\xFF\x7F\xFF\x7F\x00\x00\x00\x00\x00\x00\x00\x00".b
        break
      end
      
      @entities << Entity.new(self, fs).read_from_rom(entity_pointer)
      
      i += 1
    end
    
    @original_number_of_entities = entities.length
  end
  
  def read_door_list_from_rom(door_list_ram_pointer)
    if door_list_ram_pointer > (0x02000000+ARM9_LENGTH) && door_list_ram_pointer < fs.overlays[0][:ram_start_offset]
      # A pointer to nothing here indicates the room has no doors (e.g. Menace's room).
      @doors = []
      return
    end
    
    @doors = []
    (0..number_of_doors-1).each do |i|
      door_pointer = door_list_ram_pointer + i*16
      
      @doors << Door.new(self, game).read_from_rom(door_pointer)
    end
    
    @original_number_of_doors = doors.length
  end
  
  def read_last_4_bytes_from_rom(last_4_bytes)
    if GAME == "dos"
      @number_of_doors    = (last_4_bytes & 0b00000000_00000000_11111111_11111111)
      @room_xpos_on_map   = (last_4_bytes & 0b00000000_00111111_00000000_00000000) >> 16
      @room_ypos_on_map   = (last_4_bytes & 0b00011111_10000000_00000000_00000000) >> 23
      @palette_page_index = 0 # always 0 in dos, and so not stored in these 4 bytes
    else
      @number_of_doors    = (last_4_bytes & 0b00000000_00000000_00000000_01111111)
      @room_xpos_on_map   = (last_4_bytes & 0b00000000_00000000_00111111_10000000) >> 7
      @room_ypos_on_map   = (last_4_bytes & 0b00000000_00011111_11000000_00000000) >> 14
      @palette_page_index = (last_4_bytes & 0b00001111_10000000_00000000_00000000) >> 23
    end
  end
  
  def palette_offset
    palette_pages[palette_page_index]
  end
  
  def write_to_rom
    sector.load_necessary_overlay()
    
    raise NotImplementedError
  end
  
  def write_entities_to_rom
    sector.load_necessary_overlay()
    
    if entities.length > @original_number_of_entities
      # Repoint the entity list so there's room for more entities without overwriting anything.
      # Entities are originally stored in the arm9 file, but we can't expand that. Instead put them into an overlay file, which can be expanded.
      # We use the same overlay that the the room's layers are stored on.
      
      length_to_expand_by = (entities.length+1)*12
      new_entity_list_pointer = fs.expand_file_and_get_end_of_file_ram_address(layers.first.layer_metadata_ram_pointer, length_to_expand_by)
      @entity_list_ram_pointer = new_entity_list_pointer
      fs.write(room_metadata_ram_pointer+5*4, [entity_list_ram_pointer].pack("V"))
    end
    
    new_entity_pointer = entity_list_ram_pointer
    entities.each do |entity|
      entity.entity_ram_pointer = new_entity_pointer
      entity.write_to_rom()
      
      new_entity_pointer += 12
    end
    fs.write(new_entity_pointer, [0x7FFF7FFF, 0, 0].pack("V*")) # Marks the end of the entity list
  end
  
  def write_doors_to_rom
    sector.load_necessary_overlay()
    
    if doors.length > @original_number_of_doors
      # Repoint the door list so there's room for more doors without overwriting anything.
      # Doors are originally stored in the arm9 file, but we can't expand that. Instead put them into an overlay file, which can be expanded.
      # We use the same overlay that the the room's layers are stored on.
      
      length_to_expand_by = doors.length*16
      new_door_list_pointer = fs.expand_file_and_get_end_of_file_ram_address(layers.first.layer_metadata_ram_pointer, length_to_expand_by)
      @door_list_ram_pointer = new_door_list_pointer
      fs.write(room_metadata_ram_pointer+6*4, [door_list_ram_pointer].pack("V"))
    end
    
    new_door_pointer = door_list_ram_pointer
    doors.each do |door|
      door.door_ram_pointer = new_door_pointer
      door.write_to_rom()
      
      new_door_pointer += 16
    end
    
    @number_of_doors = doors.length
    write_last_4_bytes_to_rom()
  end
  
  def write_last_4_bytes_to_rom
    last_4_bytes = 0
    if GAME == "dos"
      last_4_bytes |= (@number_of_doors         ) & 0b00000000_00000000_11111111_11111111
      last_4_bytes |= (@room_xpos_on_map   << 16) & 0b00000000_00111111_00000000_00000000
      last_4_bytes |= (@room_ypos_on_map   << 23) & 0b00011111_10000000_00000000_00000000
    else
      last_4_bytes |= (@number_of_doors         ) & 0b00000000_00000000_00000000_01111111
      last_4_bytes |= (@room_xpos_on_map   <<  7) & 0b00000000_00000000_00111111_10000000
      last_4_bytes |= (@room_ypos_on_map   << 14) & 0b00000000_00011111_11000000_00000000
      last_4_bytes |= (@palette_page_index << 23) & 0b00001111_10000000_00000000_00000000
    end
    fs.write(room_metadata_ram_pointer+7*4, [last_4_bytes].pack("V"))
  end
  
  def z_ordered_layers
    layers.sort_by{|layer| -layer.z_index}
  end
  
  def filename
    "room_a#{area_index}-#{sector_index}-#{room_index}_%08X_x#{room_xpos_on_map}_y#{room_ypos_on_map}_w#{z_ordered_layers.last.width}_h#{z_ordered_layers.last.height}" % room_metadata_ram_pointer
  end
  
  def area_name
    if SECTOR_INDEX_TO_SECTOR_NAME[area_index]
      return SECTOR_INDEX_TO_SECTOR_NAME[area_index][sector_index]
    else
      return AREA_INDEX_TO_AREA_NAME[area_index]
    end
  end
  
  def max_layer_width
    layers.map(&:width).max
  end
  
  def max_layer_height
    layers.map(&:height).max
  end
  
  def main_layer_width
    layers.select{|layer| layer.scroll_mode == 1}.map(&:width).max
  end
  
  def main_layer_height
    layers.select{|layer| layer.scroll_mode == 1}.map(&:height).max
  end
  
  def connected_rooms
    doors.map{|door| door.destination_door.room}.uniq
  end
end
