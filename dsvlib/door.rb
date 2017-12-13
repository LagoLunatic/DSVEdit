class Door
  attr_reader :room,
              :fs,
              :game
  attr_accessor :door_ram_pointer,
                :destination_room_metadata_ram_pointer,
                :x_pos,
                :y_pos,
                :dest_x_2,
                :dest_y_2,
                :dest_x,
                :dest_y,
                :unused
  
  def initialize(room, game)
    @room = room
    @fs = game.fs
    @game = game
    @x_pos = @y_pos = @dest_x_2 = @dest_y_2 = @dest_x = @dest_y = @unused = 0
    @destination_room_metadata_ram_pointer = @room.room_metadata_ram_pointer
  end
  
  def read_from_rom(door_ram_pointer)
    @door_ram_pointer = door_ram_pointer
    
    if GAME == "hod"
      @destination_room_metadata_ram_pointer,
        @x_pos, @y_pos,
        @dest_x_2, @dest_y_2,
        @dest_x, @dest_y = fs.read(door_ram_pointer, 12).unpack("VCCCCvv")
    else
      @destination_room_metadata_ram_pointer,
        @x_pos, @y_pos,
        @dest_x_2, @dest_y_2,
        @dest_x, @dest_y,
        @unused = fs.read(door_ram_pointer, 16).unpack("VCCvvvvv")
    end
    
    return self
  end
  
  def write_to_rom
    room.sector.load_necessary_overlay()
    
    if door_ram_pointer.nil?
      raise "Can't save a door that doesn't have a pointer"
    end
    
    fs.write(door_ram_pointer, [destination_room_metadata_ram_pointer].pack("V"))
    fs.write(door_ram_pointer+4, [x_pos, y_pos].pack("CC"))
    
    if GAME == "hod"
      fs.write(door_ram_pointer+6, [dest_x_2, dest_y_2, dest_x, dest_y].pack("CCvv"))
    else
      fs.write(door_ram_pointer+6, [dest_x_2, dest_y_2, dest_x, dest_y, 0].pack("vvvv"))
    end
  end
  
  def direction
    if x_pos == 0xFF
      return :left
    elsif y_pos == 0xFF
      return :up
    elsif x_pos == room.width
      return :right
    elsif y_pos == room.height
      return :down
    else
      return nil
    end
  end
  
  def destination_room
    game.get_room_by_metadata_pointer(destination_room_metadata_ram_pointer)
  end
  
  def destination_door
    dest_room = destination_room
    if dest_room.nil?
      raise "Door has invalid destination room: %08X" % destination_room_metadata_ram_pointer
    end
    
    dest_door_predicted_x = dest_x/SCREEN_WIDTH_IN_PIXELS
    dest_door_predicted_y = dest_y/SCREEN_HEIGHT_IN_PIXELS
    case direction
    when :left
      dest_door_predicted_x += 1
    when :right
      dest_door_predicted_x -= 1
    when :up
      dest_door_predicted_y += 1
    when :down
      dest_door_predicted_y -= 1
    end
    dest_door_predicted_x = 0xFF if dest_door_predicted_x == -1
    dest_door_predicted_y = 0xFF if dest_door_predicted_y == -1
    dest_door = dest_room.doors.find{|door| door.x_pos == dest_door_predicted_x && door.y_pos == dest_door_predicted_y}
    if dest_door.nil?
      raise "Could not find matching destination door for door #{door_str}"
    end
    
    # Returns nil if there's no matching dest door
    dest_door
  end
  
  def self.data_size
    if GAME == "hod"
      12
    else
      16
    end
  end
  
  def door_str
    @door_str ||= "#{room.room_str}_%03X" % room.doors.index(self)
  end
end
