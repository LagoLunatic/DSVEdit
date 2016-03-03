
require 'fileutils'

class NDSFileSystem
  class ConversionError < StandardError ; end
  class OffsetPastEndOfFileError < StandardError ; end
  
  attr_reader :files,
              :files_by_path,
              :overlays,
              :rom
  
  def open_directory(filesystem_directory)
    @filesystem_directory = filesystem_directory
    input_rom_path = "#{@filesystem_directory}/ftc/rom.nds"
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    read_from_rom()
    @files.each do |id, file|
      next unless file[:type] == :file
      
      file[:size] = File.size(File.join(@filesystem_directory, file[:file_path]))
      file[:end_offset] = file[:start_offset] + file[:size]
    end
  end
  
  def open_and_extract_rom(input_rom_path, filesystem_directory)
    @filesystem_directory = filesystem_directory
    @rom = File.open(input_rom_path, "rb") {|file| file.read}
    read_from_rom()
    extract()
  end
  
  def write_to_rom(output_rom_path)
    print "Writing files to #{output_rom_path}... "
    
    new_start_offset = @files[0][:start_offset]
    
    @files.sort_by{|id, file| id}.each do |id, file|
      next unless file[:type] == :file
      if file[:name] =~ /\.bin$/ || file[:name] == "rom.nds"
        next
      end
      
      file_data = get_file_data_from_opened_files_cache(file[:file_path])
      new_file_size = file_data.length
      
      new_end_offset = new_start_offset + new_file_size
      if (new_start_offset..new_end_offset).include?(@arm7_rom_offset) || (new_start_offset..new_end_offset).include?(@banner_end_offset)
        new_start_offset = @banner_end_offset
        new_end_offset = new_start_offset + new_file_size
      end
      @rom[new_start_offset,new_file_size] = file_data
      offset = file[:id]*8
      @rom[@file_allocation_table_offset+offset, 8] = [new_start_offset, new_end_offset].pack("VV")
      new_start_offset += new_file_size
      
      # Update the lengths of changed overlay files.
      if file[:overlay_id]
        offset = file[:overlay_id] * 32
        @rom[@arm9_overlay_table_offset+offset+8, 4] = [new_file_size].pack("V")
      end
    end
    
    # Update arm9
    file = @extra_files.find{|file| file[:name] == "arm9.bin"}
    file_data = get_file_data_from_opened_files_cache(file[:file_path])
    new_file_size = file_data.length
    if @arm9_size != new_file_size
      raise "ARM9 changed size"
    end
    @rom[file[:start_offset], file[:size]] = file_data
    
    File.open(output_rom_path, "wb") do |f|
      f.write(@rom)
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
      ram_range = (file[:ram_start_offset]..file[:ram_start_offset]+file[:size])
      if ram_range.include?(ram_address)
        offset_in_file = ram_address - file[:ram_start_offset]
        return [file[:file_path], offset_in_file]
      end
    end
    
    @currently_loaded_files.each do |ram_start_offset, file|
      if file[:overlay_id]
        puts "overlay loaded: %02d" % file[:overlay_id]
      end
      puts "ram_range: %08X..%08X" % [file[:ram_start_offset], file[:ram_start_offset]+file[:size]]
      puts "rom_start: %08X" % file[:start_offset]
    end
    raise ConversionError.new("Failed to convert ram address to rom address: %08X." % ram_address)
  end
  
  def read(ram_address, length=1)
    file_path, offset_in_file = convert_ram_address_to_path_and_offset(ram_address)
    return read_by_file(file_path, offset_in_file, length)
  end
  
  def read_by_file(file_path, offset_in_file, length)
    file = files_by_path[file_path]
    if offset_in_file + length > file[:size]
      raise OffsetPastEndOfFileError.new("Offset %08X is past end of file #{file_path} (%08X bytes long)" % [offset_in_file, file[:size]])
    end
    
    file_data = get_file_data_from_opened_files_cache(file_path)
    return file_data[offset_in_file, length]
  end
  
  def read_until_end_marker(ram_address, end_marker)
    file_path, offset_in_file = convert_ram_address_to_path_and_offset(ram_address)
    file_data = get_file_data_from_opened_files_cache(file_path)
    substring = file_data[offset_in_file..-1]
    end_index = substring.index([end_marker].pack("C*"))
    return substring[0,end_index]
  end
  
  def write(ram_address, new_data)
    file_path, offset_in_file = convert_ram_address_to_path_and_offset(ram_address)
    write_by_file(file_path, offset_in_file, new_data)
  end
  
  def write_by_file(file_path, offset_in_file, new_data)
    file = files_by_path[file_path]
    if offset_in_file + new_data.length > file[:size]
      raise OffsetPastEndOfFileError.new("Offset %08X is past end of file #{file_path} (%08X bytes long)" % [offset_in_file, file[:size]])
    end
    
    file_data = get_file_data_from_opened_files_cache(file_path)
    file_data[offset_in_file, new_data.length] = new_data
    @opened_files_cache[file_path] = file_data
    @uncommitted_files << file_path
  end
  
  def commit_file_changes
    print "Committing changes to filesystem... "
    
    @uncommitted_files.each do |file_path|
      file_data = get_file_data_from_opened_files_cache(file_path)
      full_path = File.join(@filesystem_directory, file_path)
      File.open(full_path, "rb+") do |f|
        f.write(file_data)
      end
    end
    @uncommitted_files = []
    
    puts "Done."
  end
  
  def has_uncommitted_files?
    !@uncommitted_files.empty?
  end
  
  def expand_file_and_get_end_of_file_ram_address(ram_address, length_to_expand_by)
    file_path, offset_in_file = convert_ram_address_to_path_and_offset(ram_address)
    file = @currently_loaded_files.values.find{|file| file[:file_path] == file_path}
    file[:size] += length_to_expand_by
    
    file_data = get_file_data_from_opened_files_cache(file_path)
    local_end_of_file = file_data.length
    offset_difference = local_end_of_file - offset_in_file
    
    return ram_address + offset_difference
  end
  
