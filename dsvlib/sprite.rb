
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
              :parts_by_offset,
              :hitboxes,
              :hitboxes_by_offset,
              :frames,
              :frame_delays,
              :frame_delays_by_offset,
              :animations
  
  def initialize(sprite_pointer, fs)
    @fs = fs
    
    @sprite_pointer = sprite_pointer
    @sprite_file = fs.assets_by_pointer[sprite_pointer]
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
      part = Part.new.from_data(part_data)
      @parts << part
      @parts_by_offset[offset-part_list_offset] = part
    end
    
    @hitboxes = []
    @hitboxes_by_offset = {}
    (hitbox_list_offset..frame_list_offset-1).step(8) do |offset|
      hitbox_data = fs.read_by_file(sprite_file[:file_path], offset, 8)
      hitbox = Hitbox.new.from_data(hitbox_data)
      @hitboxes << hitbox
      @hitboxes_by_offset[offset-hitbox_list_offset] = hitbox
    end
    
    @frames = []
    offset = frame_list_offset
    remaining_hitboxes = hitboxes.dup
    number_of_frames.times do
      frame_data = fs.read_by_file(sprite_file[:file_path], offset, 12)
      frame = Frame.new.from_data(frame_data)
      frame.initialize_parts(parts, @parts_by_offset)
      frame.initialize_hitboxes_from_sprite_file(hitboxes, remaining_hitboxes)
      @frames << frame
      
      offset += 12
    end
    
    @frame_delays = []
    @frame_delays_by_offset = {}
    unless frame_delay_list_offset == 0
      (frame_delay_list_offset..animation_list_offset-1).step(8) do |offset|
        frame_delay_data = fs.read_by_file(sprite_file[:file_path], offset, 8)
        frame_delay = FrameDelay.new.from_data(frame_delay_data)
        @frame_delays << frame_delay
        @frame_delays_by_offset[offset-frame_delay_list_offset] = frame_delay
      end
    end
    
    @animations = []
    remaining_frame_delays = frame_delays.dup
    unless animation_list_offset == 0
      (animation_list_offset..file_footer_offset-1).step(8) do |offset|
        animation_data = fs.read_by_file(sprite_file[:file_path], offset, 8)
        animation = Animation.new.from_data(animation_data, offset)
        animation.initialize_frame_delays_from_sprite_file(frame_delays, remaining_frame_delays)
        @animations << animation
      end
    end
  end
  
  def read_from_rom_by_pointer(sprite_pointer)
    if SYSTEM == :nds
      @number_of_frames, @number_of_animations, @frame_list_offset, @animation_list_offset = fs.read(sprite_pointer, 12).unpack("vvVV")
    else
      @number_of_frames, @number_of_animations, @frame_list_offset, @first_animation_offset, @animation_list_offset = fs.read(sprite_pointer, 16).unpack("vvVVV")
    end
    
    @frames = []
    offset = frame_list_offset
    number_of_frames.times do
      frame_data = fs.read(offset, Frame.data_size)
      frame = Frame.new.from_data(frame_data)
      @frames << frame
      
      offset += Frame.data_size
    end
    
    @parts_by_offset = {}
    frames.each do |frame|
      offset = frame.first_part_offset
      frame.number_of_parts.times do
        part_data = fs.read(offset, Part.data_size)
        @parts_by_offset[offset] ||= Part.new.from_data(part_data)
        
        offset += Part.data_size
      end
    end
    @parts = @parts_by_offset.sort_by{|offset, part| offset}.map{|offset, part| part}
    
    @hitboxes_by_offset = {}
    frames.each do |frame|
      offset = frame.first_hitbox_offset
      frame.number_of_hitboxes.times do
        hitbox_data = fs.read(offset, Hitbox.data_size)
        @hitboxes_by_offset[offset] ||= Hitbox.new.from_data(hitbox_data)
        
        offset += Hitbox.data_size
      end
    end
    @hitboxes = @hitboxes_by_offset.sort_by{|offset, hitbox| offset}.map{|offset, hitbox| hitbox}
    
    @frames.each do |frame|
      frame.initialize_parts(parts, @parts_by_offset)
      frame.initialize_hitboxes_from_pointer(hitboxes, @hitboxes_by_offset)
    end
    
    @animations_by_offset = {}
    @animations = []
    @frame_delays_by_offset = {}
    @frame_delays = []
    if animation_list_offset && animation_list_offset != 0
      offset = animation_list_offset
      number_of_animations.times do
        if SYSTEM == :nds
          animation_data = fs.read(offset, Animation.data_size)
          animation = Animation.new.from_data(animation_data, offset)
          @animations_by_offset[offset] = animation
        else
          animation_pointer = fs.read(offset, 4).unpack("V").first
          animation_data = fs.read(animation_pointer, Animation.data_size)
          animation = Animation.new.from_data(animation_data, animation_pointer)
          @animations_by_offset[animation_pointer] = animation
        end
        
        @animations << animation
        
        offset += Animation.data_size
      end
      
      animations.each do |animation|
        offset = animation.first_frame_delay_offset
        animation.number_of_frames.times do
          frame_delay_data = fs.read(offset, FrameDelay.data_size)
          frame_delay = FrameDelay.new.from_data(frame_delay_data)
          @frame_delays_by_offset[offset] ||= frame_delay
          @frame_delays << frame_delay
          
          offset += FrameDelay.data_size
        end
      end
    end
    
    @animations.each do |animation|
      animation.initialize_frame_delays_from_pointer(frame_delays, @frame_delays_by_offset)
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
      frame.number_of_parts = frame.parts.length
      frame.number_of_hitboxes = frame.hitboxes.length
      
      if frame.parts.length == 0
        frame.first_part_offset = 0
      else
        first_part = frame.parts[0]
        first_part_index = @parts.index(first_part)
        frame.first_part_offset = first_part_index*Part.data_size
      end
      if frame.hitboxes.length == 0
        frame.first_hitbox_offset = 0
      else
        first_hitbox = frame.hitboxes[0]
        first_hitbox_index = @hitboxes.index(first_hitbox)
        frame.first_hitbox_offset = first_hitbox_index*Hitbox.data_size
      end
      
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
      animation.number_of_frames = animation.frame_delays.length
      
      if animation.frame_delays.length == 0
        animation.first_frame_delay_offset = 0
      else
        first_frame_delay = animation.frame_delays[0]
        first_frame_delay_index = @frame_delays.index(first_frame_delay)
        animation.first_frame_delay_offset = first_frame_delay_index*FrameDelay.data_size
      end
      
      new_data << animation.to_data
      offset += 8
    end
    
    new_file_size = new_data.length
    new_file_size += 0x14 # Footer size.
    
    padding = ""
    if new_file_size % 0x10 != 0
      amount_to_pad = 0x10 - (new_file_size % 0x10)
      padding = "\0"*amount_to_pad
      new_file_size += amount_to_pad
    end
    
    file_footer_offset = offset
    file_footer = [
      @number_of_frames,
      @number_of_animations,
      new_file_size,
      new_file_size,
      0,
      0
    ].pack("vvVVVV")
    new_data << file_footer
    
    new_data << padding
    
    new_data[0, 0x30] = [
      0xBEEFF00D,
      @part_list_offset,
      @hitbox_list_offset,
      @frame_list_offset,
      @frame_delay_list_offset,
      @animation_list_offset,
      0,
      0,
      file_footer_offset,
      @number_of_frames,
      @number_of_animations,
      new_file_size,
    ].pack("V*")
    
    fs.overwrite_file(sprite_file[:file_path], new_data)
  end
  
  def write_to_rom_by_pointer
    if @animations_by_offset.values != @animations || (SYSTEM == :gba && @frame_delays_by_offset.values != @frame_delays)
      # If animations were added/removed, we need to free the space used by the original animations, then get new free space for the new parts.
      # On GBA, frame delays are stored with their animation, so we also need to move the animations to free space even if only their frame delays were changed.
      @animations_by_offset.each do |offset, anim|
        fs.free_unused_space(offset, Animation.data_size)
      end
      @animations_by_offset = {}
      
      if SYSTEM == :gba
        @frame_delays_by_offset.each do |offset, frame_delay|
          fs.free_unused_space(offset, FrameDelay.data_size)
        end
        @frame_delays_by_offset = {}
        
        if @animations_by_offset.length > 0
          fs.free_unused_space(@animation_list_offset, @animations_by_offset.length*4)
        end
      end
      
      if @animations.length > 0
        if SYSTEM == :gba
          @animations.each do |anim|
            anim_offset = fs.get_free_space(Animation.data_size + anim.frame_delays.length*FrameDelay.data_size, nil)
            @animations_by_offset[anim_offset] = anim
            offset = anim_offset+Animation.data_size
            @frame_delays.each do |frame_delay|
              @frame_delays_by_offset[offset] = frame_delay
              offset += FrameDelay.data_size
            end
          end
          
          @animation_list_offset = fs.get_free_space(@animations.length*4, nil)
        else
          anim_list_offset = fs.get_free_space(@animations.length*Animation.data_size, nil)
          offset = anim_list_offset
          @animations.each do |anim|
            @animations_by_offset[offset] = anim
            offset += Animation.data_size
          end
          
          first_anim = @animations[0]
          first_anim_offset = @animations_by_offset.invert[first_anim]
          @animation_list_offset = first_anim_offset
        end
      else
        # The number of animations is now 0, so get rid of the animation list pointer.
        @animation_list_offset = 0
      end
    end
    
    if @parts_by_offset.values != @parts
      # If parts were added/removed, we need to free the space used by the original parts, then get new free space for the new parts.
      @parts_by_offset.each do |offset, part|
        fs.free_unused_space(offset, Part.data_size)
      end
      @parts_by_offset = {}
      if @parts.length > 0
        part_list_offset = fs.get_free_space(@parts.length*Part.data_size, nil)
        offset = part_list_offset
        @parts.each do |part|
          @parts_by_offset[offset] = part
          offset += Part.data_size
        end
      end
    end
    
    @parts_by_offset.each do |offset, part|
      fs.write(offset, part.to_data)
    end
    
    if @hitboxes_by_offset.values != @hitboxes
      # If hitboxes were added/removed, we need to free the space used by the original hitboxes, then get new free space for the new hitboxes.
      @hitboxes_by_offset.each do |offset, hitbox|
        fs.free_unused_space(offset, Hitbox.data_size)
      end
      @hitboxes_by_offset = {}
      if @hitboxes.length > 0
        hitbox_list_offset = fs.get_free_space(@hitboxes.length*Hitbox.data_size, nil)
        offset = hitbox_list_offset
        @hitboxes.each do |hitbox|
          @hitboxes_by_offset[offset] = hitbox
          offset += Hitbox.data_size
        end
      end
    end
    
    @hitboxes_by_offset.each do |offset, hitbox|
      fs.write(offset, hitbox.to_data)
    end
    
    offset = @frame_list_offset
    @number_of_frames = @frames.length
    @frames.each do |frame|
      frame.number_of_parts = frame.parts.length
      frame.number_of_hitboxes = frame.hitboxes.length
      
      if frame.parts.length == 0
        frame.first_part_offset = 0
      else
        first_part = frame.parts[0]
        frame.first_part_offset = @parts_by_offset.invert[first_part]
      end
      if frame.hitboxes.length == 0
        frame.first_hitbox_offset = 0
      else
        first_hitbox = frame.hitboxes[0]
        frame.first_hitbox_offset = @hitboxes_by_offset.invert[first_hitbox]
      end
      
      fs.write(offset, frame.to_data)
      offset += Frame.data_size
    end
    
    if @frame_delays_by_offset.values != @frame_delays && SYSTEM == :nds
      # If frame delays were added/removed, we need to free the space used by the original frame delays, then get new free space for the new frame delays.
      # (This code is only run for NDS because GBA frame delays are stored together with the animation, so they're handled above with animations.)
      @frame_delays_by_offset.each do |offset, frame_delay|
        fs.free_unused_space(offset, FrameDelay.data_size)
      end
      @frame_delays_by_offset = {}
      if @frame_delays.length > 0
        frame_delay_list_offset = fs.get_free_space(@frame_delays.length*FrameDelay.data_size, nil)
        offset = frame_delay_list_offset
        @frame_delays.each do |frame_delay|
          @frame_delays_by_offset[offset] = frame_delay
          offset += FrameDelay.data_size
        end
      end
    end
    
    @frame_delays_by_offset.each do |offset, frame_delay|
      fs.write(offset, frame_delay.to_data)
    end
    
    offset = @animation_list_offset
    @number_of_animations = @animations.length
    @animations.each do |animation|
      animation.number_of_frames = animation.frame_delays.length
      
      if animation.frame_delays.length == 0
        animation.first_frame_delay_offset = 0
      else
        first_frame_delay = animation.frame_delays[0]
        animation.first_frame_delay_offset = @frame_delays_by_offset.invert[first_frame_delay]
      end
      
      if SYSTEM == :gba
        anim_pointer = @animations_by_offset.invert[animation]
        fs.write(anim_pointer, animation.to_data)
        fs.write(offset, [anim_pointer].pack("V"))
        offset += 4
      else
        fs.write(offset, animation.to_data)
        offset += Animation.data_size
      end
      
      if SYSTEM == :gba
        # On GBA the frame delays come right after the animation itself, rather than being pointed to separately.
        offset += FrameDelay.data_size*animation.number_of_frames
      end
    end
    
    if SYSTEM == :gba
      if @animations.length == 0
        # If the sprite has no animations, this pointer just points back to the sprite header.
        @first_animation_offset = @sprite_pointer
      else
        first_anim = @animations[0]
        @first_animation_offset = @animations_by_offset.invert[first_anim]
      end
    end
    
    if SYSTEM == :nds
      header_data = [
        @number_of_frames,
        @number_of_animations,
        @frame_list_offset,
        @animation_list_offset,
      ].pack("vvVV")
      fs.write(sprite_pointer, header_data)
    else
      header_data = [
        @number_of_frames,
        @number_of_animations,
        @frame_list_offset,
        @first_animation_offset,
        @animation_list_offset,
      ].pack("vvVVV")
      fs.write(sprite_pointer, header_data)
    end
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
  
  def get_unique_parts_by_index
    grouped_parts = self.parts.group_by do |part|
      [
        #part.x_pos,
        #part.y_pos,
        part.gfx_x_offset,
        part.gfx_y_offset,
        part.width,
        part.height,
        part.gfx_page_index,
        part.palette_index,
        #part.vertical_flip,
        #part.horizontal_flip
      ]
    end
    
    unique_parts_by_index = {}
    grouped_parts.each do |data, similar_parts|
      similar_parts.each do |part|
        part_index = self.parts.index(part)
        unique_parts_by_index[part_index] = {
          unique_part: similar_parts.first,
          x_pos: part.x_pos,
          y_pos: part.y_pos,
          vertical_flip: part.vertical_flip,
          horizontal_flip: part.horizontal_flip,
        }
      end
    end
    
    return unique_parts_by_index
  end
  
  def get_unique_hitboxes_by_index
    grouped_hitboxes = self.hitboxes.group_by do |hitbox|
      [
        #hitbox.x_pos,
        #hitbox.y_pos,
        hitbox.width,
        hitbox.height
      ]
    end
    
    unique_hitboxes_by_index = {}
    grouped_hitboxes.each do |data, similar_hitboxes|
      similar_hitboxes.each do |hitbox|
        hitbox_index = self.hitboxes.index(hitbox)
        unique_hitboxes_by_index[hitbox_index] = {
          unique_hitbox: similar_hitboxes.first,
          x_pos: hitbox.x_pos,
          y_pos: hitbox.y_pos,
        }
      end
    end
    
    return unique_hitboxes_by_index
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
                :unused,
                :object_size,
                :object_shape
  
  OBJ_SIZES = {
    0 => [[8, 8], [16, 16], [32, 32], [64, 64]], # Square
    1 => [[16, 8], [32, 8], [32, 16], [64, 32]], # Horizontal
    2 => [[8, 16], [8, 32], [16, 32], [32, 64]], # Vertical
  }
  
  def initialize
    @x_pos = @y_pos =
        @gfx_x_offset = @gfx_y_offset =
        @width = @height =
        @gfx_page_index =
        @palette_index = @unused = 0
    @vertical_flip = false
    @horizontal_flip = false
    if SYSTEM == :gba
      @unknown = @object_size_and_shape = 0
    end
  end
  
  def from_data(part_data)
    if SYSTEM == :nds
      @x_pos, @y_pos,
        @gfx_x_offset, @gfx_y_offset,
        @width, @height,
        @gfx_page_index, flip_bits,
        @palette_index, @unused = part_data.unpack("s<s<vvvvCCCC")
      
      @vertical_flip   = (flip_bits & 0b00000001) > 0
      @horizontal_flip = (flip_bits & 0b00000010) > 0
    else
      @x_pos, @y_pos,
        @unknown, @gfx_x_offset, @gfx_y_offset,
        @width, @height,
        object_size_and_shape, @gfx_page_index,
        flip_bits, @unused = part_data.unpack("ccvCCCCCCCC")
      
      @palette_index = 0
      
      @object_size  = (object_size_and_shape & 0x30) >> 4
      @object_shape =  object_size_and_shape & 0x03
      size = OBJ_SIZES[@object_shape][@object_size]
      if size != [@width, @height]
        puts "Warning: Read a GBA part with an object size that does not match its actual size. This part will not display correctly ingame. Actual size: #{@width}x#{@height}, object size: #{size[0]}x#{size[1]}"
      end
      
      @vertical_flip   = (flip_bits & 0b00000001) > 0
      @horizontal_flip = (flip_bits & 0b00000010) > 0
    end
    
    return self
  end
  
  def to_data
    flip_bits = 0
    flip_bits |= 0b00000001 if @vertical_flip
    flip_bits |= 0b00000010 if @horizontal_flip
    
    if SYSTEM == :nds
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
    else # GBA
      @object_shape = nil
      @object_size = nil
      OBJ_SIZES.each do |obj_shape, possible_sizes|
        size_index = possible_sizes.index([@width, @height])
        if !size_index.nil?
          @object_shape = obj_shape
          @object_size = size_index
          break
        end
      end
      if @object_shape.nil?
        valid_sizes_string = OBJ_SIZES.values.flatten(1).map{|w,h| "#{w}x#{h}"}.join(", ")
        raise Sprite::SaveError.new("Invalid size for a sprite part on GBA: #{@width}x#{@height}\nValid sizes are: #{valid_sizes_string}")
      end
      object_size_and_shape = ((@object_size&3) << 4) | (@object_shape&3)
      
      [
        @x_pos,
        @y_pos,
        @unknown,
        @gfx_x_offset,
        @gfx_y_offset,
        @width,
        @height,
        object_size_and_shape,
        @gfx_page_index,
        flip_bits,
        @unused
      ].pack("ccvCCCCCCCC")
    end
  end
  
  def self.data_size
    if SYSTEM == :nds
      16
    else
      12
    end
  end
