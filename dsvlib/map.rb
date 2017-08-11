
class Map
  attr_reader :map_tile_metadata_ram_pointer,
              :map_tile_line_data_ram_pointer,
              :number_of_tiles,
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
    @secret_door_list_pointer = fs.read(MAP_SECRET_DOOR_LIST_START_OFFSET + area_index*4, 4).unpack("V*").first
    @row_widths_list_pointer = fs.read(MAP_ROW_WIDTHS_LIST_START_OFFSET + area_index*4, 4).unpack("V*").first
    
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
        
        map_tile_index, secret_door_index = fs.read(secret_door_list_pointer + i*4, 4).unpack("v*")
        secret_door = SecretDoor.new(map_tile_index, secret_door_index, tiles)
        
        if secret_door.map_tile_index >= tile_index
          @secret_doors << secret_door
        else
          # Reached the end of the secret door list for this area.
          break
        end
      end
    end
    
    @row_widths = []
    row = 0
    total_tiles_found = 0
    while true
      row_width = fs.read(@row_widths_list_pointer + row, 1).unpack("C").first
      break if total_tiles_found == number_of_tiles
      
      if total_tiles_found > number_of_tiles
        raise "Error reading map row widths: Too many tiles"
      end
      if row > 0xFF
        raise "Error reading map row widths: Read too many rows"
      end
      
      @row_widths << row_width
      total_tiles_found += row_width
      
      row += 1
    end
  end
  
  def write_to_rom
    @tiles = @tiles.sort_by{|tile| [tile.y_pos, tile.x_pos]}
    
    (0..number_of_tiles-1).each do |i|
      tile_line_data, tile_metadata = @tiles[i].to_data
      
      fs.write(map_tile_line_data_ram_pointer + i, [tile_line_data].pack("C"))
      fs.write(map_tile_metadata_ram_pointer + i*4, tile_metadata.pack("vCC"))
    end
    
    tiles_by_row = @tiles.group_by{|tile| tile.y_pos}
    max_y_pos = tiles_by_row.keys.max
    if max_y_pos < @row_widths.size - 1
      raise "Cannot decrease height of map in PoR/OoE."
    end
    (0..max_y_pos).each do |row|
      if @row_widths[row].nil?
        raise "Cannot increase height of map in PoR/OoE."
      end
      
      if tiles_by_row[row]
        @row_widths[row] = tiles_by_row[row].length
      else
        @row_widths[row] = 0
      end
      
      fs.write(@row_widths_list_pointer + row, [@row_widths[row]].pack("C"))
    end
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
  attr_reader :map_tile_index,
              :secret_door_index,
              :map_tile
  
  def initialize(map_tile_index, secret_door_index, all_map_tiles)
    @map_tile_index  = map_tile_index
    @secret_door_index = secret_door_index
    
    @map_tile = all_map_tiles[@map_tile_index]
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
    else
      @width = 64
      
      @map_tile_metadata_ram_pointer = MAP_TILE_METADATA_START_OFFSET
      @map_tile_line_data_ram_pointer = MAP_TILE_LINE_DATA_START_OFFSET
      @number_of_tiles = MAP_NUMBER_OF_TILES
      @secret_door_list_pointer = MAP_SECRET_DOOR_DATA_START_OFFSET
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
        x_pos, y_pos = fs.read(secret_door_list_pointer + i*2, 2).unpack("C*")
        
        if x_pos == 0xFF && y_pos == 0xFF
          break
        end
        
        @secret_doors << DoSSecretDoor.new(x_pos, y_pos)
        
        i += 1
      end
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
    
    if GAME == "dos"
      # TODO: sector/room indexes of abyss warp aren't set properly.
      
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
        else
          warp_room.sector_index = 0
          warp_room.room_index = 0
        end
        
        warp_room.write_to_rom()
      end
    else
      warp_rooms.each do |warp_room|
        warp_tile = @tiles.find{|tile| tile.x_pos == warp_room.x_pos_in_tiles && tile.y_pos == warp_room.y_pos_in_tiles}
        room = game.areas[0].sectors[warp_tile.sector_index].rooms[warp_tile.room_index]
        warp_room.room_pointer = room.room_metadata_ram_pointer
        
        warp_room.write_to_rom()
      end
    end
  end
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
                :is_blank
  
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
      @is_save        =  tile_metadata & 0b10000000_00000000 > 0
      @is_warp        =  tile_metadata & 0b01000000_00000000 > 0
      @sector_index   = (tile_metadata & 0b00000011_11000000) >> 6
      @room_index     =  tile_metadata & 0b00000000_00111111
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
      @tile_metadata |= (sector_index & 0b1111) << 6
      @tile_metadata |= (room_index & 0b111111)
    end
    
    return [tile_line_data, tile_metadata]
  end
end

class DoSSecretDoor < SecretDoor
  attr_reader :x_pos,
              :y_pos,
              :door_side
  
  def initialize(x_pos, y_pos)
    @x_pos = x_pos
    @y_pos = y_pos
    
    if @y_pos >= 0x80
      # If y is negative the door is on the left of the tile.
      @y_pos = (-@y_pos & 0xFF) # Negate y.
      @door_side = :left
    else
      # If y is positive the door is on the top of the tile.
      @door_side = :top
    end
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
