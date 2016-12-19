
class Game
  class InvalidGameError < StandardError ; end
  
  attr_reader :areas, :fs, :folder, :text_database, :rooms_by_metadata_pointer
  
  def initialize_from_folder(input_folder_path)
    header_path = File.join(input_folder_path, "ftc", "ndsheader.bin")
    unless File.file?(header_path)
      raise "Header file not present"
    end
    
    verify_game_and_load_constants(header_path)
    
    @folder = input_folder_path
    
    @fs = NDSFileSystem.new
    fs.open_directory(input_folder_path)
    
    read_from_rom()
  end
  
  def initialize_from_rom(input_rom_path, extract_to_hard_drive)
    unless File.file?(input_rom_path)
      raise "ROM file not present"
    end
    
    verify_game_and_load_constants(input_rom_path)
    
    if extract_to_hard_drive
      @folder = File.dirname(input_rom_path)
      rom_name = File.basename(input_rom_path, ".*")
      @folder = File.join(folder, "Extracted files #{rom_name}")
      
      @fs = NDSFileSystem.new
      fs.open_and_extract_rom(input_rom_path, folder)
    else
      @folder = nil
      
      @fs = NDSFileSystem.new
      fs.open_rom(input_rom_path)
    end
    
    read_from_rom()
  end
  
  def read_from_rom
    @areas = []
    AREA_INDEX_TO_OVERLAY_INDEX.each do |area_index, list_of_sub_areas|
      area = Area.new(area_index, self)
      @areas << area
    end
    
    @sectors_by_room_metadata_pointer = {}
    areas.each do |area|
      area.sectors.each do |sector|
        sector.room_pointers.each do |room_pointer|
          @sectors_by_room_metadata_pointer[room_pointer] = sector
        end
      end
    end
    
    @text_database = TextDatabase.new(fs)
  end
  
  def each_room
    areas.each do |area|
      area.sectors.each do |sector|
        sector.load_necessary_overlay()
        sector.rooms.each do |room|
          yield room
        end
      end
    end
  end
  
  def get_room_by_metadata_pointer(room_metadata_pointer)
    sector = @sectors_by_room_metadata_pointer[room_metadata_pointer]
    index = sector.room_pointers.index(room_metadata_pointer)
    room = sector.rooms[index]
    room
  end
  
  def enemy_dnas
    @enemy_dnas ||= begin
      enemy_dnas = []
      
      ENEMY_IDS.each do |enemy_id|
        enemy_dna = EnemyDNA.new(enemy_id, fs)
        enemy_dnas << enemy_dna
      end
      
      enemy_dnas
    end
  end
  
  def get_transition_rooms
    transition_rooms = []
    
    if GAME == "dos"
      transition_room_pointers = fs.read_until_end_marker(TRANSITION_ROOM_LIST_POINTER, [0, 0, 0, 0]).unpack("V*")
      
      transition_rooms = transition_room_pointers.map do |pointer|
        get_room_by_metadata_pointer(pointer)
      end
    else
      areas.each do |area|
        area.map.tiles.each do |tile|
          if tile.is_transition
            transition_rooms << area.sectors[tile.sector_index].rooms[tile.room_index]
          end
        end
      end
      
      transition_rooms.uniq!
    end
    
    transition_rooms
  end
  
  def fix_top_screen_on_new_game
    return unless GAME == "ooe"
    
    fs.load_overlay(20)
    fs.write(NEW_GAME_STARTING_TOP_SCREEN_TYPE_OFFSET, [0x05].pack("C"))
  end
  
  def apply_armips_patch(patch_name)
    game_name = patch_name[0,3]
    return unless GAME == game_name.downcase
    
    patch_file = "asm/#{patch_name}.asm"
    if !File.file?(patch_file)
      raise "Could not find patch file: #{patch_file}"
    end
    
    # Temporarily copy code files to asm directory so armips can be run without permanently modifying the files.
    fs.all_files.each do |file|
      next unless (file[:overlay_id] || file[:name] == "arm9.bin")
      
      file_data = fs.read_by_file(file[:file_path], 0, file[:size])
      
      output_path = File.join("asm", file[:file_path])
      output_dir = File.dirname(output_path)
      FileUtils.mkdir_p(output_dir)
      File.open(output_path, "wb") do |f|
        f.write(file_data)
      end
    end
    
    success = system("./armips/armips.exe \"#{patch_file}\"")
    unless success
      success = system("./armips/armips64.exe \"#{patch_file}\"")
      unless success
        raise "Armips call failed (try installing the Visual C++ Redistributable for Visual Studio 2015)"
      end
    end
    
    # Now reload the file contents from the temporary directory, and then delete the directory.
    fs.all_files.each do |file|
      next unless (file[:overlay_id] || file[:name] == "arm9.bin")
      
      input_path = File.join("asm", file[:file_path])
      input_dir = File.dirname(input_path)
      FileUtils.mkdir_p(input_dir)
      file_data = File.open(input_path, "rb") do |f|
        f.read()
      end
      
      fs.write_by_file(file[:file_path], 0, file_data)
    end
  ensure
    if File.exist?(File.join("asm", "ftc"))
      FileUtils.rm_r(File.join("asm", "ftc"))
    end
  end
  
  def set_starting_room(area_index, sector_index, room_index)
    apply_armips_patch("por_allow_changing_starting_room")
    
    if NEW_GAME_STARTING_AREA_INDEX_OFFSET
      fs.write(NEW_GAME_STARTING_AREA_INDEX_OFFSET, [area_index].pack("C"))
    end
    fs.write(NEW_GAME_STARTING_SECTOR_INDEX_OFFSET, [sector_index].pack("C"))
    fs.write(NEW_GAME_STARTING_ROOM_INDEX_OFFSET, [room_index].pack("C"))
  end
  
  def fix_unnamed_skills
    case GAME
    when "dos"
      soul_name_list_start = TEXT_REGIONS["Soul Names"].begin
      NAMES_FOR_UNNAMED_SKILLS.each do |soul_id, fixed_name|
        text_database.text_list[soul_id + soul_name_list_start].decoded_string = fixed_name
      end
      
      text_database.write_to_rom()
    end
  end
  
private
  
  def verify_game_and_load_constants(header_path)
    case File.read(header_path, 12)
    when "CASTLEVANIA1"
      suppress_warnings { load './constants/dos_constants.rb' }
    when "CASTLEVANIA2"
      suppress_warnings { load './constants/por_constants.rb' }
    when "CASTLEVANIA3"
      suppress_warnings { load './constants/ooe_constants.rb' }
    else
      raise InvalidGameError.new("Specified game is not a DSVania.")
    end
  end
  
  def suppress_warnings(&block)
    orig_verbosity = $VERBOSE
    $VERBOSE = nil
    yield
    $VERBOSE = orig_verbosity
  end
end
