
class Map
  attr_accessor :draw_x_offset,
                :draw_y_offset
  attr_reader :map_tile_metadata_ram_pointer,
              :map_tile_line_data_ram_pointer,
              :number_of_tiles,
              :width,
              :height,
              :secret_door_list_pointer,
              :row_widths_list_pointer,
              :game,
              :fs,
              :area_index,
              :sector_index,
              :tiles,
              :secret_doors,
              :row_widths
  
  def initialize(area_index, sector_index, game)
    @area_index = area_index
    @sector_index = sector_index
    @game = game
    @fs = game.fs
    
    read_from_rom()
  end
  
  def read_from_rom
    fs.load_overlay(MAPS_OVERLAY) if MAPS_OVERLAY
    
    @map_tile_metadata_ram_pointer = fs.read(MAP_TILE_METADATA_LIST_START_OFFSET + area_index*4, 4).unpack("V*").first
    @map_tile_line_data_ram_pointer = fs.read(MAP_TILE_LINE_DATA_LIST_START_OFFSET + area_index*4, 4).unpack("V*").first
    @number_of_tiles = fs.read(MAP_LENGTH_DATA_START_OFFSET + area_index*2, 2).unpack("v*").first
    @width, @height = fs.read(MAP_SIZES_LIST_START_OFFSET + area_index*2, 2).unpack("CC")
    @draw_x_offset, @draw_y_offset = fs.read(MAP_DRAW_OFFSETS_LIST_START_OFFSET + area_index*2, 2).unpack("CC")
    @secret_door_list_pointer = fs.read(MAP_SECRET_DOOR_LIST_START_OFFSET + area_index*4, 4).unpack("V*").first
    @row_widths_list_pointer = fs.read(MAP_ROW_WIDTHS_LIST_START_OFFSET + area_index*4, 4).unpack("V*").first
    
    # These attributes are in pairs of two tiles, so double them so they're in tiles.
    @draw_x_offset *= 2
    @draw_y_offset *= 2
    
    @tiles = []
    (0..number_of_tiles-1).each do |i|
      tile_line_data = fs.read(map_tile_line_data_ram_pointer + i).unpack("C").first
      tile_metadata = fs.read(map_tile_metadata_ram_pointer + i*4, 4).unpack("vCC")
      
      @tiles << MapTile.new(tile_metadata, tile_line_data)
    end
    
    tiles_with_secret_doors = tiles.select{|tile| tile.has_secret_door}
    
    @secret_doors = []
    if secret_door_list_pointer != 0
      tiles_with_secret_doors.each_with_index do |tile, i|
        tile_index = tiles.index(tile)
        
        secret_door_pointer = secret_door_list_pointer + i*4
        secret_door = SecretDoor.new(secret_door_pointer, fs)
        
        if secret_door.map_tile_index >= tile_index
          @secret_doors << secret_door
        else
          # Reached the end of the secret door list for this area.
          break
        end
      end
    end
    
    @row_widths = []
    total_tiles_found = 0
    @height.times do |row|
      row_width = fs.read(@row_widths_list_pointer + row, 1).unpack("C").first
      
      @row_widths << row_width
      total_tiles_found += row_width
    end
    if total_tiles_found != number_of_tiles
      raise "Error reading map row widths: Total number of tiles does not match (#{total_tiles_found} tiles found, should be #{number_of_tiles})"
    end
    @original_number_of_rows = row_widths.length
  end
  
  def write_to_rom(allow_changing_num_tiles: false)
    @tiles = @tiles.sort_by{|tile| [tile.y_pos, tile.x_pos]}
    
    max_x_pos = @tiles.map{|tile| tile.x_pos}.max
    max_y_pos = @tiles.map{|tile| tile.y_pos}.max
    @width = max_x_pos + 1
    @height = max_y_pos + 1
    
    tiles_by_row = @tiles.group_by{|tile| tile.y_pos}
    @row_widths = []
    @height.times do |row|
      if tiles_by_row[row]
        @row_widths[row] = tiles_by_row[row].length
      else
        @row_widths[row] = 0
      end
    end
    
    if row_widths.length > @original_number_of_rows
      original_length = @original_number_of_rows
      length_needed = row_widths.length
      
      new_row_widths_list_pointer = fs.free_old_space_and_find_new_free_space(row_widths_list_pointer, original_length, length_needed, nil)
      
      @original_number_of_rows = row_widths.length
      
      @row_widths_list_pointer = new_row_widths_list_pointer
      fs.write(MAP_ROW_WIDTHS_LIST_START_OFFSET + area_index*4, [row_widths_list_pointer].pack("V"))
    else
      original_length = @original_number_of_rows
      length_needed = row_widths.length
      
      fs.free_unused_space(row_widths_list_pointer + length_needed, original_length - length_needed)
      
      @original_number_of_rows = row_widths.length
    end
    
    (0..max_y_pos).each do |row|
      fs.write(row_widths_list_pointer + row, [row_widths[row]].pack("C"))
    end
    
    sum_of_row_widths = row_widths.inject(0, :+)
    if sum_of_row_widths != @tiles.length
      raise "Error writing map row widths: Total number of tiles does not match (#{sum_of_row_widths} tiles found, should be #{@tiles.length})"
    end
    
    if allow_changing_num_tiles
      @number_of_tiles = @tiles.length
      fs.write(MAP_LENGTH_DATA_START_OFFSET + area_index*2, [number_of_tiles].pack("v"))
    elsif @number_of_tiles != @tiles.length
      raise "Number of tiles on the map was changed."
    end
    
    (0..number_of_tiles-1).each do |i|
      tile_line_data, tile_metadata = @tiles[i].to_data
      
      fs.write(map_tile_line_data_ram_pointer + i, [tile_line_data].pack("C"))
      fs.write(map_tile_metadata_ram_pointer + i*4, tile_metadata.pack("vCC"))
    end
    
    fs.write(MAP_SIZES_LIST_START_OFFSET + area_index*2, [@width, @height].pack("CC"))
    
    # TODO add gui to allow manually setting draw x/y offset
    fs.write(MAP_DRAW_OFFSETS_LIST_START_OFFSET + area_index*2, [@draw_x_offset/2, @draw_y_offset/2].pack("CC"))
  end
  
  def is_abyss
    false
  end
