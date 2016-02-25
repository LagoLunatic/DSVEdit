
class Room
  class RoomReadError < StandardError ; end
  
  attr_reader :room_metadata_ram_pointer,
              :sector,
              :layers,
              :number_of_doors,
              :tileset_wrapper_A_ram_pointer,
              :graphic_tilesets_for_room,
              :palette_pages,
              :palette_page_index,
              :entities,
              :doors,
              :area_index,
              :sector_index,
              :room_index,
              :fs
  attr_accessor :room_xpos_on_map, :room_ypos_on_map

  def initialize(sector, room_metadata_ram_pointer, area_index, sector_index, room_index, fs)
    @room_metadata_ram_pointer = room_metadata_ram_pointer
    @sector = sector
    @area_index = area_index
    @sector_index = sector_index
    @room_index = room_index
    @fs = fs
    read_from_rom()
  end
  
  def read_from_rom
    #room_metadata_pointer = converter.ram_to_rom(room_metadata_ram_pointer)
    #puts "room_metadata_ram_pointer: %08X" % room_metadata_ram_pointer
    #puts "room_metadata_pointer: %08X" % room_metadata_pointer
    
    room_metadata = fs.read(room_metadata_ram_pointer, 32).unpack("V*")
    layer_list_ram_pointer = room_metadata[2]
    @tileset_wrapper_A_ram_pointer = room_metadata[3]
    palette_wrapper_ram_pointer = room_metadata[4]
    entity_list_ram_pointer = room_metadata[5]
    door_list_ram_pointer = room_metadata[6]
    last_4_bytes = room_metadata[7]
    
    read_last_4_bytes_from_rom(last_4_bytes)
    read_layer_list_from_rom(layer_list_ram_pointer)
    read_graphic_tilesets_from_rom(tileset_wrapper_A_ram_pointer)
    read_palette_pages_from_rom(palette_wrapper_ram_pointer)
    read_entity_list_from_rom(entity_list_ram_pointer)
    read_door_list_from_rom(door_list_ram_pointer)
  end
  
  def read_layer_list_from_rom(layer_list_ram_pointer)
    # 023049C4 -> 395DA4
    #layer_list_ram_pointer = rom[room_metadata_pointer + 8,4].unpack("V*").first
    #layer_list_pointer = layer_list_ram_pointer - 0x02000000 + 0x4000
    #puts "layer_list_ram_pointer: %08X" % layer_list_ram_pointer
    #layer_list_pointer = ram_to_rom(layer_list_ram_pointer, overlay_offset)
    #layer_list_pointer = converter.ram_to_rom(layer_list_ram_pointer)
    #puts "layer_list_pointer: %08X" % layer_list_pointer
    
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
    #tileset_wrapper_A_ram_pointer = rom[room_metadata_pointer + 12,4].unpack("V*").first # TODO: when this is like 0x02195984 it's a save/transition room. when it's like 0x020AF964 it's a normal room.
    #puts "tileset_wrapper_A_ram_pointer: %08X" % tileset_wrapper_A_ram_pointer
    if tileset_wrapper_A_ram_pointer > (0x02000000+ARM9_LENGTH) && tileset_wrapper_A_ram_pointer < fs.overlays[0][:ram_start_offset]
      # When this pointer is like this (e.g. 0x02195984), it just points to 00s instead of actual data.
      # What this means is that the room doesn't load a tileset. Instead it just keeps whatever tileset the previous room had loaded.
      @graphic_tilesets_for_room = nil
    else
      #tileset_wrapper_A_pointer = ram_to_rom(tileset_wrapper_A_ram_pointer, overlay_offset)# - 0x02000000 + 0x4000 # 0209EFD8 -> A2FD8.
      #tileset_wrapper_A_pointer = converter.ram_to_rom(tileset_wrapper_A_ram_pointer)
      #puts "tileset_wrapper_A_pointer: %08X" % tileset_wrapper_A_pointer
      i = 0
      @graphic_tilesets_for_room = []
      while true
        tileset_wrapper_B_ram_pointer = fs.read(tileset_wrapper_A_ram_pointer + i*8, 4).unpack("V*").first # we're not going to actually follow tileset wrapper b pointer. we're just using it to identify the tileset.
        unknown_data = fs.read(tileset_wrapper_A_ram_pointer + i*8 + 4, 4).unpack("V*").first
        #puts "x%08X" % tileset_wrapper_B_ram_pointer
        #puts "u%08X" % unknown_data
        break if tileset_wrapper_B_ram_pointer == 0
        #tileset_wrapper_B_pointer = ram_to_rom(tileset_wrapper_B_ram_pointer, overlay_offset)# - 0x02000000 + 0x4000
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
    #palette_wrapper_ram_pointer = rom[room_metadata_pointer + 16,4].unpack("V*").first # TODO: when this is like 0x02195984 it's a save/transition room. when it's like 0x020AF964 it's a normal room.
    #puts "palette_wrapper_ram_pointer: %08X" % palette_wrapper_ram_pointer
    # 022CEF68 -> 451788
    if palette_wrapper_ram_pointer > (0x02000000+ARM9_LENGTH) && palette_wrapper_ram_pointer < fs.overlays[0][:ram_start_offset]
      # When this pointer is like this (e.g. 0x02195984), it just points to 00s instead of actual data.
      # What this means is that the room doesn't load a palette. Instead it just keeps whatever palette the previous room had loaded.
      @palette_pages = [nil]
      #puts "palette_wrapper_ram_pointer: %08X" % palette_wrapper_ram_pointer
    else
      #palette_wrapper_pointer = palette_wrapper_ram_pointer - 0x02000000 + 0x4000
      #palette_wrapper_pointer = ram_to_rom(palette_wrapper_ram_pointer, overlay_offset)
      #palette_wrapper_pointer = converter.ram_to_rom(palette_wrapper_ram_pointer)
      #puts "palette_wrapper_pointer: %08X" % palette_wrapper_pointer
      
      i = 0
      @palette_pages = []
      while true
        palette_ram_pointer = fs.read(palette_wrapper_ram_pointer + i*8,4).unpack("V*").first
        #puts "palette_ram_pointer: %08X" % palette_ram_pointer
        unknown_data = fs.read(palette_wrapper_ram_pointer + i*8 + 4,4).unpack("V*").first # TODO
        
        break if palette_ram_pointer == 0
        
        #palette_pointer = converter.ram_to_rom(palette_ram_pointer)
        #puts "palette_pointer: %08X" % palette_pointer
        @palette_pages << palette_ram_pointer
        
        i += 1
      end
    end
  end
  
  def read_entity_list_from_rom(entity_list_ram_pointer)
    #entity_list_pointer = converter.ram_to_rom(entity_list_ram_pointer)
    
    i = 0
    @entities = []
    while true
      entity_pointer = entity_list_ram_pointer + i*12
      if fs.read(entity_pointer,12) == "\xFF\x7F\xFF\x7F\x00\x00\x00\x00\x00\x00\x00\x00".b
        break
      end
      
      @entities << Entity.new(self, entity_pointer, fs)
      
      i += 1
    end
  end
  
  def read_door_list_from_rom(door_list_ram_pointer)
    if door_list_ram_pointer > (0x02000000+ARM9_LENGTH) && door_list_ram_pointer < fs.overlays[0][:ram_start_offset]
      # A pointer to nothing here indicates the room has no doors (e.g. Menace's room).
      @doors = []
      return
    else
      #door_list_pointer = converter.ram_to_rom(door_list_ram_pointer)
    end
    
    @doors = []
    (0..number_of_doors-1).each do |i|
      door_pointer = door_list_ram_pointer + i*16
      
      @doors << Door.new(self, door_pointer, fs)
    end
  end
  
  def read_last_4_bytes_from_rom(last_4_bytes)
    #last_4_bytes = rom[room_metadata_pointer + 28,4].unpack("V*").first
    @number_of_doors, @room_xpos_on_map, @room_ypos_on_map, @palette_page_index = EXTRACT_EXTRA_ROOM_INFO.call(last_4_bytes)
    #puts "room pos on map: " + [room_xpos_on_map, room_ypos_on_map].inspect
  end
  
  def palette_offset
    palette_pages[palette_page_index]
  end
  
  def write_to_rom
    sector.load_necessary_overlay()
    
    raise NotImplementedError
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
end
