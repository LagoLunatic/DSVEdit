
module FreeSpaceManager
  def read_free_space_from_text_file
    @free_spaces = []
    
    # TODO: count expandable overlay ends as free space
    
    if @filesystem_directory.nil?
      return
    end
    
    freespace_file = File.join(@filesystem_directory, "_dsvedit_freespace.txt")
    if !File.file?(freespace_file)
      return
    end
    
    file_contents = File.read(freespace_file)
    free_space_strs = file_contents.scan(/^(\h+) (\h+) (\S+)$/)
    free_space_strs.each do |offset, length, path|
      offset = offset.to_i(16)
      length = length.to_i(16)
      @free_spaces << {path: path, offset: offset, length: length}
    end
    
    merge_overlapping_free_spaces()
  end
  
  def write_free_space_to_text_file(base_directory=@filesystem_directory)
    if base_directory.nil?
      return
    end
    
    output_string = ""
    output_string << "This file lists regions that were once used, but DSVEdit freed up when relocating the data to a different location.\n"
    output_string << "DSVEdit reads from this file to know what regions it can reuse later.\n"
    output_string << "Don't modify this file manually unless you know what you're doing.\n\n"
    @free_spaces.each do |free_space|
      offset = free_space[:offset]
      length = free_space[:length]
      path = free_space[:path]
      output_string << "%08X %08X %s\n" % [offset, length, path]
    end
    
    freespace_file = File.join(base_directory, "_dsvedit_freespace.txt")
    File.open(freespace_file, "w") do |f|
      f.write(output_string)
    end
  end
  
  def free_unused_space(ram_address, length)
    return if length <= 0
    
    path, offset = convert_ram_address_to_path_and_offset(ram_address)
    @free_spaces << {path: path, offset: offset, length: length}
    write_by_file(path, offset, "\0"*length, freeing_space: true)
    merge_overlapping_free_spaces()
  end
  
  def remove_free_space(file_path, offset_in_file, length)
    new_free_spaces = [] # In case a free space is only partly deleted, we might need to split it into smaller free spaces.
    @free_spaces.delete_if do |free_space|
      next unless free_space[:path] == file_path
      
      free_space_range = (free_space[:offset]...free_space[:offset]+free_space[:length])
      remove_range = (offset_in_file...offset_in_file+length)
      next if free_space_range.max < remove_range.begin || remove_range.max < free_space_range.begin
      
      if remove_range.begin > free_space_range.begin
        range_before = (free_space_range.begin...remove_range.begin)
        offset = range_before.begin
        length = range_before.end - offset
        new_free_spaces << {path: file_path, offset: offset, length: length}
      end
      if remove_range.max < free_space_range.max
        range_after = (remove_range.end...free_space_range.end)
        offset = range_after.begin
        length = range_after.end - offset
        new_free_spaces << {path: file_path, offset: offset, length: length}
      end
      
      true
    end
    
    @free_spaces += new_free_spaces
  end
  
  def merge_overlapping_free_spaces
    merged_free_spaces = []
    
    free_space_groups = @free_spaces.group_by{|free_space| free_space[:path]}
    free_space_groups.each do |path, free_space_group|
      merged_free_space_group = []
      
      free_space_group.sort_by{|free_space| free_space[:offset]}.each do |free_space|
        if merged_free_space_group.empty?
          merged_free_space_group << free_space
          next
        end
        
        prev_free_space = merged_free_space_group.last
        prev_range = (prev_free_space[:offset]..prev_free_space[:offset]+prev_free_space[:length])
        curr_range = (free_space[:offset]..free_space[:offset]+free_space[:length])
        if curr_range.include?(prev_range.begin) || prev_range.include?(curr_range.begin)
          new_offset = [curr_range.begin, prev_range.begin].min
          new_length = [curr_range.end, prev_range.end].max - new_offset
          new_free_space = {path: path, offset: new_offset, length: new_length}
          merged_free_space_group[-1] = new_free_space
        else
          merged_free_space_group << free_space
          next
        end
      end
      
      merged_free_spaces += merged_free_space_group
    end
    
    @free_spaces = merged_free_spaces
  end
  
  def get_free_space(length_needed, overlay_id = nil)
    free_spaces_sorted = @free_spaces.sort_by{|free_space| free_space[:length]}
    
    files_to_check = []
    
    if overlay_id
      files_to_check << File.join("/ftc", "overlay9_#{overlay_id}")
    end
    files_to_check << File.join("/ftc", "arm9.bin")
    
    files_to_check.each do |file_path|
      file = files_by_path[file_path]
      
      free_space = free_spaces_sorted.find do |free_space|
        free_space[:length] >= length_needed && free_space[:path] == file_path
      end
      
      # TODO: detect if there's a free space at the end of the overlay, but it's too small. we can just expand the overlay by the diff instead of fully.
      # Maybe to do this we should have everything past the end of an overlay be considered one big free space from the start.
      
      if free_space
        puts "Found free space at %08X (%08X in %s)" % [file[:ram_start_offset] + free_space[:offset], free_space[:offset], file[:file_path]]
        return file[:ram_start_offset] + free_space[:offset]
      end
    end
    
    if overlay_id
      overlay_path = File.join("/ftc", "overlay9_#{overlay_id}")
      overlay = files_by_path[overlay_path]
      return expand_file_and_get_end(overlay, length_needed)
    else
      raise "can't find"
    end
  end
end
