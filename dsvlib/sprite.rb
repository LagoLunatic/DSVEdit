
class Sprite
  attr_reader :sprite_file,
              :hitbox_list_offset,
              :sprite_list_offset,
              :frame_delay_list_offset,
              :parts,
              :hitboxes,
              :frames,
              :frame_delays,
              :fs
  
  def initialize(sprite_file, fs)
    @sprite_file = sprite_file
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom()
    magic_bytes = fs.read_by_file(sprite_file[:file_path], 0, 4).unpack("V*").first
    if magic_bytes != 0xBEEFF00D
      raise "Unknown magic bytes: %08X" % magic_bytes
    end
    
    @hitbox_list_offset, @sprite_list_offset, @frame_delay_list_offset, unknown_offset = fs.read_by_file(sprite_file[:file_path], 0x08, 16).unpack("V*")
    @number_of_frames = fs.read_by_file(sprite_file[:file_path], 0x24, 4).unpack("V*").first
    
    @parts = []
    (0x40..hitbox_list_offset-1).step(16) do |offset|
      part_data = fs.read_by_file(sprite_file[:file_path], offset, 16)
      @parts << Part.new(part_data)
    end
    
    @hitboxes = []
    (hitbox_list_offset..sprite_list_offset-1).step(8) do |offset|
      hitbox_data = fs.read_by_file(sprite_file[:file_path], offset, 8)
      @hitboxes << Hitbox.new(hitbox_data)
    end
    
    @frames = []
    offset = sprite_list_offset
    @number_of_frames.times do
      frame_data = fs.read_by_file(sprite_file[:file_path], offset, 12)
      @frames << Frame.new(frame_data, parts, hitboxes)
      
      offset += 12
    end
    
    @frame_delays = []
    offset = frame_delay_list_offset
    @number_of_frames.times do
      frame_delay_data = fs.read_by_file(sprite_file[:file_path], offset, 8)
      @frame_delays << FrameDelay.new(frame_delay_data)
      
      offset += 8
      break if offset >= unknown_offset
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
  
  def initialize(frame_data, all_sprite_parts, all_sprite_hitboxes)
    unk1, unk2, @has_hitbox, @number_of_parts, @hitbox_offset, @part_offset = frame_data.unpack("CCCCVV")
    
    parts_start_index = (part_offset / 0x10)
    @part_indexes = (parts_start_index..parts_start_index+number_of_parts-1).to_a
    @parts = @part_indexes.map{|i| all_sprite_parts[i]}
    
    if @has_hitbox > 0
      @hitbox_index = hitbox_offset / 0x10
      @hitbox = all_sprite_hitboxes[hitbox_index]
    end
  end
end

class FrameDelay
  attr_reader :frame_index,
              :delay
              
  def initialize(frame_delay_data)
    @frame_index, @delay, unk = frame_delay_data.unpack("vvV")
  end
end
