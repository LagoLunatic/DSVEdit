
require 'open3'

class Game
  class InvalidFileError < StandardError ; end
  class RoomFindError < StandardError ; end
  
  attr_reader :areas,
              :fs,
              :folder,
              :text_database,
              :rooms_by_metadata_pointer
  
  def initialize_from_folder(input_folder_path)
    header_path = File.join(input_folder_path, "ftc", "ndsheader.bin")
    gba_rom_path = File.join(input_folder_path, "rom.gba")
    if File.file?(header_path)
      verify_game_and_load_constants(header_path)
    elsif File.file?(gba_rom_path)
      verify_game_and_load_constants(gba_rom_path)
    else
      raise InvalidFileError.new("Header file not present.")
    end
    
    @folder = input_folder_path
    
    if SYSTEM == :nds
      @fs = NDSFileSystem.new
    else
      @fs = GBADummyFilesystem.new
    end
    fs.open_directory(input_folder_path)
    
    read_from_rom()
  end
  
  def initialize_from_rom(input_rom_path, extract_to_hard_drive)
    unless File.file?(input_rom_path)
      raise InvalidFileError.new("ROM file not present.")
    end
    
    verify_game_and_load_constants(input_rom_path)
    
    if extract_to_hard_drive
      @folder = File.dirname(input_rom_path)
      
      rom_name = File.basename(input_rom_path, ".*")
      @folder = File.join(folder, "Extracted files #{rom_name}")
      
      if SYSTEM == :nds
        @fs = NDSFileSystem.new
      else
        @fs = GBADummyFilesystem.new
      end
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
    if sector.nil?
      raise RoomFindError.new("Error: %08X does not point to a valid room." % room_metadata_pointer)
    end
    index = sector.room_pointers.index(room_metadata_pointer)
    room = sector.rooms[index]
    room
  end
  
  def room_by_str(room_str)
    room_str =~ /^(\h\h)-(\h\h)-(\h\h)$/
    area_index, sector_index, room_index = $1.to_i(16), $2.to_i(16), $3.to_i(16)
    return areas[area_index].sectors[sector_index].rooms[room_index]
  end
  
  def entity_by_str(entity_str)
    entity_str =~ /^(\h\h)-(\h\h)-(\h\h)_(\h+)$/
    area_index, sector_index, room_index, entity_index = $1.to_i(16), $2.to_i(16), $3.to_i(16), $4.to_i(16)
    return areas[area_index].sectors[sector_index].rooms[room_index].entities[entity_index]
  end
  
  def door_by_str(door_str)
    door_str =~ /^(\h\h)-(\h\h)-(\h\h)_(\h+)$/
    area_index, sector_index, room_index, door_index = $1.to_i(16), $2.to_i(16), $3.to_i(16), $4.to_i(16)
    return areas[area_index].sectors[sector_index].rooms[room_index].doors[door_index]
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
  
  def special_objects
    @special_objects ||= begin
      special_objects = []
      
      SPECIAL_OBJECT_IDS.each do |obj_id|
        obj = SpecialObjectType.new(obj_id, fs)
        special_objects << obj
      end
      
      special_objects
    end
  end
  
  def players
    @players ||= begin
      players = []
      
      (0..PLAYER_COUNT-1).each do |index|
        player = Player.new(index, fs)
        players << player
      end
      
      players
    end
  end
  
  def entity_type_docs
    @entity_type_docs ||= begin
      file_contents = File.read("./docs/lists/#{GAME} Entity Types.txt")
      entity_type_docs_arr = file_contents.scan(/^(\h\h [^\n]+\n(?:  [^\n]+\n)*)/)
      
      entity_type_docs = {}
      entity_type_docs_arr.each do |desc|
        id = desc.first[0..1].to_i(16)
        entity_type_docs[id] = desc.first[3..-1]
      end
      
      entity_type_docs
    end
  rescue Errno::ENOENT => e
    ""
  end
  
  def enemy_docs
    @enemy_docs ||= begin
      file_contents = File.read("./docs/lists/#{GAME} Enemies.txt")
      enemy_docs_arr = file_contents.scan(/^(\h\h [^\n]+\n(?:  [^\n]+\n)*)/)
      
      enemy_docs = {}
      enemy_docs_arr.each do |desc|
        id = desc.first[0..1].to_i(16)
        enemy_docs[id] = desc.first[3..-1]
      end
      
      enemy_docs
    end
  rescue Errno::ENOENT => e
    ""
  end
  
  def special_object_docs
    @special_object_docs ||= begin
      file_contents = File.read("./docs/lists/#{GAME} Special Object List.txt")
      special_object_docs_arr = file_contents.scan(/^(\h\h [^\n]+\n(?:  [^\n]+\n)*)/)
      
      special_object_docs = {}
      special_object_docs_arr.each do |desc|
        id = desc.first[0..1].to_i(16)
        special_object_docs[id] = desc.first[3..-1]
      end
      
      special_object_docs
    end
  rescue Errno::ENOENT => e
    ""
  end
  
  def enemy_format_doc
    @enemy_format_docs ||= begin
      file_contents = File.read("./docs/formats/#{GAME} Enemy DNA Format.txt")
      
      file_contents
    end
  rescue Errno::ENOENT => e
    ""
  end
  
  def item_format_docs
    @item_format_docs ||= begin
      file_contents = File.read("./docs/formats/#{GAME} Item Formats.txt")
      item_format_docs_arr = file_contents.scan(/^(\S[^\n]+\n(?:  [^\n]+\n)*)/)
      
      item_format_docs = {}
      item_format_docs_arr.each_with_index do |desc, index|
        name = desc.first.lines.first.strip[0..-2]
        item_format_docs[name] = desc.first
      end
      
      item_format_docs
    end
  rescue Errno::ENOENT => e
    ""
  end
  
  def player_format_doc
    @player_format_docs ||= begin
      file_contents = File.read("./docs/formats/#{GAME} Player Format.txt")
      
      file_contents
    end
  rescue Errno::ENOENT => e
    ""
  end
  
  def items
    @items ||= begin
      items = []
      
      ITEM_TYPES.each do |item_type|
        (0..item_type[:count]-1).each do |index|
          items << GenericEditable.new(index, item_type, fs)
        end
      end
      
      items
    end
  end
  
  def get_item_global_id_by_type_and_index(item_type_index, item_index)
    if !PICKUP_SUBTYPES_FOR_ITEMS.include?(item_type_index) && !PICKUP_SUBTYPES_FOR_SKILLS.include?(item_type_index)
      raise "Bad item type: %02X" % item_type_index
    end
    
    if PICKUP_SUBTYPES_FOR_SKILLS.include?(item_type_index)
      # Skills have multiple subtypes that work the same, we simplify it to use the first subtype.
      item_type_index = PICKUP_SUBTYPES_FOR_SKILLS.first
    end
    
    item_type_index -= 2
    
    global_id = 0
    (0..item_type_index-1).each do |earlier_item_type|
      global_id += ITEM_TYPES[earlier_item_type][:count]
    end
    global_id += item_index
    
    return global_id
  end
  
  def get_item_by_type_and_index(item_type_index, item_index)
    global_id = get_item_global_id_by_type_and_index(item_type_index, item_index)
    return items[global_id]
  end
  
  def get_item_type_and_index_by_global_id(item_global_id)
    this_item_type_first_global_id = 0
    ITEM_TYPES.each_with_index do |item_type, i|
      this_item_type_global_id_range = (this_item_type_first_global_id..this_item_type_first_global_id+item_type[:count]-1)
      if this_item_type_global_id_range.include?(item_global_id)
        item_type_index = i + 2
        item_index = item_global_id - this_item_type_first_global_id
        return [item_type_index, item_index]
      end
      
      this_item_type_first_global_id += item_type[:count]
    end
    
    raise "Could not find item by global ID: %04X" % item_global_id
  end
  
  def wooden_chest_item_pools
    @wooden_chest_item_pools ||= begin
      wooden_chest_item_pools = []
      
      (NUMBER_OF_ITEM_POOLS*2).times do |i|
        wooden_chest_item_pools << ItemPool.new(i, fs)
      end
      
      wooden_chest_item_pools
    end
  end
  
  def shop_item_pools
    @shop_item_pools ||= begin
      shop_item_pools = []
      
      if GAME == "ooe"
        SHOP_HARDCODED_ITEM_POOL_COUNT.times do |i|
          shop_item_pools << OoEHardcodedShopItemPool.new(i, fs)
        end
      end
      
      SHOP_ITEM_POOL_COUNT.times do |i|
        shop_item_pools << ShopItemPool.new(i, fs)
      end
      
      if GAME == "por"
        shop_item_pools << ShopPointItemPool.new(fs)
      end
      
      shop_item_pools
    end
  end
  
  def magic_seals
    @magic_seals ||= begin
      magic_seals = []
      
      MAGIC_SEAL_COUNT.times do |i|
        magic_seals << MagicSeal.new(i, fs)
      end
      
      magic_seals
    end
  end
  
  def get_map(area_index, sector_index)
    if GAME == "dos" && [10, 11].include?(sector_index)
      @abyss_map ||= DoSMap.new(area_index, sector_index, self)
    elsif GAME == "dos" || GAME == "aos"
      @castle_map ||= DoSMap.new(area_index, sector_index, self)
    else
      @maps ||= begin
        maps = []
        
        AREA_INDEX_TO_OVERLAY_INDEX.keys.each do |area_index|
          maps << Map.new(area_index, sector_index, self)
        end
        
        maps
      end
      
      @maps[area_index]
    end
  end
  
  def clear_map_cache
    @abyss_map = nil
    @castle_map = nil
    @maps = nil
  end
  
  def fix_map_sector_and_room_indexes(area_index, sector_index)
    # TODO also fix warps
    
    map = get_map(area_index, sector_index)
    area = areas[area_index]
    
    map.tiles.each do |tile|
      tile.sector_index, tile.room_index = area.get_sector_and_room_indexes_from_map_x_y(tile.x_pos, tile.y_pos, map.is_abyss) || [0, 0]
    end
    map.write_to_rom()
  end
  
  def get_transition_rooms
    transition_rooms = []
    
    if GAME == "dos" || GAME == "aos"
      transition_room_pointers = fs.read_until_end_marker(TRANSITION_ROOM_LIST_POINTER, [0, 0, 0, 0]).unpack("V*")
      
      transition_rooms = transition_room_pointers.map do |pointer|
        get_room_by_metadata_pointer(pointer)
      end
    else
      areas.each_with_index do |area, area_index|
        map = get_map(area_index, 0)
        map.tiles.each do |tile|
          if tile.is_transition
            transition_rooms << area.sectors[tile.sector_index].rooms[tile.room_index]
          end
        end
      end
      
      transition_rooms.uniq!
    end
    
    transition_rooms
  end
  
  def read_song_index_by_area_and_sector(area_index, sector_index)
    case GAME
    when "por"
      list_entry_length = 1
    else
      list_entry_length = 4
    end
    
    if area_index == 0
      pointer = SECTOR_MUSIC_LIST_START_OFFSET + sector_index*list_entry_length
    else
      pointer = AREA_MUSIC_LIST_START_OFFSET + area_index*list_entry_length
    end
    
    return fs.read(pointer, 1).unpack("C").first # Only read the first byte since the other 3 in DoS/OoE don't seem to matter.
  end
  
  def write_song_index_by_area_and_sector(song_index, area_index, sector_index)
    case GAME
    when "por"
      list_entry_length = 1
    else
      list_entry_length = 4
    end
    
    if area_index == 0
      pointer = SECTOR_MUSIC_LIST_START_OFFSET + sector_index*list_entry_length
    else
      pointer = AREA_MUSIC_LIST_START_OFFSET + area_index*list_entry_length
    end
    
    fs.write(pointer, [song_index].pack("C"))
  end
  
  def read_song_index_by_bgm_index(bgm_index)
    raise "DoS and OoE don't have a list of available BGMs." unless GAME == "por"
    
    pointer = AVAILABLE_BGM_POOL_START_OFFSET + bgm_index*2
    return fs.read(pointer, 2).unpack("v").first
  end
  
  def write_song_index_by_bgm_index(song_index, bgm_index)
    raise "DoS and OoE don't have a list of available BGMs." unless GAME == "por"
    
    pointer = AVAILABLE_BGM_POOL_START_OFFSET + bgm_index*2
    return fs.write(pointer, [song_index].pack("v"))
  end
  
  def fix_top_screen_on_new_game
    return unless GAME == "ooe" && REGION == :usa
    
    fs.load_overlay(20) # Specifically for OoE
    fs.write(NEW_GAME_STARTING_TOP_SCREEN_TYPE_OFFSET, [0x05].pack("C"))
    fs.load_overlay(AREAS_OVERLAY) # Load back OoE's main overlay for area and sector data
  end
  
  def apply_armips_patch(patch_name)
    game_name = patch_name[0,3]
    return unless GAME == game_name.downcase
    
    if REGION != :usa
      patch_name = "#{REGION.to_s}_#{patch_name}"
    end
    
    patch_file = "asm/#{patch_name}.asm"
    if !File.file?(patch_file)
      raise "Could not find patch file: #{patch_file}"
    end
    
    # Temporarily copy code files to asm directory so armips can be run without permanently modifying the files.
    if SYSTEM == :nds
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
    else
      output_path = File.join("asm", "ftc", "rom.gba")
      output_dir = File.dirname(output_path)
      FileUtils.mkdir_p(output_dir)
      File.open(output_path, "wb") do |f|
        f.write(fs.rom)
      end
    end
    
    stdout, stderr, status = Open3.capture3("./armips/armips.exe \"#{patch_file}\"")
    unless status.success?
      stdout64, stderr64, status64 = Open3.capture3("./armips/armips64.exe \"#{patch_file}\"")
      unless status64.success?
        raise "Armips call failed (try installing the Visual C++ Redistributable for Visual Studio 2015).\nError message from armips was:\n#{stdout}#{stdout64}"
      end
    end
    
    # Now reload the file contents from the temporary directory, and then delete the directory.
    if SYSTEM == :nds
      fs.all_files.each do |file|
        next unless (file[:overlay_id] || file[:name] == "arm9.bin")
        
        input_path = File.join("asm", file[:file_path])
        file_data = File.open(input_path, "rb") do |f|
          f.read()
        end
        
        fs.overwrite_file(file[:file_path], file_data)
      end
    else
      input_path = File.join("asm", "ftc", "rom.gba")
      file_data = File.open(input_path, "rb") do |f|
        f.read()
      end
      
      fs.overwrite_rom(file_data)
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
  
  def add_new_overlay
    fs.add_new_overlay_file()
    apply_armips_patch("#{GAME}_load_new_overlay")
  end
  
  def start_test_room(save_file_index, area_index, sector_index, room_index, x_pos, y_pos)
    @orig_fs = @fs
    
    @fs = @fs.dup
    
    patch_name = "#{GAME}_room_test"
    apply_armips_patch(patch_name)
    
    fs.load_overlay(TEST_ROOM_OVERLAY) if TEST_ROOM_OVERLAY
    
    if SYSTEM == :nds
      x_pos *= 0x1000
      y_pos *= 0x1000
    end
    
    fs.write(TEST_ROOM_SAVE_FILE_INDEX_LOCATION, [save_file_index].pack("C")) if TEST_ROOM_SAVE_FILE_INDEX_LOCATION
    fs.write(TEST_ROOM_AREA_INDEX_LOCATION     , [area_index].pack("C")) if TEST_ROOM_AREA_INDEX_LOCATION
    fs.write(TEST_ROOM_SECTOR_INDEX_LOCATION   , [sector_index].pack("C"))
    fs.write(TEST_ROOM_ROOM_INDEX_LOCATION     , [room_index].pack("C"))
    fs.write(TEST_ROOM_X_POS_LOCATION          , [x_pos].pack("V"))
    fs.write(TEST_ROOM_Y_POS_LOCATION          , [y_pos].pack("V"))
    
    # In OoE the test room overlay and area overlay are loaded at the same spot.
    # So after we're done with the test room overlay we need to load the area overlay back.
    fs.load_overlay(AREAS_OVERLAY) if AREAS_OVERLAY
  end
  
  def end_test_room
    if @orig_fs.nil?
      return
    end
    @fs = @orig_fs
    @orig_fs = nil
  end
  
  def fix_unnamed_skills
    skill_region_name = case GAME
    when "dos"
      "Soul Names"
    when "por"
      "Skill Names"
    when "ooe"
      "Item Names"
    else
      return
    end
    
    first_skill_name_index = TEXT_REGIONS[skill_region_name].begin
    NAMES_FOR_UNNAMED_SKILLS.each do |skill_index, fixed_name|
      text_database.text_list[skill_index + first_skill_name_index].decoded_string = fixed_name
    end
    
    text_database.write_to_rom()
  end
  
