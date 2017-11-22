
class MagicSeal
  attr_reader :magic_seal_index,
              :magic_seal_pointer,
              :fs
  attr_accessor :num_points,
                :radius,
                :rotation,
                :point_order_list_pointer,
                :point_order_list,
                :sprite_pointer,
                :gfx_pointer,
                :palette_pointer,
                :time_limit,
                :finished_image_index
  
  def initialize(magic_seal_index, fs)
    @magic_seal_index = magic_seal_index
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    @magic_seal_pointer = fs.read(MAGIC_SEAL_LIST_START + magic_seal_index*4, 4).unpack("V").first
    
    @num_points, @radius, @rotation, @unknown1, @unknown2,
      @point_order_list_pointer,
      @sprite_pointer, @gfx_pointer, @palette_pointer,
      @time_limit, @finished_image_index = fs.read(magic_seal_pointer, 0x20).unpack("vvvvVVVVVvv")
    
    @point_order_list = []
    i = 0
    while true
      point_index = fs.read(point_order_list_pointer+i).unpack("C").first
      if point_index == 0xFF
        break
      end
      
      @point_order_list << point_index
      
      i += 1
    end
    
    @original_pointer_order_list_length = point_order_list.length
  end
  
  def write_to_rom
    if point_order_list.length > @original_pointer_order_list_length
      # Repoint the point order list so there's room for more entries without overwriting anything.
      
      original_length = @original_pointer_order_list_length+1
      length_needed = point_order_list.length+1
      
      new_point_order_list_pointer = fs.free_old_space_and_find_new_free_space(point_order_list_pointer, original_length, length_needed, nil)
      
      @original_pointer_order_list_length = point_order_list.length
      
      @point_order_list_pointer = new_point_order_list_pointer
      fs.write(magic_seal_pointer+0x14, [point_order_list_pointer].pack("V"))
    elsif point_order_list.length < @original_pointer_order_list_length
      original_length = @original_pointer_order_list_length+1
      length_needed = point_order_list.length+1
      
      fs.free_unused_space(point_order_list_pointer + length_needed, original_length - length_needed)
      
      @original_pointer_order_list_length = point_order_list.length
    end
    
    data = [
      @num_points, @radius, @rotation, @unknown1, @unknown2,
      @point_order_list_pointer,
      @sprite_pointer, @gfx_pointer, @palette_pointer,
      @time_limit, @finished_image_index
    ].pack("vvvvVVVVVvv")
    fs.write(magic_seal_pointer, data)
    
    point_order_list.each_with_index do |point_index, i|
      fs.write(point_order_list_pointer+i, [point_index].pack("C"))
    end
    end_marker_location = point_order_list_pointer + point_order_list.length
    fs.write(end_marker_location, [0xFF].pack("C")) # Marks the end of the point order list
  end
end
