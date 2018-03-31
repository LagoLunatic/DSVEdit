
class Quest < GenericEditable
  attr_accessor :is_a_kill_quest,
                :which_kill_quest_index,
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
      if is_a_kill_quest?
        @which_kill_quest_index, @num_enemies_to_kill = fs.read(self["Requirements Pointer"], 4).unpack("vv")
      elsif is_a_fetch_quest?
        @num_required_items = fs.read(self["Requirements Pointer"], 2).unpack("v").first
        @required_item_ids = fs.read(self["Requirements Pointer"]+2, @num_required_items*2).unpack("v*")
      end
    end
  end
  
  def reward_item
    return nil if @reward == 0 || @reward == 0xFFFF
    return game.items[@reward-1]
  end
  
  def is_a_kill_quest?
    raise "Game is not OoE" if GAME != "ooe"
    return self["Quest Modifiers"]["Is a kill quest"]
  end
  
  def is_a_fetch_quest?
    return !is_a_kill_quest? && self["Requirements Pointer"] != 0
  end
  
  def reward_is_gold?
    raise "Game is not OoE" if GAME != "ooe"
    return self["Quest Modifiers"]["Reward is gold"]
  end
  
  def reward_is_pickup?
    return !reward_is_gold?
  end
  
  def write_to_rom
    super
    
    case GAME
    when "ooe"
      if is_a_kill_quest?
        fs.write(self["Requirements Pointer"], [@which_kill_quest_index, @num_enemies_to_kill].pack("vv"))
      elsif is_a_fetch_quest?
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