end

class Hitbox
  attr_accessor :x_pos,
                :y_pos,
                :width,
                :height
  
  def initialize
    @x_pos = @y_pos = @width = @height = 0
  end
  
  def from_data(hitbox_data)
    if SYSTEM == :nds
      @x_pos, @y_pos, @width, @height = hitbox_data.unpack("s<s<vv")
    else
      @x_pos, @y_pos, @width, @height = hitbox_data.unpack("ccCC")
    end
    
    return self
  end
  
  def to_data
    if SYSTEM == :nds
      [@x_pos, @y_pos, @width, @height].pack("s<s<vv")
    else
      [@x_pos, @y_pos, @width, @height].pack("ccCC")
    end
  end
  
  def self.data_size
    if SYSTEM == :nds
      8
    else
      4
    end
  end
end

class Frame
  attr_reader :unknown,
              :part_indexes,
              :part_offsets,
              :parts,
              :hitbox_indexes,
              :hitbox_offsets,
              :hitboxes
  attr_accessor :number_of_parts,
                :first_part_offset,
                :number_of_hitboxes,
                :first_hitbox_offset
  
  def initialize
    @unknown = @number_of_hitboxes = @number_of_parts = @first_hitbox_offset = @first_part_offset = 0
    @parts = []
    @hitboxes = []
    if SYSTEM == :gba
      @unknown_2 = 0
    end
  end
  
  def from_data(frame_data)
    if SYSTEM == :nds
      @unknown, @number_of_hitboxes, @number_of_parts, @first_hitbox_offset, @first_part_offset = frame_data.unpack("vCCVV")
    elsif GAME == "aos"
      @unknown, @number_of_hitboxes, @number_of_parts, @unknown_2, @first_hitbox_offset, @first_part_offset = frame_data.unpack("VCCvVV")
    else # hod
      @unk1, @unk2, @unk3, @number_of_parts, @unk5, @first_part_offset = frame_data.unpack("ccvvvV")
      @number_of_hitboxes = 0
      @first_hitbox_offset = 0
    end
    
    return self
  end
  
  def initialize_parts(all_sprite_parts, all_sprite_parts_by_offset)
    @part_offsets = (@first_part_offset..@first_part_offset+@number_of_parts*Part.data_size-1).step(Part.data_size).to_a
    @parts = @part_offsets.map{|offset| all_sprite_parts_by_offset[offset]}
    @part_indexes = @parts.map{|part| all_sprite_parts.index(part)}
  end
  
  def initialize_hitboxes_from_sprite_file(all_sprite_hitboxes, all_remaining_sprite_hitboxes)
    if all_remaining_sprite_hitboxes.length < number_of_hitboxes
      raise "Not enough hitboxes left"
    end
    @hitboxes = all_remaining_sprite_hitboxes.shift(number_of_hitboxes)
    @hitbox_indexes = @hitboxes.map{|hitbox| all_sprite_hitboxes.index(hitbox)}
  end
  
  def initialize_hitboxes_from_pointer(all_sprite_hitboxes, all_sprite_hitboxes_by_offset)
    @hitbox_offsets = (@first_hitbox_offset..@first_hitbox_offset+@number_of_hitboxes*Hitbox.data_size-1).step(Hitbox.data_size).to_a
    @hitboxes = @hitbox_offsets.map{|offset| all_sprite_hitboxes_by_offset[offset]}
    if @hitboxes.include?(nil)
      raise "Couldn't find hitboxes"
    end
    @hitbox_indexes = @hitboxes.map{|hitbox| all_sprite_hitboxes.index(hitbox)}
  end
  
  def to_data
    if SYSTEM == :nds
      [
        @unknown,
        @number_of_hitboxes,
        @number_of_parts,
        @first_hitbox_offset,
        @first_part_offset
      ].pack("vCCVV")
    elsif GAME == "aos"
      [
        @unknown,
        @number_of_hitboxes,
        @number_of_parts,
        @unknown_2,
        @first_hitbox_offset,
        @first_part_offset
      ].pack("VCCvVV")
    else # hod
      [
        @unk1,
        @unk2,
        @unk3,
        @number_of_parts,
        @unk5,
        @first_part_offset
      ].pack("ccvvvV")
    end
  end
  
  def self.data_size
    if SYSTEM == :nds
      12
    elsif GAME == "aos"
      16
    else # hod
      12
    end
  end
