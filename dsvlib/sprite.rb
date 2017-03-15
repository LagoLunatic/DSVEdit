
class Sprite
  class SaveError < StandardError ; end
  
  attr_reader :fs,
              :sprite_pointer,
              :sprite_file,
              :part_list_offset,
              :hitbox_list_offset,
              :frame_list_offset,
              :frame_delay_list_offset,
              :animation_list_offset,
              :file_footer_offset,
              :number_of_frames,
              :number_of_animations,
              :parts,
              :hitboxes,
              :frames,
              :frame_delays,
              :animations
  
  def initialize(sprite_pointer, fs)
    @fs = fs
    
    @sprite_pointer = sprite_pointer
    @sprite_file = fs.find_file_by_ram_start_offset(sprite_pointer)
    if @sprite_file
      read_from_rom_by_sprite_file(@sprite_file)
    else
      read_from_rom_by_pointer(@sprite_pointer)
    end
  end
  
  def read_from_rom_by_sprite_file(sprite_file)
    magic_bytes = fs.read_by_file(sprite_file[:file_path], 0, 4).unpack("V*").first
    if magic_bytes != 0xBEEFF00D
      raise "Unknown magic bytes for sprite file %s: %08X" % [sprite_file[:file_path], magic_bytes]
    end
    
    @part_list_offset, @hitbox_list_offset, @frame_list_offset,
      @frame_delay_list_offset, @animation_list_offset, unused_1, unused_2,
      @file_footer_offset, @number_of_frames, @number_of_animations = fs.read_by_file(sprite_file[:file_path], 0x04, 40).unpack("V*")
    
    @parts = []
    @parts_by_offset = {}
    (part_list_offset..hitbox_list_offset-1).step(16) do |offset|
      part_data = fs.read_by_file(sprite_file[:file_path], offset, 16)
      part = Part.new(part_data)
      @parts << part
      @parts_by_offset[offset-part_list_offset] = part
    end
    
    @hitboxes = []
    @hitboxes_by_offset = {}
    (hitbox_list_offset..frame_list_offset-1).step(8) do |offset|
      hitbox_data = fs.read_by_file(sprite_file[:file_path], offset, 8)
      hitbox = Hitbox.new(hitbox_data)
      @hitboxes << hitbox
      @hitboxes_by_offset[offset-hitbox_list_offset] = hitbox
    end
    
    @frames = []
    offset = frame_list_offset
    disposable_hitbox_list = hitboxes.dup
    number_of_frames.times do
      frame_data = fs.read_by_file(sprite_file[:file_path], offset, 12)
      frame = Frame.new(frame_data)
      frame.initialize_parts(parts, @parts_by_offset)
      frame.initialize_hitboxes_from_sprite_file(disposable_hitbox_list)
      @frames << frame
      
      offset += 12
    end
    
    @frame_delays = []
    @frame_delays_by_offset = {}
    unless frame_delay_list_offset == 0
      (frame_delay_list_offset..animation_list_offset-1).step(8) do |offset|
        frame_delay_data = fs.read_by_file(sprite_file[:file_path], offset, 8)
        frame_delay = FrameDelay.new(frame_delay_data)
        @frame_delays << frame_delay
        @frame_delays_by_offset[offset-frame_delay_list_offset] = frame_delay
      end
    end
    
    @animations = []
    unless animation_list_offset == 0
      (animation_list_offset..file_footer_offset-1).step(8) do |offset|
        animation_data = fs.read_by_file(sprite_file[:file_path], offset, 8)
        animation = Animation.new(animation_data)
        animation.initialize_frame_delays(frame_delays, @frame_delays_by_offset)
        @animations << animation
      end
    end
  end
  
  def read_from_rom_by_pointer(sprite_pointer)
    @number_of_frames, @number_of_animations, @frame_list_offset, @animation_list_offset = fs.read(sprite_pointer, 12).unpack("vvVV")
    
    @frames = []
    offset = frame_list_offset
    number_of_frames.times do
      frame_data = fs.read(offset, 12)
      frame = Frame.new(frame_data)
      @frames << frame
      
      offset += 12
    end
    
    @parts_by_offset = {}
    frames.each do |frame|
      offset = frame.first_part_offset
      frame.number_of_parts.times do
        part_data = fs.read(offset, 16)
        @parts_by_offset[offset] ||= Part.new(part_data)
        
        offset += 16
      end
    end
    @parts = @parts_by_offset.sort_by{|offset, part| offset}.map{|offset, part| part}
    
    @hitboxes_by_offset = {}
    frames.each do |frame|
      offset = frame.first_hitbox_offset
      frame.number_of_hitboxes.times do
        hitbox_data = fs.read(offset, 8)
        @hitboxes_by_offset[offset] ||= Hitbox.new(hitbox_data)
        
        offset += 8
      end
    end
    @hitboxes = @hitboxes_by_offset.sort_by{|offset, hitbox| offset}.map{|offset, hitbox| hitbox}
    
    @frames.each do |frame|
      frame.initialize_parts(parts, @parts_by_offset)
      frame.initialize_hitboxes_from_pointer(hitboxes, @hitboxes_by_offset)
    end
    
    @animations = []
    @frame_delays_by_offset = {}
    @frame_delays = []
    if animation_list_offset && animation_list_offset != 0
      (animation_list_offset..animation_list_offset+number_of_animations*8-1).step(8) do |offset|
        animation_data = fs.read(offset, 8)
        @animations << Animation.new(animation_data)
      end
      
      animations.each do |animation|
        offset = animation.first_frame_delay_offset
        animation.number_of_frames.times do
          frame_delay_data = fs.read(offset, 8)
          @frame_delays_by_offset[offset] ||= FrameDelay.new(frame_delay_data)
          
          offset += 8
        end
      end
    end
    
    @animations.each do |animation|
      animation.initialize_frame_delays(frame_delays, @frame_delays_by_offset)
    end
  end
  
  def write_to_rom
    if @sprite_file
      write_to_rom_by_sprite_file()
    else
      write_to_rom_by_pointer()
    end
  end
  
  def write_to_rom_by_sprite_file
    new_data = "\0"*0x40
    
    offset = 0x40
    @part_list_offset = offset
    @parts.each do |part|
      new_data << part.to_data
      offset += 16
    end
    
    @hitbox_list_offset = offset
    @hitboxes.each do |hitbox|
      new_data << hitbox.to_data
      offset += 8
    end
    
    @frame_list_offset = offset
    @number_of_frames = @frames.length
    @frames.each do |frame|
      new_data << frame.to_data
      offset += 12
    end
    
    @frame_delay_list_offset = offset
    @frame_delays.each do |frame_delay|
      new_data << frame_delay.to_data
      offset += 8
    end
    
    @animation_list_offset = offset
    @number_of_animations = @animations.length
    @animations.each do |animation|
      new_data << animation.to_data
      offset += 8
    end
    
    new_file_size = new_data.length + 16
    
    file_footer_offset = offset
    file_footer = [
      @number_of_frames,
      @number_of_animations,
      new_file_size,
      new_file_size,
      0
    ].pack("vvVVV")
    new_data << file_footer
    
    new_data[0, 0x30] = [
      0xBEEFF00D,
      @part_list_offset,
      @hitbox_list_offset,
      @frame_list_offset,
      @frame_delay_list_offset,
      @animation_list_offset,
      0,
      0,
      file_footer_offset, # file footer offset
      @number_of_frames,
      @number_of_animations,
      new_file_size,
    ].pack("V*")
    
    fs.overwrite_file(sprite_file[:file_path], new_data)
  end
  
  def write_to_rom_by_pointer
    raise SaveError.new("Sprites without a sprite file cannot currently be saved.")
  end
  
  def min_x
    (parts + hitboxes).map{|item| item.x_pos}.min
  end
  
  def min_y
    (parts + hitboxes).map{|item| item.y_pos}.min
  end
  
  def max_x
    (parts + hitboxes).map{|item| item.x_pos + item.width}.max
  end
  
  def max_y
    (parts + hitboxes).map{|item| item.y_pos + item.height}.max
  end
  
  def full_width
    max_x - min_x
  end
  
  def full_height
    max_y - min_y
  end
