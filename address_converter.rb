
class AddressConverter
  class ConversionError < StandardError ; end
  
  attr_reader :loaded_files, :rom, :all_overlays
  
  def initialize(rom)
    @loaded_files = {}
    @rom = rom
    initialize_all_overlays()
    load_file(0x02000000, 0x4000, ARM9_LENGTH)
  end
  
  def ram_to_rom(ram_address)
    loaded_files.each do |ram_start, file|
      #puts "ram_range: %08X..%08X" % [file[:ram_range].begin, file[:ram_range].end]
      #puts "rom_start: %08X" % file[:rom_start]
      
      if file[:ram_range].include?(ram_address)
        return file[:rom_start] + (ram_address - file[:ram_range].begin)
      end
    end
    
    loaded_files.each do |ram_start, file|
      puts "ram_range: %08X..%08X" % [file[:ram_range].begin, file[:ram_range].end]
      puts "rom_start: %08X" % file[:rom_start]
    end
    raise ConversionError.new("Failed to convert ram address to rom address: %08X." % ram_address)
  end
  
  def ram_to_filename_and_local_address(ram_address)
    loaded_files.each do |ram_start, file|
      if file[:ram_range].include?(ram_address)
        local_address = ram_address - file[:ram_range].begin
        return [file[:filename], local_address]
      end
    end
    
    loaded_files.each do |ram_start, file|
      puts "ram_range: %08X..%08X" % [file[:ram_range].begin, file[:ram_range].end]
      puts "rom_start: %08X" % file[:rom_start]
    end
    raise ConversionError.new("Failed to convert ram address to rom address: %08X." % ram_address)
  end
  
  def load_overlay(overlay_index)
    ram_start = all_overlays[overlay_index][:ram].begin
    rom_start = all_overlays[overlay_index][:rom].begin
    length = all_overlays[overlay_index][:rom].end - all_overlays[overlay_index][:rom].begin
    load_file(ram_start, rom_start, length+100)
    @loaded_files[ram_start][:filename] = "overlay9_#{overlay_index}"
  end
  
  def load_file(ram_start, rom_start, length)
    @loaded_files[ram_start] = {:ram_range => (ram_start..ram_start+length), :rom_start => rom_start}
  end
  
  def initialize_all_overlays
    @all_overlays = []
    i = 0
    while true
      overlay = {}
      
      tmp_offset = OVERLAY_RAM_INFO_START_OFFSET + 4 + 32*i
      overlay_ram_start_offset = rom[tmp_offset, 4].unpack("V*").first
      break if overlay_ram_start_offset == 0 || overlay_ram_start_offset == 0xFFFFFFFF
      overlay_ram_size = rom[tmp_offset+4, 4].unpack("V*").first
      overlay_ram_end_offset = overlay_ram_start_offset + overlay_ram_size
      overlay[:ram] = (overlay_ram_start_offset..overlay_ram_end_offset)
      
      tmp_offset = OVERLAY_ROM_INFO_START_OFFSET + 8*i
      overlay_rom_start_offset = rom[tmp_offset, 4].unpack("V*").first
      overlay_rom_end_offset = rom[tmp_offset+4, 4].unpack("V*").first
      overlay[:rom] = (overlay_rom_start_offset..overlay_rom_end_offset)
      
      @all_overlays << overlay
      i += 1
    end
  end
end
