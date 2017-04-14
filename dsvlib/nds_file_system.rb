
require 'fileutils'

class NDSFileSystem
  class InvalidFileError < StandardError ; end
  class ConversionError < StandardError ; end
  class OffsetPastEndOfFileError < StandardError ; end
  class FileExpandError < StandardError ; end
  
  attr_reader :files,
              :files_by_path,
              :files_by_index,
              :overlays,
              :rom
  
  def open_directory(filesystem_directory)
    @filesystem_directory = filesystem_directory
    input_rom_path = "#{@filesystem_directory}/ftc/rom.nds"
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    read_from_rom(read_header_and_tables_from_hard_drive = true)
    @files.each do |id, file|
      next unless file[:type] == :file
      
      file[:size] = File.size(File.join(@filesystem_directory, file[:file_path]))
      file[:end_offset] = file[:start_offset] + file[:size]
    end
    get_file_ram_start_offsets_and_file_data_types()
  end
  
  def open_and_extract_rom(input_rom_path, filesystem_directory)
    @filesystem_directory = filesystem_directory
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    read_from_rom()
    extract_to_hard_drive()
    get_file_ram_start_offsets_and_file_data_types()
  end
  
  def open_rom(input_rom_path)
    @filesystem_directory = nil
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    read_from_rom()
    extract_to_memory()
    get_file_ram_start_offsets_and_file_data_types()
  end
  
  def write_to_rom(output_rom_path)
    print "Writing files to #{output_rom_path}... "
    
    new_rom = @rom.dup
    
    expanded_files = []
    max_written_address = 0
    
    files_written = 0
    files_without_dirs.sort_by{|id, file| id}.each do |id, file|
      file_data = get_file_data_from_opened_files_cache(file[:file_path])
      new_file_size = file_data.length
      file[:size] = new_file_size
      
      offset = file[:id]*8
      old_start_offset, old_end_offset = @rom[@file_allocation_table_offset+offset, 8].unpack("VV")
      old_size = old_end_offset - old_start_offset
      if new_file_size > old_size
        expanded_files << file
        next
      end
      
      new_start_offset = old_start_offset
      new_end_offset = new_start_offset + new_file_size
      new_rom[new_start_offset,new_file_size] = file_data
      offset = file[:id]*8
      new_rom[@file_allocation_table_offset+offset, 8] = [new_start_offset, new_end_offset].pack("VV")
      max_written_address = new_end_offset if new_end_offset > max_written_address
      
      files_written += 1
      if block_given?
        yield(files_written)
      end
    end
    
    expanded_files.each do |file|
      file_data = get_file_data_from_opened_files_cache(file[:file_path])
      new_file_size = file_data.length
      
      pad = max_written_address % 0x200
      if pad != 0
        # Pad start of file to next 0x200
        max_written_address += 0x200 - pad
      end
      new_start_offset = max_written_address
      new_end_offset = new_start_offset + new_file_size
      
      new_rom[new_start_offset,new_file_size] = file_data
      offset = file[:id]*8
      new_rom[@file_allocation_table_offset+offset, 8] = [new_start_offset, new_end_offset].pack("VV")
      max_written_address = new_end_offset if new_end_offset > max_written_address
      
      files_written += 1
      if block_given?
        yield(files_written)
      end
    end
    
    if @total_used_rom_size != max_written_address
      # Update used ROM size in the header.
      @total_used_rom_size = max_written_address
      write_by_file("/ftc/ndsheader.bin", 0x80, [@total_used_rom_size].pack("V"))
      
      update_header_checksum()
    end
    
    # Update arm9, header, and tables
    [
      "arm9.bin",
      "ndsheader.bin",
      "arm9_overlay_table.bin",
      #"fat.bin", # Already handled by above code, don't overwrite
      "fnt.bin"
    ].each do |filename|
      file = @extra_files.find{|file| file[:name] == filename}
      file_data = get_file_data_from_opened_files_cache(file[:file_path])
      new_file_size = file_data.length
      if filename == "arm9.bin" && @arm9_size != new_file_size
        raise "ARM9 changed size"
      end
      new_rom[file[:start_offset], file[:size]] = file_data
    end
    
    File.open(output_rom_path, "wb") do |f|
      f.write(new_rom)
    end
    puts "Done"
  end
  
  def all_files
    @files.values + @extra_files
  end
  
  def print_files
    @files.each do |id, file|
      puts "%02X" % id
      puts file.inspect
      gets
    end
  end
  
  def load_overlay(overlay_id)
    overlay = @overlays[overlay_id]
    load_file(overlay)
  end
  
  def load_file(file)
    @currently_loaded_files[file[:ram_start_offset]] = file
  end
  
  def convert_ram_address_to_path_and_offset(ram_address)
    @currently_loaded_files.each do |ram_start_offset, file|
      ram_range = (file[:ram_start_offset]..file[:ram_start_offset]+file[:size]-1)
      if ram_range.include?(ram_address)
        offset_in_file = ram_address - file[:ram_start_offset]
        return [file[:file_path], offset_in_file]
      end
    end
    
    str = ""
    @currently_loaded_files.each do |ram_start_offset, file|
      if file[:overlay_id]
        str << "\n overlay loaded: %02d" % file[:overlay_id]
      end
      str << "\n ram_range: %08X..%08X" % [file[:ram_start_offset], file[:ram_start_offset]+file[:size]]
      str << "\n rom_start: %08X" % file[:start_offset]
    end
    raise ConversionError.new("Failed to convert ram address to rom address: %08X. #{str}" % ram_address)
  end
  
  def read(ram_address, length=1, options={})
    file_path, offset_in_file = convert_ram_address_to_path_and_offset(ram_address)
    return read_by_file(file_path, offset_in_file, length, options)
  end
  
  def read_by_file(file_path, offset_in_file, length, options={})
    file = files_by_path[file_path]
    
    if options[:allow_length_to_exceed_end_of_file]
      max_offset = offset_in_file
    else
      max_offset = offset_in_file + length
    end
    if max_offset > file[:size]
      if options[:allow_reading_into_next_file_in_ram] && file[:ram_start_offset]
        next_file_in_ram = find_file_by_ram_start_offset(file[:ram_start_offset]+0xC)
        if next_file_in_ram
          return read_by_file(next_file_in_ram[:file_path], offset_in_file - file[:size], length, options=options)
        end
      end
      
      raise OffsetPastEndOfFileError.new("Offset %08X (length %08X) is past end of file #{file_path} (%08X bytes long)" % [offset_in_file, length, file[:size]])
    end
    
    file_data = get_file_data_from_opened_files_cache(file_path)
    return file_data[offset_in_file, length]
  end
  
  def read_until_end_marker(ram_address, end_markers)
    file_path, offset_in_file = convert_ram_address_to_path_and_offset(ram_address)
    file_data = get_file_data_from_opened_files_cache(file_path)
    substring = file_data[offset_in_file..-1]
    end_index = substring.index(end_markers.pack("C*"))
    return substring[0,end_index]
  end
  
  def write(ram_address, new_data)
    file_path, offset_in_file = convert_ram_address_to_path_and_offset(ram_address)
    write_by_file(file_path, offset_in_file, new_data)
  end
  
  def write_by_file(file_path, offset_in_file, new_data, freeing_space: false)
    file = files_by_path[file_path]
    if offset_in_file + new_data.length > file[:size]
      raise OffsetPastEndOfFileError.new("Offset %08X is past end of file #{file_path} (%08X bytes long)" % [offset_in_file, file[:size]])
    end
    
    file_data = get_file_data_from_opened_files_cache(file_path)
    file_data[offset_in_file, new_data.length] = new_data
    @opened_files_cache[file_path] = file_data
    @uncommitted_files << file_path
    
    remove_free_space(file_path, offset_in_file, new_data.length) unless freeing_space
  end
  
  def overwrite_file(file_path, new_data)
    file = files_by_path[file_path]
    @opened_files_cache[file_path] = new_data
    file[:size] = new_data.size
    @uncommitted_files << file_path
    
    if file[:overlay_id]
      update_overlay_length(file)
    end
  end
  
  def find_file_by_ram_start_offset(ram_start_offset)
    unless ram_start_offset >= 0x02000000 && ram_start_offset < 0x03000000
      raise "RAM start offset %08X is invalid." % ram_start_offset
    end
    
    files.values.find do |file|
      file[:type] == :file && file[:ram_start_offset] == ram_start_offset
    end
  end
  
  def is_pointer?(value)
    value >= 0x02000000 && value < 0x03000000
  end
  
  def commit_changes(base_directory = @filesystem_directory)
    print "Committing changes to filesystem... "
    
    @uncommitted_files.uniq.each do |file_path|
      file_data = get_file_data_from_opened_files_cache(file_path)
      full_path = File.join(base_directory, file_path)
      
      full_dir = File.dirname(full_path)
      FileUtils.mkdir_p(full_dir)
      
      File.open(full_path, "wb") do |f|
        f.write(file_data)
      end
    end
    
    @uncommitted_files = []
    
    write_free_space_to_text_file(base_directory)
    
    puts "Done."
  end
  
  def has_uncommitted_changes?
    !@uncommitted_files.empty?
  end
  
  def read_free_space_from_text_file
    @free_spaces = []
    
    if @filesystem_directory.nil?
      return
    end
    
    freespace_file = File.join(@filesystem_directory, "_dsvedit_freespace.txt")
    if !File.file?(freespace_file)
      return
    end
    
    file_contents = File.read(freespace_file)
    free_space_strs = file_contents.scan(/^(\h+) (\h+) (\s+)$/)
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
    path, offset = convert_ram_address_to_path_and_offset(ram_address)
    @free_spaces << {path: path, offset: offset, length: length}
    write_by_file(path, offset, "\0"*length, freeing_space: true)
    merge_overlapping_free_spaces()
  end
  
  def remove_free_space(file_path, offset_in_file, length)
    #puts "REMOVE: #{offset_in_file} #{length}"
    new_free_spaces = [] # In case a free space is only partly delete, we might need to split it into smaller free spaces.
    #p @free_spaces
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
    #p @free_spaces
  end
  
  def merge_overlapping_free_spaces
    #puts "MERGE"
    #p @free_spaces
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
    #p @free_spaces
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
  
  def expand_file_and_get_end_of_file_ram_address(ram_address, length_to_expand_by)
    file_path, offset_in_file = convert_ram_address_to_path_and_offset(ram_address)
    file = @currently_loaded_files.values.find{|file| file[:file_path] == file_path}
    
    return expand_file_and_get_end(file, length_to_expand_by)
  end
  
  def expand_file_and_get_end(file, length_to_expand_by)
    old_size = file[:size]
    
    expand_file(file, length_to_expand_by)
    
    return file[:ram_start_offset] + old_size
  end
  
  def expand_file(file, length_to_expand_by)
    file_path = file[:file_path]
    
    if file[:overlay_id] && ROOM_OVERLAYS.include?(file[:overlay_id]) && file[:size] + length_to_expand_by > MAX_ALLOWABLE_ROOM_OVERLAY_SIZE
      raise FileExpandError.new("Failed to expand room overlay #{file[:overlay_id]} to #{file[:size] + length_to_expand_by} bytes because that is larger than the maximum size a room overlay can be in this game (#{MAX_ALLOWABLE_ROOM_OVERLAY_SIZE} bytes).")
    end
    
    if file_path == "/ftc/arm9.bin"
      raise FileExpandError.new("Cannot expand arm9.")
    end
    
    old_size = file[:size]
    file[:size] += length_to_expand_by
    
    @uncommitted_files << file_path
    
    if file[:overlay_id]
      update_overlay_length(file)
    end
    
    # Expand the actual file data string, and fill it with 0 bytes.
    write_by_file(file_path, old_size, "\0"*length_to_expand_by, freeing_space: true)
  end
  
  def update_overlay_length(file)
    write_by_file("/ftc/arm9_overlay_table.bin", file[:overlay_id]*32 + 8, [file[:size]].pack("V"))
  end
  
  def add_new_overlay_file
    overlay_id = NEW_OVERLAY_ID
    if @overlays[overlay_id]
      raise "Already added a new overlay, overlay9_#{overlay_id}. DSVEdit can currently only add one new overlay. Use the existing one."
    end
    ram_pointer = NEW_OVERLAY_FREE_SPACE_START
    file_size = 4
    bss_size = 0
    static_initializer_start = 0 # todo?
    static_initializer_end = 0 # todo?
    file_id = @files.keys.select{|key| key < 0xF000}.max + 1
    
    file_name = "overlay9_#{overlay_id}"
    file_path = File.join("/ftc", file_name)
    
    # write_to_rom will calculate new rom offsets for this file anyway, we don't need to set these here.
    rom_start_offset = 0
    rom_end_offset = 0
    
    new_file = {:name => file_name, :type => :file, :id => file_id, :overlay_id => overlay_id, :ram_start_offset => ram_pointer, :size => file_size, :start_offset => rom_start_offset, :end_offset => rom_end_offset, :file_path => file_path}
    @overlays << new_file
    @files[file_id] = new_file
    @files_by_path[new_file[:file_path]] = new_file
    
    path = File.join(@filesystem_directory, file_path)
    @opened_files_cache[file_path] = "\0"*file_size
    @uncommitted_files << file_path
    
    new_overlay_table_entry = [overlay_id, ram_pointer, file_size, bss_size, static_initializer_start, static_initializer_end, file_id, 0].pack("V*")
    arm9_overlay_table_file = files_by_path["/ftc/arm9_overlay_table.bin"]
    arm9_overlay_table_file[:size] = overlay_id*32 + 32
    write_by_file("/ftc/arm9_overlay_table.bin", overlay_id*32, new_overlay_table_entry)
    @uncommitted_files << "/ftc/arm9_overlay_table.bin"
    
    new_file_allocation_table_entry = [rom_start_offset, rom_end_offset].pack("VV")
    file_allocation_table_file = files_by_path["/ftc/fat.bin"]
    file_allocation_table_file[:size] = file_id*8 + 8
    write_by_file("/ftc/fat.bin", file_id*8, new_file_allocation_table_entry)
    @uncommitted_files << "/ftc/fat.bin"
    
    write_new_table_sizes_to_header()
  end
  
  def write_new_table_sizes_to_header
    file_name_table_size = files_by_path["/ftc/fnt.bin"][:size]
    write_by_file("/ftc/ndsheader.bin", 0x44, [file_name_table_size].pack("V"))
    file_allocation_table_size = files_by_path["/ftc/fat.bin"][:size]
    write_by_file("/ftc/ndsheader.bin", 0x4C, [file_allocation_table_size].pack("V"))
    arm9_overlay_table_size = files_by_path["/ftc/arm9_overlay_table.bin"][:size]
    write_by_file("/ftc/ndsheader.bin", 0x54, [arm9_overlay_table_size].pack("V"))
    
    update_header_checksum()
  end
  
  def update_header_checksum
    header_data_to_crc = read_by_file("/ftc/ndsheader.bin", 0, 0x15E)
    header_checksum = CRC16.calc(header_data_to_crc, 0xFFFF)
    write_by_file("/ftc/ndsheader.bin", 0x15E, [header_checksum].pack("v"))
  end
  
  def all_sprite_pointers
    @all_sprite_pointers ||= files.select do |id, file|
      file[:type] == :file && file[:file_path] =~ /^\/so\/p_/
    end.map do |id, file|
      file[:ram_start_offset]
    end
  end
    
  def files_without_dirs
    files.select{|id, file| file[:type] == :file}
  end
  
  def initialize_copy(orig)
    super
    
    @uncommitted_files = @uncommitted_files.dup
    
    orig_opened_files_cache = @opened_files_cache
    @opened_files_cache = {}
    @uncommitted_files.each do |path|
      @opened_files_cache[path] = orig_opened_files_cache[path].dup
    end
    
    @files = {}
    orig.files.each do |id, file|
      @files[id] = file.dup
    end
    @extra_files = @extra_files.map do |file|
      file.dup
    end
    generate_file_paths()
  end
  
  def inspect; to_s; end
  
