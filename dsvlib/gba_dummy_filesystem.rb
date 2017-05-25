
class GBADummyFilesystem
  class ReadError < StandardError ; end
  
  include FreeSpaceManager
  
  attr_reader :rom
  
  def open_directory(filesystem_directory)
    @filesystem_directory = filesystem_directory
    input_rom_path = File.join(@filesystem_directory, "rom.gba")
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    read_free_space_from_text_file()
  end
  
  def open_and_extract_rom(input_rom_path, filesystem_directory)
    @filesystem_directory = filesystem_directory
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    extract_to_hard_drive()
    read_free_space_from_text_file()
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
    
    remove_free_space("rom.gba", offset, new_data.length)
  end
  
  def write_by_file(file_path, offset_in_file, new_data, freeing_space: false)
    # Dummy function for the FSM.
    if file_path != "rom.gba"
      raise "Invalid file: #{file_path}"
    end
    
    old_data = rom[offset_in_file, new_data.length]
    if old_data && old_data.length == new_data.length
      rom[offset_in_file, new_data.length] = new_data
    else
      raise "Invalid offset/size: %08X, length %08X" % [offset_in_file, new_data.length]
    end
    
    remove_free_space(file_path, offset_in_file, new_data.length) unless freeing_space
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
    #@original_compressed_sizes[address] = compressed_size # TODO preserve
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
    
    # TODO: check if new compressed length is bigger than original compressed length and raise an error
    #p [compr_data.length, @compressed_length]
    #if compr_data.length > @compressed_length
    #  raise "New GFX data too large"
    #end
    
    write(address, compr_data)
  end
  
  def load_overlay(overlay_id)
    # Do nothing.
  end
  
  def files_without_dirs
    # This is for the progress dialog when writing to the rom. Give it a dummy max value of 1.
    ["rom.gba"]
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
    
    puts "Done."
  end
  
  def has_uncommitted_changes?
    @has_uncommitted_changes
  end
  
  def find_file_by_ram_start_offset(ram_start_offset)
    nil
  end
  
  def convert_ram_address_to_path_and_offset(address)
    # Dummy function for the FSM.
    return ["rom.gba", convert_address(address)]
  end
  
  def files_by_path
    # Dummy function for the FSM.
    {"rom.gba" => {:name => "rom.gba", :type => :file, :start_offset => 0, :end_offset => 0 + @rom.size, :ram_start_offset => 0x08000000, :size => @rom.size}}
  end
  
  def is_pointer?(value)
    value >= 0x08000000 && value < 0x09000000
  end
end
