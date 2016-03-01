
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
    game.each_room do |room|
      room.entities.each do |entity|
        randomize_entity(entity)
      end
    end
    
    if options[:randomize_doors]
      randomize_doors()
    end
    
    if options[:randomize_enemy_drops]
      randomize_enemy_drops()
    end
    
    if options[:randomize_starting_room]
      game.fix_top_screen_on_new_game()
      randomize_starting_room()
    end
  end
  
  def randomize_entity(entity)
    case entity.type
    when 0x01 # Enemy
      randomize_enemy(entity)
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
      return unless options[:randomize_bosses]
      
      available_enemy_ids_for_entity = BOSS_IDS
    elsif enemy.is_common_enemy?
      return unless options[:randomize_enemies]
      
      available_enemy_ids_for_entity = COMMON_ENEMY_IDS.dup
      if !VERY_LARGE_ENEMIES.include?(enemy.subtype)
        available_enemy_ids_for_entity -= VERY_LARGE_ENEMIES
      end
    else
      puts "Enemy #{enemy} isn't in either the enemy list or boss list. Todo: fix this"
      return
    end
    
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
      
      enemy.dna_attributes["Item 1"] = rng.rand(ITEM_GLOBAL_ID_RANGE)
      enemy.dna_attributes["Item 2"] = rng.rand(ITEM_GLOBAL_ID_RANGE)
      
      case GAME
      when "dos"
        enemy.dna_attributes["Item Chance"] = rng.rand(0x01..0x40)
        
        enemy.dna_attributes["Soul"] = rng.rand(SOUL_GLOBAL_ID_RANGE)
        enemy.dna_attributes["Soul Chance"] = rng.rand(0x01..0x40)
      when "por"
        enemy.dna_attributes["Item 1 Chance"] = rng.rand(0x01..0x32)
        enemy.dna_attributes["Item 2 Chance"] = rng.rand(0x01..0x32)
      when "ooe"
        enemy.dna_attributes["Item 1 Chance"] = rng.rand(0x01..0x0F)
        enemy.dna_attributes["Item 2 Chance"] = rng.rand(0x01..0x0F)
        
        enemy.dna_attributes["Glyph"] = rng.rand(GLYPH_GLOBAL_ID_RANGE)
        enemy.dna_attributes["Glyph Chance"] = rng.rand(0x01..0x0F)
      end
      
      enemy.write_to_rom()
    end
  end
  
  def randomize_starting_room
    area = game.areas.sample(random: rng)
    sector = area.sectors.sample(random: rng)
    room = sector.rooms.sample(random: rng)
    game.set_starting_room(area.area_index, sector.sector_index, room.room_index)
  end
  
  def randomize_doors
    raise NotImplementedError
  end
end
