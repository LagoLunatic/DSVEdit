
class TextDatabase
  class StringDatabaseTooLargeError < StandardError ; end
  
  attr_reader :fs,
              :text_list
  
  def initialize(fs)
    @fs = fs
    read_from_rom()
  end
  
  def read_from_rom
    @text_list = []
    TEXT_RANGE.each do |text_id|
      text = Text.new(text_id, fs)
      @text_list << text
    end
  end
  
  def write_to_rom
    # Writes all text back into ROM, repointing everything in case any strings are longer than they were originally.
    # Note that you can't go past where strings would normally end in RAM for the original game - that would either overwrite or be overwritten by other data.
    # However, this function packs the new strings in more snugly than they were in the original game, leaving no free space between them. This means that there is a significant amount of extra room for increasing the size of strings at the end. But not unlimited, so raise an error if even that extra space isn't enough to hold the new strings.
    
    next_string_ram_pointer = STRING_DATABASE_START_OFFSET
    text_list.each do |text|
      if next_string_ram_pointer + text.encoded_string.length + 3 >= STRING_DATABASE_END_OFFSET
        # Writing strings past this point would result in something being overwritten, so raise an error.
        raise StringDatabaseTooLargeError.new
      end
      
      text.string_ram_pointer = next_string_ram_pointer
      text.write_to_rom()
      
      next_string_ram_pointer += text.encoded_string.length + 3
    end
  end
end
