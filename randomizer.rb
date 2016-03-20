
class Randomizer
  attr_reader :options,
              :allow_randomization_between_items_skills_passives,
              :rng,
              :log,
              :game
  
  def initialize(seed, game, options={})
    @game = game
    
    @options = options
    @allow_randomization_between_items_skills_passives = true
    
    @next_available_item_id = 0
    
    @log = File.open("./logs/random.txt", "a")
    if seed
      @rng = Random.new(seed)
      log.puts "Using seed: #{seed}"
    else
      @rng = Random.new
      log.puts "New random seed: #{rng.seed}"
    end
    @log.close()
  end
  
  def randomize
    @boss_entities = []
    @transition_rooms = []
    game.each_room do |room|
      @enemy_pool_for_room = []
      
      room.entities.each do |entity|
        randomize_entity(entity)
        
        if entity.type == 0x02 && entity.subtype == 0x5A
          @transition_rooms << room
        end
      end
    end
    
    if options[:randomize_bosses]
      randomize_bosses()
    end
    
    if options[:randomize_doors]
      randomize_transition_doors()
    end
    
    if options[:randomize_enemy_drops]
      randomize_enemy_drops()
    end
    
    if options[:randomize_boss_souls]
      randomize_boss_souls()
    end
    
    if options[:randomize_starting_room]
      game.fix_top_screen_on_new_game()
      randomize_starting_room()
    end
    
    if options[:randomize_enemy_ai]
      randomize_enemy_ai()
    end
  end
  
  def randomize_entity(entity)
    case entity.type
    when 0x01 # Enemy
      randomize_enemy(entity)
    when 0x02
      randomize_special_objects(entity)
    when ENTITY_TYPE_FOR_PICKUPS
      case GAME
      when "dos", "por"
        randomize_pickup_dos_por(entity)
      when "ooe"
        randomize_pickup_ooe(entity)
      end
    end
    
    entity.write_to_rom()
  end
  
  def randomize_enemy(enemy)
    available_enemy_ids_for_entity = nil
    
    if enemy.is_boss?
      if RANDOMIZABLE_BOSS_IDS.include?(enemy.subtype)
        # Will be randomized by a separate function.
        @boss_entities << enemy
      end
      
      return
    elsif enemy.is_common_enemy?
      return unless options[:randomize_enemies]
      
      available_enemy_ids_for_entity = COMMON_ENEMY_IDS.dup
      if !VERY_LARGE_ENEMIES.include?(enemy.subtype)
        available_enemy_ids_for_entity -= VERY_LARGE_ENEMIES
      end
    else
      puts "Enemy #{enemy.subtype} isn't in either the enemy list or boss list. Todo: fix this"
      return
    end
    
    if @enemy_pool_for_room.length >= 5
      # We don't want the room to have too many different enemies as this would take up too much space in RAM and crash.
      
      enemy.subtype = @enemy_pool_for_room.sample(random: rng)
    else
      # Enemies are chosen weighted closer to the ID of what the original enemy was so that early game enemies are less likely to roll into endgame enemies.
      # Method taken from: https://gist.github.com/O-I/3e0654509dd8057b539a
      weights = available_enemy_ids_for_entity.map do |possible_enemy_id|
        id_difference = (possible_enemy_id - enemy.subtype)
        weight = (available_enemy_ids_for_entity.length - id_difference).abs
        weight = weight**2
        weight
      end
      ps = weights.map{|w| w.to_f / weights.reduce(:+)}
      weighted_enemy_ids = available_enemy_ids_for_entity.zip(ps).to_h
      random_enemy_id = weighted_enemy_ids.max_by{|_, weight| rng.rand ** (1.0 / weight)}.first
      
      #random_enemy_id = available_enemy_ids_for_entity.sample(random: rng)
      enemy.subtype = random_enemy_id
      @enemy_pool_for_room << random_enemy_id
    end
    
    enemy_dna = game.enemy_dnas[enemy.subtype]
    case enemy_dna.name.decoded_string
    when "Bat"
      # 50% chance to be a single bat, 50% chance to be a spawner.
      if rng.rand <= 0.5
        enemy.var_a = 0
      else
        enemy.var_a = 0x100
      end
    when "Fleaman"
      enemy.var_a = rng.rand(1..10)
    end
  end
  
  def randomize_bosses
    shuffled_boss_ids = RANDOMIZABLE_BOSS_IDS.shuffle(random: rng)
    queued_dna_changes = Hash.new{|h, k| h[k] = {}}
    
    shuffled_boss_ids.each_with_index do |new_boss_id, i|
      old_boss_id = RANDOMIZABLE_BOSS_IDS[i]
      old_boss = game.enemy_dnas[old_boss_id]
      
      # Make the new boss have the stats of the old boss so it fits in at this point in the game.
      queued_dna_changes[new_boss_id]["HP"]      = old_boss["HP"]
      queued_dna_changes[new_boss_id]["MP"]      = old_boss["MP"]
      queued_dna_changes[new_boss_id]["EXP"]     = old_boss["EXP"]
      queued_dna_changes[new_boss_id]["Attack"]  = old_boss["Attack"]
      queued_dna_changes[new_boss_id]["Defense"] = old_boss["Defense"]
    end
    
    @boss_entities.each do |boss_entity|
      old_boss_id = boss_entity.subtype
      boss_index = RANDOMIZABLE_BOSS_IDS.index(old_boss_id)
      new_boss_id = shuffled_boss_ids[boss_index]
      old_boss = game.enemy_dnas[old_boss_id]
      new_boss = game.enemy_dnas[new_boss_id]
      
      case old_boss.name.decoded_string
      when "Balore"
        if boss_entity.var_a == 2
          # Not actually Balore, this is the wall of ice blocks right before Balore.
          # We need to get rid of this because we don't want two bosses inside the room. Especially if they're different bosses, as that would take up too much RAM and crash the game.
          boss_entity.type = 0
          boss_entity.subtype = 0
          boss_entity.write_to_rom()
          next
        end
      when "Paranoia"
        if boss_entity.var_a == 1
          # Mini-paranoia.
          next
        end
      end
      
      case new_boss.name.decoded_string
      when "Balore"
        boss_entity.x_pos = 16
        boss_entity.y_pos = 176
        
        if old_boss.name.decoded_string == "Puppet Master"
          boss_entity.x_pos += 144
        end
      when "Puppet Master"
        boss_entity.x_pos = 328
        boss_entity.y_pos = 64
      when "Gergoth"
        unless old_boss_id == new_boss_id
          # Set Gergoth to boss rush mode, unless he's in his tower.
          boss_entity.var_a = 0
        end
      when "Paranoia"
        # If Paranoia spawns in Gergoth's tall tower, his position and the position of his mirrors can become disjointed.
        # This combination of x and y seems to be one of the least buggy.
        boss_entity.x_pos = 0x1F
        boss_entity.y_pos = 0x80
        
        boss_entity.var_a = 2
      when "Aguni"
        boss_entity.var_a = 0
        boss_entity.var_b = 0
      else
        boss_entity.var_a = 1
      end
      
      boss_entity.subtype = new_boss_id
      
      boss_entity.write_to_rom()
      
      # Update the boss doors for the new boss
      new_boss_door_var_b = BOSS_ID_TO_BOSS_DOOR_VAR_B[new_boss_id]
      ([boss_entity.room] + boss_entity.room.connected_rooms).each do |room|
        room.entities.each do |entity|
          if entity.type == 0x02 && entity.subtype == 0x25
            entity.var_b = new_boss_door_var_b
            
            entity.write_to_rom()
          end
        end
      end
    end
    
    queued_dna_changes.each do |boss_id, changes|
      boss = game.enemy_dnas[boss_id]
      
      changes.each do |attribute_name, new_value|
        boss[attribute_name] = new_value
      end
      
      boss.write_to_rom()
    end
  end
  
  def randomize_special_objects(entity)
    return unless GAME == "dos"
    
    if entity.subtype >= 0x5E && options[:remove_events]
      if entity.subtype == 0x5F # event with yoko and julius going over the bridge
        # Replace it with magic seal 1
        entity.type = 4
        entity.subtype = 2
        entity.var_a = 0x01FF # unique id
        entity.var_b = 0x3D # magic seal 1
        entity.x_pos = 0x0080
        entity.y_pos = 0x0140
      else
        # Remove it
        entity.type = 0
        entity.subtype = 0
      end
    end
  end
  
  def randomize_pickup_dos_por(pickup)
    if allow_randomization_between_items_skills_passives
      if rng.rand(1..100) <= 80 # 80% chance to randomize into an item
        pickup.subtype = ITEM_LOCAL_ID_RANGES.keys.sample(random: rng)
        pickup.var_b = rng.rand(ITEM_LOCAL_ID_RANGES[pickup.subtype])
      elsif GAME == "dos"
        pickup.type = 2 # special object
        pickup.subtype = 1 # candle
        pickup.var_a = 0 # glowing soul lamp
        pickup.var_b = (ITEM_BYTE_11_RANGE_FOR_SKILLS.to_a + ITEM_BYTE_11_RANGE_FOR_PASSIVES.to_a).sample(random: rng)
      else # 20% chance to randomize into a skill/passive
        pickup.subtype = ITEM_BYTE_7_VALUE_FOR_SKILLS_AND_PASSIVES
        pickup.var_b = (ITEM_BYTE_11_RANGE_FOR_SKILLS.to_a + ITEM_BYTE_11_RANGE_FOR_PASSIVES.to_a).sample(random: rng)
      end
      
    else
      
    end
  end
  
  def randomize_pickup_ooe(pickup)
    unless [0x15, 0x16].include?(pickup.subtype) || (pickup.subtype == 0x02 && pickup.var_a == 0x00) # wooden chest, red chest, or glyph statue
      return
    end
    
    pickup.subtype = [0x15, 0x16, 0x02].sample(random: rng)
    case pickup.subtype
    when 0x15
      pickup.var_a = rng.rand(0x00..0x0F)
      pickup.var_b = 0
    when 0x16
      # Chest
      pickup.var_a = rng.rand(0x0070..0x0162)
      pickup.var_b = @next_available_item_id
      @next_available_item_id += 1
    when 0x02
      # Glyph statue
      pickup.var_a = 0x00
      pickup.var_b = rng.rand(0x00..0x50)
    end
  end
  
  def randomize_enemy_drops
    COMMON_ENEMY_IDS.each do |enemy_id|
      enemy = EnemyDNA.new(enemy_id, game.fs)
      
      if rng.rand <= 0.5 # 50% chance to have an item drop
        enemy["Item 1"] = rng.rand(ITEM_GLOBAL_ID_RANGE)
        
        if rng.rand <= 0.5 # Further 50% chance (25% total) to have a second item drop
          enemy["Item 2"] = rng.rand(ITEM_GLOBAL_ID_RANGE)
        else
          enemy["Item 2"] = 0
        end
      else
        enemy["Item 1"] = 0
        enemy["Item 2"] = 0
      end
      
      case GAME
      when "dos"
        enemy["Item Chance"] = rng.rand(0x01..0x40)
        
        enemy["Soul"] = rng.rand(SOUL_GLOBAL_ID_RANGE)
        enemy["Soul Chance"] = rng.rand(0x01..0x40)
      when "por"
        enemy["Item 1 Chance"] = rng.rand(0x01..0x32)
        enemy["Item 2 Chance"] = rng.rand(0x01..0x32)
      when "ooe"
        enemy["Item 1 Chance"] = rng.rand(0x01..0x0F)
        enemy["Item 2 Chance"] = rng.rand(0x01..0x0F)
        
        enemy["Glyph"] = rng.rand(GLYPH_GLOBAL_ID_RANGE)
        enemy["Glyph Chance"] = rng.rand(0x01..0x0F)
      end
      
      enemy.write_to_rom()
    end
  end
  
  def randomize_boss_souls
    return unless GAME == "dos"
    
    important_soul_ids = [
      0x00, # puppet master
      0x01, # zephyr
      0x02, # paranoia
      0x20, # succubus
      0x2E, # alucard's bat form
      0x35, # flying armor
      0x36, # bat company
      0x37, # black panther
      0x74, # balore
      0x75, # malphas
      0x77, # rahab
      0x78, # hippogryph
    ]
    
    unused_important_soul_ids = important_soul_ids.dup
    
    bosses = []
    RANDOMIZABLE_BOSS_IDS.each do |enemy_id|
      boss = EnemyDNA.new(enemy_id, game.fs)
      bosses << boss
    end
    
    bosses.each do |boss|
      if unused_important_soul_ids.length > 0
        random_soul_id = unused_important_soul_ids.sample(random: rng)
        unused_important_soul_ids.delete(random_soul_id)
      else # Exhausted the important souls. Give the boss a random soul instead.
        random_soul_id = rng.rand(SOUL_GLOBAL_ID_RANGE)
      end
      
      boss["Soul"] = random_soul_id
      boss.write_to_rom()
    end
  end
  
  def randomize_starting_room
    area = game.areas.sample(random: rng)
    sector = area.sectors.sample(random: rng)
    room = sector.rooms.sample(random: rng)
    game.set_starting_room(area.area_index, sector.sector_index, room.room_index)
  end
  
  def randomize_transition_doors
    @transition_rooms.uniq!
    remaining_transition_rooms = @transition_rooms.dup
    queued_door_changes = Hash.new{|h, k| h[k] = {}}
    
    @transition_rooms.each_with_index do |room, i|
      next unless remaining_transition_rooms.include?(room) # Already randomized this room
      
      # Only randomize one of the doors, no point in randomizing them both.
      inside_door = room.doors.first
      old_outside_door = inside_door.destination_door
      random_index = rng.rand(remaining_transition_rooms.length)
      transition_room_to_swap_with = remaining_transition_rooms.delete_at(random_index)
      inside_door_to_swap_with = transition_room_to_swap_with.doors.first
      new_outside_door = inside_door_to_swap_with.destination_door
      
      queued_door_changes[inside_door]["destination_room_metadata_ram_pointer"] = inside_door_to_swap_with.destination_room_metadata_ram_pointer
      queued_door_changes[inside_door]["dest_x"] = inside_door_to_swap_with.dest_x
      queued_door_changes[inside_door]["dest_y"] = inside_door_to_swap_with.dest_y
      
      queued_door_changes[inside_door_to_swap_with]["destination_room_metadata_ram_pointer"] = inside_door.destination_room_metadata_ram_pointer
      queued_door_changes[inside_door_to_swap_with]["dest_x"] = inside_door.dest_x
      queued_door_changes[inside_door_to_swap_with]["dest_y"] = inside_door.dest_y
      
      queued_door_changes[old_outside_door]["destination_room_metadata_ram_pointer"] = new_outside_door.destination_room_metadata_ram_pointer
      queued_door_changes[old_outside_door]["dest_x"] = new_outside_door.dest_x
      queued_door_changes[old_outside_door]["dest_y"] = new_outside_door.dest_y
      
      queued_door_changes[new_outside_door]["destination_room_metadata_ram_pointer"] = old_outside_door.destination_room_metadata_ram_pointer
      queued_door_changes[new_outside_door]["dest_x"] = old_outside_door.dest_x
      queued_door_changes[new_outside_door]["dest_y"] = old_outside_door.dest_y
    end
    
    queued_door_changes.each do |door, changes|
      changes.each do |attribute_name, new_value|
        door.send("#{attribute_name}=", new_value)
      end
      
      door.write_to_rom()
    end
  end
  
  def randomize_enemy_ai
    common_enemy_dnas = game.enemy_dnas[0..COMMON_ENEMY_IDS.last]
    available_ais = common_enemy_dnas.map{|dna| dna["Running AI"]}
    
    common_enemy_dnas.each do |dna|
      dna["Running AI"] = available_ais.sample(random: rng)
      dna.write_to_rom()
    end
  end
end
