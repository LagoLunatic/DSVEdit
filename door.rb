class Door
  attr_reader :room,
              :fs,
              :door_ram_pointer
  attr_accessor :destination_room_metadata_ram_pointer,
                :x_pos,
                :y_pos,
                :dest_x_unused,
                :dest_y_unused,
                :dest_x,
                :dest_y
  
  def initialize(room, door_ram_pointer, fs)
    @room = room
    @fs = fs
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
    fs.write(door_ram_pointer, [destination_room_metadata_ram_pointer].pack("V"))
    fs.write(door_ram_pointer+4, [x_pos, y_pos].pack("C*"))
    fs.write(door_ram_pointer+6, [dest_x_unused, dest_y_unused, dest_x, dest_y].pack("v*"))
  end
end
