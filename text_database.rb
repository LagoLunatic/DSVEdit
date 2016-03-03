
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
    
    # For DoS, note that you can't go past where strings would normally end in RAM for the original game - that would either overwrite or be overwritten by other data.
    # However, this function packs the new strings in more snugly than they were originally in DoS, leaving no free space between them. This means that there is a significant amount of extra room for increasing the size of strings at the end. But not unlimited, so raise an error if even that extra space isn't enough to hold the new strings.
    
    # For OoE, the strings are already packed snugly, so we can't gain any space that way. But we can expand the overlay file here since nothing immediately follows it in RAM.
    
    if TEXT_REGIONS_OVERLAYS.first
      fs.load_overlay(TEXT_REGIONS_OVERLAYS.first[1])
    end
    
    next_string_ram_pointer = STRING_DATABASE_START_OFFSET
    should_write_to_end_of_file = false
    text_list.each do |text|
      if next_string_ram_pointer + text.encoded_string.length + 3 > STRING_DATABASE_ALLOWABLE_END_OFFSET
        # Writing strings past this point would result in something being overwritten, so raise an error.
        
        raise StringDatabaseTooLargeError.new
      end
      
      if GAME == "ooe" && next_string_ram_pointer + text.encoded_string.length + 3 >= STRING_DATABASE_ORIGINAL_END_OFFSET
        # Reached the end of where strings were in the original game, but in OoE we can expand the file.
        
        should_write_to_end_of_file = true
        next_string_ram_pointer = fs.expand_file_and_get_end_of_file_ram_address(text.string_ram_pointer, text.encoded_string.length + 3)
      end
      
      text.string_ram_pointer = next_string_ram_pointer
      text.write_to_rom()
      
      if should_write_to_end_of_file
        next_string_ram_pointer = fs.expand_file_and_get_end_of_file_ram_address(text.string_ram_pointer, text.encoded_string.length + 3)
      else
        next_string_ram_pointer += text.encoded_string.length + 3
      end
    end
  end
end
