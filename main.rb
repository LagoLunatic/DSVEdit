
require 'fileutils'
require 'optparse'
require 'yaml'

require_relative 'renderer.rb'
require_relative 'tmx_interface.rb'
require_relative 'major_area.rb'
require_relative 'sub_area.rb'
require_relative 'room.rb'
require_relative 'layer.rb'
require_relative 'entity.rb'
require_relative 'address_converter.rb'
require_relative 'map.rb'
require_relative 'door.rb'

require_relative 'constants/shared_constants.rb'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: main.rb [options]"
  
  opts.on("-g", "--game DoS/PoR/OoE", "Which game to execute on") do |game|
    options[:game] = game.downcase
    case options[:game]
    when "dos"
      require_relative 'constants/dos_constants.rb'
    when "por"
      require_relative 'constants/por_constants.rb'
    when "ooe"
      require_relative 'constants/ooe_constants.rb'
    else
      raise "Invalid game: #{options[:game]}"
    end
  end
  
  opts.on("-r", "--rooms 020AB03C,020A8740", Array, "Only execute for these rooms (room metadata ram addresses)") do |rooms|
    rooms = rooms.map{|str| str.to_i(16)}
    options[:rooms] = rooms
  end
  
  opts.on("-a", "--areas 0,2", Array, "Only execute for rooms in these major areas (area IDs)") do |areas|
    areas.map! do |area|
      area = area.to_i
      raise "Invalid area: #{area}" unless AREA_INDEX_TO_OVERLAY_INDEX.keys.include?(area)
      area
    end
    options[:major_areas] = areas
  end
  
  #opts.on("-re", "--regions 0,2", Array, "Only execute for rooms in these sub-areas (area IDs)") do |areas|
  #  areas.map! do |area|
  #    area = area.to_i
  #    #raise "Invalid area: #{area}" unless AREA_INDEX_TO_OVERLAY_INDEX.keys.include?(area) # TODO: validate subareas
  #    area
  #  end
  #  options[:sub_areas] = areas
  #end
  
  opts.on("-m", "--mode render_tileset/render_room/export_tmx/import_tmx/map/randomize/locate", "What action to execute") do |mode|
    raise "Invalid mode: #{mode}" unless %w(render_tileset render_room export_tmx import_tmx map randomize locate).include?(mode)
    options[:mode] = mode
  end
  
  opts.on("-l", "--locate 02-3C", "Print a list of rooms that contain the specified entity") do |entity|
    match = entity.match(/^(\h{1,2})-(\h{1,2})$/)
    raise "Invalid entity format" if match.nil?
    type = match[1].to_i(16)
    subtype = match[2].to_i(16)
    options[:locate_type] = type
    options[:locate_subtype] = subtype
  end
  
  opts.on("-s", "--seed 123", "Seed to use for the randomizer") do |seed|
    raise "Seed must be an integer" unless seed =~ /^\d+$/
    options[:seed] = seed.to_i
  end
end.parse!

if options[:game].nil?
  puts "Must specify game"
  exit
end

raise "Must specify entity to locate" if options[:mode] == "locate" && options[:locate_type].nil?

if options[:mode] == "randomize"
  randomize_doors = false
  only_randomize_transition_doors = true
  randomize_doors_going_back = false
  randomize_enemies = true
  randomize_bosses = false
  allow_randomization_between_items_skills_passives = true
  seed = options[:seed]
  log = File.open("./logs/random.txt", "a")
  if seed
    rng = Random.new(seed)
    log.puts "Using seed: #{seed}"
  else
    rng = Random.new
    log.puts "New random seed: #{rng.seed}"
  end
  log.close()
end

if File.exist?("settings.yml")
  settings = YAML::load_file("settings.yml")
else
  settings = {}
end
if settings[:input_rom_paths].nil?
  settings[:input_rom_paths] = {}
end
if settings[:output_rom_paths].nil?
  settings[:output_rom_paths] = {}
