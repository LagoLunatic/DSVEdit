
class Quest < GenericEditable
  attr_accessor :which_kill_quest_index,
                :num_enemies_to_kill,
                :required_item_ids
  
  def initialize(index, game)
    @index = index
    
    quest_type = {
      name: "Quests",
      list_pointer: QUEST_LIST_POINTER,
      count: QUEST_COUNT,
      kind: :quest,
      format: QUEST_LIST_FORMAT
    }
    super(index, quest_type, game)
  end
  
  def read_from_rom
    super
    
    case GAME
    when "ooe"
      if ooe_is_a_kill_quest?
        @which_kill_quest_index, @num_enemies_to_kill = fs.read(self["Requirements Pointer"], 4).unpack("vv")
      elsif ooe_is_a_fetch_quest?
        @num_required_items = fs.read(self["Requirements Pointer"], 2).unpack("v").first
        @required_item_ids = fs.read(self["Requirements Pointer"]+2, @num_required_items*2).unpack("v*")
      end
    end
  end
  
  def reward_item
    case GAME
    when "por"
      return nil if self["Reward"] == 0 || !por_reward_is_a_pickup?
    when "ooe"
      return nil if self["Reward"] == 0 || self["Reward"] == 0xFFFF || ooe_reward_is_gold?
    end
    
    return game.items[self["Reward"]-1]
  end
  
  def por_reward_is_a_pickup?
    raise "Game is not PoR" if GAME != "por"
    return true if self["Quest Modifiers"]["Reward is an item"]
    return true if self["Quest Modifiers"]["Reward is a subweapon or spell"]
    return true if self["Quest Modifiers"]["Reward is a relic"]
    return false
  end
  
  def ooe_is_a_kill_quest?
    raise "Game is not OoE" if GAME != "ooe"
    return self["Quest Modifiers"]["Is a kill quest"]
  end
  
  def ooe_is_a_fetch_quest?
    raise "Game is not OoE" if GAME != "ooe"
    return !ooe_is_a_kill_quest? && self["Requirements Pointer"] != 0
  end
  
  def ooe_reward_is_gold?
    raise "Game is not OoE" if GAME != "ooe"
    return self["Quest Modifiers"]["Reward is gold"]
  end
  
  def ooe_reward_is_pickup?
    raise "Game is not OoE" if GAME != "ooe"
    return !ooe_reward_is_gold?
  end
  
  def write_to_rom
    super
    
    case GAME
    when "ooe"
      if ooe_is_a_kill_quest?
        fs.write(self["Requirements Pointer"], [@which_kill_quest_index, @num_enemies_to_kill].pack("vv"))
      elsif ooe_is_a_fetch_quest?
        # TODO: Which items are actually taken out of the player's inventory is hardcoded.
        # Changing these @required_item_ids only affects what items you need to complete the quest.
        
        if @required_item_ids.length != @num_required_items
          raise "Number of required items changed"
        end
        data = [@required_item_ids.length] + @required_item_ids
        fs.write(self["Requirements Pointer"], data.pack("v*"))
      end
    end
  end
end