end

class Part
  attr_accessor :x_pos,
                :y_pos,
                :gfx_x_offset,
                :gfx_y_offset,
                :width,
                :height,
                :gfx_page_index,
                :vertical_flip,
                :horizontal_flip,
                :palette_index,
                :unused
  
  def initialize(part_data)
    @x_pos, @y_pos,
      @gfx_x_offset, @gfx_y_offset,
      @width, @height,
      @gfx_page_index, flip_bits,
      @palette_index, @unused = part_data.unpack("s<s<vvvvCCCC")
    
    @vertical_flip   = (flip_bits & 0b00000001) > 0
    @horizontal_flip = (flip_bits & 0b00000010) > 0
  end
  
  def to_data
    flip_bits = 0
    flip_bits |= 0b00000001 if @vertical_flip
    flip_bits |= 0b00000010 if @horizontal_flip
    
    [
      @x_pos,
      @y_pos,
      @gfx_x_offset,
      @gfx_y_offset,
      @width,
      @height,
      @gfx_page_index,
      flip_bits,
      @palette_index,
      @unused
    ].pack("s<s<vvvvCCCC")
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
  
  def to_data
    [@x_pos, @y_pos, @width, @height].pack("s<s<vv")
  end
end

class Frame
  attr_reader :unknown,
              :number_of_hitboxes,
              :number_of_parts,
              :first_hitbox_offset,
              :first_part_offset,
              :part_indexes,
              :part_offsets,
              :parts,
              :hitbox_indexes,
              :hitbox_offsets,
              :hitboxes
  
  def initialize(frame_data)
    @unknown, @number_of_hitboxes, @number_of_parts, @first_hitbox_offset, @first_part_offset = frame_data.unpack("vCCVV")
  end
  
  def initialize_parts(all_sprite_parts, all_sprite_parts_by_offset)
    @part_offsets = (@first_part_offset..@first_part_offset+@number_of_parts*0x10-1).step(0x10).to_a
    @parts = @part_offsets.map{|offset| all_sprite_parts_by_offset[offset]}
    @part_indexes = @parts.map{|part| all_sprite_parts.index(part)}
  end
  
  def initialize_hitboxes_from_sprite_file(all_sprite_hitboxes)
    if all_sprite_hitboxes.length < number_of_hitboxes
      raise "Not enough hitboxes left"
    end
    @hitboxes = all_sprite_hitboxes.shift(number_of_hitboxes)
  end
  
  def initialize_hitboxes_from_pointer(all_sprite_hitboxes, all_sprite_hitboxes_by_offset)
    @hitbox_offsets = (@first_hitbox_offset..@first_hitbox_offset+@number_of_hitboxes*0x08-1).step(0x08).to_a
    @hitboxes = @hitbox_offsets.map{|offset| all_sprite_hitboxes_by_offset[offset]}
    if @hitboxes.include?(nil)
      raise "Couldn't find hitboxes"
    end
    @hitbox_indexes = @hitboxes.map{|part| all_sprite_hitboxes.index(part)}
  end
  
  def to_data
    [
      @unknown,
      @number_of_hitboxes,
      @number_of_parts,
      @first_hitbox_offset,
      @first_part_offset
    ].pack("vCCVV")
  end
end

class FrameDelay
  attr_reader :frame_index,
              :delay,
              :unknown
              
  def initialize(frame_delay_data)
    @frame_index, @delay, @unknown = frame_delay_data.unpack("vvV")
  end
  
  def to_data
    [@frame_index, @delay, @unknown].pack("vvV")
  end
end

class Animation
  attr_reader :number_of_frames,
              :first_frame_delay_offset,
              :frame_delay_indexes,
              :frame_delays
              
  def initialize(animation_data)
    @number_of_frames, @first_frame_delay_offset = animation_data.unpack("VV")
  end
  
  def initialize_frame_delays(all_frame_delays, all_frame_delays_by_offset)#(frame_list_offset, all_frame_delay_indexes)
    @frame_delay_offsets = (@first_frame_delay_offset..@first_frame_delay_offset+@number_of_frames*0x08-1).step(0x08).to_a
    @frame_delays = @frame_delay_offsets.map{|offset| all_frame_delays_by_offset[offset]}
    @frame_delay_indexes = @frame_delays.map{|frame_delay| all_frame_delays.index(frame_delay)}
  end
  
  def to_data
    [@number_of_frames, @first_frame_delay_offset].pack("VV")
  end
end
