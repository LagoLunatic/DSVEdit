
require 'fileutils'

class NDSFileSystem
  def read_from_rom(rom)
    @rom = rom
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
    get_file_name_table()
    get_overlay_table()
    get_file_allocation_table()
    get_extra_files()
    generate_file_paths()
  end
  
  def extract(output_folder)
    all_files.each do |file|
      next unless file[:type] == :file
      #next unless file[:overlay_id]
      
      start_offset, end_offset, file_path = file[:start_offset], file[:end_offset], file[:file_path]
      file_data = @rom[start_offset..end_offset-1]
      
      output_path = File.join(output_folder, file_path)
      output_dir = File.dirname(output_path)
      FileUtils.mkdir_p(output_dir)
      File.open(output_path, "wb") do |f|
        f.write(file_data)
      end
    end
  end
  
  def write_to_rom(output_rom_path, input_folder)
    new_start_offset = @files[0][:start_offset]
    
    @files.sort_by{|id, file| id}.each do |id, file|
      next unless file[:type] == :file
      if file[:name] =~ /\.bin$/ || file[:name] == "rom.nds"
        next
      end
      
      path = File.join(input_folder, file[:file_path])
      next unless File.file?(path)
      raise "File not found: #{path}" unless File.exist?(path)
      
      file_data = File.open(path, "rb") {|file| file.read}
      new_file_size = file_data.length
      
      unless file[:name] =~ /\.bin$/ || file[:name] == "rom.nds"
        new_end_offset = new_start_offset + new_file_size
        if (new_start_offset..new_end_offset).include?(@arm7_rom_offset) || (new_start_offset..new_end_offset).include?(@banner_end_offset)
          new_start_offset = @banner_end_offset
          new_end_offset = new_start_offset + new_file_size
        end
        @rom[new_start_offset,new_file_size] = file_data
        offset = file[:id]*8
        @rom[@file_allocation_table_offset+offset, 8] = [new_start_offset, new_end_offset].pack("VV")
        new_start_offset += new_file_size
      end
      
      # Update the lengths of changed overlay files.
      if file[:overlay_id]
        offset = file[:overlay_id] * 32
        @rom[@arm9_overlay_table_offset+offset+8, 4] = [new_file_size].pack("V")
      end
    end
    
    File.open(output_rom_path, "wb") do |f|
      f.write(@rom)
    end
    puts "Wrote #{output_rom_path}"
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
  
private
  
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
      
      @files[file_id] = {:name => "overlay9_#{overlay_id}", :type => :file, :id => file_id, :overlay_id => overlay_id}
      
      offset += 32
    end
  end
  
  def get_file_allocation_table
    file_allocation_table_data = @rom[@file_allocation_table_offset, @file_allocation_table_size]
    
    id = 0x00
    offset = 0x00
    while offset < @file_allocation_table_size
      @files[id][:start_offset], @files[id][:end_offset] = file_allocation_table_data[offset,8].unpack("VV")
      
      id += 1
      offset += 0x08
    end
  end
  
  def get_extra_files
    @extra_files = []
    @extra_files << {:name => "ndsheader.bin", :type => :file, :start_offset => 0x0, :end_offset => 0x4000}
    @extra_files << {:name => "arm9.bin", :type => :file, :start_offset => @arm9_rom_offset, :end_offset => @arm9_rom_offset + @arm9_size}
    @extra_files << {:name => "arm7.bin", :type => :file, :start_offset => @arm7_rom_offset, :end_offset => @arm7_rom_offset + @arm7_size}
    @extra_files << {:name => "arm9_overlay_table.bin", :type => :file, :start_offset => @arm9_overlay_table_offset, :end_offset => @arm9_overlay_table_offset + @arm9_overlay_table_size}
    @extra_files << {:name => "arm7_overlay_table.bin", :type => :file, :start_offset => @arm7_overlay_table_offset, :end_offset => @arm7_overlay_table_offset + @arm7_overlay_table_size}
    @extra_files << {:name => "fnt.bin", :type => :file, :start_offset => @file_name_table_offset, :end_offset => @file_name_table_offset + @file_name_table_size}
    @extra_files << {:name => "fat.bin", :type => :file, :start_offset => @file_allocation_table_offset, :end_offset => @file_allocation_table_offset + @file_allocation_table_size}
    @extra_files << {:name => "banner.bin", :type => :file, :start_offset => @banner_start_offset, :end_offset => @banner_end_offset}
    @extra_files << {:name => "rom.nds", :type => :file, :start_offset => 0, :end_offset => @rom.length}
  end
  
  def generate_file_paths
    all_files.each do |file|
      if file[:parent_id] == 0xF000
        file[:file_path] = file[:name]
      elsif file[:parent_id].nil?
        file[:file_path] = File.join("ftc", file[:name])
      else
        file[:file_path] = File.join(@files[file[:parent_id]][:name], file[:name])
      end
    end
  end
end
