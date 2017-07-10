
require_relative 'ui_skeleton_editor'

class SkeletonEditorDialog < Qt::Dialog
  GREY_PEN = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(128, 128, 128)), 2)
  RED_PEN = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(224, 16, 16)), 2)
  GREEN_PEN = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(16, 224, 16)), 2)
  BLUE_PEN = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(16, 16, 224)), 2)
  WHITE_PEN = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(255, 255, 255)), 2)
  
  attr_reader :game, :fs
  
  slots "pose_changed_no_tween(int)"
  slots "toggle_show_skeleton(int)"
  slots "toggle_show_hitboxes(int)"
  slots "toggle_show_points(int)"
  slots "animation_changed(int)"
  slots "animation_keyframe_changed_no_tween(int)"
  slots "toggle_animation_paused()"
  slots "advance_tweenframe()"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(parent, sprite_info, fs, renderer)
    super(parent, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    
    
    @sprite_info = sprite_info
    @fs = fs
    @renderer = renderer
    
    @ui = Ui_SkeletonEditor.new
    @ui.setup_ui(self)
    
    @skeleton_graphics_scene = Qt::GraphicsScene.new
    @ui.skeleton_graphics_view.setScene(@skeleton_graphics_scene)
    
    @animation_timer = Qt::Timer.new()
    @animation_timer.setSingleShot(true)
    connect(@animation_timer, SIGNAL("timeout()"), self, SLOT("advance_tweenframe()"))
    
    set_animation_paused(true)
    
    connect(@ui.pose_index, SIGNAL("activated(int)"), self, SLOT("pose_changed_no_tween(int)"))
    connect(@ui.show_skeleton, SIGNAL("stateChanged(int)"), self, SLOT("toggle_show_skeleton(int)"))
    connect(@ui.show_hitboxes, SIGNAL("stateChanged(int)"), self, SLOT("toggle_show_hitboxes(int)"))
    connect(@ui.show_points, SIGNAL("stateChanged(int)"), self, SLOT("toggle_show_points(int)"))
    connect(@ui.animation_index, SIGNAL("activated(int)"), self, SLOT("animation_changed(int)"))
    connect(@ui.seek_slider, SIGNAL("valueChanged(int)"), self, SLOT("animation_keyframe_changed_no_tween(int)"))
    connect(@ui.toggle_paused_button, SIGNAL("clicked()"), self, SLOT("toggle_animation_paused()"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    self.show()
    
    self.load_skeleton()
  end
  
  def load_skeleton
    @skeleton = SpriteSkeleton.new(@sprite_info.skeleton_file, @fs)
    
    chunky_frames, @min_x, @min_y, _, _, _, _, _ = @renderer.render_sprite(@sprite_info)
    @pixmap_frames = chunky_frames.map do |chunky_image|
      pixmap = Qt::Pixmap.new
      blob = chunky_image.to_blob
      pixmap.loadFromData(blob, blob.length)
      pixmap
    end
    
    @ui.skeleton_file_name.text = @skeleton.skeleton_file
    
    @ui.pose_index.clear()
    @skeleton.poses.each_index do |i|
      @ui.pose_index.addItem("%02X" % i)
    end
    
    pose_changed(0)
    
    @ui.animation_index.clear()
    @skeleton.animations.each_with_index do |animation, i|
      @ui.animation_index.addItem("%02X" % i)
    end
    animation_changed(0)
  end
  
  def pose_changed_no_tween(i)
    @current_pose_index = i
    pose = @skeleton.poses[@current_pose_index]
    @current_pose_joint_states = initialize_joint_states(pose)
    @tweening_progress = 0.0
    @previous_pose = nil
    
    update_drawn_joints()
    
    @ui.pose_index.setCurrentIndex(i)
  end
  
  def pose_changed(i)
    if @current_pose_joint_states
      @previous_pose = @skeleton.poses[@current_pose_index]
      @previous_pose_joint_state = @current_pose_joint_states
      
      @current_pose_index = i
      pose = @skeleton.poses[@current_pose_index]
      
      @current_pose_joint_states = initialize_joint_states(pose)
      @tweening_progress = 0.0
    else
      @current_pose_index = i
      pose = @skeleton.poses[@current_pose_index]
      
      @current_pose_joint_states = initialize_joint_states(pose)
      @previous_pose_joint_state = @current_pose_joint_states
      @previous_pose = @skeleton.poses[@current_pose_index]
      @tweening_progress = 0.0
    end
    
    update_drawn_joints()
    
    @ui.pose_index.setCurrentIndex(i)
  end
  
  def animation_changed(i)
    @current_animation_index = i
    
    @animation_timer.stop()
    @ui.seek_slider.value = 0
    @current_animation_keyframe_index = 0
    
    @current_animation = @skeleton.animations[@current_animation_index]
    if @current_animation.nil?
      @ui.seek_slider.enabled = false
      @ui.toggle_paused_button.enabled = false
      return
    end
    
    @ui.seek_slider.enabled = true
    @ui.seek_slider.minimum = 0
    @ui.seek_slider.maximum = @current_animation.keyframes.length-1
    @ui.toggle_paused_button.enabled = true
    
    if @current_animation.keyframes.length > 0
      animation_keyframe_changed(0)
      start_animation()
    else
      # Animation with no keyframes
    end
  end
  
  def initialize_joint_states(pose)
    joint_states_for_pose = []
    
    @skeleton.joints.each_with_index do |joint, joint_index|
      joint_change = pose.joint_changes[joint_index]
      joint_state = JointState.new
      joint_states_for_pose << joint_state
      
      if joint.parent_id == 0xFF
        joint_state.x_pos = 0
        joint_state.y_pos = 0
        joint_state.inherited_rotation = 0
        next
      end
      
      parent_joint = @skeleton.joints[joint.parent_id]
      parent_joint_change = pose.joint_changes[joint.parent_id]
      parent_joint_state = joint_states_for_pose[joint.parent_id]
      
      joint_state.x_pos = parent_joint_state.x_pos
      joint_state.y_pos = parent_joint_state.y_pos
      joint_state.inherited_rotation = parent_joint_change.rotation
      
      if parent_joint.copy_parent_visual_rotation && parent_joint.parent_id != 0xFF
        joint_state.inherited_rotation += parent_joint_state.inherited_rotation
      end
      connected_rotation_in_degrees = joint_state.inherited_rotation / 182.0
      
      offset_angle = connected_rotation_in_degrees
      offset_angle += 90 * joint.positional_rotation
      
      offset_angle_in_radians = offset_angle * Math::PI / 180
      
      joint_state.x_pos += joint_change.distance*Math.cos(offset_angle_in_radians)
      joint_state.y_pos += joint_change.distance*Math.sin(offset_angle_in_radians)
    end
    
    joint_states_for_pose
  end
  
  def tween_poses(previous_pose, next_pose, tweening_progress)
    tweened_pose = Pose.new
    previous_pose.joint_changes.each_with_index do |prev_joint_change, joint_index|
      next_joint_change = next_pose.joint_changes[joint_index]
      
      prev_multiplier = 1.0 - tweening_progress
      next_multiplier = tweening_progress
      tweened_rotation = merge_two_angles(prev_joint_change.rotation, next_joint_change.rotation, prev_multiplier, next_multiplier)
      tweened_distance = prev_joint_change.distance*prev_multiplier + next_joint_change.distance*next_multiplier
      tweened_joint_change_data = [tweened_rotation, tweened_distance, prev_joint_change.new_frame_id].pack("vcC")
      tweened_joint_change = JointChange.new(tweened_joint_change_data)
      
      tweened_pose.joint_changes << tweened_joint_change
    end
    
    tweened_states = initialize_joint_states(tweened_pose)
    
    return [tweened_states, tweened_pose]
  end
  
  def merge_two_angles(a, b, a_multiplier, b_multiplier)
    if b - a >= 0x8000
      b -= 0x10000
    elsif a - b >= 0x8000
      a -= 0x10000
    end
    
    a*a_multiplier + b*b_multiplier
  end
  
  def animation_keyframe_changed(i)
    @current_animation_keyframe_index = i
    @current_animation_tweenframe_index = 0
    @current_keyframe = @current_animation.keyframes[@current_animation_keyframe_index]
    pose_changed(@current_keyframe.pose_id)
    animation_tweenframe_changed(0)
    @ui.seek_slider.value = @current_animation_keyframe_index
    
    millisecond_delay = (1 / 60.0 * 1000).round
    @animation_timer.start(millisecond_delay)
  end
  
  def animation_keyframe_changed_no_tween(i, force=false)
    return if i == @current_animation_keyframe_index && @ui.seek_slider.value == @current_animation_keyframe_index && !force
    
    @current_animation_keyframe_index = i
    @current_animation_tweenframe_index = 0
    @current_keyframe = @current_animation.keyframes[@current_animation_keyframe_index]
    pose_changed_no_tween(@current_keyframe.pose_id)
    animation_tweenframe_changed(0)
    @ui.seek_slider.value = @current_animation_keyframe_index
    
    millisecond_delay = (1 / 60.0 * 1000).round
    @animation_timer.start(millisecond_delay)
  end
  
  def animation_tweenframe_changed(i)
    @current_animation_tweenframe_index = i
    @tweening_progress = @current_animation_tweenframe_index.to_f / @current_keyframe.length_in_frames
    #@ui.frame_delay.text = "%04X" % frame_delay.delay
    update_drawn_joints()
  end
  
  def advance_tweenframe
    if @current_animation && !@animation_paused
      if @current_animation_tweenframe_index >= @current_keyframe.length_in_frames
        advance_keyframe()
      else
        animation_tweenframe_changed(@current_animation_tweenframe_index+1)
      end
      
      millisecond_delay = (1 / 60.0 * 1000).round
      @animation_timer.start(millisecond_delay)
    end
  end
  
  def set_animation_paused(paused)
    @animation_paused = paused
    if @animation_paused
      @ui.toggle_paused_button.text = "Play"
    else
      @ui.toggle_paused_button.text = "Pause"
      
      start_animation()
    end
  end
  
  def start_animation
    millisecond_delay = (1 / 60.0 * 1000).round
    @animation_timer.start(millisecond_delay)
  end
  
  def toggle_animation_paused
    set_animation_paused(!@animation_paused)
  end
  
  def advance_keyframe
    if @current_animation && !@animation_paused
      if @current_animation_keyframe_index >= @current_animation.keyframes.length-1
        animation_keyframe_changed(0)
        
        unless @ui.loop_animation.checked
          set_animation_paused(true)
        end
      else
        animation_keyframe_changed(@current_animation_keyframe_index+1)
      end
    end
  end
  
  def update_drawn_joints
    @skeleton_graphics_scene.items.each do |item|
      @skeleton_graphics_scene.removeItem(item)
    end
    
    next_pose = @skeleton.poses[@current_pose_index]
    
    if @previous_pose
      @current_tweened_joint_states, pose = tween_poses(@previous_pose, next_pose, @tweening_progress)
    else
      @current_tweened_joint_states = @current_pose_joint_states
      pose = next_pose
    end
    
    @skeleton.joint_indexes_by_draw_order.each do |joint_index|
      joint = @skeleton.joints[joint_index]
      joint_change = pose.joint_changes[joint_index]
      joint_state = @current_tweened_joint_states[joint_index]
      
      next if joint.frame_id == 0xFF
      
      rotation = joint_change.rotation
      if joint.parent_id != 0xFF && joint.copy_parent_visual_rotation
        rotation += joint_state.inherited_rotation
      end
      rotation_in_degrees = rotation/182.0
      
      if joint_change.new_frame_id == 0xFF
        frame_id = joint.frame_id
      else
        frame_id = joint_change.new_frame_id
      end
      pixmap = @pixmap_frames[frame_id]
      graphics_item = Qt::GraphicsPixmapItem.new(pixmap)
      graphics_item.setOffset(@min_x, @min_y)
      graphics_item.setPos(joint_state.x_pos, joint_state.y_pos)
      graphics_item.setRotation(rotation_in_degrees)
      if joint.horizontal_flip && joint.vertical_flip
        graphics_item.scale(-1, -1)
      elsif joint.horizontal_flip
        graphics_item.scale(-1, 1)
      elsif joint.vertical_flip
        graphics_item.scale(1, -1)
      end
      @skeleton_graphics_scene.addItem(graphics_item)
    end
    
    if @ui.show_skeleton.checked
      @skeleton.joints.each_index do |joint_index|
        joint = @skeleton.joints[joint_index]
        joint_change = pose.joint_changes[joint_index]
        joint_state = @current_tweened_joint_states[joint_index]
        
        ellipse = @skeleton_graphics_scene.addEllipse(joint_state.x_pos-1, joint_state.y_pos-1, 3, 3, GREY_PEN)
        ellipse.setZValue(1)
        if joint.parent_id != 0xFF
          parent_joint = @skeleton.joints[joint.parent_id]
          parent_joint_state = @current_tweened_joint_states[joint.parent_id]
          line = @skeleton_graphics_scene.addLine(joint_state.x_pos, joint_state.y_pos, parent_joint_state.x_pos, parent_joint_state.y_pos, GREY_PEN)
          line.setZValue(1)
        end
      end
    end
    
    if @ui.show_hitboxes.checked
      @skeleton.hitboxes.each do |hitbox|
        joint = @skeleton.joints[hitbox.parent_joint_id]
        joint_change = pose.joint_changes[hitbox.parent_joint_id]
        joint_state = @current_tweened_joint_states[hitbox.parent_joint_id]
        
        x_pos = joint_state.x_pos
        y_pos = joint_state.y_pos
        
        offset_angle = hitbox.rotation + joint_change.rotation
        if joint.copy_parent_visual_rotation
          offset_angle += joint_state.inherited_rotation
        end
        offset_angle_in_degrees = offset_angle / 182.0
        offset_angle_in_radians = offset_angle_in_degrees * Math::PI / 180
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
        hitbox_item.setRect(x_pos-hitbox.width/2, y_pos-hitbox.height/2, hitbox.width, hitbox.height)
        hitbox_item.setTransformOriginPoint(hitbox_item.rect.center)
        rotation_in_degrees = hitbox.rotation / 182.0
        hitbox_item.setRotation(rotation_in_degrees)
        hitbox_item.setZValue(1)
        @skeleton_graphics_scene.addItem(hitbox_item)
      end
    end
    
    if @ui.show_points.checked?
      @skeleton.points.each do |point|
        joint = @skeleton.joints[point.parent_joint_id]
        joint_change = pose.joint_changes[point.parent_joint_id]
        joint_state = @current_tweened_joint_states[point.parent_joint_id]
        
        x_pos = joint_state.x_pos
        y_pos = joint_state.y_pos
        
        offset_angle = point.rotation + joint_change.rotation
        if joint.copy_parent_visual_rotation
          offset_angle += joint_state.inherited_rotation
        end
        offset_angle_in_degrees = offset_angle / 182.0
        offset_angle_in_radians = offset_angle_in_degrees * Math::PI / 180
        x_pos += point.distance*Math.cos(offset_angle_in_radians)
        y_pos += point.distance*Math.sin(offset_angle_in_radians)
        
        ellipse = @skeleton_graphics_scene.addEllipse(x_pos, y_pos, 3, 3, RED_PEN)
        ellipse.setZValue(1)
      end
    end
  end
  
  def toggle_show_skeleton(checked)
    update_drawn_joints()
  end
  
  def toggle_show_hitboxes(checked)
    update_drawn_joints()
  end
  
  def toggle_show_points(checked)
    update_drawn_joints()
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      
    end
  end
  
  def inspect; to_s; end
end

class JointState
  attr_accessor :x_pos,
                :y_pos,
                :inherited_rotation
end
