
require 'nokogiri'

class SpriterInterface
  class ExportError < StandardError ; end
  class ImportError < StandardError ; end
  
  def self.export(output_path, name, skeleton, sprite_info, fs, renderer)
    sprite = sprite_info.sprite
    
    chunky_frames, min_x, min_y = renderer.render_sprite(sprite_info)
    chunky_frames.each_with_index do |chunky_frame, i|
      chunky_frame.save(output_path + "/frame%02X.png" % i, :fast_rgba)
    end
    
    image_width = chunky_frames.first.width
    image_height = chunky_frames.first.height
    pivot_x_in_pixels = -min_x
    pivot_y_in_pixels = -min_y
    # For the pivot point, x=0 means the left edge, x=1 means the right edge, y=0 means the bottom edge, and y=1 means the top edge.
    pivot_x = pivot_x_in_pixels.to_f / image_width
    pivot_y = pivot_y_in_pixels.to_f / image_height
    pivot_y = 1 - pivot_y
    
    #palettes = renderer.generate_palettes(sprite_info.palette_pointer, 16)
    #palette = palettes[0]
    #
    #gfx_page = sprite_info.gfx_pages[0]
    #chunky_gfx_page = renderer.render_gfx_page(gfx_page, palette, gfx_page.canvas_width)
    #chunky_gfx_page.save(output_path + "/#{name}.png", :fast_rgba)
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.spriter_data(
              :scml_version => "1.0", 
              :generator => "DSVEdit's Spriter Interface", 
              :generator_version => "b1",
              :pixel_mode => 1) {
        xml.folder(
          :id => 0,
          #:name => "."
        ) {
          chunky_frames.each_with_index do |chunky_frame, i|
            xml.file(
              :id => 0,
              :name => "frame%02X.png" % i,
              :width => chunky_frame.width,
              :height => chunky_frame.height,
              :pivot_x => 0,#-min_x,
              :pivot_y => 0,#-min_y
            )
          end
        }
        
        xml.entity(:id => 0, :name => name) {
          #xml.character_map(:id => 0, :name => "charmap name here") {
          #  xml.map(
          #    :folder => 0,
          #    :file => 0,
          #    :target_folder => -1,
          #    :target_file => -1,
          #  )
          #}
          
          # Spriter doesn't support parenting to non-bone sprites. So to allow this we need to create a spriter bone for all non-bones, as well as for all bones.
          skeleton.joints.each_with_index do |bone_joint, joint_index|
            is_bone = bone_joint.frame_id == 0xFF
            distance = skeleton.poses[0].joint_changes[joint_index].distance
            
            xml.obj_info(
              name: "bone_%02X" % joint_index,
              type: "bone",
              w: 20, #distance,#is_bone ? distance : 0, # These dummy bones should have 0 length...?
              h: 10,
            )
          end
          
          skeleton.animations.each_with_index do |animation, animation_index|
            total_anim_length_in_frames = animation.keyframes.inject(0){|sum, keyframe| sum + keyframe.length_in_frames}
            total_anim_length_in_milliseconds = total_anim_length_in_frames / 60.0 * 1000
            
            xml.animation(:id => animation_index,
              :name => "anim_%02X" % animation_index,
              :length => total_anim_length_in_milliseconds.ceil,
              :looping => true
            ) {
              xml.mainline {
                object_joints = skeleton.joints.select{|joint| joint.frame_id != 0xFF}
                
                time = 0
                
                animation.keyframes.each_with_index do |keyframe, keyframe_index|
                  #pose_index = keyframe.pose_id
                  #pose = skeleton.poses[pose_index]
                  
                  xml.key(
                    id: keyframe_index,
                    time: time.floor,
                  ) {
                    skeleton.joints.each_with_index do |bone_joint, bone_index|
                      parent_bone_index = bone_joint.parent_id == 0xFF ? -1 : bone_joint.parent_id
                      joint_index = skeleton.joints.index(bone_joint)
                      
                      xml.bone_ref(
                        id: bone_index,
                        parent: parent_bone_index,
                        timeline: joint_index,
                        key: keyframe_index
                      )
                    end
                    
                    skeleton.joint_indexes_by_draw_order.each do |joint_index|
                      object_joint = skeleton.joints[joint_index]
                      object_index = object_joints.index(object_joint)
                      
                      parent_bone_index = object_joint.parent_id == 0xFF ? -1 : object_joint.parent_id
                      joint_index = skeleton.joints.index(object_joint)
                      
                      xml.object_ref(
                        id: object_index,
                        parent: joint_index, # The non-bone should just be a direct child of its equivalent bone.
                        timeline: skeleton.number_of_joints + object_index, # Non-bone timelines are after bone timelines.
                        key: keyframe_index,
                        z_index: 0
                      )
                    end
                  }
                  
                  length_in_milliseconds = keyframe.length_in_frames / 60.0 * 1000
                  time += length_in_milliseconds
                end
              }
              
              timeline_id = 0
              # Export bone timelines.
              skeleton.joints.each_with_index do |joint, joint_index|
                is_bone = true
                export_timeline(xml, skeleton, animation, joint, joint_index, timeline_id, pivot_x, pivot_y, is_bone)
                timeline_id += 1
              end
              # Export object timelines.
              skeleton.joints.each_with_index do |joint, joint_index|
                is_bone = joint.frame_id == 0xFF
                next if is_bone
                
                export_timeline(xml, skeleton, animation, joint, joint_index, timeline_id, pivot_x, pivot_y, is_bone)
                timeline_id += 1
              end
            }
          end
        }
      }
    end
    
    filename = output_path + "/#{name}.scml"
    FileUtils::mkdir_p(File.dirname(filename))
    File.open(filename, "w") do |f|
      f.write(builder.to_xml)
    end
  end
  
  def self.export_timeline(xml, skeleton, animation, joint, joint_index, timeline_id, pivot_x, pivot_y, is_bone)
    xml.timeline(
      id: timeline_id,
      name: is_bone ? "bone_%02X" % joint_index : "joint_%02X" % joint_index,
      object_type: is_bone ? "bone" : "sprite"
    ) {
      time = 0
      
      animation.keyframes.each_with_index do |keyframe, keyframe_index|
        pose = skeleton.poses[keyframe.pose_id]
        
        joint_change = pose.joint_changes[joint_index]
        joint_states = initialize_joint_states(pose, skeleton)
        joint_state = joint_states[joint_index]
        
        rel_x = joint_state.x_pos
        rel_y = joint_state.y_pos
        rel_rotation = joint_change.rotation
        if joint.parent_id != 0xFF && joint.copy_parent_visual_rotation
          rel_rotation += joint_state.inherited_rotation
        end
        
        if joint.parent_id != 0xFF
          # The X and Y in the SCML file are relevant to the parent bone, so we need to subtract the parent's X and Y.
          # (Note that the X and Y displayed in Spriter's UI are absolute.)
          parent_joint = skeleton.joints[joint.parent_id]
          parent_joint_state = joint_states[joint.parent_id]
          parent_joint_change = pose.joint_changes[joint.parent_id]
          rel_x -= parent_joint_state.x_pos
          rel_y -= parent_joint_state.y_pos
          
          #parent_rotation = parent_joint_change.rotation
          #if parent_joint.parent_id != 0xFF && parent_joint.copy_parent_visual_rotation
          #  parent_rotation += parent_joint_state.inherited_rotation
          #  #rel_rotation += parent_joint_state.inherited_rotation
          #end
          #rel_rotation -= parent_rotation
        end
        
        rel_rotation_in_degrees = rel_rotation/182.0
        
        rel_rotation_in_degrees = -rel_rotation_in_degrees # Spriter angles are inverted compared to skeleton angles.
        
        #if joint_index == 0x18
        #  p [joint_state.x_pos, joint_state.y_pos, rel_x, rel_y, parent_joint_state.x_pos, parent_joint_state.y_pos]
        #end
        #if joint_index == 0x1A
        #  rot = joint_change.rotation
        #  if joint.parent_id != 0xFF && joint.copy_parent_visual_rotation
        #    rot += joint_state.inherited_rotation
        #  end
        #  p [rot/182.0, rel_rotation_in_degrees, parent_rotation/182.0]
        #end
        
        frame_id = joint_change.new_frame_id == 0xFF ? joint.frame_id : joint_change.new_frame_id
        
        xml.key(
          id: keyframe_index,
          time: time.floor,
        ) {
          if is_bone
            xml.bone(
              x: rel_x,
              y: -rel_y, # Relevant Y in the SCML file is inverted. (But not the absolute Y displayed in Spriter's UI, that's normal.)
              angle: 0,
            )
          else
            xml.object(
              folder: 0,
              file: frame_id,
              x: 0,
              y: 0,
              angle: rel_rotation_in_degrees, # this angle in the SCML file is relative to the parent bone. but in spriter's UI it's an absolute angle.
              pivot_x: pivot_x,
              pivot_y: pivot_y
            )
          end
        }
        
        length_in_milliseconds = keyframe.length_in_frames / 60.0 * 1000
        time += length_in_milliseconds
      end
    }
  end
  
  def self.import(input_path, name, sprite_info, fs, renderer)
  end
  
  def self.initialize_joint_states(pose, skeleton)
    joint_states_for_pose = []
    
    for joint_index in 0...pose.joint_changes.count
      joint_state = JointState.new
      joint = skeleton.joints[joint_index]
      joint_change = pose.joint_changes[joint_index]
      
      if joint.parent_id == 0xFF
        joint_state.x_pos = 0
        joint_state.y_pos = 0
        joint_state.inherited_rotation = 0
      else
        parent_joint = skeleton.joints[joint.parent_id]
        parent_joint_change = pose.joint_changes[joint.parent_id]
        parent_joint_state = joint_states_for_pose[joint.parent_id]
        
        joint_state.x_pos = parent_joint_state.x_pos
        joint_state.y_pos = parent_joint_state.y_pos
        joint_state.inherited_rotation = parent_joint_change.rotation
        
        if parent_joint.copy_parent_visual_rotation
          joint_state.inherited_rotation += parent_joint_state.inherited_rotation
        end
        
        connected_rotation_in_degrees = joint_state.inherited_rotation / 182.0
        
        offset_angle = connected_rotation_in_degrees
        offset_angle += 90 * joint.positional_rotation
        
        offset_angle_in_radians = offset_angle * Math::PI / 180
        
        joint_state.x_pos += joint_change.distance*Math.cos(offset_angle_in_radians)
        joint_state.y_pos += joint_change.distance*Math.sin(offset_angle_in_radians)
        
      end
      joint_states_for_pose << joint_state
    end
    
    return joint_states_for_pose
  end
  
  def self.initialize_joint_states_new(pose, skeleton)
    joint_states_for_pose = []
    
    for joint_index in 0...pose.joint_changes.count
      joint_state = JointState.new
      joint = skeleton.joints[joint_index]
      joint_change = pose.joint_changes[joint_index]
      
      joint_state.inherited_rotation = joint_change.rotation
      joint_state.connected_rotation = joint_change.rotation
      
      if joint.parent_id != 0xFF
        parent_joint = skeleton.joints[joint.parent_id]
        parent_joint_state = joint_states_for_pose[joint.parent_id]
        
        if joint.copy_parent_visual_rotation # maybe this variable should be called something like "is_mobile" or "is_turning"
          joint_state.inherited_rotation += parent_joint_state.inherited_rotation
        else
          joint_state.connected_rotation -= parent_joint_state.inherited_rotation
        end
      end
      
      case joint.positional_rotation
        when 0
          joint_state.x_pos = joint_change.distance
          joint_state.y_pos = 0
        when 1
          joint_state.x_pos = 0
          joint_state.y_pos = joint_change.distance
        when 2
          joint_state.x_pos = joint_change.distance * -1
          joint_state.y_pos = 0
        when 3
          joint_state.x_pos = 0
          joint_state.y_pos = joint_change.distance * -1
        else # just to be safe
          joint_state.x_pos = 0
          joint_state.y_pos = 0
      end
      
      # workaround for functions that need absolute positions
      if joint.parent_id != 0xFF
        joint_state.x_pos += parent_joint_state.x_pos
        joint_state.y_pos += parent_joint_state.y_pos
      end
      
      joint_states_for_pose << joint_state
    end

    return joint_states_for_pose
  end
  
end
