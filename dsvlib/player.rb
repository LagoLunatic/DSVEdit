
class Player < GenericEditable
  def initialize(index, game)
    @index = index
    
    player_type = {
      name: "Players",
      list_pointer: PLAYER_LIST_POINTER,
      count: PLAYER_COUNT,
      kind: :player,
      format: PLAYER_LIST_FORMAT
    }
    super(index, player_type, game)
  end
end
