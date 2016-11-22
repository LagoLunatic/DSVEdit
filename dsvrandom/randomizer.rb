
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
    @used_skills = []
    @used_items = []
    
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
    overlay_ids_for_common_enemies = OVERLAY_FILE_FOR_ENEMY_AI.select do |enemy_id, overlay_id|
      COMMON_ENEMY_IDS.include?(enemy_id)
    end
    overlay_ids_for_common_enemies = overlay_ids_for_common_enemies.values.uniq
    
    game.each_room do |room|
      @enemy_pool_for_room = []
      enemy_overlay_id_for_room = overlay_ids_for_common_enemies.sample(random: rng)
      @allowed_enemies_for_room = COMMON_ENEMY_IDS.select do |enemy_id|
        overlay = OVERLAY_FILE_FOR_ENEMY_AI[enemy_id]
        overlay.nil? || overlay == enemy_overlay_id_for_room
      end
      
      room.entities.each do |entity|
        randomize_entity(entity)
      end
    end
    
    if options[:remove_events] && GAME == "dos"
      game.set_starting_room(0, 0, 1) # Start the game in the castle instead of the prologue area.
      
      @boss_entities.each do |boss_entity|
        if boss_entity.subtype == 0x68 # Dmitrii
          boss_entity.var_a = 0 # Boss rush Dmitrii, doesn't crash when there are no events.
          boss_entity.write_to_rom()
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
    when 0x04
      case GAME
      when "dos", "por"
        randomize_pickup_dos_por(entity)
      when "ooe"
        # Do nothing, pickups are special objects in OoE.
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
      
      available_enemy_ids_for_entity = @allowed_enemies_for_room.dup
    else
      puts "Enemy #{enemy.subtype} isn't in either the enemy list or boss list. Todo: fix this"
      return
    end
    
    if @enemy_pool_for_room.length >= 7
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
    case GAME
    when "dos"
      dos_adjust_randomized_enemy(enemy, enemy_dna)
    when "por"
      por_adjust_randomized_enemy(enemy, enemy_dna)
    when "ooe"
      ooe_adjust_randomized_enemy(enemy, enemy_dna)
    end
  end
  
  def dos_adjust_randomized_enemy(enemy, enemy_dna)
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
  
  def por_adjust_randomized_enemy(enemy, enemy_dna)
    case enemy_dna.name.decoded_string
    when "Bat", "Fleaman"
      dos_adjust_randomized_enemy(enemy, enemy_dna)
    end
  end
  
  def ooe_adjust_randomized_enemy(enemy, enemy_dna)
    case enemy_dna.name.decoded_string
    when "Bat", "Fleaman"
      dos_adjust_randomized_enemy(enemy, enemy_dna)
    when "Ghost"
      enemy.var_a = rng.rand(1..10) # Max ghosts on screen at once.
    when "Saint Elmo"
      enemy.var_a = rng.rand(1..3)
      enemy.var_b = 0x78
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
      
      result = case GAME
      when "dos"
        dos_adjust_randomized_boss(boss_entity, old_boss_id, new_boss_id, old_boss, new_boss)
      when "por"
        por_adjust_randomized_boss(boss_entity, old_boss_id, new_boss_id, old_boss, new_boss)
      when "ooe"
        ooe_adjust_randomized_boss(boss_entity, old_boss_id, new_boss_id, old_boss, new_boss)
      end
      if result == :skip
        next
      end
      
      boss_entity.subtype = new_boss_id
      
      boss_entity.write_to_rom()
      
      # Update the boss doors for the new boss
      new_boss_door_var_b = BOSS_ID_TO_BOSS_DOOR_VAR_B[new_boss_id] || 0
      ([boss_entity.room] + boss_entity.room.connected_rooms).each do |room|
        room.entities.each do |entity|
          if entity.type == 0x02 && entity.subtype == BOSS_DOOR_SUBTYPE
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
  
  def dos_adjust_randomized_boss(boss_entity, old_boss_id, new_boss_id, old_boss, new_boss)
    case old_boss.name.decoded_string
    when "Balore"
      if boss_entity.var_a == 2
        # Not actually Balore, this is the wall of ice blocks right before Balore.
        # We need to get rid of this because having this + a different boss besides Balore in the same room will load two different overlays into the same spot and crash the game.
        boss_entity.type = 0
        boss_entity.subtype = 0
        boss_entity.write_to_rom()
        return :skip
      end
    when "Paranoia"
      if boss_entity.var_a == 1
        # Mini-paranoia.
        return :skip
      end
    end
    
    case new_boss.name.decoded_string
    when "Flying Armor"
      boss_entity.x_pos = boss_entity.room.main_layer_width * SCREEN_WIDTH_IN_PIXELS / 2
      boss_entity.y_pos = 80
    when "Balore"
      boss_entity.x_pos = 16
      boss_entity.y_pos = 176
      
      if old_boss.name.decoded_string == "Puppet Master"
        boss_entity.x_pos += 144
      end
    when "Malphas"
      boss_entity.var_b = 0
    when "Dmitrii"
      boss_entity.var_a = 0 # Boss rush Dmitrii, doesn't crash when there are no events.
    when "Dario"
      boss_entity.var_b = 0
    when "Puppet Master"
      boss_entity.x_pos = 256
      boss_entity.y_pos = 96
      
      boss_entity.var_a = 0
    when "Gergoth"
      unless old_boss_id == new_boss_id
        # Set Gergoth to boss rush mode, unless he's in his tower.
        boss_entity.var_a = 0
      end
    when "Zephyr"
      # Don't put Zephyr inside the left or right walls. If he is either Soma or him will get stuck and soft lock the game.
      boss_entity.x_pos = 256
      
      # TODO: If Zephyr spawns in a room that is 1 screen wide then either he or Soma will get stuck, regardless of what Zephyr's x pos is. Need to make sure Zephyr only spawns in rooms 2 screens wide or wider.
      # also if zephyr spawns inside rahab's room you can't reach him until you have rahab's soul.
    when "Paranoia"
      # If Paranoia spawns in Gergoth's tall tower, his position and the position of his mirrors can become disjointed.
      # This combination of x and y seems to be one of the least buggy.
      boss_entity.x_pos = 0x1F
      boss_entity.y_pos = 0x80
      
      boss_entity.var_a = 2
    when "Aguni"
      boss_entity.var_a = 0
      boss_entity.var_b = 0
    when "Death"
      # TODO: when you kill death in a room besides his own, he just freezes up, soft locking the game.
    else
      boss_entity.var_a = 1
    end
  end
  
  def por_adjust_randomized_boss(boss_entity, old_boss_id, new_boss_id, old_boss, new_boss)
    case old_boss.name.decoded_string
    when "Behemoth"
      if boss_entity.var_b == 0x02
        # Scripted Behemoth that chases you down the hallway.
        return :skip
      end
    end
    
    if (0x81..0x84).include?(new_boss_id)
      dos_adjust_randomized_boss(boss_entity, old_boss_id, new_boss_id, old_boss, new_boss)
    end
    
    case new_boss.name.decoded_string
    when "Stella"
      boss_entity.var_a = 0 # Just Stella, we don't want Stella&Loretta.
    end
  end
  
  def ooe_adjust_randomized_boss(boss_entity, old_boss_id, new_boss_id, old_boss, new_boss)
    case old_boss.name.decoded_string
    when "Brachyura"
      boss_entity.x_pos = 0x0080
      boss_entity.y_pos = 0x0A20
    when "Giant Skeleton"
      if boss_entity.var_a == 0
        # Non-boss version of the giant skeleton.
        return :skip
      end
    end
    
    if new_boss.name.decoded_string != "Giant Skeleton"
      boss_entity.room.entities.each do |entity|
        if entity.type == 0x02 && entity.subtype == 0x3E && entity.var_a == 0x01
          # Searchlights in Giant Skeleton's boss room. These will soft lock the game if Giant Skeleton isn't here, so we need to tweak it a bit.
          entity.var_a = 0x00
          entity.write_to_rom()
        end
      end
    end
    
    case new_boss.name.decoded_string
    when "Wallman"
      # We don't want Wallman to be offscreen because then he's impossible to defeat.
      boss_entity.x_pos = 0xCC
      boss_entity.y_pos = 0xAF
    end
  end
  
  def randomize_special_objects(entity)
    case GAME
    when "dos"
      dos_randomize_special_objects(entity)
    when "por"
      por_randomize_special_objects(entity)
    when "ooe"
      ooe_randomize_special_objects(entity)
    end
  end
  
  def dos_randomize_special_objects(entity)
    if entity.subtype >= 0x5E && options[:remove_events]
      case entity.subtype 
      when 0x5F # event with yoko and julius going over the bridge
        # Replace it with magic seal 1
        entity.type = 4
        entity.subtype = 2
        entity.var_a = 0x0200 # unique id
        entity.var_b = 0x3D # magic seal 1
        entity.x_pos = 0x0080
        entity.y_pos = 0x0140
      when 0x65 # mina's talisman event
        # Replace it with mina's talisman
        entity.type = 4
        entity.subtype = 4
        entity.var_a = 0x0201 # unique id
        entity.var_b = 0x35 # mina's talisman
        entity.x_pos = 0x0080
        entity.y_pos = 0x00A0
      when 0x69 # event in throne room with dario and aguni
        # do nothing. if we remove this event the game will crash when entering the mirror.
      when 0x6A..0x6B # event in center of castle + event where julius breaks the seal to the mine of judgement
        # do nothing
      when 0x6C..0x6E # menace events
        # do nothing
      when 0x71..0x72 # epilogue
        # do nothing
      else
        # Remove it
        entity.type = 0
        entity.subtype = 0
      end
    elsif entity.subtype == 0x06 && options[:remove_events]
      # Area name
      # Remove it
      entity.type = 0
      entity.subtype = 0
    elsif entity.subtype == 0x01 && entity.var_a == 0x00
      # Soul candle
      if options[:randomize_souls_relics_and_glyphs]
        entity.type = 0x04
        randomize_pickup_dos_por(entity)
      end
    elsif entity.subtype == 0x01 && entity.var_a == 0x10
      # Money chest
      if options[:randomize_items]
        entity.type = 0x04
        randomize_pickup_dos_por(entity)
      end
    end
  end
  
  def por_randomize_special_objects(entity)
    if entity.subtype >= 0x95 && options[:remove_events]
      case entity.subtype 
      when nil
      else
        # Remove it
        entity.type = 0
        entity.subtype = 0
      end
    elsif entity.subtype == 0x79 && options[:remove_events]
      # Area name
      # Remove it
      entity.type = 0
      entity.subtype = 0
    elsif entity.subtype == 0x01 && (entity.var_a == 0x0E || entity.var_a == 0x0F)
      # Money chest
      if options[:randomize_items]
        entity.type = 0x04
        randomize_pickup_dos_por(entity)
      end
    end
  end
  
  def ooe_randomize_special_objects(entity)
    if entity.subtype >= 0x5E && options[:remove_events]
      case entity.subtype 
      when 0x63 # tutorial event that would normally give you your first glyph
        # Replace it with a free glyph.
        entity.type = 4
        entity.subtype = 2
        entity.var_a = 0x00
        entity.var_b = 0x02 # confodere
        entity.x_pos = 0x00B0
        entity.y_pos = 0x0070
      when 0x89 # Villager in Torpor
        # Do nothing
      when 0x8A # Magnes glyph + tutorial
        # Replace it with a free glyph.
        entity.type = 4
        entity.subtype = 2
        entity.var_a = 0x00
        entity.var_b = 0x39 # magnes
        entity.x_pos = 0x0080
        entity.y_pos = 0x02B0
      else
        # Remove it
        entity.type = 0
        entity.subtype = 0
      end
    elsif entity.subtype == 0x55 && options[:remove_events]
      # Area name
      # Remove it
      entity.type = 0
      entity.subtype = 0
    elsif entity.subtype == 0x02 && entity.var_a == 0x00
      # Glyph statue
      randomize_pickup_ooe(entity)
    elsif (0x15..0x17).include?(entity.subtype)
      # Chest
      randomize_pickup_ooe(entity)
    end
  end
  
  def randomize_pickup_dos_por(pickup)
    case GAME
    when "dos"
      return if !options[:randomize_items] && pickup.subtype < 0x05
      return if !options[:randomize_souls_relics_and_glyphs] && pickup.subtype >= 0x05 # free soul
      
      if pickup.subtype == 0x02 && (0x3D..0x41).include?(pickup.var_b)
        # magic seal
        pickup.var_a = get_unique_id()
        return
      elsif pickup.subtype == 0x02 && pickup.var_b == 0x39
        # tower key
        pickup.var_a = get_unique_id()
        return
      end
    when "por"
      return if !options[:randomize_items] && pickup.subtype < 0x08
      return if !options[:randomize_souls_relics_and_glyphs] && pickup.subtype >= 0x08 # relic
      
      if pickup.subtype >= 0x08 && [0x5C, 0x5D].include?(pickup.var_b)
        # change cube or call cube
        return
      end
    end
    
    rand = rng.rand(1..100)
    if options[:randomize_items] && ((1..90).include?(rand) || !options[:randomize_souls_relics_and_glyphs])
      if (1..88).include?(rand)
        # Randomize into an item
        pickup.type = 4 # pickup
        pickup.subtype = ITEM_LOCAL_ID_RANGES.keys.sample(random: rng)
        pickup.var_b = rng.rand(ITEM_LOCAL_ID_RANGES[pickup.subtype])
        
        pickup.var_a = get_unique_id()
      else
        # Randomize into a money chest
        case GAME
        when "dos"
          pickup.type = 2 # special object
          pickup.subtype = 1 # destructible object
          pickup.var_a = 0x10 # money chest
        when "por"
          pickup.type = 2 # special object
          pickup.subtype = 1 # destructible object
          pickup.var_a = rng.rand(0x0E..0x0F) # money chest
        end
      end
    elsif options[:randomize_souls_relics_and_glyphs] && ((91..100).include?(rand) || !options[:randomize_items])
      case GAME
      when "dos"
        # Randomize into a soul lamp
        pickup.type = 2 # special object
        pickup.subtype = 1 # candle
        pickup.var_a = 0 # glowing soul lamp
        pickup.var_b = rng.rand(SOUL_GLOBAL_ID_RANGE)
      when "por"
        # Randomize into a skill or relic
        pickup.type = 4 # pickup
        pickup.subtype = 8 # skill
        pickup.var_b = rng.rand(SKILL_GLOBAL_ID_RANGE)
      end
    end
  end
  
  def randomize_pickup_ooe(pickup)
    unless (0x15..0x17).include?(pickup.subtype) || (pickup.subtype == 0x02 && pickup.var_a == 0x00) # chest or glyph statue
      return
    end
    
    return if !options[:randomize_items] && (0x15..0x17).include?(pickup.subtype) # chest
    return if !options[:randomize_souls_relics_and_glyphs] && pickup.subtype == 0x02 && pickup.var_a == 0x00 # glyph statue
    
    allowed_subtypes = []
    if options[:randomize_items]
      allowed_subtypes += [0x15, 0x16] # chest
    end
    if options[:randomize_souls_relics_and_glyphs]
      allowed_subtypes += [0x02] # glyph statue
    end
    pickup.subtype = allowed_subtypes.sample(random: rng)
    
    case pickup.subtype
    when 0x15
      # Wooden chest
      pickup.var_a = rng.rand(0x00..0x0F)
      pickup.var_b = 0
    when 0x16
      # Red chest
      pickup.var_a = rng.rand(0x0070..0x0162)
      pickup.var_b = get_unique_id()
      
      if rng.rand(1..100) < 15
        # Blue chest
        pickup.subtype = 0x17
      end
    when 0x02
      # Glyph statue
      pickup.var_a = 0x00
      pickup.var_b = rng.rand(0x00..0x50)
    end
  end
  
  def randomize_enemy_drops
    if GAME == "ooe"
      BOSS_IDS.each do |enemy_id|
        enemy = EnemyDNA.new(enemy_id, game.fs)
        
        if enemy["Glyph"] != 0
          # Boss that has a glyph you can absorb during the fight (Albus, Barlowe, and Wallman).
          # These must be done before common enemies because otherwise there won't be any unique glyphs left to give them.
          
          enemy["Glyph"] = get_random_glyph()
          enemy["Glyph Chance"] = rng.rand(0x01..0x0F)
          
          enemy.write_to_rom()
        end
      end
    end
    
    COMMON_ENEMY_IDS.each do |enemy_id|
      enemy = EnemyDNA.new(enemy_id, game.fs)
      
      if rng.rand <= 0.5 # 50% chance to have an item drop
        enemy["Item 1"] = get_random_item()
        
        if rng.rand <= 0.5 # Further 50% chance (25% total) to have a second item drop
          enemy["Item 2"] = get_random_item()
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
        
        enemy["Soul"] = get_random_soul()
        enemy["Soul Chance"] = rng.rand(0x01..0x40)
      when "por"
        enemy["Item 1 Chance"] = rng.rand(0x01..0x32)
        enemy["Item 2 Chance"] = rng.rand(0x01..0x32)
      when "ooe"
        enemy["Item 1 Chance"] = rng.rand(0x01..0x0F)
        enemy["Item 2 Chance"] = rng.rand(0x01..0x0F)
        
        enemy["Glyph"] = get_random_glyph()
        enemy["Glyph Chance"] = rng.rand(0x01..0x0F)
      end
      
      enemy.write_to_rom()
    end
  end
  
  def get_random_id(global_id_range, used_list)
    available_ids = global_id_range.to_a - used_list
    id = available_ids.sample(random: rng)
    used_list << id
    return id
  end
  
  def get_random_item
    get_random_id(ITEM_GLOBAL_ID_RANGE, @used_items) || 0
  end
  
  def get_random_soul
    get_random_id(SOUL_GLOBAL_ID_RANGE, @used_skills) || 0xFF
  end
  
  def get_random_glyph
    get_random_id(GLYPH_GLOBAL_ID_RANGE, @used_skills) || 0
  end
  
  def get_unique_id
    id = @next_available_item_id
    @next_available_item_id += 1
    return id
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
    transition_rooms = game.get_transition_rooms()
    remaining_transition_rooms = transition_rooms.dup
    remaining_transition_rooms.reject! do |room|
      FAKE_TRANSITION_ROOMS.include?(room.room_metadata_ram_pointer)
    end
    queued_door_changes = Hash.new{|h, k| h[k] = {}}
    
    transition_rooms.each_with_index do |transition_room, i|
      next unless remaining_transition_rooms.include?(transition_room) # Already randomized this room
      
      remaining_transition_rooms.delete(transition_room)
      
      # Transition rooms can only lead to rooms in the same area or the game will crash.
      remaining_transition_rooms_for_area = remaining_transition_rooms.select do |other_room|
        transition_room.area_index == other_room.area_index
      end
      
      # Only randomize one of the doors, no point in randomizing them both.
      inside_door = transition_room.doors.first
      old_outside_door = inside_door.destination_door
      transition_room_to_swap_with = remaining_transition_rooms_for_area.sample(random: rng)
      remaining_transition_rooms.delete(transition_room_to_swap_with)
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
    
    common_enemy_dnas.each do |this_dna|
      this_overlay = OVERLAY_FILE_FOR_ENEMY_AI[this_dna]
      available_enemies_with_same_overlay = common_enemy_dnas.select do |other_dna|
         other_overlay = OVERLAY_FILE_FOR_ENEMY_AI[other_dna.enemy_id]
         other_overlay.nil? || other_overlay == this_overlay
      end
      
      this_dna["Running AI"] = available_enemies_with_same_overlay.sample(random: rng)["Running AI"]
      this_dna.write_to_rom()
    end
  end
end