end

class FrameDelay
  attr_accessor :frame_index,
                :delay,
                :unknown
  
  def initialize
    @frame_index = @delay = @unknown = 0
  end
  
  def from_data(frame_delay_data)
    if SYSTEM == :nds
      @frame_index, @delay, @unknown = frame_delay_data.unpack("vvV")
    else
      @frame_index, @delay, @unknown = frame_delay_data.unpack("CCv")
    end
    
    return self
  end
  
  def to_data
    if SYSTEM == :nds
      [@frame_index, @delay, @unknown].pack("vvV")
    else
      [@frame_index, @delay, @unknown].pack("CCv")
    end
  end
  
  def self.data_size
    if SYSTEM == :nds
      8
    else
      4
    end
  end
end

class Animation
  attr_reader :frame_delay_indexes,
              :frame_delays
  attr_accessor :number_of_frames,
                :first_frame_delay_offset
  
  def initialize
    @number_of_frames = @first_frame_delay_offset = 0
    @frame_delays = []
    if SYSTEM == :gba
      @unknown_1 = 0
      @unknown_2 = 1
    end
  end
  
  def from_data(animation_data, offset=nil)
    if SYSTEM == :nds
      @number_of_frames, @first_frame_delay_offset = animation_data.unpack("VV")
    else
      @number_of_frames, @unknown_1, @unknown_2 = animation_data.unpack("CCv")
      @first_frame_delay_offset = offset + 4
    end
    
    return self
  end
  
  def initialize_frame_delays_from_sprite_file(all_frame_delays, all_remaining_frame_delays)
    if all_remaining_frame_delays.length < number_of_frames
      raise "Not enough frame delays left"
    end
    @frame_delays = all_remaining_frame_delays.shift(number_of_frames)
    @frame_delay_indexes = @frame_delays.map{|frame_delay| all_frame_delays.index(frame_delay)}
  end
  
  def initialize_frame_delays_from_pointer(all_frame_delays, all_frame_delays_by_offset)
    @frame_delay_offsets = (@first_frame_delay_offset..@first_frame_delay_offset+@number_of_frames*FrameDelay.data_size-1).step(FrameDelay.data_size).to_a
    @frame_delays = @frame_delay_offsets.map{|offset| all_frame_delays_by_offset[offset]}
    @frame_delay_indexes = @frame_delays.map{|frame_delay| all_frame_delays.index(frame_delay)}
  end
  
  def to_data
    if SYSTEM == :nds
      [@number_of_frames, @first_frame_delay_offset].pack("VV")
    else
      [@number_of_frames, @unknown_1, @unknown_2].pack("CCv")
    end
  end
  
  def self.data_size
    if SYSTEM == :nds
      8
    else
      4
    end
  end
end
