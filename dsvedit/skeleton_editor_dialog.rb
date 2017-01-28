
require_relative 'ui_skeleton_editor'

class SkeletonEditorDialog < Qt::Dialog
  GREY_PEN = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(128, 128, 128)), 2)
  RED_PEN = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(224, 16, 16)), 2)
  GREEN_PEN = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(16, 224, 16)), 2)
  BLUE_PEN = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(16, 16, 224)), 2)
  WHITE_PEN = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(255, 255, 255)), 2)
  
  attr_reader :game, :fs
  
  slots "pose_changed(int)"
  slots "toggle_show_skeleton(int)"
  slots "toggle_show_hitboxes(int)"
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
    connect(@ui.show_hitboxes, SIGNAL("stateChanged(int)"), self, SLOT("toggle_show_hitboxes(int)"))
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
      joint.total_rotation = parent_joint_change.rotation
      
      if parent_joint.copy_parent_visual_rotation && parent_joint.parent_id != 0xFF
        joint.total_rotation += parent_joint.total_rotation
      end
      connected_rotation_in_degrees = joint.total_rotation/182.0
      
      offset_angle = connected_rotation_in_degrees
      offset_angle += 90 * joint.positional_rotation
      
      offset_angle_in_radians = offset_angle * Math::PI / 180
      
      joint.x_pos += joint_change.distance*Math.cos(offset_angle_in_radians)
      joint.y_pos += joint_change.distance*Math.sin(offset_angle_in_radians)
    end
    
    @skeleton.joint_indexes_by_draw_order.each do |joint_index|
      joint = @skeleton.joints[joint_index]
      joint_change = pose[joint_index]
      
      next if joint.frame_id == 0xFF
      
      rotation = joint_change.rotation
      if joint.parent_id != 0xFF && joint.copy_parent_visual_rotation
        rotation += joint.total_rotation
      end
      rotation_in_degrees = rotation/182.0
      
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
        ellipse = @skeleton_graphics_scene.addEllipse(joint.x_pos-1, joint.y_pos-1, 3, 3, GREY_PEN)
        ellipse.setZValue(1)
        if joint.parent_id != 0xFF
          parent_joint = @skeleton.joints[joint.parent_id]
          line = @skeleton_graphics_scene.addLine(joint.x_pos, joint.y_pos, parent_joint.x_pos, parent_joint.y_pos, GREY_PEN)
          line.setZValue(1)
        end
      end
      
      if @ui.show_hitboxes.checked
        @skeleton.hitboxes.select{|hitbox| hitbox.parent_joint_id == joint_index}.each do |hitbox|
          x_pos = joint.x_pos-hitbox.width/2
          y_pos = joint.y_pos-hitbox.height/2
          
          offset_angle = joint_change.rotation/182.0 + 90
          offset_angle_in_radians = offset_angle * Math::PI / 180
          x_pos += hitbox.distance*Math.cos(offset_angle_in_radians)
          y_pos += hitbox.distance*Math.sin(offset_angle_in_radians)
          
          hitbox_item = Qt::GraphicsRectItem.new
          if hitbox.can_damage_player && hitbox.can_take_damage
            hitbox_item.setPen(RED_PEN)
          elsif hitbox.can_damage_player
            hitbox_item.setPen(BLUE_PEN)
          elsif hitbox.can_take_damage
            hitbox_item.setPen(GREEN_PEN)
          else
            hitbox_item.setPen(WHITE_PEN)
          end
          hitbox_item.setRect(x_pos, y_pos, hitbox.width, hitbox.height)
          hitbox_item.setTransformOriginPoint(hitbox_item.rect.center)
          rotation_in_degrees = hitbox.rotation/182.0
          hitbox_item.setRotation(rotation_in_degrees)
          hitbox_item.setZValue(1)
          @skeleton_graphics_scene.addItem(hitbox_item)
        end
      end
    end
    
    @ui.pose_index.setCurrentIndex(i)
  end
  
  def toggle_show_skeleton(checked)
    pose_changed(@current_pose_index)
  end
  
  def toggle_show_hitboxes(checked)
    pose_changed(@current_pose_index)
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      
    end
  end
end
