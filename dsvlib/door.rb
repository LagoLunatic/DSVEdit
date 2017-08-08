class Door
  attr_reader :room,
              :fs,
              :game,
              :destination_door
  attr_accessor :door_ram_pointer,
                :destination_room_metadata_ram_pointer,
                :x_pos,
                :y_pos,
                :dest_x_unused,
                :dest_y_unused,
                :dest_x,
                :dest_y
  
  def initialize(room, game)
    @room = room
    @fs = game.fs
    @game = game
  end
  
  def read_from_rom(door_ram_pointer)
    @door_ram_pointer = door_ram_pointer
    
    @destination_room_metadata_ram_pointer,
      @x_pos, @y_pos,
      @dest_x_unused, @dest_y_unused,
      @dest_x, @dest_y,
      @unknown = fs.read(door_ram_pointer, 16).unpack("VCCvvvvv")
    
    return self
  end
  
  def write_to_rom
    room.sector.load_necessary_overlay()
    
    if door_ram_pointer.nil?
      raise "Can't save a door that doesn't have a pointer"
    end
    
    fs.write(door_ram_pointer, [destination_room_metadata_ram_pointer].pack("V"))
    fs.write(door_ram_pointer+4, [x_pos, y_pos].pack("C*"))
    fs.write(door_ram_pointer+6, [dest_x_unused, dest_y_unused, dest_x, dest_y, 0].pack("v*"))
  end
  
  def direction
    if x_pos == 0xFF
      return :left
    elsif y_pos == 0xFF
      return :up
    elsif x_pos == room.main_layer_width
      return :right
    elsif y_pos == room.main_layer_height
      return :down
    else
      return nil
    end
  end
  
  def destination_door
    dest_room = nil
    game.each_room do |room|
      if room.room_metadata_ram_pointer == destination_room_metadata_ram_pointer
        dest_room = room
        break
      end
    end
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
  
  def door_str
    door_index = room.doors.index(self)
    "#{room.room_str}_%03X" % door_index
  end
end
