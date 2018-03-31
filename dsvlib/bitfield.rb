
class Bitfield
  attr_accessor :value
  attr_reader :names
  
  def initialize(value, names)
    @value = value
    @names = names
  end
  
  def [](index)
    if index.is_a?(String)
      index = names.index(index)
    end
    
    return ((@value >> index) & 0b1) > 0
  end
  
  def []=(index, bool)
    if index.is_a?(String)
      index = names.index(index)
    end
    
    if bool
      @value |= (1 << index)
    else
      @value &= ~(1 << index)
    end
  end
end
