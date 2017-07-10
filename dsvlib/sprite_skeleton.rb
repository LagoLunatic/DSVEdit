
class SpriteSkeleton
  attr_reader :fs,
              :skeleton_file,
              :number_of_joints,
              :number_of_invisible_joints,
              :number_of_visible_joints,
              :number_of_hitboxes,
              :number_of_poses,
              :number_of_unknown2,
              :number_of_animations,
              :joints,
              :poses,
              :hitboxes,
              :points,
              :joint_indexes_by_draw_order,
              :animations
  
  def initialize(skeleton_file, fs)
    @fs = fs
    @skeleton_file = skeleton_file[:file_path]
    
    read_from_rom()
  end
  
  def read_from_rom()
    @original_filename = fs.read_by_file(skeleton_file, 0x03, 0x1D)
    @x_offset, @y_offset = fs.read_by_file(skeleton_file, 0x22, 4).unpack("s<s<")
    @number_of_joints, @number_of_invisible_joints, @number_of_visible_joints,
      @number_of_hitboxes, @number_of_poses, @number_of_unknown2, @number_of_animations = fs.read_by_file(skeleton_file, 0x26, 7).unpack("C*")
    
    @joints = []
    offset = 0x30
    number_of_joints.times do
      joint_data = fs.read_by_file(skeleton_file, offset, 4)
      joint = Joint.new(joint_data, @joints)
      @joints << joint
      offset += 4
    end
    
    @poses = []
    number_of_poses.times do
      pose_data = fs.read_by_file(skeleton_file, offset, 2 + 4*number_of_joints)
      pose = Pose.new.from_pose_data(pose_data)
      @poses << pose
      offset += 2 + 4*number_of_joints
    end
    
    @hitboxes = []
    number_of_hitboxes.times do
      hitbox_data = fs.read_by_file(skeleton_file, offset, 8)
      @hitboxes << SkeletonHitbox.new(hitbox_data)
      offset += 8
    end
    
    @points = []
    number_of_unknown2.times do
      data = fs.read_by_file(skeleton_file, offset, 4)
      @points << SkeletonPoint.new(data)
      offset += 4
    end
    
    @joint_indexes_by_draw_order = fs.read_by_file(skeleton_file, offset, number_of_visible_joints).unpack("C*")
    offset += number_of_visible_joints
    
    @animations = []
    number_of_animations.times do
      num_keyframes = fs.read_by_file(skeleton_file, offset, 1).unpack("C").first
      offset += 1
      
      keyframes = []
      num_keyframes.times do
        keyframe_data = fs.read_by_file(skeleton_file, offset, 3)
        keyframes << SkeletonKeyframe.new(keyframe_data)
        offset += 3
      end
      
      @animations << SkeletonAnimation.new(keyframes)
    end
  end
  
  def write_to_rom_by_skeleton_file
    new_data = "\0\0\0"
    new_data << @original_filename
    new_data << [
      0, 0,
      @x_offset, @y_offset,
      @number_of_joints,
      @number_of_invisible_joints,
      @number_of_visible_joints,
      @number_of_hitboxes,
      @number_of_poses,
      @number_of_unknown2,
      @number_of_animations,
      0, 0, 0,
    ].pack("CCs<s<CCCCCCCCCC")
    
    offset = 0x30
    @joints.each do |joint|
      new_data << joint.to_data
      offset += 4
    end
    
    @poses.each do |pose|
      new_data << pose.to_data
      offset += 2 + 4*number_of_joints
    end
    
    @hitboxes.each do |hitbox|
      new_data << hitbox.to_data
      offset += 8
    end
    
    @points.each do |point|
      new_data << point.to_data
      offset += 4
    end
    
    new_data << @joint_indexes_by_draw_order.pack("C*")
    offset += number_of_visible_joints
    
    @animations.each do |animation|
      num_keyframes = animation.keyframes.length
      new_data << [num_keyframes].pack("C")
      offset += 1
      animation.keyframes.each do |keyframe|
        new_data << keyframe.to_data
        offset += 3
      end
    end
    
    new_file_size = new_data.length
    new_file_size += 0x14 # Footer size.
    
    padding = ""
    if new_file_size % 0x10 != 0
      amount_to_pad = 0x10 - (new_file_size % 0x10)
      padding = "\0"*amount_to_pad
      new_file_size += amount_to_pad
    end
    
    new_data << padding
    
    fs.overwrite_file(skeleton_file, new_data)
  end