end

class MapTile
  attr_reader :tile_metadata,
              :tile_line_data
              
  attr_accessor :bottom_door,
                :bottom_wall,
                :bottom_secret,
                :right_door,
                :right_wall,
                :right_secret,
                :top_door,
                :top_wall,
                :top_secret,
                :left_door,
                :left_wall,
                :left_secret,
                :is_save,
                :is_warp,
                :is_secret,
                :is_transition,
                :is_entrance,
                :sector_index,
                :room_index,
                :y_pos,
                :x_pos,
                :is_blank,
                :is_castle_b_warp,
                :has_secret_door
  
  def initialize(tile_metadata, tile_line_data)
    @tile_metadata = tile_metadata
    @tile_line_data = tile_line_data
    read_from_rom()
  end
  
  def read_from_rom
    @bottom_wall    = (tile_line_data & 0b11000000) >> 6 == 1
    @bottom_door    = (tile_line_data & 0b11000000) >> 6 == 2
    @bottom_secret  = (tile_line_data & 0b11000000) >> 6 == 3
    @right_wall     = (tile_line_data & 0b00110000) >> 4 == 1
    @right_door     = (tile_line_data & 0b00110000) >> 4 == 2
    @right_secret   = (tile_line_data & 0b00110000) >> 4 == 3
    @top_wall       = (tile_line_data & 0b00001100) >> 2 == 1
    @top_door       = (tile_line_data & 0b00001100) >> 2 == 2
    @top_secret     = (tile_line_data & 0b00001100) >> 2 == 3
    @left_wall      =  tile_line_data & 0b00000011       == 1
    @left_door      =  tile_line_data & 0b00000011       == 2
    @left_secret    =  tile_line_data & 0b00000011       == 3
    
    @is_save        =  tile_metadata[0] & 0b10000000_00000000 > 0
    @is_warp        =  tile_metadata[0] & 0b01000000_00000000 > 0
    @is_secret      =  tile_metadata[0] & 0b00100000_00000000 > 0
    @is_transition  =  tile_metadata[0] & 0b00010000_00000000 > 0
    @is_entrance    =  tile_metadata[0] & 0b00001000_00000000 > 0
    @sector_index   = (tile_metadata[0] & 0b00000011_11000000) >> 6
    @room_index     =  tile_metadata[0] & 0b00000000_00111111
    @y_pos          =  tile_metadata[1]
    @x_pos          =  tile_metadata[2]
    
    @has_secret_door = (bottom_door && bottom_wall) ||
                       (right_door && right_wall) ||
                       (top_door && top_wall) ||
                       (left_door && left_wall)
  end
  
  def to_data
    @tile_line_data = 0
    
    if left_secret
      @tile_line_data |= 3
    elsif left_door
      @tile_line_data |= 2
    elsif left_wall
      @tile_line_data |= 1
    end
    
    if top_secret
      @tile_line_data |= 3 << 2
    elsif top_door
      @tile_line_data |= 2 << 2
    elsif top_wall
      @tile_line_data |= 1 << 2
    end
    
    if right_secret
      @tile_line_data |= 3 << 4
    elsif right_door
      @tile_line_data |= 2 << 4
    elsif right_wall
      @tile_line_data |= 1 << 4
    end
    
    if bottom_secret
      @tile_line_data |= 3 << 6
    elsif bottom_door
      @tile_line_data |= 2 << 6
    elsif bottom_wall
      @tile_line_data |= 1 << 6
    end
    
    @tile_metadata = []
    @tile_metadata[0] = 0
    if is_save
      @tile_metadata[0] |= 1 << 15
    end
    if is_warp
      @tile_metadata[0] |= 1 << 14
    end
    if is_secret
      @tile_metadata[0] |= 1 << 13
    end
    if is_transition
      @tile_metadata[0] |= 1 << 12
    end
    if is_entrance
      @tile_metadata[0] |= 1 << 11
    end
    @tile_metadata[0] |= (sector_index & 0b1111) << 6
    @tile_metadata[0] |= (room_index & 0b111111)
    
    @tile_metadata[1] = @y_pos
    @tile_metadata[2] = @x_pos
    
    return [tile_line_data, tile_metadata]
  end
