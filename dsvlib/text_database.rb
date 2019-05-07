
class TextDatabase
  class StringDatabaseTooLargeError < StandardError ; end
  
  attr_reader :fs,
              :text_list
  
  def initialize(fs)
    @fs = fs
    @text_list = TextList.new(fs) # Lazy loader
  end
  
  def write_to_rom
    # Writes all text back into ROM, repointing everything in case any strings are longer than they were originally.
    
    # For DoS, note that you can't go past where strings would normally end in RAM for the original game - that would either overwrite or be overwritten by other data.
    # However, this function packs the new strings in more snugly than they were originally in DoS, leaving no free space between them. This means that there is a significant amount of extra room for increasing the size of strings at the end. But not unlimited, so raise an error if even that extra space isn't enough to hold the new strings.
    
    # For OoE, the strings are already packed snugly, so we can't gain any space that way. But we can expand the overlay file here since nothing immediately follows it in RAM.
    
    # For PoR, the strings are split across two different overlay files, so we have to handle those separately.
    
    if REGION == :jp || GAME == "hod"
      header_footer_length = 4
    else
      header_footer_length = 3
    end
    
    overlays = TEXT_REGIONS_OVERLAYS.values.uniq
    overlays.each do |overlay|
      fs.load_overlay(overlay) if overlay
      
      text_list_for_overlay = text_list.select{|text| text.overlay_id == overlay}
      
      next_string_ram_pointer = STRING_DATABASE_START_OFFSET
      should_write_to_end_of_file = false
      text_list_for_overlay.each do |text|
        if next_string_ram_pointer + text.encoded_string.length + header_footer_length >= STRING_DATABASE_ALLOWABLE_END_OFFSET
          # Writing strings past this point would result in something being overwritten, so raise an error.
          
          raise StringDatabaseTooLargeError.new
        end
        
        region_name = TEXT_REGIONS.find{|name, range| range.include?(text.text_id)}[0]
        
        if GAME == "ooe" && next_string_ram_pointer + text.encoded_string.length + header_footer_length >= STRING_DATABASE_ORIGINAL_END_OFFSET
          # Reached the end of where strings were in the original game, but in OoE we can expand the file.
          
          should_write_to_end_of_file = true
          next_string_ram_pointer = fs.expand_file_and_get_end_of_file_ram_address(text.string_ram_pointer, text.encoded_string.length + header_footer_length)
        end
        
        # System strings and AoS strings must be aligned to the nearest 4 bytes or they won't be displayed.
        region_name = TEXT_REGIONS.find{|name, range| range.include?(text.text_id)}[0]
        if GAME == "aos" || (region_name == "System" && next_string_ram_pointer % 4 != 0)
          next_string_ram_pointer = ((next_string_ram_pointer / 4) * 4) + 4
        end
        
        text.string_ram_pointer = next_string_ram_pointer
        
        if should_write_to_end_of_file
          next_string_ram_pointer = fs.expand_file_and_get_end_of_file_ram_address(text.string_ram_pointer, text.encoded_string.length + header_footer_length)
        else
          next_string_ram_pointer += text.encoded_string.length + header_footer_length
        end
      end
    end
    
    overlays.each do |overlay|
      fs.load_overlay(overlay)
      
      text_list_for_overlay = text_list.select{|text| text.overlay_id == overlay}
      text_list_for_overlay.each do |text|
        text.write_to_rom()
      end
    end
  end
end

class TextList
  include Enumerable
  
  attr_reader :fs
  
  def initialize(fs)
    @fs = fs
    @text_list = [nil]*TEXT_RANGE.size
  end
  
  # Only create and cache the texts that were specifically requested.
  def [](text_id_or_range)
    if text_id_or_range.is_a?(Integer)
      text_id = text_id_or_range
      @text_list[text_id] ||= Text.new(text_id, fs)
    elsif text_id_or_range.is_a?(Range)
      range = text_id_or_range
      range.map do |text_id|
        @text_list[text_id] ||= Text.new(text_id, fs)
      end
    else
      raise "Invalid argument to text list: #{text_id_or_range.inspect}"
    end
  end
  
  def each(&block)
    self[TEXT_RANGE] # Need to initialize the full text list before iterating over it.
    @text_list.each(&block)
  end
end
