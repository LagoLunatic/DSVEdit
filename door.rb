class Door
  attr_reader :room,
              :rom,
              :converter,
              :door_pointer,
              :destination_room_metadata_ram_pointer,
              :x_pos,
              :y_pos,
              :dest_x,
              :dest_y
  
  def initialize(room, door_pointer, rom, converter)
    @room = room
    @rom = rom
    @converter = converter
    @door_pointer = door_pointer
    
    read_from_rom()
  end
  
  def read_from_rom
    @destination_room_metadata_ram_pointer = rom[door_pointer,4].unpack("V*").first
    @x_pos, @y_pos = rom[door_pointer+4,2].unpack("C*")
    @dest_x_A, @dest_y_A, @dest_x_B, @dest_y_B = rom[door_pointer+6,8].unpack("v*")
    @unk1, @unk2 = rom[door_pointer+14,2].unpack("C*")
    raise [@dest_x_A, @dest_y_A].inspect if @dest_x_A > 0 || @dest_y_A > 0
    #raise [@dest_x_B, @dest_y_B].inspect if @dest_x_B > 0 || @dest_y_B > 0
    raise [@unk1, @unk2].inspect if @unk1 > 0 || @unk2 > 0
    # todo: get rest of bytes
  end
  
  def write_to_rom
    raise NotImplementedError
  end
end