private
  
  def read_from_rom
    @game_name = @rom[0x00,12]
    raise "Not a DSVania" unless %w(CASTLEVANIA1 CASTLEVANIA2 CASTLEVANIA3).include?(@game_name)
    
    @arm9_rom_offset, @arm9_entry_address, @arm9_ram_offset, @arm9_size = @rom[0x20,16].unpack("VVVV")
    @arm7_rom_offset, @arm7_entry_address, @arm7_ram_offset, @arm7_size = @rom[0x30,16].unpack("VVVV")
    
    @file_name_table_offset, @file_name_table_size, @file_allocation_table_offset, @file_allocation_table_size = @rom[0x40,16].unpack("VVVV")
    
    @arm9_overlay_table_offset, @arm9_overlay_table_size = @rom[0x50,8].unpack("VV")
    @arm7_overlay_table_offset, @arm7_overlay_table_size = @rom[0x58,8].unpack("VV")
    
    @banner_start_offset = @rom[0x68,4].unpack("V").first
    @banner_end_offset = @banner_start_offset + 0x840 # ??
    
    @files = {}
    @overlays = []
    @currently_loaded_files = {}
    @opened_files_cache = {}
    @uncommitted_files = []
    
    get_file_name_table()
    get_overlay_table()
    get_file_allocation_table()
    get_extra_files()
    generate_file_paths()
    get_file_ram_start_offsets()
  end
  
  def extract
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
  
  def get_file_name_table
    file_name_table_data = @rom[@file_name_table_offset, @file_name_table_size]
    
    subtable_offset, subtable_first_file_id, number_of_dirs = file_name_table_data[0x00,8].unpack("Vvv")
    get_file_name_subtable(subtable_offset, subtable_first_file_id, 0xF000)
    
    i = 1
    while i < number_of_dirs
      subtable_offset, subtable_first_file_id, parent_dir_id = file_name_table_data[0x00+i*8,8].unpack("Vvv")
      get_file_name_subtable(subtable_offset, subtable_first_file_id, 0xF000 + i)
      i += 1
    end
  end
  
  def get_file_name_subtable(subtable_offset, subtable_first_file_id, parent_dir_id)
    i = 0
    offset = @file_name_table_offset + subtable_offset
    next_file_id = subtable_first_file_id
    
    while true
      length = @rom[offset,1].unpack("C*").first
      offset += 1
      
      case length
      when 0x01..0x7F
        type = :file
        
        name = @rom[offset,length]
        offset += length
        
        id = next_file_id
        next_file_id += 1
      when 0x81..0xFF
        type = :subdir
        
        length = length & 0x7F
        name = @rom[offset,length]
        offset += length
        
        id = @rom[offset,2].unpack("v").first
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
  
  def get_overlay_table
    overlay_table_data = @rom[@arm9_overlay_table_offset, @arm9_overlay_table_size]
    
    offset = 0x00
    while offset < @arm9_overlay_table_size
      overlay_id, overlay_ram_address, overlay_size, _, _, _, file_id, _ = overlay_table_data[0x00+offset,32].unpack("V*")
      
      @files[file_id] = {:name => "overlay9_#{overlay_id}", :type => :file, :id => file_id, :overlay_id => overlay_id, :ram_start_offset => overlay_ram_address, :size => overlay_size}
      @overlays << @files[file_id]
      
      offset += 32
    end
  end
  
  def get_file_ram_start_offsets
    offset = LIST_OF_FILE_RAM_LOCATIONS_START_OFFSET
    while offset < LIST_OF_FILE_RAM_LOCATIONS_END_OFFSET
      file_data = @rom[offset, LIST_OF_FILE_RAM_LOCATIONS_ENTRY_LENGTH]
      
      ram_start_offset = file_data[0,4].unpack("V*").first
      
      file_path = file_data[6..-1]
      file_path = file_path.delete("\x00") # Remove null bytes padding the end of the string
      file = files_by_path[file_path]
      
      file[:ram_start_offset] = ram_start_offset
      
      offset += LIST_OF_FILE_RAM_LOCATIONS_ENTRY_LENGTH
    end
  end
  
  def get_file_allocation_table
    file_allocation_table_data = @rom[@file_allocation_table_offset, @file_allocation_table_size]
    
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
    @extra_files << {:name => "ndsheader.bin", :type => :file, :start_offset => 0x0, :end_offset => 0x4000}
    arm9_file = {:name => "arm9.bin", :type => :file, :start_offset => @arm9_rom_offset, :end_offset => @arm9_rom_offset + @arm9_size, :ram_start_offset => @arm9_ram_offset, :size => @arm9_size}
    @extra_files << arm9_file
    load_file(arm9_file)
    @extra_files << {:name => "arm7.bin", :type => :file, :start_offset => @arm7_rom_offset, :end_offset => @arm7_rom_offset + @arm7_size}
    @extra_files << {:name => "arm9_overlay_table.bin", :type => :file, :start_offset => @arm9_overlay_table_offset, :end_offset => @arm9_overlay_table_offset + @arm9_overlay_table_size}
    @extra_files << {:name => "arm7_overlay_table.bin", :type => :file, :start_offset => @arm7_overlay_table_offset, :end_offset => @arm7_overlay_table_offset + @arm7_overlay_table_size}
    @extra_files << {:name => "fnt.bin", :type => :file, :start_offset => @file_name_table_offset, :end_offset => @file_name_table_offset + @file_name_table_size}
    @extra_files << {:name => "fat.bin", :type => :file, :start_offset => @file_allocation_table_offset, :end_offset => @file_allocation_table_offset + @file_allocation_table_size}
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
end