end

class SecretDoor
  attr_reader :secret_door_pointer,
              :fs
  attr_accessor :map_tile_index,
                :secret_door_index
  
  def initialize(secret_door_pointer, fs)
    @fs = fs
    @map_tile_index, @secret_door_index = fs.read(secret_door_pointer, 4).unpack("vv")
  end
  
  def write_to_rom
    fs.write(secret_door_pointer, [@map_tile_index, @secret_door_index].pack("vv"))
  end
end

class DoSMap < Map
  attr_reader :is_abyss,
              :warp_rooms
  
  def initialize(area_index, sector_index, game)
    @area_index = area_index
    @sector_index = sector_index
    @game = game
    @fs = game.fs
    
    if GAME == "dos" && [10, 11].include?(sector_index)
      @is_abyss = true
    else
      @is_abyss = false
    end
    
    read_from_rom()
  end
  
  def read_from_rom
    if is_abyss
      @width = 18
      
      @map_tile_metadata_ram_pointer = ABYSS_MAP_TILE_METADATA_START_OFFSET
      @map_tile_line_data_ram_pointer = ABYSS_MAP_TILE_LINE_DATA_START_OFFSET
      @number_of_tiles = ABYSS_MAP_NUMBER_OF_TILES
      @secret_door_list_pointer = ABYSS_MAP_SECRET_DOOR_DATA_START_OFFSET
      @draw_x_offset_pointer = ABYSS_MAP_DRAW_X_OFFSET_LOCATION
      @draw_y_offset_pointer = ABYSS_MAP_DRAW_Y_OFFSET_LOCATION
    else
      @width = 64
      
      @map_tile_metadata_ram_pointer = MAP_TILE_METADATA_START_OFFSET
      @map_tile_line_data_ram_pointer = MAP_TILE_LINE_DATA_START_OFFSET
      @number_of_tiles = MAP_NUMBER_OF_TILES
      @secret_door_list_pointer = MAP_SECRET_DOOR_DATA_START_OFFSET
      @draw_x_offset_pointer = MAP_DRAW_X_OFFSET_LOCATION
      @draw_y_offset_pointer = MAP_DRAW_Y_OFFSET_LOCATION
    end
    
    @tiles = []
    i = 0
    while i < number_of_tiles
      2.times do
        tile_line_data = fs.read(map_tile_line_data_ram_pointer + i/2).unpack("C").first
        if i.even?
          tile_line_data = tile_line_data >> 4
        else
          tile_line_data = tile_line_data & 0b00001111
        end
        
        index_for_metadata = i
        if is_abyss
          # For some reason, the Abyss's tile metadata (but not line data) has an extra block at the end of each row.
          # Here we skip that extra block so that the tile metadata and line data stay in sync.
          index_for_metadata += i / @width
        end
        tile_metadata = fs.read(map_tile_metadata_ram_pointer + index_for_metadata*2, 2).unpack("v").first
        
        @tiles << DoSMapTile.new(tile_metadata, tile_line_data, i, @width)
        
        i += 1
      end
    end
    
    if @secret_door_list_pointer
      @secret_doors = []
      i = 0
      while true
        secret_door_pointer = secret_door_list_pointer + i*2
        x_pos, y_pos = fs.read(secret_door_pointer, 2).unpack("C*")
        
        if x_pos == 0xFF && y_pos == 0xFF
          break
        end
        
        @secret_doors << DoSSecretDoor.new(secret_door_pointer, fs)
        
        i += 1
      end
    end
    
    if @draw_x_offset_pointer
      @draw_x_offset = game.fs.read(@draw_x_offset_pointer, 1).unpack("C").first
      @draw_y_offset = game.fs.read(@draw_y_offset_pointer, 1).unpack("C").first
    else
      @draw_x_offset = 0
      @draw_y_offset = 0
    end
    
    if GAME == "dos"
      @warp_rooms = []
      WARP_ROOM_COUNT.times do |i|
        @warp_rooms << DoSWarpRoom.new(i, fs)
      end
    elsif GAME == "aos"
      @warp_rooms = []
      WARP_ROOM_COUNT.times do |i|
        @warp_rooms << AoSWarpRoom.new(i, fs)
      end
    elsif GAME == "hod"
      @warp_rooms = []
      WARP_ROOM_COUNT.times do |i|
        @warp_rooms << HoDWarpRoom.new(i, fs)
      end
    end
  end
  
  def write_to_rom
    i = 0
    while i < number_of_tiles
      prev_tile_line_data = nil
      2.times do
        tile_line_data, tile_metadata = @tiles[i].to_data
        
        if i.even?
          prev_tile_line_data = tile_line_data
        else
          tile_line_data |= (prev_tile_line_data << 4)
          prev_tile_line_data = nil
          
          fs.write(map_tile_line_data_ram_pointer + i/2, [tile_line_data].pack("C"))
        end
        
        index_for_metadata = i
        if is_abyss
          # For some reason, the Abyss's tile metadata (but not line data) has an extra block at the end of each row.
          # Here we skip that extra block so that the tile metadata and line data stay in sync.
          index_for_metadata += i / @width
        end
        
        fs.write(map_tile_metadata_ram_pointer + index_for_metadata*2, [tile_metadata].pack("v"))
        
        i += 1
      end
    end
    
    # Round these down to the nearest multiple of 2, since odd numbered draw offsets cause the entire map to render glitched.
    @draw_x_offset = @draw_x_offset/2*2
    @draw_y_offset = @draw_y_offset/2*2
    game.fs.write(@draw_x_offset_pointer, [@draw_x_offset].pack("C"))
    game.fs.write(@draw_y_offset_pointer, [@draw_y_offset].pack("C"))
    
    if is_abyss
      # Do nothing.
    elsif GAME == "dos"
      warp_rooms_x_sorted = warp_rooms.sort_by{|tile| [tile.x_pos_in_tiles, tile.y_pos_in_tiles] }
      warp_rooms_y_sorted = warp_rooms.sort_by{|tile| [tile.y_pos_in_tiles, tile.x_pos_in_tiles] }
      warp_rooms.each do |warp_room|
        warp_room.x_pos_in_pixels = warp_room.x_pos_in_tiles*4
        warp_room.y_pos_in_pixels = warp_room.y_pos_in_tiles*4
        warp_room.x_index         = warp_rooms_x_sorted.index(warp_room)
        warp_room.y_index         = warp_rooms_y_sorted.index(warp_room)
        
        warp_tile = @tiles.find{|tile| tile.x_pos == warp_room.x_pos_in_tiles && tile.y_pos == warp_room.y_pos_in_tiles}
        if warp_tile && !warp_tile.is_blank
          warp_room.sector_index = warp_tile.sector_index
          warp_room.room_index = warp_tile.room_index
        elsif warp_room.x_pos_in_tiles == 54 && warp_room.y_pos_in_tiles == 42
          warp_room.sector_index = 0xB
          warp_room.room_index = 0x23
        else
          warp_room.sector_index = 0
          warp_room.room_index = 0
        end
        
        warp_room.write_to_rom()
      end
    elsif GAME == "aos"
      warp_rooms.each do |warp_room|
        warp_tile = @tiles.find{|tile| tile.x_pos == warp_room.x_pos_in_tiles && tile.y_pos == warp_room.y_pos_in_tiles}
        room = game.areas[0].sectors[warp_tile.sector_index].rooms[warp_tile.room_index]
        warp_room.room_pointer = room.room_metadata_ram_pointer
        
        warp_room.write_to_rom()
      end
    elsif GAME == "hod"
      warp_rooms.each do |warp_room|
        # In HoD the map tile doesn't have the sector/room indexes so we need to search through all rooms in the game to find a matching one.
        x = warp_room.x_pos_in_tiles
        y = warp_room.y_pos_in_tiles
        matched_castle_a_room = nil
        matched_castle_b_room = nil
        game.each_room do |room|
          if (room.room_xpos_on_map..room.room_xpos_on_map+room.width-1).include?(x) && (room.room_ypos_on_map..room.room_ypos_on_map+room.height-1).include?(y)
            if room.sector_index.odd? # Castle B
              matched_castle_b_room = room unless matched_castle_b_room
            else # Castle A
              matched_castle_a_room = room unless matched_castle_a_room
            end
          end
        end
        
        if matched_castle_a_room
          warp_room.castle_a_room_pointer = matched_castle_a_room.room_metadata_ram_pointer
        else
          warp_room.castle_a_room_pointer = 0
        end
        if matched_castle_b_room
          warp_room.castle_b_room_pointer = matched_castle_b_room.room_metadata_ram_pointer
        else
          warp_room.castle_b_room_pointer = 0
        end
        
        warp_room.write_to_rom()
      end
    end
  end
  
  def inspect; to_s; end