end
if !settings[:input_rom_paths][options[:game]]
  while true
    puts "Specify input ROM path for #{LONG_GAME_NAME} (this file will not be modified):"
    path = gets.chomp
    if File.exist?(path) && File.file?(path)
      game_title = File.read(path, 12)
      if game_title == "CASTLEVANIA1" && options[:game] == "dos"
        break
      elsif game_title == "CASTLEVANIA2" && options[:game] == "por"
        break
      elsif game_title == "CASTLEVANIA3" && options[:game] == "ooe"
        break
      else
        puts "That file isn't a #{LONG_GAME_NAME} ROM."
      end
    else
      puts "That path doesn't point to a file."
    end
  end
  settings[:input_rom_paths][options[:game]] = path
end
if !settings[:output_rom_paths][options[:game]]
  while true
    puts "Specify output ROM path for #{LONG_GAME_NAME} (this file WILL be modified):"
    path = gets.chomp
    if File.exist?(path) && !File.file?(path)
      puts "That path points to a directory."
    else
      break
    end
  end
  settings[:output_rom_paths][options[:game]] = path
end
File.open("settings.yml", "w") do |f|
  f.write(settings.to_yaml)
end

input_rom_path = settings[:input_rom_paths][options[:game]]
rom = File.open(input_rom_path, "rb") {|file| file.read}

renderer = Renderer.new(rom)
tiled = TMXInterface.new(rom)
converter = AddressConverter.new(rom)

CONSTANT_OVERLAYS.each do |overlay_index|
  converter.load_overlay(overlay_index)
end

start_time = Time.now
located_rooms = []
output_folder = "../Exported #{options[:game]}"

