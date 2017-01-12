
require_relative 'ui_skeleton_editor'

class SkeletonEditorDialog < Qt::Dialog
  RED_PEN = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(224, 16, 16)), 2)
  
  attr_reader :game, :fs
  
  slots "pose_changed(int)"
  slots "toggle_show_skeleton(int)"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(parent, fs, skeleton_file, chunky_frames, min_x, min_y)
    super(parent, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    
    @skeleton = SpriteSkeleton.new(skeleton_file, fs)
    @chunky_frames = chunky_frames
    @min_x = min_x
    @min_y = min_y
    
    @ui = Ui_SkeletonEditor.new
    @ui.setup_ui(self)
    
    @skeleton_graphics_scene = Qt::GraphicsScene.new
    @ui.skeleton_graphics_view.setScene(@skeleton_graphics_scene)
    
    connect(@ui.pose_index, SIGNAL("activated(int)"), self, SLOT("pose_changed(int)"))
    connect(@ui.show_skeleton, SIGNAL("stateChanged(int)"), self, SLOT("toggle_show_skeleton(int)"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    self.show()
    
    self.load_skeleton()
  end
  
  def load_skeleton
    @ui.skeleton_file_name.text = @skeleton.skeleton_file
    
    @ui.pose_index.clear()
    @skeleton.poses.each_index do |i|
      @ui.pose_index.addItem("%02X" % i)
    end
    
    pose_changed(0)
  end
  
  def pose_changed(i)
    @current_pose_index = i
    @skeleton_graphics_scene.items.each do |item|
      @skeleton_graphics_scene.removeItem(item)
    end
    
    pose = @skeleton.poses[@current_pose_index]
    
    @skeleton.joints.each_with_index do |joint, joint_index|
      next if joint.parent_id == 0xFF
      
      joint_change = pose[joint_index]
      
      parent_joint = @skeleton.joints[joint.parent_id]
      parent_joint_change = pose[joint.parent_id]
      
      joint.x_pos = parent_joint.x_pos
      joint.y_pos = parent_joint.y_pos
      
      connected_rotation = parent_joint_change.rotation
      grandparent_id = parent_joint.parent_id
      if grandparent_id != 0xFF && parent_joint.copy_parent_visual_rotation
        connected_rotation += pose[grandparent_id].rotation
      end
      connected_rotation_in_degrees = connected_rotation/182.0
      
      offset_angle = connected_rotation_in_degrees
      offset_angle += 90 * joint.positional_rotation
      
      offset_angle_in_radians = offset_angle * Math::PI / 180
      
      joint.x_pos += joint_change.distance*Math.cos(offset_angle_in_radians)
      joint.y_pos += joint_change.distance*Math.sin(offset_angle_in_radians)
    end
    
    @skeleton.joint_indexes_by_draw_order.each do |joint_index|
      joint = @skeleton.joints[joint_index]
      joint_change = pose[joint_index]
      rotation = joint_change.rotation
      if joint.parent_id != 0xFF && joint.copy_parent_visual_rotation
        parent_joint_change = pose[joint.parent_id]
        rotation += parent_joint_change.rotation
      end
      rotation_in_degrees = rotation/182.0
      
      next if joint.frame_id == 0xFF
      
      if joint_change.new_frame_id == 0xFF
        frame_id = joint.frame_id
      else
        frame_id = joint_change.new_frame_id
      end
      chunky_image = @chunky_frames[frame_id]
      if joint.horizontal_flip
        chunky_image.mirror!
      end
      if joint.vertical_flip
        chunky_image.flip!
      end
      pixmap = Qt::Pixmap.new
      blob = chunky_image.to_blob
      pixmap.loadFromData(blob, blob.length)
      graphics_item = Qt::GraphicsPixmapItem.new(pixmap)
      graphics_item.setOffset(@min_x, @min_y)
      graphics_item.setPos(joint.x_pos, joint.y_pos)
      graphics_item.setRotation(rotation_in_degrees)
      @skeleton_graphics_scene.addItem(graphics_item)
      
      
      if @ui.show_skeleton.checked
        ellipse = @skeleton_graphics_scene.addEllipse(joint.x_pos-1, joint.y_pos-1, 3, 3, RED_PEN)
        ellipse.setZValue(1)
        if joint.parent_id != 0xFF
          parent_joint = @skeleton.joints[joint.parent_id]
          line = @skeleton_graphics_scene.addLine(joint.x_pos, joint.y_pos, parent_joint.x_pos, parent_joint.y_pos, RED_PEN)
          line.setZValue(1)
        end
      end
    end
    
    @ui.pose_index.setCurrentIndex(i)
  end
  
  def toggle_show_skeleton(checked)
    pose_changed(@current_pose_index)
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      
    end
  end
end