end

class DoSMapTile
  attr_reader :tile_metadata,
              :tile_line_data,
              :map_width
              
  attr_accessor :bottom_door,
                :bottom_wall,
                :bottom_secret,
                :right_door,
                :right_wall,
                :right_secret,
                :top_door,
                :top_wall,
                :top_secret,
                :left_door,
                :left_wall,
                :left_secret,
                :is_save,
                :is_warp,
                :is_secret,
                :is_transition,
                :is_entrance,
                :sector_index,
                :room_index,
                :y_pos,
                :x_pos,
                :is_blank,
                :is_castle_b_warp,
                :region_index,
                :which_map_item,
                :room_index_plus_1
  
  def initialize(tile_metadata, tile_line_data, tile_index, map_width)
    @tile_metadata = tile_metadata
    @tile_line_data = tile_line_data
    @tile_index = tile_index
    @map_width = map_width
    
    read_from_rom()
  end
  
  def read_from_rom
    @top_secret     = (tile_line_data & 0b1100) >> 2 == 1
    @top_door       = (tile_line_data & 0b1100) >> 2 == 2
    @top_wall       = (tile_line_data & 0b1100) >> 2 == 3
    @left_secret    =  tile_line_data & 0b0011       == 1
    @left_door      =  tile_line_data & 0b0011       == 2
    @left_wall      =  tile_line_data & 0b0011       == 3

    @is_blank       = tile_metadata == 0xFFFF
    
    unless is_blank
      if GAME == "hod"
        @is_save           =  tile_metadata & 0b10000000_00000000 > 0
        @is_warp           =  tile_metadata & 0b01000000_00000000 > 0
        @is_castle_b_warp  =  tile_metadata & 0b00100000_00000000 > 0
        @region_index      = (tile_metadata & 0b00001111_00000000) >> 8
        @which_map_item    = (tile_metadata & 0b00000000_11000000) >> 6 # which map item this tile corresponds to. 0 is none, 1-3 are maps 1-3. TODO allow editing this manually.
        @room_index_plus_1 = (tile_metadata & 0b00000000_00111111) # TODO does this affect anything? TODO regenerate this aftering editing the map.
      else
        @is_save        =  tile_metadata & 0b10000000_00000000 > 0
        @is_warp        =  tile_metadata & 0b01000000_00000000 > 0
        @sector_index   = (tile_metadata & 0b00000011_11000000) >> 6
        @room_index     =  tile_metadata & 0b00000000_00111111
      end
    end
    
    @y_pos          = @tile_index / map_width
    @x_pos          = @tile_index % map_width
  end
  
  def to_data
    @tile_line_data = 0
    
    if left_secret
      @tile_line_data |= 1
    elsif left_door
      @tile_line_data |= 2
    elsif left_wall
      @tile_line_data |= 3
    end
    
    if top_secret
      @tile_line_data |= 1 << 2
    elsif top_door
      @tile_line_data |= 2 << 2
    elsif top_wall
      @tile_line_data |= 3 << 2
    end
    
    if is_blank
      @tile_metadata = 0xFFFF
    else
      @tile_metadata = 0
      if is_save
        @tile_metadata |= 1 << 15
      end
      if is_warp
        @tile_metadata |= 1 << 14
      end
      if GAME == "hod"
        if is_castle_b_warp
          @tile_metadata |= 1 << 13
        end
        @tile_metadata |= (region_index & 0b1111) << 8
      else
        @tile_metadata |= (sector_index & 0b1111) << 6
        @tile_metadata |= (room_index & 0b111111)
      end
    end
    
    return [tile_line_data, tile_metadata]
  end
