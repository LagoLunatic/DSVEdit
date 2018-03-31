
class Quest < GenericEditable
  attr_reader :index
  
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
end
