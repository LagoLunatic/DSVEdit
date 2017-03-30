
class Player < GenericEditable
  attr_reader :index
  
  def initialize(index, fs)
    @index = index
    @fs = fs
    
    player_type = {
      name: "Players",
      list_pointer: PLAYER_LIST_POINTER,
      count: PLAYER_COUNT,
      kind: :player,
      format: PLAYER_LIST_FORMAT
    }
    super(index, player_type, fs)
  end
end