private
  
  def verify_game_and_load_constants(header_path)
    title = File.read(header_path, 16)
    
    case title
    when "CASTLEVANIA1ACVE"
      suppress_warnings { load './constants/nds_constants.rb' }
      suppress_warnings { load './constants/dos_constants.rb' }
    when "CASTLEVANIA2ACBE"
      suppress_warnings { load './constants/nds_constants.rb' }
      suppress_warnings { load './constants/por_constants.rb' }
    when "CASTLEVANIA3YR9E"
      suppress_warnings { load './constants/nds_constants.rb' }
      suppress_warnings { load './constants/ooe_constants.rb' }
    when "CASTLEVANIA1ACVJ"
      suppress_warnings { load './constants/nds_constants.rb' }
      suppress_warnings { load './constants/dos_constants.rb' }
      suppress_warnings { load './constants/dos_constants_jp.rb' }
    when "CASTLEVANIA2ACBJ"
      suppress_warnings { load './constants/nds_constants.rb' }
      suppress_warnings { load './constants/por_constants.rb' }
      suppress_warnings { load './constants/por_constants_jp.rb' }
    when "CASTLEVANIA3YR9J"
      suppress_warnings { load './constants/nds_constants.rb' }
      suppress_warnings { load './constants/ooe_constants.rb' }
      suppress_warnings { load './constants/ooe_constants_jp.rb' }
    else
      title_gba = File.read(header_path, 0xB0)[0xA0,0x10]
      
      case title_gba
      when "CASTLEVANIA2A2CE"
        suppress_warnings { load './constants/gba_constants.rb' }
        suppress_warnings { load './constants/aos_constants.rb' }
      else
        raise InvalidFileError.new("Specified game is not a DSVania or is not a supported region.")
      end
    end
  end
  
  def suppress_warnings(&block)
    orig_verbosity = $VERBOSE
    $VERBOSE = nil
    yield
    $VERBOSE = orig_verbosity
  end
end