private
  
  def read_from_rom(read_header_and_tables_from_hard_drive = false)
    if read_header_and_tables_from_hard_drive
      header = read_header_or_table_data_from_hard_drive("ndsheader.bin")
    else
      header = @rom[0, 0x4000]
    end
    
    @game_name = header[0x00,12]
    raise InvalidFileError.new("Not a DSVania") unless %w(CASTLEVANIA1 CASTLEVANIA2 CASTLEVANIA3).include?(@game_name)
    @game_code = header[0x0C,4]
    raise InvalidFileError.new("This region is not supported") unless %w(ACVE ACBE YR9E ACVJ ACBJ YR9J).include?(@game_code)
    
    @arm9_rom_offset, @arm9_entry_address, @arm9_ram_offset, @arm9_size = header[0x20,16].unpack("VVVV")
    @arm7_rom_offset, @arm7_entry_address, @arm7_ram_offset, @arm7_size = header[0x30,16].unpack("VVVV")
    
    @file_name_table_offset, @file_name_table_size, @file_allocation_table_offset, @file_allocation_table_size = header[0x40,16].unpack("VVVV")
    
    @arm9_overlay_table_offset, @arm9_overlay_table_size = header[0x50,8].unpack("VV")
    @arm7_overlay_table_offset, @arm7_overlay_table_size = header[0x58,8].unpack("VV")
    
    @banner_start_offset = header[0x68,4].unpack("V").first
    @banner_end_offset = @banner_start_offset + 0x840 # ??
    
    @total_used_rom_size = header[0x80,4].unpack("V").first
    
    @files = {}
    @overlays = []
    @currently_loaded_files = {}
    @opened_files_cache = {}
    @uncommitted_files = []
    
    get_extra_files()
    if read_header_and_tables_from_hard_drive
      file_name_table_data = read_header_or_table_data_from_hard_drive("fnt.bin")
      overlay_table_data = read_header_or_table_data_from_hard_drive("arm9_overlay_table.bin")
      file_allocation_table_data = read_header_or_table_data_from_hard_drive("fat.bin")
    else
      file_name_table_data = @rom[@file_name_table_offset, @file_name_table_size]
      overlay_table_data = @rom[@arm9_overlay_table_offset, @arm9_overlay_table_size]
      file_allocation_table_data = @rom[@file_allocation_table_offset, @file_allocation_table_size]
    end
    get_file_name_table(file_name_table_data)
    get_overlay_table(overlay_table_data)
    get_file_allocation_table(file_allocation_table_data)
    generate_file_paths()
    CONSTANT_OVERLAYS.each do |overlay_index|
      load_overlay(overlay_index)
    end
    
    read_free_space_from_text_file()
  end
  
  def extract_to_hard_drive
    print "Extracting files from ROM... "
    
    all_files.each do |file|
      next unless file[:type] == :file
      #next unless (file[:overlay_id] || file[:name] == "arm9.bin" || file[:name] == "rom.nds")
      
      start_offset, end_offset, file_path = file[:start_offset], file[:end_offset], file[:file_path]
      file_data = @rom[start_offset..end_offset-1]
      
      output_path = File.join(@filesystem_directory, file_path)
      output_dir = File.dirname(output_path)
      FileUtils.mkdir_p(output_dir)
      File.open(output_path, "wb") do |f|
        f.write(file_data)
      end
    end
    
    freespace_file = File.join(@filesystem_directory, "_dsvedit_freespace.txt")
    if File.file?(freespace_file)
      FileUtils.rm(freespace_file)
    end
    
    puts "Done."
  end
  
  def extract_to_memory
    print "Extracting files from ROM to memory... "
    
    all_files.each do |file|
      next unless file[:type] == :file
      
      start_offset, end_offset, file_path = file[:start_offset], file[:end_offset], file[:file_path]
      file_data = @rom[start_offset..end_offset-1]
      
      @opened_files_cache[file_path] = file_data
    end
    
    puts "Done."
  end
  
  def get_file_data_from_opened_files_cache(file_path)
    if @opened_files_cache[file_path]
      file_data = @opened_files_cache[file_path]
    else
      path = File.join(@filesystem_directory, file_path)
      file_data = File.open(path, "rb") {|file| file.read}
      @opened_files_cache[file_path] = file_data
    end
    
    return file_data
  end
  
  def get_file_name_table(file_name_table_data)
    subtable_offset, subtable_first_file_id, number_of_dirs = file_name_table_data[0x00,8].unpack("Vvv")
    get_file_name_subtable(file_name_table_data, subtable_offset, subtable_first_file_id, 0xF000)
    
    i = 1
    while i < number_of_dirs
      subtable_offset, subtable_first_file_id, parent_dir_id = file_name_table_data[0x00+i*8,8].unpack("Vvv")
      get_file_name_subtable(file_name_table_data, subtable_offset, subtable_first_file_id, 0xF000 + i)
      i += 1
    end
  end
  
  def get_file_name_subtable(file_name_table_data, subtable_offset, subtable_first_file_id, parent_dir_id)
    i = 0
    offset = subtable_offset
    next_file_id = subtable_first_file_id
    
    while true
      length = file_name_table_data[offset,1].unpack("C*").first
      offset += 1
      
      case length
      when 0x01..0x7F
        type = :file
        
        name = file_name_table_data[offset,length]
        offset += length
        
        id = next_file_id
        next_file_id += 1
      when 0x81..0xFF
        type = :subdir
        
        length = length & 0x7F
        name = file_name_table_data[offset,length]
        offset += length
        
        id = file_name_table_data[offset,2].unpack("v").first
        offset += 2
      when 0x00
        # end of subtable
        break
      when 0x80
        # reserved
        break
      end
      
      @files[id] = {:name => name, :type => type, :parent_id => parent_dir_id, :id => id}
      i += 1
    end
  end
  
  def get_overlay_table(overlay_table_data)
    offset = 0x00
    while offset < @arm9_overlay_table_size
      overlay_id, overlay_ram_address, overlay_size, _, _, _, file_id, _ = overlay_table_data[0x00+offset,32].unpack("V*")
      
      @files[file_id] = {:name => "overlay9_#{overlay_id}", :type => :file, :id => file_id, :overlay_id => overlay_id, :ram_start_offset => overlay_ram_address, :size => overlay_size}
      @overlays << @files[file_id]
      
      offset += 32
    end
  end
  
  def get_file_ram_start_offsets_and_file_data_types
    @files_by_index = []
    offset = LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET
    while offset < LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET
      file_data = read(offset, LIST_OF_FILE_RAM_LOCATIONS_ENTRY_LENGTH)
      
      ram_start_offset = file_data[0..3].unpack("V").first
      
      file_data_type = file_data[4..5].unpack("v").first
      
      file_path = file_data[6..-1]
      file_path = file_path.delete("\x00") # Remove null bytes padding the end of the string
      file = files_by_path[file_path]
      
      if ram_start_offset != 0
        file[:ram_start_offset] = ram_start_offset
      end
      file[:file_data_type] = file_data_type
      
      @files_by_index << file
      
      offset += LIST_OF_FILE_RAM_LOCATIONS_ENTRY_LENGTH
    end
    
    if GAME == "por"
      # Richter's gfx files don't have a ram offset stored in the normal place.
      i = 0
      files.values.each do |file|
        if file[:ram_start_offset] == nil && file[:file_path] =~ /\/sc2\/s0_ri_..\.dat/
          file[:ram_start_offset] = read(RICHTERS_LIST_OF_GFX_POINTERS + i*4, 4).unpack("V").first
          i += 1
        end
      end
    end
  end
  
  def get_file_allocation_table(file_allocation_table_data)
    id = 0x00
    offset = 0x00
    while offset < @file_allocation_table_size
      @files[id][:start_offset], @files[id][:end_offset] = file_allocation_table_data[offset,8].unpack("VV")
      @files[id][:size] = @files[id][:end_offset] - @files[id][:start_offset]
      
      id += 1
      offset += 0x08
    end
  end
  
  def get_extra_files
    @extra_files = []
    @extra_files << {:name => "ndsheader.bin", :type => :file, :start_offset => 0x0, :end_offset => 0x4000, :size => 0x4000}
    arm9_file = {:name => "arm9.bin", :type => :file, :start_offset => @arm9_rom_offset, :end_offset => @arm9_rom_offset + @arm9_size, :ram_start_offset => @arm9_ram_offset, :size => @arm9_size}
    @extra_files << arm9_file
    load_file(arm9_file)
    @extra_files << {:name => "arm7.bin", :type => :file, :start_offset => @arm7_rom_offset, :end_offset => @arm7_rom_offset + @arm7_size, :size => @arm7_size}
    @extra_files << {:name => "arm9_overlay_table.bin", :type => :file, :start_offset => @arm9_overlay_table_offset, :end_offset => @arm9_overlay_table_offset + @arm9_overlay_table_size, :size => @arm9_overlay_table_size}
    @extra_files << {:name => "arm7_overlay_table.bin", :type => :file, :start_offset => @arm7_overlay_table_offset, :end_offset => @arm7_overlay_table_offset + @arm7_overlay_table_size, :size => @arm7_overlay_table_size}
    @extra_files << {:name => "fnt.bin", :type => :file, :start_offset => @file_name_table_offset, :end_offset => @file_name_table_offset + @file_name_table_size, :size => @file_name_table_size}
    @extra_files << {:name => "fat.bin", :type => :file, :start_offset => @file_allocation_table_offset, :end_offset => @file_allocation_table_offset + @file_allocation_table_size, :size => @file_allocation_table_size}
    @extra_files << {:name => "banner.bin", :type => :file, :start_offset => @banner_start_offset, :end_offset => @banner_end_offset}
    @extra_files << {:name => "rom.nds", :type => :file, :start_offset => 0, :end_offset => @rom.length}
  end
  
  def generate_file_paths
    @files_by_path = {}
    
    all_files.each do |file|
      if file[:parent_id] == 0xF000
        file[:file_path] = file[:name]
      elsif file[:parent_id].nil?
        file[:file_path] = File.join("/ftc", file[:name])
      else
        file[:file_path] = "/" + File.join(@files[file[:parent_id]][:name], file[:name])
      end
      
      @files_by_path[file[:file_path]] = file
    end
  end
  
  def read_header_or_table_data_from_hard_drive(file_name)
    if @filesystem_directory.nil?
      raise "No folder to read table data from"
    end
    
    file_path = File.join(@filesystem_directory, "ftc", file_name)
    unless File.file?(file_path)
      raise "Not a file: #{file_path}"
    end
    
    file_data = File.open(file_path, "rb") {|file| file.read}
    
    return file_data
  end
end
