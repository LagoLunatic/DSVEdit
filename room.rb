
class Room
  class RoomReadError < StandardError ; end
  
  attr_reader :room_metadata_ram_pointer,
              :layers,
              :number_of_doors,
              :graphic_tilesets_for_room,
              #:palette_pointer,
              :palette_pages,
              :palette_page_index,
              :entities,
              :doors,
              :tileset_offsets_by_filename_by_tileset_wrapper_B_pointer,
              :rom,
              #:overlay_offset,
              :major_area_index,
              :area_index,
              :room_index,
              :converter
  attr_accessor :room_xpos_on_map, :room_ypos_on_map

  def initialize(room_metadata_ram_pointer, rom, major_area_index, area_index, room_index, converter)
    @room_metadata_ram_pointer = room_metadata_ram_pointer
    @rom = rom
    @major_area_index = major_area_index
    @area_index = area_index
    @room_index = room_index
    @converter = converter
    read_from_rom()
  end
  
  def read_from_rom
    #overlay_index = AREA_INDEX_TO_OVERLAY_INDEX[major_area_index][area_index]
    #@overlay_offset = ALL_OVERLAYS[overlay_index][:rom].begin
    initialize_tileset_offsets_by_filename_by_tileset_wrapper_B_pointer()
    
    #room_metadata_pointer = room_metadata_ram_pointer - 0x02000000 + 0x4000
    #room_metadata_pointer = ram_to_rom(room_metadata_ram_pointer, overlay_offset)
    room_metadata_pointer = converter.ram_to_rom(room_metadata_ram_pointer)
    #puts "room_metadata_ram_pointer: %08X" % room_metadata_ram_pointer
    #puts "room_metadata_pointer: %08X" % room_metadata_pointer
    
    room_metadata = rom[room_metadata_pointer,32].unpack("V*")
    layer_list_ram_pointer = room_metadata[2]
    tileset_wrapper_A_ram_pointer = room_metadata[3]
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
    layer_list_pointer = converter.ram_to_rom(layer_list_ram_pointer)
    #puts "layer_list_pointer: %08X" % layer_list_pointer
    
    @layers = []
    i = 0
    while true
      is_a_pointer_check = rom[layer_list_pointer + i*16 + 15].unpack("C*").first
      break if i == 4 # maximum 4 layers per room. TODO: check if this is also true in dos and por
      if is_a_pointer_check != 0x02
        break
      end
      
      @layers << Layer.new(self, layer_list_pointer + i*16, rom, converter)
      
      i += 1
    end

    if @layers.length == 0
      raise RoomReadError.new("Couldn't find any layers")
    end
  end
  
  def read_graphic_tilesets_from_rom(tileset_wrapper_A_ram_pointer)
    #tileset_wrapper_A_ram_pointer = rom[room_metadata_pointer + 12,4].unpack("V*").first # TODO: when this is like 0x02195984 it's a save/transition room. when it's like 0x020AF964 it's a normal room.
    #puts "tileset_wrapper_A_ram_pointer: %08X" % tileset_wrapper_A_ram_pointer
    if tileset_wrapper_A_ram_pointer > (0x02000000+ARM9_LENGTH) && tileset_wrapper_A_ram_pointer < converter.all_overlays[0][:ram].begin
      # When this pointer is like this (e.g. 0x02195984), it just points to 00s instead of actual data.
      # What this means is that the room doesn't load a tileset. Instead it just keeps whatever tileset the previous room had loaded.
      @graphic_tilesets_for_room = nil
    else
      #tileset_wrapper_A_pointer = ram_to_rom(tileset_wrapper_A_ram_pointer, overlay_offset)# - 0x02000000 + 0x4000 # 0209EFD8 -> A2FD8.
      tileset_wrapper_A_pointer = converter.ram_to_rom(tileset_wrapper_A_ram_pointer)
      #puts "tileset_wrapper_A_pointer: %08X" % tileset_wrapper_A_pointer
      i = 0
      @graphic_tilesets_for_room = []
      while true
        tileset_wrapper_B_ram_pointer = rom[tileset_wrapper_A_pointer + i*8, 4].unpack("V*").first # we're not going to actually follow tileset wrapper b pointer. we're just using it to identify the tileset.
        unknown_data = rom[tileset_wrapper_A_pointer + i*8 + 4, 4].unpack("V*").first
        #puts "x%08X" % tileset_wrapper_B_ram_pointer
        #puts "u%08X" % unknown_data
        break if tileset_wrapper_B_ram_pointer == 0
        #tileset_wrapper_B_pointer = ram_to_rom(tileset_wrapper_B_ram_pointer, overlay_offset)# - 0x02000000 + 0x4000
        #unknown_data2 = rom[tileset_wrapper_B_pointer, 4].unpack("V*").first # TODO
        #unknown_data3 = rom[tileset_wrapper_B_pointer+4, 4].unpack("V*").first
        #puts "u%08X" % unknown_data2
        #puts "u%08X" % unknown_data3
        if tileset_offsets_by_filename_by_tileset_wrapper_B_pointer[tileset_wrapper_B_ram_pointer].nil?
          puts "Couldn't find tileset. Possible transition room? wrapper B ram %08X. wrapper A ram: %08X" % [tileset_wrapper_B_ram_pointer, tileset_wrapper_A_ram_pointer]
          break
        end
        graphic_tile_data_start_offset = tileset_offsets_by_filename_by_tileset_wrapper_B_pointer[tileset_wrapper_B_ram_pointer][:start_offset]
        @graphic_tilesets_for_room << graphic_tile_data_start_offset
        i += 1
      end
    end
  end
  
  def read_palette_pages_from_rom(palette_wrapper_ram_pointer)
    #palette_wrapper_ram_pointer = rom[room_metadata_pointer + 16,4].unpack("V*").first # TODO: when this is like 0x02195984 it's a save/transition room. when it's like 0x020AF964 it's a normal room.
    #puts "palette_wrapper_ram_pointer: %08X" % palette_wrapper_ram_pointer
    # 022CEF68 -> 451788
    if palette_wrapper_ram_pointer > (0x02000000+ARM9_LENGTH) && palette_wrapper_ram_pointer < converter.all_overlays[0][:ram].begin
      # When this pointer is like this (e.g. 0x02195984), it just points to 00s instead of actual data.
      # What this means is that the room doesn't load a palette. Instead it just keeps whatever palette the previous room had loaded.
      @palette_pages = [nil]
      #puts "palette_wrapper_ram_pointer: %08X" % palette_wrapper_ram_pointer
    else
      #palette_wrapper_pointer = palette_wrapper_ram_pointer - 0x02000000 + 0x4000
      #palette_wrapper_pointer = ram_to_rom(palette_wrapper_ram_pointer, overlay_offset)
      palette_wrapper_pointer = converter.ram_to_rom(palette_wrapper_ram_pointer)
      #puts "palette_wrapper_pointer: %08X" % palette_wrapper_pointer
      
      i = 0
      @palette_pages = []
      while true
        palette_ram_pointer = rom[palette_wrapper_pointer + i*8,4].unpack("V*").first
        #puts "palette_ram_pointer: %08X" % palette_ram_pointer
        unknown_data = rom[palette_wrapper_pointer + i*8 + 4,4].unpack("V*").first # TODO
        
        break if palette_ram_pointer == 0
        
        palette_pointer = converter.ram_to_rom(palette_ram_pointer)
        #puts "palette_pointer: %08X" % palette_pointer
        @palette_pages << palette_pointer
        
        i += 1
      end
    end
  end
  
  def read_entity_list_from_rom(entity_list_ram_pointer)
    entity_list_pointer = converter.ram_to_rom(entity_list_ram_pointer)
    
    i = 0
    @entities = []
    while true
      entity_pointer = entity_list_pointer + i*12
      if rom[entity_pointer,12] == "\xFF\x7F\xFF\x7F\x00\x00\x00\x00\x00\x00\x00\x00".b
        break
      end
      
      @entities << Entity.new(self, entity_pointer, rom, converter)
      
      i += 1
    end
  end
  
  def read_door_list_from_rom(door_list_ram_pointer)
    if door_list_ram_pointer > (0x02000000+ARM9_LENGTH) && door_list_ram_pointer < converter.all_overlays[0][:ram].begin
      # A pointer to nothing here indicates the room has no doors (e.g. Menace's room).
      @doors = []
      return
    else
      door_list_pointer = converter.ram_to_rom(door_list_ram_pointer)
    end
    
    @doors = []
    (0..number_of_doors-1).each do |i|
      door_pointer = door_list_pointer + i*16
      
      @doors << Door.new(self, door_pointer, rom, converter)
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
    raise NotImplementedError
  end
  
  def initialize_tileset_offsets_by_filename_by_tileset_wrapper_B_pointer
    filenames_in_bc_folder = []
    offset = 0x00
    while true
      length = rom[FILENAMES_IN_BC_FOLDER_START_OFFSET + offset, 1].unpack("C*").first
      if length == 0
        break
      end
      filename = rom[FILENAMES_IN_BC_FOLDER_START_OFFSET + offset + 1, length]
      filenames_in_bc_folder << filename
      offset += 1 + length
    end
    
    tileset_offsets_by_filename = {}
    filenames_in_bc_folder.each_with_index do |filename, i|
      file_start_offset, file_end_offset = rom[FILES_IN_BC_FOLDER_ROM_OFFSETS_LIST_START + 8*i, 8].unpack("V*")
      tileset_offsets_by_filename[filename] = {start_offset: file_start_offset, end_offset: file_end_offset}
    end
    
    @tileset_offsets_by_filename_by_tileset_wrapper_B_pointer = {}
    rom[BC_FOLDER_START_OFFSET..BC_FOLDER_END_OFFSET].scan(/.{#{BC_FOLDER_FILE_LENGTH}}/m).each do |file_data|
      tileset_wrapper_B_pointer = file_data[0,4].unpack("V*").first
      filename = file_data[6..-1]
      filename = filename.delete("\x00") # remove null bytes padding the end of the string
      filename =~ /^\/bc\/(.+\.dat)$/
      filename = $1
      if tileset_offsets_by_filename[filename]
        @tileset_offsets_by_filename_by_tileset_wrapper_B_pointer[tileset_wrapper_B_pointer] = tileset_offsets_by_filename[filename]
      end
    end
  end
  
  def z_ordered_layers
    layers.sort_by{|layer| -layer.z_index}
  end
  
  def filename
    "room_a#{major_area_index}-#{area_index}-#{room_index}_%08X_x#{room_xpos_on_map}_y#{room_ypos_on_map}_w#{z_ordered_layers.last.width}_h#{z_ordered_layers.last.height}" % room_metadata_ram_pointer
  end
  
  def area_name
    #return ""
    #return major_area_index.to_s
    if AREA_INDEX_TO_AREA_NAME[major_area_index].class == Hash
      if AREA_INDEX_TO_AREA_NAME[major_area_index][area_index]
        AREA_INDEX_TO_AREA_NAME[major_area_index][area_index]
      else
        major_area_index
      end
    elsif AREA_INDEX_TO_AREA_NAME[major_area_index].class == String
      AREA_INDEX_TO_AREA_NAME[major_area_index]
    elsif AREA_INDEX_TO_AREA_NAME[major_area_index].nil?
      major_area_index.to_s
    else
      raise "Misformatted area name: #{AREA_INDEX_TO_AREA_NAME[major_area_index].inspect}"
    end
  end
end