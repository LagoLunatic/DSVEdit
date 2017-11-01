
class Room
  class RoomReadError < StandardError ; end
  class WriteError < StandardError ; end
  
  attr_reader :room_metadata_ram_pointer,
              :area,
              :sector,
              :layers,
              :number_of_doors,
              :layer_list_ram_pointer,
              :gfx_list_pointer,
              :palette_wrapper_pointer,
              :entity_list_ram_pointer,
              :door_list_ram_pointer,
              :gfx_pages,
              :palette_pages,
              :area_index,
              :sector_index,
              :room_index,
              :fs,
              :game
  attr_accessor :layer_list_ram_pointer,
                :gfx_list_pointer,
                :palette_wrapper_pointer,
                :entity_list_ram_pointer,
                :door_list_ram_pointer,
                :room_xpos_on_map,
                :room_ypos_on_map,
                :palette_page_index,
                :color_effects,
                :entities,
                :doors

  def initialize(sector, room_metadata_ram_pointer, area_index, sector_index, room_index, game)
    @room_metadata_ram_pointer = room_metadata_ram_pointer
    @area = sector.area
    @sector = sector
    @area_index = area_index
    @sector_index = sector_index
    @room_index = room_index
    @fs = game.fs
    @game = game
    read_from_rom()
  end
  
  def read_from_rom
    if GAME == "hod"
      room_metadata = fs.read(room_metadata_ram_pointer, 36).unpack("V*")
      @layer_list_ram_pointer = room_metadata[2]
      @gfx_list_pointer = room_metadata[3]
      @palette_wrapper_pointer = room_metadata[5]
      @entity_list_ram_pointer = room_metadata[6]
      @door_list_ram_pointer = room_metadata[7]
      extra_data = room_metadata[8]
      read_extra_data_from_rom(extra_data)
    else
      if SYSTEM == :nds
        room_metadata = fs.read(room_metadata_ram_pointer, 32).unpack("V*")
        extra_data = room_metadata[7]
        read_extra_data_from_rom(extra_data)
      else
        room_metadata = fs.read(room_metadata_ram_pointer, 36).unpack("V*")
        extra_data = room_metadata[7]
        extra_data_2 = room_metadata[8]
        read_extra_data_from_rom(extra_data, extra_data_2)
      end
      @layer_list_ram_pointer = room_metadata[2]
      @gfx_list_pointer = room_metadata[3]
      @palette_wrapper_pointer = room_metadata[4]
      @entity_list_ram_pointer = room_metadata[5]
      @door_list_ram_pointer = room_metadata[6]
    end
    
    read_layer_list_from_rom(layer_list_ram_pointer)
    read_graphic_tilesets_from_rom(gfx_list_pointer)
    read_palette_pages_from_rom(@palette_wrapper_pointer)
    read_entity_list_from_rom(entity_list_ram_pointer)
    read_door_list_from_rom(door_list_ram_pointer)
  end
  
  def read_layer_list_from_rom(layer_list_ram_pointer)
    @layers = []
    i = 0
    while true
      if SYSTEM == :nds
        break if i == 4 # Maximum of 4 layers per room.
        
        is_a_pointer_check = fs.read(layer_list_ram_pointer + i*16 + 15).unpack("C*").first
        if is_a_pointer_check != 0x02
          break
        end
        
        layer = Layer.new(self, layer_list_ram_pointer + i*16, fs)
        layer.read_from_rom()
        @layers << layer
      elsif GAME == "aos"
        break if i == 3 # Maximum of 3 layers per room.
        
        layer_data = fs.read(layer_list_ram_pointer + i*12).unpack("VVV")
        if layer_data.all?{|x| x == 0}
          break
        end
        
        layer = Layer.new(self, layer_list_ram_pointer + i*12, fs)
        layer.read_from_rom()
        if layer.layer_metadata_ram_pointer != 0 # TODO
          @layers << layer
          if color_effects & 0xC0 == 0x40 && color_effects & 1<<(i+1) > 0
            layer.opacity = 0x0F # HACK
          end
        end
      elsif GAME == "hod"
        break if i == 3 # Maximum of 3 layers per room.
        
        layer_data = fs.read(layer_list_ram_pointer + i*8).unpack("VV")
        if layer_data[1] == 0
          break
        end
        
        layer = Layer.new(self, layer_list_ram_pointer + i*8, fs)
        layer.read_from_rom()
        if layer.layer_metadata_ram_pointer != 0 # TODO
          @layers << layer
          if color_effects & 0xC0 == 0x40 && color_effects & 1<<(i+1) > 0
            layer.opacity = 0x0F # HACK
          end
        end
      end
      
      i += 1
    end

    if @layers.length == 0 # TODO
      #raise RoomReadError.new("Couldn't find any layers")
    end
  rescue NDSFileSystem::ConversionError => e
    # When layer_list_ram_pointer points to something outside the overlay, that means the room has no layers.
    @layers = []
  end
  
  def read_graphic_tilesets_from_rom(gfx_list_pointer)
    @gfx_pages = RoomGfxPage.from_room_gfx_page_list(gfx_list_pointer, fs)
  rescue NDSFileSystem::ConversionError => e
    # When gfx_list_pointer is like this (e.g. 0x02195984), it just points to 00s instead of actual data.
    # What this means is that the room doesn't load any gfx pages. Instead it just keeps whatever gfx pages the previous room had loaded.
    @gfx_pages = []
  end
  
  def read_palette_pages_from_rom(palette_wrapper_pointer)
    i = 0
    @palette_pages = PaletteWrapper.from_palette_wrapper_pointer(palette_wrapper_pointer, fs)
    
    if SYSTEM == :nds
      @palette_pages = @palette_pages[palette_page_index..palette_page_index]
    end
  rescue NDSFileSystem::ConversionError => e
    # When palette_wrapper_pointer is like this (e.g. 0x02195984), it just points to 00s instead of actual data.
    # What this means is that the room doesn't load a palette. Instead it just keeps whatever palette the previous room had loaded.
    @palette_pages = []
  end
  
  def read_entity_list_from_rom(entity_list_ram_pointer)
    i = 0
    @entities = []
    while true
      if entity_list_ram_pointer == 0 && GAME == "hod"
        break
      end
      
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
    
    if GAME == "hod"
      i = 0
      while true
        door_pointer = door_list_ram_pointer + i*Door.data_size
        
        dest_room_pointer = fs.read(door_pointer, 4).unpack("V").first
        break unless fs.is_pointer?(dest_room_pointer)
        
        @doors << Door.new(self, game).read_from_rom(door_pointer)
        
        i += 1
      end
      
      @number_of_doors = doors.length
    else
      (0..number_of_doors-1).each do |i|
        door_pointer = door_list_ram_pointer + i*Door.data_size
        
        @doors << Door.new(self, game).read_from_rom(door_pointer)
      end
    end
    
    @original_number_of_doors = doors.length
  rescue NDSFileSystem::ConversionError => e
    # When door_list_ram_pointer points to nothing it indicates the room has no doors (e.g. Menace's room).
    @doors = []
    @original_number_of_doors = 0
  end
  
  def read_extra_data_from_rom(extra_data, extra_data_2=nil)
    if GAME == "dos"
      @number_of_doors    = (extra_data & 0b00000000_00000000_11111111_11111111)
      @room_xpos_on_map   = (extra_data & 0b00000000_00111111_00000000_00000000) >> 16
      @room_ypos_on_map   = (extra_data & 0b00011111_10000000_00000000_00000000) >> 23
      @palette_page_index = 0 # Always 0 in DoS, and so not stored in this data
    elsif GAME == "aos"
      @number_of_doors    = (extra_data   & 0b00000000_00000000_11111111_11111111)
      @color_effects      = (extra_data   & 0b11111111_11111111_00000000_00000000) >> 16
      @room_xpos_on_map   = (extra_data_2 & 0b00000000_01111111_00000000_00000000) >> 16
      @room_ypos_on_map   = (extra_data_2 & 0b00111111_10000000_00000000_00000000) >> 23
      @palette_page_index = 0 # Always 0 in AoS
    elsif GAME == "hod"
      # TODO
      unk_1               = (extra_data & 0b00000000_00000000_00000000_11111111)
      unk_2               = (extra_data & 0b00000000_00000000_11111111_00000000) >> 8
      @room_xpos_on_map   = (extra_data & 0b00000000_01111111_00000000_00000000) >> 16
      @room_ypos_on_map   = (extra_data & 0b00111111_10000000_00000000_00000000) >> 23
      unk_5               = (extra_data & 0b01000000_00000000_00000000_00000000) >> 30
      unk_6               = (extra_data & 0b10000000_00000000_00000000_00000000) >> 31
      #p "%X %X %X %X" % [unk_1, unk_2, unk_5, unk_6]
      @color_effects      = 0
      @palette_page_index = 0 # Always 0 in HoD
    else # PoR or OoE
      @number_of_doors    = (extra_data & 0b00000000_00000000_00000000_01111111)
      @room_xpos_on_map   = (extra_data & 0b00000000_00000000_00111111_10000000) >> 7
      @room_ypos_on_map   = (extra_data & 0b00000000_00011111_11000000_00000000) >> 14
      @palette_page_index = (extra_data & 0b00001111_10000000_00000000_00000000) >> 23
    end
  end
  
  def write_to_rom
    sector.load_necessary_overlay()
    
    room_data = [layer_list_ram_pointer, gfx_list_pointer, palette_wrapper_pointer, entity_list_ram_pointer, door_list_ram_pointer].pack("V*")
    fs.write(room_metadata_ram_pointer + 8, room_data)
    
    write_extra_data_to_rom()
    
    read_from_rom()
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
      
      original_length = (@original_number_of_entities+1)*12
      length_needed = (entities.length+1)*12
      
      new_entity_list_pointer = fs.free_old_space_and_find_new_free_space(entity_list_ram_pointer, original_length, length_needed, overlay_id)
      
      @original_number_of_entities = entities.length
      
      @entity_list_ram_pointer = new_entity_list_pointer
      fs.write(room_metadata_ram_pointer+5*4, [entity_list_ram_pointer].pack("V"))
    elsif entities.length < @original_number_of_entities
      original_length = (@original_number_of_entities+1)*12
      length_needed = (entities.length+1)*12
      
      fs.free_unused_space(entity_list_ram_pointer + length_needed, original_length - length_needed)
      
      @original_number_of_entities = entities.length
    end
    
    new_entity_pointer = entity_list_ram_pointer
    entities.each do |entity|
      entity.entity_ram_pointer = new_entity_pointer
      
      new_entity_pointer += 12
    end
    entities.each do |entity|
      entity.write_to_rom()
    end
    fs.write(new_entity_pointer, [0x7FFF7FFF, 0, 0].pack("V*")) # Marks the end of the entity list
  end
  
  def update_entity_byte_5s
    if SYSTEM == :gba
      # AoS only loads entities when you get close to them in the room.
      # It checks this by looking at the x or y pos of the entity.
      # However, it assumes that all entities in the room are ordered by the x or y pos.
      # So we need to reorder them for the entities to load correctly.
      
      # Room is considered vertical if height is greater than width, otherwise horizontal.
      if main_layer_width < main_layer_height
        entities.sort_by! do |entity|
          entity.y_pos
        end
      else
        entities.sort_by! do |entity|
          entity.x_pos
        end
      end
      
      entities.each_with_index do |entity, i|
        # Byte 5 acts as a unique ID for this entity in the room.
        # If two entities in the same room share a byte 5, one of them won't appear.
        entity.byte_5 = i
        
        if GAME == "hod"
          byte_5_and_type  = (entity.type   &  0x3) << 6
          byte_5_and_type |= (entity.byte_5 & 0x3F)
          fs.write(entity.entity_ram_pointer+4, [byte_5_and_type].pack("C"))
        else
          fs.write(entity.entity_ram_pointer+4, [entity.byte_5].pack("C"))
        end
      end
    end
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
      
      old_length = @original_number_of_doors*16
      new_length = doors.length*16
      
      new_door_list_pointer = fs.free_old_space_and_find_new_free_space(door_list_ram_pointer, old_length, new_length, overlay_id)
      
      @original_number_of_doors = doors.length
      
      @door_list_ram_pointer = new_door_list_pointer
      fs.write(room_metadata_ram_pointer+6*4, [door_list_ram_pointer].pack("V"))
    elsif doors.length < @original_number_of_doors
      old_length = @original_number_of_doors*16
      new_length = doors.length*16
      
      fs.free_unused_space(door_list_ram_pointer + new_length, old_length - new_length)
      
      @original_number_of_doors = doors.length
    end
    
    new_door_pointer = door_list_ram_pointer
    doors.each do |door|
      door.door_ram_pointer = new_door_pointer
      door.write_to_rom()
      
      new_door_pointer += 16
    end
    
    @number_of_doors = doors.length
    write_extra_data_to_rom()
  end
  
  def write_extra_data_to_rom
    extra_data = 0
    if GAME == "dos"
      extra_data |= (@number_of_doors         ) & 0b00000000_00000000_11111111_11111111
      extra_data |= (@room_xpos_on_map   << 16) & 0b00000000_00111111_00000000_00000000
      extra_data |= (@room_ypos_on_map   << 23) & 0b00011111_10000000_00000000_00000000
    elsif GAME == "aos"
      extra_data_2 = 0
      extra_data   |= (@number_of_doors         ) & 0b00000000_00000000_11111111_11111111
      extra_data   |= (@color_effects      << 16) & 0b11111111_11111111_00000000_00000000
      extra_data_2 |= (@room_xpos_on_map   << 16) & 0b00000000_00111111_00000000_00000000
      extra_data_2 |= (@room_ypos_on_map   << 23) & 0b00011111_10000000_00000000_00000000
      
      fs.write(room_metadata_ram_pointer+8*4, [extra_data_2].pack("V"))
    else
      extra_data |= (@number_of_doors         ) & 0b00000000_00000000_00000000_01111111
      extra_data |= (@room_xpos_on_map   <<  7) & 0b00000000_00000000_00111111_10000000
      extra_data |= (@room_ypos_on_map   << 14) & 0b00000000_00011111_11000000_00000000
      extra_data |= (@palette_page_index << 23) & 0b00001111_10000000_00000000_00000000
    end
    fs.write(room_metadata_ram_pointer+7*4, [extra_data].pack("V"))
  end
  
  def add_new_layer
    sector.load_necessary_overlay()
    
    if layers.length >= Room.max_number_of_layers
      raise "Can't add new layer; room already has #{Room.max_number_of_layers} layers."
    end
    
    if SYSTEM == :nds
      overlay = fs.overlays[overlay_id]
      overlay_ram_end = overlay[:ram_start_offset]+overlay[:size]
      
      if layers.length == 0 && layer_list_ram_pointer >= overlay_ram_end
        # Invalid room where layer list pointer points outside the overlay file. So we create a blank layer list in free space first.
        @layer_list_ram_pointer = fs.get_free_space(Layer.layer_list_entry_size*4, overlay_id)
        fs.write(room_metadata_ram_pointer+2*4, [@layer_list_ram_pointer].pack("V"))
        self.write_to_rom()
      end
    else
      # On GBA the layer list doesn't just have free space for us to add layers up to 4, so we first need to move the layer list into fre space.
      new_num_layers = layers.length + 1
      @layer_list_ram_pointer = fs.get_free_space(Layer.layer_list_entry_size*new_num_layers)
      fs.write(room_metadata_ram_pointer+2*4, [@layer_list_ram_pointer].pack("V"))
      
      layers.each_with_index do |layer, i|
        layer.layer_list_entry_ram_pointer = layer_list_ram_pointer + i*Layer.layer_list_entry_size
        layer.write_to_rom()
      end
      
      self.write_to_rom()
    end
    
    new_layer_i = layers.length
    new_layer = Layer.new(self, layer_list_ram_pointer + new_layer_i*Layer.layer_list_entry_size, fs)
    
    new_layer.z_index = 0x16
    new_layer.scroll_mode = 0x01
    new_layer.main_gfx_page_index = 0x00
    new_layer.opacity = 0x1F
    new_layer.tileset_compression_type = 0
    if SYSTEM == :gba
      new_layer.bg_control = 0x1D48
      new_layer.tileset_compression_type = 2
    end
    
    new_layer.layer_metadata_ram_pointer = fs.get_free_space(16, overlay_id)
    
    main_layer = layers.first
    if main_layer
      new_layer.width = main_layer.width
      new_layer.height = main_layer.height
      new_layer.tileset_pointer = main_layer.tileset_pointer
      new_layer.collision_tileset_pointer = main_layer.collision_tileset_pointer
    else
      # Room that has no layers.
      new_layer.width = 1
      new_layer.height = 1
      new_layer.tileset_pointer = 0
      new_layer.collision_tileset_pointer = 0
    end
    new_layer.layer_tiledata_ram_start_offset = nil # Layer#write_to_rom will get free space and put this there.
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
    sector.name
  end
  
  def self.max_number_of_layers
    if SYSTEM == :nds
      4
    else
      3
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
  
  alias width main_layer_width
  alias height main_layer_height
  
  def connected_rooms
    doors.map{|door| door.destination_door.room}.uniq
  end
  
  def room_str
    @room_str ||= "%02X-%02X-%02X" % [area_index, sector_index, room_index]
  end
  
  def inspect; to_s; end
