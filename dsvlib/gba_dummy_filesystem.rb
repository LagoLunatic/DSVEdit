
class GBADummyFilesystem
  attr_reader :rom
  
  def initialize(rom_path)
    @rom = File.open(rom_path, "rb"){|f| f.read}
  end
  
  def read(address, length = 1, options={})
    address -= 0x08000000
    return rom[address, length]
  end
  
  def write(address, new_data)
    address -= 0x08000000
    rom[address, new_data.length] = new_data
  end
  
  def decompress(address)
    io = StringIO.new(@rom)
    decompressed_data = GBADecompress.new(io, address - 0x08000000).decompress[4..-1]
    return decompressed_data
  end
  
  def load_overlay(overlay_id)
    # Do nothing.
  end
  
  def read_until_end_marker(address, end_markers)
    address -= 0x08000000
    substring = rom[address..-1]
    end_index = substring.index(end_markers.pack("C*"))
    return substring[0,end_index]
  end
  
  def has_uncommitted_files?
    false # TODO
  end
end
