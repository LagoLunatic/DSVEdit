
class Room
  class RoomReadError < StandardError ; end
  class WriteError < StandardError ; end
  
  attr_reader :room_metadata_ram_pointer,
              :sector,
              :layers,
              :number_of_doors,
              :layer_list_ram_pointer,
              :gfx_list_pointer,
              :entity_list_ram_pointer,
              :door_list_ram_pointer,
              :gfx_pages,
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
    @layer_list_ram_pointer = room_metadata[2]
    @gfx_list_pointer = room_metadata[3]
    palette_wrapper_ram_pointer = room_metadata[4]
    @entity_list_ram_pointer = room_metadata[5]
    @door_list_ram_pointer = room_metadata[6]
    last_4_bytes = room_metadata[7]
    
    read_last_4_bytes_from_rom(last_4_bytes)
    read_layer_list_from_rom(layer_list_ram_pointer) rescue NDSFileSystem::ConversionError
    read_graphic_tilesets_from_rom(gfx_list_pointer)
    read_palette_pages_from_rom(palette_wrapper_ram_pointer)
    read_entity_list_from_rom(entity_list_ram_pointer)
    read_door_list_from_rom(door_list_ram_pointer)
  end
  
  def read_layer_list_from_rom(layer_list_ram_pointer)
    @layers = []
    i = 0
    while true
      is_a_pointer_check = fs.read(layer_list_ram_pointer + i*16 + 15).unpack("C*").first
      break if i == 4 # Maximum of 4 layers per room.
      if is_a_pointer_check != 0x02
        break
      end
      
      layer = Layer.new(self, layer_list_ram_pointer + i*16, fs)
      layer.read_from_rom()
      @layers << layer
      
      i += 1
    end

    if @layers.length == 0
      raise RoomReadError.new("Couldn't find any layers")
    end
  end
  
  def read_graphic_tilesets_from_rom(gfx_list_pointer)
    @gfx_pages = GfxWrapper.from_gfx_list_pointer(gfx_list_pointer, fs)
  rescue NDSFileSystem::ConversionError => e
    # When gfx_list_pointer is like this (e.g. 0x02195984), it just points to 00s instead of actual data.
    # What this means is that the room doesn't load any gfx pages. Instead it just keeps whatever gfx pages the previous room had loaded.
    @gfx_pages = []
  end
  
  def read_palette_pages_from_rom(palette_wrapper_ram_pointer)
    i = 0
    @palette_pages = []
    while true
      palette_ram_pointer = fs.read(palette_wrapper_ram_pointer + i*8,4).unpack("V*").first
      unknown_data = fs.read(palette_wrapper_ram_pointer + i*8 + 4,4).unpack("V*").first # TODO
      
      break if palette_ram_pointer == 0
      
      @palette_pages << palette_ram_pointer
      
      i += 1
    end
  rescue NDSFileSystem::ConversionError => e
    # When palette_wrapper_ram_pointer is like this (e.g. 0x02195984), it just points to 00s instead of actual data.
    # What this means is that the room doesn't load a palette. Instead it just keeps whatever palette the previous room had loaded.
    @palette_pages = []
  end
  
  def read_entity_list_from_rom(entity_list_ram_pointer)
    i = 0
    @entities = []
    while true
      entity_pointer = entity_list_ram_pointer + i*12
      if fs.read(entity_pointer, 2).unpack("v").first == 0x7FFF
        break
      end
      
      @entities << Entity.new(self, fs).read_from_rom(entity_pointer)
      
      i += 1
    end
    
    @original_number_of_entities = entities.length
  end
  
  def read_door_list_from_rom(door_list_ram_pointer)
    @doors = []
    (0..number_of_doors-1).each do |i|
      door_pointer = door_list_ram_pointer + i*16
      
      @doors << Door.new(self, game).read_from_rom(door_pointer)
    end
    
    @original_number_of_doors = doors.length
  rescue NDSFileSystem::ConversionError => e
    # When door_list_ram_pointer points to nothing it indicates the room has no doors (e.g. Menace's room).
    @doors = []
    @original_number_of_doors = 0
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
      
      if layers.empty?
        raise WriteError.new("Cannot add new entities to a room with no layers. Add a new layer first.")
      end
      
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
      
      if layers.empty?
        raise WriteError.new("Cannot add new doors to a room with no layers. Add a new layer first.")
      end
      
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
  
  def add_new_layer
    sector.load_necessary_overlay()
    
    if layers.length >= 4
      raise "Can't add new layer; room already has 4 layers."
    end
    
    overlay = fs.overlays[overlay_id]
    overlay_ram_start = overlay[:ram_start_offset]
    overlay_ram_end = overlay[:ram_start_offset]+overlay[:size]
    
    if layers.length == 0 && layer_list_ram_pointer >= overlay_ram_end
      # Invalid room where layer list pointer points outside the overlay file. So we expand the file and create a blank layer list.
      @layer_list_ram_pointer = fs.expand_file_and_get_end_of_file_ram_address(overlay_ram_start, 16*4)
      fs.write(room_metadata_ram_pointer+2*4, [@layer_list_ram_pointer].pack("V"))
    end
    
    new_layer_i = layers.length
    new_layer = Layer.new(self, layer_list_ram_pointer + new_layer_i*16, fs)
    
    new_layer.z_index = 0x16
    new_layer.scroll_mode = 0x01
    new_layer.opacity = 0x1F
    new_layer.main_gfx_page_index = 0x00
    
    new_layer.layer_metadata_ram_pointer = fs.expand_file_and_get_end_of_file_ram_address(overlay_ram_start, 16)
    
    main_layer = layers.first
    if main_layer
      new_layer.width = main_layer.width
      new_layer.height = main_layer.height
      new_layer.ram_pointer_to_tileset_for_layer = main_layer.ram_pointer_to_tileset_for_layer
      new_layer.collision_tileset_ram_pointer = main_layer.collision_tileset_ram_pointer
    else
      # Room that has no layers.
      new_layer.width = 1
      new_layer.height = 1
      new_layer.ram_pointer_to_tileset_for_layer = 0
      new_layer.collision_tileset_ram_pointer = 0
    end
    new_layer.layer_tiledata_ram_start_offset = overlay_ram_start # Just a dummy pointer. Layer#write_to_rom will expand the file and set this to a new pointer.
    new_layer.tiles = []
    
    new_layer.write_to_rom()
    
    @layers << new_layer
  end
  
  def overlay_id
    AREA_INDEX_TO_OVERLAY_INDEX[sector.area.area_index][sector.sector_index]
  end
  
  def z_ordered_layers
    layers.sort_by{|layer| -layer.z_index}
  end
  
  def filename
    "room_%02X-%02X-%02X_%08X" % [area_index, sector_index, room_index, room_metadata_ram_pointer]
  end
  
  def area_name
    if SECTOR_INDEX_TO_SECTOR_NAME[area_index]
      return SECTOR_INDEX_TO_SECTOR_NAME[area_index][sector_index]
    else
      return AREA_INDEX_TO_AREA_NAME[area_index]
    end
  end
  
  def max_layer_width
    layers.map(&:width).max || 0
  end
  
  def max_layer_height
    layers.map(&:height).max || 0
  end
  
  def main_layer_width
    if layers.length > 0
      layers.first.width
    else
      0
    end
  end
  
  def main_layer_height
    if layers.length > 0
      layers.first.height
    else
      0
    end
  end
  
  def connected_rooms
    doors.map{|door| door.destination_door.room}.uniq
  end
end
