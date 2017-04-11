
class GBADummyFilesystem
  class ReadError < StandardError ; end
  
  attr_reader :rom
  
  def initialize(rom_path)
    @rom = File.open(rom_path, "rb"){|f| f.read}
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
