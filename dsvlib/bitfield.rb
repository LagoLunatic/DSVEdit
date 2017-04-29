
class Bitfield
  attr_accessor :value
  attr_reader :names
  
  def initialize(value, names)
    @value = value
    @names = names
  end
  
  def [](index)
    return ((@value >> index) & 0b1) > 0
  end
  
  def []=(index, bool)
    if bool
      @value |= (1 << index)
    else
      @value &= ~(1 << index)
    end
  end
end