if %w(render_tileset render_room export_tmx import_tmx locate randomize).include?(options[:mode])
  AREA_INDEX_TO_OVERLAY_INDEX.each do |major_area_index, list_of_sub_areas|
    if options[:major_areas] && !options[:major_areas].include?(major_area_index)
      next
    end
    
    major_area = MajorArea.new(major_area_index, rom, converter)
    
    major_area.sub_areas.each do |sub_area|
      if options[:sub_areas] && !options[:sub_areas].include?(sub_area.sub_area_index)
        next
      end
      #puts "major_area_index: #{major_area_index}"
      #puts "sub_area_index: #{sub_area.sub_area_index}"
      
      sub_area.rooms.each do |room|
        if !options[:rooms].nil? && !options[:rooms].include?(room.room_metadata_ram_pointer)
          next
        end
        
        folder = "#{output_folder}/rooms"
        
        case options[:mode]
        when "render_tileset"
          room.layers.each do |layer|
            tileset_filename = "#{folder}/#{room.area_name}/Tilesets/#{layer.tileset_filename}.png"
            
            renderer.render_tileset(layer.pointer_to_tileset_for_layer, room.palette_offset, room.graphic_tilesets_for_room, layer.colors_per_palette, tileset_filename)
          end
        when "render_room"
          renderer.render_room(folder, room)
        when "export_tmx"
          tiled.create("./#{folder}/#{room.area_name}/#{room.filename}.tmx", room)
        when "import_tmx"
          tiled.read("./#{folder}/#{room.area_name}/#{room.filename}.tmx", room)
        when "randomize"
          # Randomize entities
          
          available_enemy_ids_for_room = COMMON_ENEMY_IDS.dup
          #if room.entities.count{|entity| entity.is_enemy?} >= 4
          #  available_enemy_ids_for_room -= VERY_LARGE_ENEMIES
          #end
          
          room.entities.each do |entity|
            case entity.type
            when 0x01 # Enemy
              next unless randomize_enemies
              
              available_enemy_ids_for_entity = nil
              if entity.is_boss?
                next unless randomize_bosses
                available_enemy_ids_for_entity = BOSS_IDS
              elsif entity.is_common_enemy?
                available_enemy_ids_for_entity = available_enemy_ids_for_room
                if !VERY_LARGE_ENEMIES.include?(entity.subtype)
                  available_enemy_ids_for_entity -= VERY_LARGE_ENEMIES
                end
              else
                puts "Enemy #{entity} isn't in either the enemy list or boss list. Todo: fix this"
                next
              end
              
              # Enemies are chosen weighted closer to the ID of what the original enemy was so that early game enemies are less likely to roll into endgame enemies.
              # Method taken from: https://gist.github.com/O-I/3e0654509dd8057b539a
              weights = available_enemy_ids_for_entity.map do |possible_enemy_id|
                id_difference = (possible_enemy_id - entity.subtype)
                weight = (available_enemy_ids_for_entity.length - id_difference).abs
                weight = weight**2
                weight
              end
              ps = weights.map{|w| w.to_f / weights.reduce(:+)}
              weighted_enemy_ids = available_enemy_ids_for_entity.zip(ps).to_h
              random_enemy_id = weighted_enemy_ids.max_by{|_, weight| rng.rand ** (1.0 / weight)}.first
              
              #random_enemy_id = available_enemy_ids_for_entity.sample(random: rng)
              entity.subtype = random_enemy_id
              
            when 0x02
              
            when 0x04 # Pickup
              if allow_randomization_between_items_skills_passives
                if rng.rand(1..100) <= 80 # 80% chance to randomize into an item
                  entity.subtype = ITEM_ID_RANGES.keys.sample(random: rng)
                  entity.var_b = rng.rand(ITEM_ID_RANGES[entity.subtype])
                elsif options[:game] == "dos"
                  entity.type = 2 # special object
                  entity.subtype = 1 # candle
                  entity.var_a = 0 # glowing soul lamp
                  entity.var_b = (ITEM_BYTE_11_RANGE_FOR_SKILLS.to_a + ITEM_BYTE_11_RANGE_FOR_PASSIVES.to_a).sample(random: rng)
                else # 20% chance to randomize into a skill/passive
                  entity.subtype = ITEM_BYTE_7_VALUE_FOR_SKILLS_AND_PASSIVES
                  entity.var_b = (ITEM_BYTE_11_RANGE_FOR_SKILLS.to_a + ITEM_BYTE_11_RANGE_FOR_PASSIVES.to_a).sample(random: rng)
                end
                
              else
                
              end
            end
            
            entity.write_to_rom()
          end
        when "locate"
          room.entities.each do |entity|
            if entity.type == options[:locate_type] && entity.subtype == options[:locate_subtype]
              located_rooms << room.room_metadata_ram_pointer
              break
            end
          end
        else
          raise "Invalid mode: #{options[:mode]}"
        end
      end
    end
  end
else
  folder = "#{output_folder}/maps/"
  if options[:game] == "dos"
    map = DoSMap.new(MAP_TILE_METADATA_START_OFFSET, MAP_TILE_LINE_DATA_START_OFFSET, 3008, rom, converter)
    renderer.render_map(map, folder, i)
  else
    i = 0
    while true
      map_tile_metadata_ram_pointer = rom[converter.ram_to_rom(MAP_TILE_METADATA_LIST_START_OFFSET+i*4), 4].unpack("V*").first
      break if map_tile_metadata_ram_pointer == 0
      map_tile_line_data_ram_pointer = rom[converter.ram_to_rom(MAP_TILE_LINE_DATA_LIST_START_OFFSET+i*4), 4].unpack("V*").first
      number_of_tiles = rom[converter.ram_to_rom(MAP_LENGTH_DATA_START_OFFSET+i*2), 2].unpack("v*").first
      
      map = Map.new(map_tile_metadata_ram_pointer, map_tile_line_data_ram_pointer, number_of_tiles, rom, converter)
      renderer.render_map(map, folder, i)
      
      i += 1
    end
  end
end

