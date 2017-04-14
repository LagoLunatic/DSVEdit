
class GBADummyFilesystem
  class ReadError < StandardError ; end
  
  attr_reader :rom
  
  def open_directory(filesystem_directory)
    @filesystem_directory = filesystem_directory
    input_rom_path = "#{@filesystem_directory}/rom.gba"
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
  end
  
  def open_and_extract_rom(input_rom_path, filesystem_directory)
    @filesystem_directory = filesystem_directory
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    extract_to_hard_drive()
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
  end
  
  def decompress(address)
    io = StringIO.new(@rom)
    offset = convert_address(address)
    decompressed_data = GBADecompress.new(io, offset).decompress[4..-1]
    return decompressed_data
  end
  
  def load_overlay(overlay_id)
    # Do nothing.
  end
  
  def read_until_end_marker(address, end_markers)
    offset = convert_address(address)
    substring = rom[offset..-1]
    end_index = substring.index(end_markers.pack("C*"))
    return substring[0,end_index]
  end
  
  def has_uncommitted_files?
    false # TODO
  end
  
  def find_file_by_ram_start_offset(ram_start_offset)
    nil
  end
  
  def is_pointer?(value)
    value >= 0x08000000 && value < 0x09000000
  end
end
