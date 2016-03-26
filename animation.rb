
class Animation
  attr_reader :animation_file,
              :hitbox_list_offset,
              :anim_list_offset,
              :final_list_offset,
              :parts,
              :hitboxes,
              :frames,
              :fs
  
  def initialize(animation_file, fs)
    @animation_file = animation_file
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom()
    @hitbox_list_offset, @anim_list_offset, @final_list_offset = fs.read_by_file(animation_file[:file_path], 0x08, 12).unpack("V*")
    
    @parts = []
    (0x40..hitbox_list_offset-1).step(16) do |offset|
      part_data = fs.read_by_file(animation_file[:file_path], offset, 16)
      @parts << Part.new(part_data)
    end
    
    @hitboxes = []
    (hitbox_list_offset..anim_list_offset-1).step(8) do |offset|
      hitbox_data = fs.read_by_file(animation_file[:file_path], offset, 8)
      @hitboxes << Hitbox.new(hitbox_data)
    end
    
    @frames = []
    (anim_list_offset..final_list_offset-1).step(12) do |offset|
      frame_data = fs.read_by_file(animation_file[:file_path], offset, 12)
      @frames << Frame.new(frame_data, parts, hitboxes)
    end
  end
end

class Part
  attr_reader :x_pos,
              :y_pos,
              :gfx_x_offset,
              :gfx_y_offset,
              :width,
              :height,
              :gfx_page_index,
              :vertical_flip,
              :horizontal_flip,
              :palette_index
  
  def initialize(part_data)
    @x_pos, @y_pos,
      @gfx_x_offset, @gfx_y_offset,
      @width, @height,
      @gfx_page_index, flip_bits,
      @palette_index, unknown = part_data.unpack("s<s<vvvvCCCC")
    
    @vertical_flip   = (flip_bits & 0b00000001) > 0
    @horizontal_flip = (flip_bits & 0b00000010) > 0
  end
end

class Hitbox
  attr_reader :x_pos,
              :y_pos,
              :width,
              :height
  
  def initialize(hitbox_data)
    @x_pos, @y_pos, @width, @height = hitbox_data.unpack("s<s<vv")
  end
end

class Frame
  attr_reader :has_hitbox,
              :number_of_parts,
              :hitbox_offset,
              :part_offset,
              :part_indexes,
              :parts,
              :hitbox_index,
              :hitbox
  
  def initialize(frame_data, all_animation_parts, all_animation_hitboxes)
    unk1, unk2, @has_hitbox, @number_of_parts, @hitbox_offset, @part_offset = frame_data.unpack("CCCCVV")
    
    parts_start_index = (part_offset / 0x10)
    @part_indexes = (parts_start_index..parts_start_index+number_of_parts-1).to_a
    @parts = @part_indexes.map{|i| all_animation_parts[i]}
    
    if @has_hitbox > 0
      @hitbox_index = hitbox_offset / 0x10
      @hitbox = all_animation_hitboxes[hitbox_index]
    end
  end
end