end

class RoomGfxPage
  attr_reader :gfx_pointer,
              :gfx_wrapper,
              :gfx_load_offset,
              :first_chunk_index,
              :num_chunks,
              :unknown
              
  def initialize(pointer, fs, gfx_load_offset=nil)
    if GAME == "hod"
      @gfx_pointer = fs.read(pointer, 4).unpack("V").first
      @gfx_load_offset = gfx_load_offset
      @first_chunk_index = 0
      @num_chunks = 4
      @unknown = 0
    else
      @gfx_pointer, @gfx_load_offset, @first_chunk_index, @num_chunks, @unknown = fs.read(pointer, 8).unpack("VCCCC")
    end
    @gfx_wrapper = GfxWrapper.new(gfx_pointer, fs)
  end
  
  def colors_per_palette
    gfx_wrapper.colors_per_palette
  end
  
  def self.from_room_gfx_page_list(gfx_list_pointer, fs)
    gfx_pages = []
    i = 0
    offset = gfx_list_pointer
    hod_gfx_load_offset = 0x10
    while true
      gfx_pointer = fs.read(offset, 4).unpack("V").first
      
      break if gfx_pointer == 0
      
      gfx_page = RoomGfxPage.new(offset, fs, hod_gfx_load_offset)
      gfx_pages << gfx_page
      
      i += 1
      if GAME == "hod"
        offset += 4
        hod_gfx_load_offset += 4
        if i >= 4
          break
        end
      else
        offset += 8
      end
    end
    
    return gfx_pages
  end
end
