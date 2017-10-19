
require 'nokogiri'

class SpriterInterface
  class ExportError < StandardError ; end
  class ImportError < StandardError ; end
  
  def self.export(output_path, name, skeleton, sprite_info, fs, renderer)
    sprite = sprite_info.sprite
    
    chunky_frames, min_x, min_y = renderer.render_sprite(sprite_info)
    chunky_frames.each_with_index do |chunky_frame, i|
      chunky_frame.save(output_path + "/frame%02X.png" % i)
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
    #chunky_gfx_page = renderer.render_gfx_page(gfx_page.file, palette, gfx_page.canvas_width)
    #chunky_gfx_page.save(output_path + "/#{name}.png")
    
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
        
        xml.entity(:id => 0, :name => "entity name here") {
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
          
          xml.animation(:id => 0,
            :name => "animname",
            :length => skeleton.number_of_poses*100, # TODO
            :looping => true
          ) {
            xml.mainline {
              skeleton.poses.each_with_index do |pose, pose_index|
                xml.key(
                  id: pose_index,
                  time: pose_index*100, # TODO
                ) {
                  bone_joints = skeleton.joints.select{|joint| joint.frame_id == 0xFF}
                  object_joints = skeleton.joints.select{|joint| joint.frame_id != 0xFF}
                  
                  skeleton.joints.each_with_index do |bone_joint, bone_index|
                    parent_bone_index = bone_joint.parent_id == 0xFF ? -1 : bone_joint.parent_id
                    joint_index = skeleton.joints.index(bone_joint)
                    
                    xml.bone_ref(
                      id: bone_index,
                      parent: parent_bone_index,
                      timeline: joint_index,
                      key: pose_index
                    )
                  end
                  
                  #bone_joints.each_with_index do |bone_joint, bone_index|
                  #  if bone_joint.parent_id == 0xFF
                  #    parent_bone_index = -1
                  #  else
                  #    parent = skeleton.joints[bone_joint.parent_id]
                  #    parent_bone_index = bone_joints.index(parent)
                  #  end
                  #  joint_index = skeleton.joints.index(bone_joint)
                  #  
                  #  xml.bone_ref(
                  #    id: bone_index,
                  #    parent: parent_bone_index,
                  #    timeline: joint_index,
                  #    key: pose_index
                  #  )
                  #end
                  
                  object_joints.each_with_index do |object_joint, object_index|
                    #if object_joint.parent_id == 0xFF
                    #  parent_bone_index = -1
                    #else
                    #  parent = skeleton.joints[object_joint.parent_id]
                    #  parent_bone_index = bone_joints.index(parent)
                    #end
                    parent_bone_index = object_joint.parent_id == 0xFF ? -1 : object_joint.parent_id
                    joint_index = skeleton.joints.index(object_joint)
                    #puts "joint index %02X, object: parent is %02X" % [joint_index, parent_bone_index]
                    
                    xml.object_ref(
                      id: object_index,
                      parent: joint_index, # The non-bone should just be a direct child of its equivalent bone.
                      timeline: skeleton.number_of_joints + object_index, # Non-bone timelines are after bone timelines.
                      key: pose_index,
                      z_index: 0
                    )
                  end
                  
                  #skeleton.joints.each_with_index do |joint, joint_index|
                  #  is_bone = joint.frame_id == 0xFF
                  #  parent_id = joint.parent_id == 0xFF ? -1 : joint.parent_id
                  #  
                  #  if is_bone
                  #    xml.bone_ref(
                  #      id: joint_index,
                  #      parent: parent_id,
                  #      timeline: joint_index,
                  #      key: pose_index
                  #    )
                  #  else
                  #    xml.object_ref(
                  #      id: joint_index,
                  #      parent: parent_id,
                  #      timeline: joint_index,
                  #      key: pose_index,
                  #      z_index: 0
                  #    )
                  #  end
                  #end
                }
              end
            }
            
            timeline_id = 0
            # Export bone timelines.
            skeleton.joints.each_with_index do |joint, joint_index|
              is_bone = true
              export_timeline(xml, skeleton, joint, joint_index, timeline_id, pivot_x, pivot_y, is_bone)
              timeline_id += 1
            end
            # Export object timelines.
            skeleton.joints.each_with_index do |joint, joint_index|
              is_bone = joint.frame_id == 0xFF
              next if is_bone
              
              export_timeline(xml, skeleton, joint, joint_index, timeline_id, pivot_x, pivot_y, is_bone)
              timeline_id += 1
            end
          }
        }
      }
    end
    
    filename = output_path + "/#{name}.scml"
    FileUtils::mkdir_p(File.dirname(filename))
    File.open(filename, "w") do |f|
      f.write(builder.to_xml)
    end
  end
  
  def self.export_timeline(xml, skeleton, joint, joint_index, timeline_id, pivot_x, pivot_y, is_bone)
    xml.timeline(
      id: timeline_id,
      name: is_bone ? "bone_%02X" % joint_index : "joint_%02X" % joint_index,
      object_type: is_bone ? "bone" : "sprite"
    ) {
      skeleton.poses.each_with_index do |pose, pose_index|
        joint_change = pose.joint_changes[joint_index]
        if joint.parent_id == 0xFF
          angle = 0
          parent_is_bone = false
        else
          parent_joint = skeleton.joints[joint.parent_id]
          parent_joint_change = pose.joint_changes[joint.parent_id]
          parent_is_bone = parent_joint.frame_id == 0xFF
          
          #angle = joint_change.rotation / 182.0
          angle = parent_joint_change.rotation / 182.0
          #if parent_joint.copy_parent_visual_rotation
          #  angle += parent_joint_state.inherited_rotation
          #end
          #all_joint_angles[joint_index] = angle
          angle += joint.positional_rotation * 90
        end
        
        frame_id = joint_change.new_frame_id == 0xFF ? joint.frame_id : joint_change.new_frame_id
        distance = joint_change.distance
        
        xml.key(
          id: pose_index,
          time: pose_index*100, # TODO
          spin: 0,
          #curve_type: 0,
          #c1: "",
          #c2: ""
        ) {
          if is_bone
            xml.bone(
              x: distance*5, #parent_is_bone ? distance : 0, # If the parent is a dummy bone we added set the distance to 0?
              y: 0,
              angle: angle,
              #scale_x: distance,
            )
          else
            xml.object(
              folder: 0,
              file: frame_id,
              x: 0,
              y: 0,
              angle: 0,
              pivot_x: pivot_x,
              pivot_y: pivot_y
            )
          end
        }
      end
    }
  end
  
  def self.import(input_path, name, sprite_info, fs, renderer)
  end
end
