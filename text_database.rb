
class TextDatabase
  attr_reader :fs,
              :text_list
  
  def initialize(fs)
    @fs = fs
    read_from_rom()
  end
  
  def read_from_rom
    @text_list = []
    STRING_RANGE.each do |text_id|
      text = Text.new(text_id, fs)
      @text_list << text
    end
  end
  
  def write_to_rom
    raise NotImplementedError.new
  end
end
