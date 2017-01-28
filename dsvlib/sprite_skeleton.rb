
class SpriteSkeleton
  attr_reader :fs,
              :skeleton_file,
              :joints,
              :poses,
              :hitboxes,
              :points,
              :joint_indexes_by_draw_order
  
  def initialize(skeleton_file, fs)
    @fs = fs
    @skeleton_file = skeleton_file[:file_path]
    
    read_from_rom()
  end
  
  def read_from_rom()
    number_of_joints, number_of_invisible_joints, number_of_visible_joints,
      number_of_hitboxes, number_of_poses, number_of_unknown2, number_of_animations = fs.read_by_file(skeleton_file, 0x26, 7).unpack("C*")
    
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
      offset += 2
      @poses << []
      @joints.length.times do
        joint_change_data = fs.read_by_file(skeleton_file, offset, 4)
        joint_change = JointChange.new(joint_change_data)
        @poses.last << joint_change
        offset += 4
      end
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
      num_frames = fs.read_by_file(skeleton_file, offset, 1).unpack("C").first
      offset += 1
      
      frames = []
      num_frames.times do
        frame_data = fs.read_by_file(skeleton_file, offset, 3)
        frames << SkeletonFrame.new(frame_data)
        offset += 3
      end
      
      @animations << SkeletonAnimation.new(frames)
    end
  end
end

class Joint
  attr_reader :parent_id,
              :frame_id,
              :bits,
              :palette,
              :parent
  attr_accessor :x_pos,
                :y_pos,
                :total_rotation
              
  def initialize(joint_data, all_joints)
    @parent_id, @frame_id, @bits, @palette = joint_data.unpack("CCCC")
    if parent_id == 0xFF
      @x_pos = 0
      @y_pos = 0
      @total_rotation = 0
    else
      @parent = all_joints[@parent_id]
    end
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
end

class JointChange
  attr_reader :rotation,
              :distance,
              :new_frame_id
              
  def initialize(joint_data)
    @rotation, @distance, @new_frame_id = joint_data.unpack("vcC")
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
end

class SkeletonPoint
  attr_reader :rotation,
              :distance,
              :parent_joint_id
              
  def initialize(point_data)
    @rotation, @distance, @parent_joint_id = point_data.unpack("vCC")
  end
end

class SkeletonAnimation
  attr_reader :frames
  
  def initialize(frames)
    @frames = frames
  end
end

class SkeletonFrame
  attr_reader :pose_id,
              :length_in_frames,
              :unknown
              
  def initialize(frame_data)
    @pose_id, @length_in_frames, @unknown = frame_data.unpack("CCC")
  end
end
