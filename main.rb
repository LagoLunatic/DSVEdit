
require 'fileutils'
require 'optparse'
require 'yaml'

require_relative 'dsve'

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
  
  opts.on("-a", "--areas 0,2", Array, "Only execute for rooms in these areas (area IDs)") do |areas|
    areas.map! do |area|
      area = area.to_i
      raise "Invalid area: #{area}" unless AREA_INDEX_TO_OVERLAY_INDEX.keys.include?(area)
      area
    end
    options[:areas] = areas
  end
  
  opts.on("--sectors 0,2", Array, "Only execute for rooms in these sectors (sector IDs)") do |sectors|
    sectors.map! do |sector|
      sector = sector.to_i
      sector
    end
    options[:sectors] = sectors
  end
  
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

game = Game.new

folder = settings[:input_folder_paths][GAME]
if File.directory?(folder)
  game.initialize_from_folder(folder)
else
  input_rom_path = settings[:input_rom_paths][options[:game]]
  game.initialize_from_rom(input_rom_path)
end

fs = game.fs

renderer = Renderer.new(fs)
tiled = TMXInterface.new()
if options[:mode] == "randomize"
  randomizer = Randomizer.new(options[:seed])
end

start_time = Time.now
located_rooms = []
output_folder = "../Exported #{options[:game]}"

case options[:mode]
when "map"
  folder = "#{output_folder}/maps/"
  
  game.areas.each do |area|
    map = area.map
    
    output_map_path = "#{folder}/map-#{area.area_index}.png"
    img = renderer.render_map(map)
    
    FileUtils::mkdir_p(File.dirname(output_map_path))
    img.save(output_map_path)
  end
else
  folder = "#{output_folder}/rooms"
  
  game.areas.each do |area|
    area.sectors.each do |sector|
      if options[:sectors] && !options[:sectors].include?(sector.sector_index)
        next
      end
      
      sector.load_necessary_overlay()
      
      sector.rooms.each do |room|
        if !options[:rooms].nil? && !options[:rooms].include?(room.room_metadata_ram_pointer)
          next
        end
        
        case options[:mode]
        when "render_tileset"
          room.layers.each do |layer|
            tileset_filename = "#{folder}/#{room.area_name}/Tilesets/#{layer.tileset_filename}.png"
            renderer.get_tileset(layer.ram_pointer_to_tileset_for_layer, room.palette_offset, room.graphic_tilesets_for_room, layer.colors_per_palette, layer.collision_tileset_ram_pointer, tileset_filename)
            
            tileset_filename = "#{folder}/#{room.area_name}/Tilesets/#{layer.tileset_filename}_collision.png"
            renderer.render_collision_tileset(layer.collision_tileset_ram_pointer, tileset_filename)
          end
        when "render_room"
          renderer.render_room(folder, room)
          renderer.render_room(folder, room, collision = true)
        when "export_tmx"
          tiled.create("./#{folder}/#{room.area_name}/#{room.filename}.tmx", room)
        when "import_tmx"
          tiled.read("./#{folder}/#{room.area_name}/#{room.filename}.tmx", room)
        when "randomize"
          randomizer.randomize_room(room)
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
end

puts "Finished."

if options[:game] == "dos"
  # Change the starting room to skip the tutorial.
  fs.write(0x0202FB84, [0x00].pack("C*"))
  fs.write(0x0202FB90, [0x01].pack("C*"))
end

if GAME == "ooe"
  # Change the starting room so you can skip Ecclesia's cutscenes.
  fs.write(0x020AC15C, [0x03].pack("C")) # 3rd room in Ecclesia is Ecclesia's entrance room, that leads onto the world map.
  
  # Make the top screen when you start a new game have a normal map right from the start, instead of a black screen.
  fs.load_overlay(20)
  fs.write(0x02214F68, [0x05].pack("C"))
  
  # Make all areas on the world map accessible.
  fs.write(0x020AA8E4, [0xE3A00001].pack("V"))
end

puts "Time taken: #{Time.now-start_time}"

if options[:mode] == "locate"
  puts "Rooms containing specified entity: " + located_rooms.map{|x|"%08X" % x}.join(" ")
end

fs.commit_file_changes()
output_rom_path = settings[:output_rom_paths][options[:game]]
fs.write_to_rom(output_rom_path)
