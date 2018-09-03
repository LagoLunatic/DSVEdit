
class GBADummyFilesystem
  class ReadError < StandardError ; end
  class CompressedDataTooLarge < StandardError ; end
  class FileExpandError < StandardError ; end
  class OffsetPastEndOfFileError < StandardError ; end
  
  include FreeSpaceManager
  
  attr_reader :rom,
              :files_by_path
  
  def open_directory(filesystem_directory)
    @filesystem_directory = filesystem_directory
    input_rom_path = File.join(@filesystem_directory, "rom.gba")
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    initialize_files_by_path()
    read_free_space_from_text_file()
    read_original_compressed_sizes_from_text_file()
  end
  
  def open_and_extract_rom(input_rom_path, filesystem_directory)
    @filesystem_directory = filesystem_directory
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    initialize_files_by_path()
    extract_to_hard_drive()
    read_free_space_from_text_file()
    read_original_compressed_sizes_from_text_file()
  end
  
  def open_rom(input_rom_path)
    @filesystem_directory = nil
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    initialize_files_by_path()
  end
  
  def extract_to_hard_drive
    output_path = File.join(@filesystem_directory, "rom.gba")
    output_dir = File.dirname(output_path)
    FileUtils.mkdir_p(output_dir)
    File.open(output_path, "wb") do |f|
      f.write(@rom)
    end
    
    freespace_file = File.join(@filesystem_directory, "_dsvedit_freespace.txt")
    if File.file?(freespace_file)
      FileUtils.rm(freespace_file)
    end
    freespace_file = File.join(@filesystem_directory, "_dsvedit_orig_compressed_sizes.txt")
    if File.file?(freespace_file)
      FileUtils.rm(freespace_file)
    end
  end
  
  def write_to_rom(output_rom_path)
    print "Writing files to #{output_rom_path}... "
    
    File.open(output_rom_path, "wb") do |f|
      f.write(@rom)
    end
    yield 2
    puts "Done"
  end
  
  def rom_file_extension
    "gba"
  end
  
  def convert_address(address)
    if !is_pointer?(address)
      raise ReadError.new("Invalid address: %08X" % address)
    end
    address - 0x08000000
  end
  
  def read(address, length = 1, options={})
    offset = convert_address(address)
    return rom[offset, length]
  end
  
  def write(address, new_data)
    offset = convert_address(address)
    rom[offset, new_data.length] = new_data
    
    @has_uncommitted_changes = true
    
    remove_free_space("/rom.gba", offset, new_data.length)
  end
  
  def write_by_file(file_path, offset_in_file, new_data, freeing_space: false)
    # Dummy function for the FSM.
    if file_path != "/rom.gba"
      raise "Invalid file: #{file_path}"
    end
    
    file = files_by_path[file_path]
    if offset_in_file + new_data.length > file[:size]
      raise OffsetPastEndOfFileError.new("Offset %08X is past end of the rom (%08X bytes long)" % [offset_in_file, file[:size]])
    end
    
    rom[offset_in_file, new_data.length] = new_data
    
    @has_uncommitted_changes = true
    
    remove_free_space(file_path, offset_in_file, new_data.length) unless freeing_space
  end
  
  def read_by_file(file_path, offset_in_file, length)
    # Dummy function for the FSM.
    if file_path != "/rom.gba"
      raise "Invalid file: #{file_path}"
    end
    
    file = files_by_path[file_path]
    if offset_in_file + length > file[:size]
      raise OffsetPastEndOfFileError.new("Offset %08X is past end of the rom (%08X bytes long)" % [offset_in_file, file[:size]])
    end
    
    return rom[offset_in_file, length]
  end
  
  def overwrite_rom(new_data)
    @rom = new_data
  end
  
  def decompress(address)
    decompressed_data, compressed_size = decompress_and_get_compressed_size(address)
    return decompressed_data
  end
  
  def decompress_and_get_compressed_size(address)
    offset = convert_address(address)
    decompressed_data, compressed_size = GBALZ77.decompress(rom[offset..-1])
    if @original_compressed_sizes[address].nil?
      # Never read from this compressed data before so we don't know what its original length is.
      # Preserve this value forever so we can tell whether new data being written here would overwrite stuff after this or not.
      @original_compressed_sizes[address] = compressed_size
    end
    return [decompressed_data[4..-1], compressed_size]
  end
  
  def compress_write(address, new_data)
    uncomp_size = new_data.size + 4
    if uncomp_size > 0xFFFFFF
      raise "New data too large"
    end
    header = 0x10 | (uncomp_size << 8)
    new_data = [header].pack("V") + new_data
    
    compr_data = GBALZ77.compress(new_data)
    
    orig_compressed_size = @original_compressed_sizes[address]
    if orig_compressed_size.nil?
      # Read from the compressed data to figure out what its original compressed size is if we've never done so before.
      decompress(address)
      orig_compressed_size = @original_compressed_sizes[address]
    end
    
    puts "Old size: %06X, new size: %06X" % [orig_compressed_size, compr_data.length]
    if compr_data.length > orig_compressed_size
      raise CompressedDataTooLarge.new("New compressed data too large. The original data was 0x%06X bytes long, the new data is 0x%06X bytes long." % [orig_compressed_size, compr_data.length])
    end
    
    write(address, compr_data)
  end
  
  def convert_integer_to_bit_index(bit)
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
  
  def convert_bit_index_to_integer(new_bit_index)
    return 1 << new_bit_index
  end
  
  def reload_file_from_disk(file_path)
    if @has_uncommitted_changes
      puts "Cannot reload file as it has unsaved changes: #{file_path}"
      return
    end
    
    rom_path = File.join(@filesystem_directory, "rom.gba")
    @rom = File.open(rom_path, "rb") {|file| file.read}
    puts "Successfully reloaded #{file_path}"
  end
  
  def load_overlay(overlay_id)
    # Do nothing.
  end
  
  def files_without_dirs
    # This is for the progress dialog when writing to the rom. Give it a dummy max value of 1.
    {nil => {:name => "rom.gba", :type => :file, :start_offset => 0, :end_offset => 0 + @rom.size, :ram_start_offset => 0x08000000, :size => @rom.size, :file_path => "/rom.gba"}}
  end
  
  def all_files
    [{:name => "rom.gba", :type => :file, :start_offset => 0, :end_offset => 0 + @rom.size, :ram_start_offset => 0x08000000, :size => @rom.size, :file_path => "/rom.gba"}]
  end
  
  def read_until_end_marker(address, end_markers)
    offset = convert_address(address)
    substring = rom[offset..-1]
    end_index = substring.index(end_markers.pack("C*"))
    return substring[0,end_index]
  end
  
  def commit_changes(base_directory = @filesystem_directory)
    print "Committing changes to filesystem... "
    
    full_path = File.join(base_directory, "rom.gba")
    full_dir = File.dirname(full_path)
    FileUtils.mkdir_p(full_dir)
    File.open(full_path, "wb") do |f|
      f.write(@rom)
    end
    
    @has_uncommitted_changes = false
    
    write_free_space_to_text_file(base_directory)
    write_original_compressed_sizes_to_text_file(base_directory)
    
    puts "Done."
  end
  
  def has_uncommitted_changes?
    @has_uncommitted_changes
  end
  
  def assets_by_pointer
    {}
  end
  
  def convert_ram_address_to_path_and_offset(address)
    # Dummy function for the FSM.
    return ["/rom.gba", convert_address(address)]
  end
  
  def initialize_files_by_path
    @files_by_path = {"/rom.gba" => {:name => "rom.gba", :type => :file, :start_offset => 0, :end_offset => 0 + @rom.size, :ram_start_offset => 0x08000000, :size => @rom.size, :file_path => "/rom.gba"}}
  end
  
  def is_pointer?(value)
    value >= 0x08000000 && value < 0x09000000
  end
  
  def expand_file(file, length_to_expand_by)
    file_path = file[:file_path]
    
    if file[:size] + length_to_expand_by > MAX_ALLOWABLE_ROM_SIZE
      raise FileExpandError.new("Failed to expand rom to #{file[:size] + length_to_expand_by} bytes because that is larger than the maximum rom size allowed (#{MAX_ALLOWABLE_ROM_SIZE} bytes).")
    end
    
    old_size = file[:size]
    file[:size] += length_to_expand_by
    
    @has_uncommitted_changes = true
    
    # Expand the actual file data string, and fill it with 0 bytes.
    write_by_file(file_path, old_size, "\0"*length_to_expand_by, freeing_space: true)
  end
  
  def read_original_compressed_sizes_from_text_file
    @original_compressed_sizes = {}
    
    if @filesystem_directory.nil?
      return
    end
    
    orig_sizes_file = File.join(@filesystem_directory, "_dsvedit_orig_compressed_sizes.txt")
    if !File.file?(orig_sizes_file)
      return
    end
    
    file_contents = File.read(orig_sizes_file)
    orig_size_strs = file_contents.scan(/^(\h+) (\h+)$/)
    orig_size_strs.each do |address, orig_size|
      address = address.to_i(16)
      orig_size = orig_size.to_i(16)
      @original_compressed_sizes[address] = orig_size
    end
  end
  
  def write_original_compressed_sizes_to_text_file(base_directory=@filesystem_directory)
    if base_directory.nil?
      return
    end
    
    output_string = ""
    output_string << "This file lists locations of LZ77 compressed data in the ROM, and what the original compressed length of that data was.\n"
    output_string << "DSVEdit reads from this file so it knows whether certain new compressed data can fit in the old spot without overwriting anything.\n"
    output_string << "Don't modify this file manually unless you know what you're doing.\n\n"
    
    @original_compressed_sizes.each do |address, orig_size|
      output_string << "%08X %06X\n" % [address, orig_size]
    end
    
    orig_sizes_file = File.join(base_directory, "_dsvedit_orig_compressed_sizes.txt")
    File.open(orig_sizes_file, "w") do |f|
      f.write(output_string)
    end
  end
end
