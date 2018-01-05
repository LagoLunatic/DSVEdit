
require 'fileutils'

class NDSFileSystem
  class InvalidFileError < StandardError ; end
  class InvalidRevisionError < StandardError ; end
  class ConversionError < StandardError ; end
  class OffsetPastEndOfFileError < StandardError ; end
  class FileExpandError < StandardError ; end
  class ArmShiftedImmediateError < StandardError ; end
  
  include FreeSpaceManager
  
  attr_reader :files,
              :files_by_path,
              :assets,
              :assets_by_pointer,
              :overlays,
              :rom
  
  def open_directory(filesystem_directory)
    @filesystem_directory = filesystem_directory
    input_rom_path = "#{@filesystem_directory}/ftc/rom.nds"
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    read_from_rom(read_header_and_tables_from_hard_drive = true)
    @files.each do |id, file|
      next unless file[:type] == :file
      
      old_file_size = file[:size]
      file[:size] = File.size(File.join(@filesystem_directory, file[:file_path]))
      
      if file[:overlay_id] && old_file_size != file[:size]
        update_overlay_length(file)
      end
    end
    get_assets()
    read_free_space_from_text_file()
  end
  
  def open_and_extract_rom(input_rom_path, filesystem_directory, &block)
    @filesystem_directory = filesystem_directory
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    read_from_rom()
    extract_to_hard_drive(&block)
    get_assets()
    read_free_space_from_text_file()
  end
  
  def open_rom(input_rom_path)
    @filesystem_directory = nil
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    read_from_rom()
    extract_to_memory()
    get_assets()
    read_free_space_from_text_file()
  end
  
  def write_to_rom(output_rom_path)
    print "Writing files to #{output_rom_path}... "
    
    if overlays[NEW_OVERLAY_ID]
      # Shift asset memory down to make room for the free space overlay.
      new_asset_memory_start = NEW_OVERLAY_FREE_SPACE_START + overlays[NEW_OVERLAY_ID][:size]
      new_asset_memory_start = (new_asset_memory_start + 3) / 4 * 4 # Round up to the nearest word.
      write(ASSET_MEMORY_START_HARDCODED_LOCATION, [new_asset_memory_start].pack("V"))
    end
    
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
  
  def rom_file_extension
    "nds"
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
  
  def load_file(new_file)
    # First unload any files overlapping this new one.
    # This is so there are no conflicts where something tries to read from the new file, but reads from an older on that wasn't loaded in the exact same place but overlapped it nonetheless.
    new_file_ram_range = (new_file[:ram_start_offset]..new_file[:ram_start_offset]+new_file[:size]-1)
    @currently_loaded_files.each do |ram_start_offset, file|
      ram_range = (file[:ram_start_offset]..file[:ram_start_offset]+file[:size]-1)
      if ram_range.include?(new_file_ram_range.first) || new_file_ram_range.include?(ram_range.first)
        @currently_loaded_files.delete(ram_start_offset)
      end
    end
    
    # Then load the new file.
    @currently_loaded_files[new_file[:ram_start_offset]] = new_file
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
      if options[:allow_reading_into_next_file_in_ram] && file[:asset_pointer]
        next_file_in_ram = assets_by_pointer[file[:asset_pointer]+0xC]
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
  
  def reload_file_from_disk(file_path)
    if @uncommitted_files.include?(file_path)
      puts "Cannot reload file as it has unsaved changes: #{file_path}"
      return
    end
    
    if @opened_files_cache[file_path]
      @opened_files_cache[file_path] = nil
    end
    
    file = files_by_path[file_path]
    if file.nil?
      puts "Could not find file #{file_path} to reload"
      return
    end
    
    full_path = File.join(@filesystem_directory, file_path)
    if !File.file?(full_path)
      puts "File was deleted: #{file_path}"
      return
    end
    
    old_file_size = file[:size]
    file[:size] = File.size(full_path)
    
    if file[:overlay_id] && old_file_size != file[:size]
      update_overlay_length(file)
    end
    
    puts "Successfully reloaded #{file_path}"
  end
  
  def convert_arm_shifted_immediate_to_integer(constant, constant_shift)
    constant_shift &= 0xF
    unless constant_shift == 0
      constant_shift = (0x10 - constant_shift)*2
    end
    integer = constant << constant_shift
    return integer
  end
  
  def read_arm_shifted_immediate_integer(code_location)
    constant, constant_shift = read(code_location, 2).unpack("CC")
    
    return convert_arm_shifted_immediate_to_integer(constant, constant_shift)
  end
  
  def check_integer_can_be_an_arm_shifted_immediate?(integer)
    if integer <= 0xFF
      return true
    else
      binary_string = "%b" % integer
      num_trailing_zeros = binary_string.length - binary_string.rindex("1") - 1
      if num_trailing_zeros.odd?
        # Arm shifted immediates cannot be shifted by an odd number of bytes.
        num_trailing_zeros -= 1
      end
      if num_trailing_zeros == 0
        return false
      end
      constant = integer >> num_trailing_zeros
      if constant >= 0x100
        return false
      end
      return true
    end
  end
  
  def convert_integer_to_arm_shifted_immediate(integer)
    if integer <= 0xFF
      constant_shift = 0
      constant = integer
    else
      binary_string = "%b" % integer
      num_trailing_zeros = binary_string.length - binary_string.rindex("1") - 1
      if num_trailing_zeros.odd?
        # Arm shifted immediates cannot be shifted by an odd number of bytes.
        num_trailing_zeros -= 1
      end
      if num_trailing_zeros == 0
        raise ArmShiftedImmediateError.new("Invalid value for an arm shifted immediate: %X." % integer)
      end
      constant = integer >> num_trailing_zeros
      if constant >= 0x100
        raise ArmShiftedImmediateError.new("Invalid value for an arm shifted immediate: %X." % integer)
      end
      constant_shift = (0x10 - num_trailing_zeros/2)
    end
    
    return [constant, constant_shift]
  end
  
  def replace_arm_shifted_immediate_integer(code_location, new_integer)
    constant, constant_shift = convert_integer_to_arm_shifted_immediate(new_integer)
    
    # The upper nibble of the constant shift byte is some other code we don't want to overwrite.
    old_constant_shift_byte = read(code_location+1, 1).unpack("C").first
    old_constant_shift_byte &= 0xF0
    constant_shift |= old_constant_shift_byte
    
    write(code_location, [constant, constant_shift].pack("CC"))
  end
  
  def convert_arm_shifted_immediate_to_bit_index(constant, constant_shift)
    bit = convert_arm_shifted_immediate_to_integer(constant, constant_shift)
    
    if bit == 0
      return 0
    else
      # Get the number of bits this was shifted by.
      # This is so we can get the bit index instead of the bit.
      # For example, instead of bit 0x200, we want index 9.
      # We do this by converting to a string and counting the number of 0s in it.
      binary_string = "%b" % bit
      bit_index = binary_string.count("0")
      if binary_string.count("1") != 1
        # There's more than one bit set. This shouldn't happen since there's only supposed to be one single bit here.
        # So just default to bit 0.
        bit_index = 0
      end
      return bit_index
    end
  end
  
  def read_hardcoded_bit_constant(code_location)
    constant, constant_shift = read(code_location, 2).unpack("CC")
    
    return convert_arm_shifted_immediate_to_bit_index(constant, constant_shift)
  end
  
  def convert_bit_index_to_arm_shifted_immediate(bit_index)
    if !(0..0x1F).include?(bit_index)
      raise ArmShiftedImmediateError.new("Invalid bit index: %X, must be between 00 and 1F." % bit_index)
    end
    
    if bit_index.even?
      constant = 1
    else
      constant = 2
    end
    if bit_index == 0
      constant_shift = 0
    else
      constant_shift = (0x10 - bit_index/2)
    end
    
    return [constant, constant_shift]
  end
  
  def replace_hardcoded_bit_constant(code_location, new_bit_index)
    constant, constant_shift = convert_bit_index_to_arm_shifted_immediate(new_bit_index)
    
    # The upper nibble of the constant shift byte is some other code we don't want to overwrite.
    old_constant_shift_byte = read(code_location+1, 1).unpack("C").first
    old_constant_shift_byte &= 0xF0
    constant_shift |= old_constant_shift_byte
    
    write(code_location, [constant, constant_shift].pack("CC"))
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
    static_initializer_start = 0 # No static initializer
    static_initializer_end = 0
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
    
    load_overlay(NEW_OVERLAY_ID)
  end
  
  def has_free_space_overlay?
    !!(NEW_OVERLAY_ID && @overlays[NEW_OVERLAY_ID])
  end
  
  def fix_free_space_overlay_start_address
    overlay = overlays[NEW_OVERLAY_ID]
    overlay[:ram_start_offset] = NEW_OVERLAY_FREE_SPACE_START
    write_by_file("/ftc/arm9_overlay_table.bin", NEW_OVERLAY_ID*32 + 4, [NEW_OVERLAY_FREE_SPACE_START].pack("V"))
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
    # TODO: instead of using the filename, use the asset type to select these
    @all_sprite_pointers ||= files.select do |id, file|
      file[:type] == :file && file[:file_path] =~ /^\/so\/p_/
    end.map do |id, file|
      file[:asset_pointer]
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
    
    @rom_version = header[0x1E,1].unpack("C").first
    
    if REGION == :jp && ["dos", "por"].include?(GAME)
      raise InvalidRevisionError.new("This ROM revision is not supported. For the Japanese version of #{LONG_GAME_NAME}, only revision 01 is supported.") unless @rom_version == 1
    else
      raise InvalidRevisionError.new("This ROM revision is not supported. For the Japanese version of #{LONG_GAME_NAME}, only the original version is supported.") unless @rom_version == 0
    end
    
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
    load_overlay(NEW_OVERLAY_ID) if overlays[NEW_OVERLAY_ID]
  end
  
  def extract_to_hard_drive
    print "Extracting files from ROM... "
    
    files_written = 0
    total_files = all_files.size
    all_files.each do |file|
      next unless file[:type] == :file
      
      start_offset, end_offset, file_path = file[:start_offset], file[:end_offset], file[:file_path]
      size = end_offset - start_offset
      file_data = @rom[start_offset,size]
      
      output_path = File.join(@filesystem_directory, file_path)
      output_dir = File.dirname(output_path)
      FileUtils.mkdir_p(output_dir)
      File.open(output_path, "wb") do |f|
        f.write(file_data)
      end
      
      files_written += 1
      if block_given?
        percentage = (files_written.to_f / total_files * 100).floor
        yield(percentage)
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
      size = end_offset - start_offset
      file_data = @rom[start_offset,size]
      
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
  
  def get_assets
    @assets = []
    @assets_by_pointer = {}
    offset = ASSET_LIST_START
    while offset < ASSET_LIST_END
      asset_entry = read(offset, ASSET_LIST_ENTRY_LENGTH)
      
      asset_pointer = asset_entry[0,4].unpack("V").first
      
      asset_type = asset_entry[4,2].unpack("v").first
      
      file_path = asset_entry[6..-1]
      file_path = file_path.delete("\x00") # Remove null bytes padding the end of the string
      file = files_by_path[file_path]
      
      if asset_pointer != 0
        file[:asset_pointer] = asset_pointer
        @assets_by_pointer[asset_pointer] = file
      end
      file[:asset_type] = asset_type
      
      @assets << file
      
      offset += ASSET_LIST_ENTRY_LENGTH
    end
    
    if GAME == "por"
      # Richter's gfx files don't have a ram offset stored in the normal place.
      i = 0
      files.values.each do |file|
        if file[:asset_pointer] == nil && file[:file_path] =~ /\/sc2\/s0_ri_..\.dat/
          asset_pointer = read(RICHTERS_LIST_OF_GFX_POINTERS + i*4, 4).unpack("V").first
          file[:asset_pointer] = asset_pointer
          @assets_by_pointer[asset_pointer] = file
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
        file[:file_path] = "/" + file[:name]
      elsif file[:parent_id].nil?
        file[:file_path] = File.join("/ftc", file[:name])
      else
        file[:file_path] = File.join(@files[file[:parent_id]][:file_path], file[:name])
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
