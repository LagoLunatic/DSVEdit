class Door
  attr_reader :room,
              :fs,
              :game,
              :door_ram_pointer,
              :destination_door
  attr_accessor :destination_room_metadata_ram_pointer,
                :x_pos,
                :y_pos,
                :dest_x_unused,
                :dest_y_unused,
                :dest_x,
                :dest_y
  
  def initialize(room, door_ram_pointer, game)
    @room = room
    @fs = game.fs
    @game = game
    @door_ram_pointer = door_ram_pointer
    
    read_from_rom()
  end
  
  def read_from_rom
    @destination_room_metadata_ram_pointer = fs.read(door_ram_pointer,4).unpack("V*").first
    @x_pos, @y_pos = fs.read(door_ram_pointer+4,2).unpack("C*")
    @dest_x_unused, @dest_y_unused, @dest_x, @dest_y = fs.read(door_ram_pointer+6,8).unpack("v*")
    @unk1, @unk2 = fs.read(door_ram_pointer+14,2).unpack("C*")
    #raise [@dest_x_A, @dest_y_A].inspect if @dest_x_A > 0 || @dest_y_A > 0
    #raise [@dest_x_B, @dest_y_B].inspect if @dest_x_B > 0 || @dest_y_B > 0
    #raise [@unk1, @unk2].inspect if @unk1 > 0 || @unk2 > 0
    # todo: get rest of bytes
  end
  
  def write_to_rom
    room.sector.load_necessary_overlay()
    
    fs.write(door_ram_pointer, [destination_room_metadata_ram_pointer].pack("V"))
    fs.write(door_ram_pointer+4, [x_pos, y_pos].pack("C*"))
    fs.write(door_ram_pointer+6, [dest_x_unused, dest_y_unused, dest_x, dest_y].pack("v*"))
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
      raise "Unknown direction"
    end
  end
  
  def destination_door
    @destination_door = begin
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
        raise "dest_door is nil"
      end
      
      dest_door
    end
  end
end
