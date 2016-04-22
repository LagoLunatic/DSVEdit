
class Bitfield
  attr_reader :value
  
  def initialize(value)
    @value = value
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