end

class Joint
  attr_reader :parent_id,
              :frame_id,
              :bits,
              :palette,
              :parent
              
  def initialize(joint_data, all_joints)
    @parent_id, @frame_id, @bits, @palette = joint_data.unpack("CCCC")
    @parent = all_joints[@parent_id]
  end
  
  def positional_rotation
    @bits & 0x03
  end
  
  def copy_parent_visual_rotation
    @bits & 0x04 > 0
  end
  
  def horizontal_flip
    @bits & 0x08 > 0
  end
  
  def vertical_flip
    @bits & 0x10 > 0
  end
  
  def to_data
    [@parent_id, @frame_id, @bits, @palette].pack("CCCC")
  end
end

class Pose
  attr_accessor :x_offset,
                :y_offset,
                :joint_changes
                
  def initialize
    @x_offset = 0
    @y_offset = 0
    @joint_changes = []
  end
  
  def from_pose_data(pose_data)
    @x_offset, @y_offset = pose_data[0,2].unpack("CC")
    
    joint_changes_data = pose_data[2..-1]
    num_joints = joint_changes_data.size/4
    @joint_changes = []
    num_joints.times do |i|
      joint_change_data = joint_changes_data[i*4,4]
      joint_change = JointChange.new(joint_change_data)
      @joint_changes << joint_change
    end
    
    self
  end
  
  def to_data
    data = [@x_offset, @y_offset].pack("CC")
    
    joint_changes.each do |joint_change|
      data << joint_change.to_data
    end
    
    data
  end
end

class JointChange
  attr_reader :rotation,
              :distance,
              :new_frame_id
              
  def initialize(joint_data)
    @rotation, @distance, @new_frame_id = joint_data.unpack("vcC")
  end
  
  def to_data
    [@rotation, @distance, @new_frame_id].pack("vcC")
  end
end

class SkeletonHitbox
  attr_reader :rotation,
              :distance,
              :width,
              :height,
              :parent_joint_id,
              :bits,
              :unknown3
              
  def initialize(hitbox_data)
    @rotation, @distance, @width, @height, @parent_joint_id, @bits, @unknown3 = hitbox_data.unpack("vCCCCCC")
  end
  
  def can_damage_player
    @bits & 0x01 > 0
  end
  
  def can_take_damage
    @bits & 0x02 > 0
  end
  
  def to_data
    [
      @rotation,
      @distance,
      @width,
      @height,
      @parent_joint_id,
      @bits,
      @unknown3
    ].pack("vCCCCCC")
  end
end

class SkeletonPoint
  attr_reader :rotation,
              :distance,
              :parent_joint_id
              
  def initialize(point_data)
    @rotation, @distance, @parent_joint_id = point_data.unpack("vCC")
  end
  
  def to_data
    [@rotation, @distance, @parent_joint_id].pack("vCC")
  end
end

class SkeletonAnimation
  attr_reader :keyframes
  
  def initialize(keyframes)
    @keyframes = keyframes
  end
end

class SkeletonKeyframe
  attr_accessor :pose_id,
                :length_in_frames,
                :unknown
              
  def initialize(frame_data)
    @pose_id, @length_in_frames, @unknown = frame_data.unpack("CCC")
  end
  
  def to_data
    [@pose_id, @length_in_frames, @unknown].pack("CCC")
  end
end