end

class DoSSecretDoor < SecretDoor
  attr_accessor :x_pos,
                :y_pos,
                :door_side
  
  def initialize(secret_door_pointer, fs)
    @fs = fs
    @secret_door_pointer = secret_door_pointer
    @x_pos, @y_pos = fs.read(secret_door_pointer, 2).unpack("CC")
    
    if @y_pos >= 0x80
      # If y is negative the door is on the left of the tile.
      @y_pos = (-@y_pos & 0xFF) # Negate y.
      @door_side = :left
    else
      # If y is positive the door is on the top of the tile.
      @door_side = :top
    end
  end
  
  def write_to_rom
    if @x_pos == 0xFF && @y_pos == 0xFF
      # End marker.
      y_and_door_side = @y_pos
    elsif @door_side == :left
      y_and_door_side = (-@y_pos & 0xFF) # Negate y.
    else
      y_and_door_side = @y_pos
    end
    fs.write(secret_door_pointer, [@x_pos, y_and_door_side].pack("CC"))
  end
end

class DoSWarpRoom
  attr_reader :warp_room_index,
              :fs,
              :warp_room_data_pointer,
              :warp_room_icon_pos_data_pointer
  attr_accessor :sector_index,
                :room_index,
                :x_pos_in_pixels,
                :y_pos_in_pixels,
                :x_index,
                :y_index,
                :area_name_index,
                :x_pos_in_tiles,
                :y_pos_in_tiles
  
  def initialize(warp_room_index, fs)
    @warp_room_index = warp_room_index
    @fs = fs
    
    @warp_room_data_pointer = WARP_ROOM_LIST_START + warp_room_index*7
    @warp_room_icon_pos_data_pointer = WARP_ROOM_ICON_POS_LIST_START + warp_room_index*2
    
    @sector_index, @room_index,
      @x_pos_in_pixels, @y_pos_in_pixels,
      @x_index, @y_index,
      @area_name_index = fs.read(warp_room_data_pointer, 7).unpack("C*")
    @x_pos_in_tiles, @y_pos_in_tiles = fs.read(warp_room_icon_pos_data_pointer, 2).unpack("C*")
  end
  
  def write_to_rom
    fs.write(warp_room_data_pointer, [
      @sector_index, @room_index,
      @x_pos_in_pixels, @y_pos_in_pixels,
      @x_index, @y_index,
      @area_name_index
    ].pack("C*"))
    fs.write(warp_room_icon_pos_data_pointer, [@x_pos_in_tiles, @y_pos_in_tiles].pack("C*"))
  end