# Randomize which soul bosses drop
if options[:game] == "dos" && options[:mode] == "randomize"
  boss_soul_ids = BOSS_IDS.map do |id|
    soul_id = rom[ENEMY_DNA_START_OFFSET + id*36 + 26].unpack("C*").first # 27th byte is the soul this enemy drops.
    soul_id
  end
  #raise boss_soul_ids.map{|x| x.to_s(16)}.inspect
  boss_soul_ids = boss_soul_ids.shuffle(random: rng)
  important_boss_soul_ids = [0x35, 0x74, 0x75, 0x00, 0x01, 0x02, 0x36, 0x37, 0x77, 0x78] # maybe add succubus to this list?
  unused_important_boss_soul_ids = important_boss_soul_ids.dup
  
  # TODO: make bosses sometimes drop a good item like a weapon in addition to the soul
  
  BOSS_IDS.shuffle.each_with_index do |id, i|
    next if id == 0x66 # don't randomize balore's soul since you need it to get out.
    #random_soul_id = boss_soul_ids.delete_at($rng.rand(boss_soul_ids.length)) # deletes the element from the array so it can't be chosen twice.
    #random_soul_id = boss_soul_ids[i] # has been shuffled already so this is random
    if unused_important_boss_soul_ids.length > 0
      random_soul_id = unused_important_boss_soul_ids.sample(random: rng)
      unused_important_boss_soul_ids.delete(random_soul_id)
    else # Exhausted the important souls. Give the boss an unimportant boss soul instead.
      random_soul_id = (boss_soul_ids - important_boss_soul_ids).sample(random: rng)
    end
    #puts "%08X" % (ENEMY_DNA_START_OFFSET + id*36 + 26)
    #exit
    rom[ENEMY_DNA_START_OFFSET + id*36 + 26] = [random_soul_id].pack("C*")
    #rom[ENEMY_DNA_START_OFFSET + id*36 + 14] = [0].pack("C*") # set hp to 0 for debugging purposes
    #rom[ENEMY_DNA_START_OFFSET + id*36 + 15] = [0].pack("C*")
  end
  
  # The below line fixes a bug in the game. The bug works like this: The first time you get an ability soul, it activates the other ability souls whose binary bits are equal to the integer representation of the ability soul you just got. For example doppelganger is the 2nd ability soul (starting from 0 - not 1), which in binary is 00000010. This means it activates the 1st ability soul, which is malphas. Even if you don't have malphas yet. This bugged code runs the first time you get a soul of each type, but works fine for red, blue, and yellow souls. So only you first ability soul is affected. Normally this is balore, the 0th ability soul. So this bug isn't noticeable in a normal playthrough, because 0 doesn't activate any ability souls.
  rom[0x32240,7*4] = [0xE3540003, 0x0A00002D, 0x908FF104, 0xEA000011, 0xEA000001, 0xEA000004, 0xEA000007].pack("V*")
  
  # Change the starting room to skip the tutorial.
  #rom[0x33B84] = [0x00].pack("C*")
  #rom[0x33B90] = [0x01].pack("C*")
end

if GAME == "ooe"
  # Change the starting room so you can skip Ecclesia's cutscenes.
  code_address = converter.ram_to_rom(0x020AC15C)
  rom[code_address] = [0x03].pack("C*") # 3rd room in Ecclesia is Ecclesia's entrance room, that leads onto the world map.
  
  # Make all areas on the world map accessible.
  code_address = converter.ram_to_rom(0x020AA8E4)
  rom[code_address,4] = [0xE3A00001].pack("V*")
end

puts "Time taken: #{Time.now-start_time}"

if options[:mode] == "locate"
  puts "Rooms containing specified entity: " + located_rooms.map{|x|"%08X" % x}.join(" ")
end

output_rom_path = settings[:output_rom_paths][options[:game]]
File.open(output_rom_path, "wb") do |f|
  f.write(rom)
end
