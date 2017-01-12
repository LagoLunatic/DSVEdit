
class SpriteSkeleton
  attr_reader :fs,
              :skeleton_file,
              :joints,
              :poses,
              :joint_indexes_by_draw_order
  
  def initialize(skeleton_file, fs)
    @fs = fs
    @skeleton_file = skeleton_file[:file_path]
    
    read_from_rom()
  end
  
  def read_from_rom()
    number_of_joints, number_of_invisible_joints, number_of_visible_joints,
      number_of_unknown, number_of_joint_animations, number_of_unknown2 = fs.read_by_file(skeleton_file, 0x26, 6).unpack("C*")
    
    p ["number_of_joints, number_of_invisible_joints, number_of_visible_joints, number_of_unknown, number_of_joint_animations, number_of_unknown2:", number_of_joints, number_of_invisible_joints, number_of_visible_joints, number_of_unknown, number_of_joint_animations, number_of_unknown2]
    
    @joints = []
    offset = 0x30
    number_of_joints.times do
      joint_data = fs.read_by_file(skeleton_file, offset, 4)
      joint = Joint.new(joint_data, @joints)
      @joints << joint
      offset += 4
    end
    puts joints.last.frame_id
    
    @poses = []
    number_of_joint_animations.times do
      offset += 2
      puts "%08X" % offset
      @poses << []
      @joints.length.times do
        joint_change_data = fs.read_by_file(skeleton_file, offset, 4)
        joint_change = JointChange.new(joint_change_data)
        @poses.last << joint_change
        offset += 4
      end
    end
    
    @unknown = []
    number_of_unknown.times do
      data = fs.read_by_file(skeleton_file, offset, 8)
      @unknown << data.unpack("C*")
      offset += 8
    end
    p @unknown
    
    @unknown2 = []
    number_of_unknown2.times do
      data = fs.read_by_file(skeleton_file, offset, 4)
      @unknown2 << data.unpack("C*")
      offset += 4
    end
    p @unknown2
    
    @joint_indexes_by_draw_order = fs.read_by_file(skeleton_file, offset, number_of_visible_joints).unpack("C*")
  end
end

class Joint
  attr_reader :parent_id,
              :frame_id,
              :bits,
              :palette,
              :parent
  attr_accessor :x_pos,
                :y_pos
              
  def initialize(joint_data, all_joints)
    @parent_id, @frame_id, @bits, @palette = joint_data.unpack("CCCC")
    if parent_id == 0xFF
      @x_pos = 0
      @y_pos = 0
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