end

class AoSWarpRoom
  attr_reader :warp_room_index,
              :fs,
              :warp_room_data_pointer
  attr_accessor :x_pos_in_tiles,
                :y_pos_in_tiles,
                :room_pointer
  
  def initialize(warp_room_index, fs)
    @warp_room_index = warp_room_index
    @fs = fs
    
    @warp_room_data_pointer = WARP_ROOM_LIST_START + warp_room_index*8
    
    @x_pos_in_tiles, @y_pos_in_tiles,
      @room_pointer = fs.read(warp_room_data_pointer, 8).unpack("vvV")
  end
  
  def write_to_rom
    fs.write(warp_room_data_pointer, [
      @x_pos_in_tiles,
      @y_pos_in_tiles,
      @room_pointer
    ].pack("vvV"))
  end
end

class HoDWarpRoom
  attr_reader :warp_room_index,
              :fs,
              :warp_room_data_pointer
  attr_accessor :x_pos_in_tiles,
                :y_pos_in_tiles,
                :castle_a_room_pointer,
                :castle_b_room_pointer
  
  def initialize(warp_room_index, fs)
    @warp_room_index = warp_room_index
    @fs = fs
    
    @warp_room_data_pointer = WARP_ROOM_LIST_START + warp_room_index*0xC
    
    @x_pos_in_tiles, @y_pos_in_tiles,
      @castle_a_room_pointer, @castle_b_room_pointer = fs.read(warp_room_data_pointer, 0xC).unpack("vvVV")
  end
  
  def write_to_rom
    fs.write(warp_room_data_pointer, [
      @x_pos_in_tiles,
      @y_pos_in_tiles,
      @castle_a_room_pointer,
      @castle_b_room_pointer
    ].pack("vvVV"))
  end
end
