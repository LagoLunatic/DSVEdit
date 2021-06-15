
require 'csv'

class TextDatabase
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
    
    # Clear all text that is currently using free space beforehand.
    text_list.each do |text|
      if text.string_ram_pointer < STRING_DATABASE_START_OFFSET || text.string_ram_pointer >= STRING_DATABASE_ALLOWABLE_END_OFFSET
        # This text isn't currently in the original string database. It's in free space.
        # Therefore, we tell the free space manager to clear it, so this space can be used again.
        string_length = text.original_encoded_string_length + header_footer_length
        if string_length % 4 != 0
          # Because the free space manager pads the free spaces it gives up to 4 bytes, we have to clear up to the padded length to fully clear each of these.
          string_length = ((string_length / 4) * 4) + 4
        end
        fs.free_unused_space(text.string_ram_pointer, string_length)
      end
    end
    
    overlays = TEXT_REGIONS_OVERLAYS.values.uniq
    overlays.each do |overlay|
      fs.load_overlay(overlay) if overlay
      
      # Remove nonzero free spaces just once for each overlay, instead of once for each string.
      fs.automatically_remove_nonzero_free_spaces_for_overlay(overlay)
      
      text_list_for_overlay = text_list.select{|text| text.overlay_id == overlay}
      
      next_string_ram_pointer = STRING_DATABASE_START_OFFSET
      writing_to_end_of_file = false
      using_free_space_manager = false
      text_list_for_overlay.each do |text|
        if next_string_ram_pointer + text.encoded_string.length + header_footer_length >= STRING_DATABASE_ALLOWABLE_END_OFFSET
          # Writing strings past this point would result in something being overwritten, so start using the free space manager instead.
          using_free_space_manager = true
        end
        
        region_name = TEXT_REGIONS.find{|name, range| range.include?(text.text_id)}[0]
        
        if using_free_space_manager
          next_string_ram_pointer = fs.get_free_space(text.encoded_string.length + header_footer_length, overlay, remove_nonzero_spaces = false)
          
          # Write null bytes to where the string will take up so the free space manager doesn't consider this space free.
          string_length = text.encoded_string.length + header_footer_length
          fs.write(next_string_ram_pointer, "\0"*string_length)
        else
          if !writing_to_end_of_file && GAME == "ooe" && next_string_ram_pointer + text.encoded_string.length + header_footer_length >= STRING_DATABASE_ORIGINAL_END_OFFSET
            # Reached the end of where strings were in the original game, but in OoE we can expand the file.
            writing_to_end_of_file = true
          end
          if writing_to_end_of_file
            next_string_ram_pointer = fs.expand_overlay_and_get_end(overlay, text.encoded_string.length + header_footer_length)
          end
          
          # System strings and AoS strings must be aligned to the nearest 4 bytes or they won't be displayed.
          region_name = TEXT_REGIONS.find{|name, range| range.include?(text.text_id)}[0]
          if GAME == "aos" || (region_name == "System" && next_string_ram_pointer % 4 != 0)
            next_string_ram_pointer = ((next_string_ram_pointer / 4) * 4) + 4
          end
        end
        
        text.string_ram_pointer = next_string_ram_pointer
        
        if !writing_to_end_of_file && !using_free_space_manager
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
  
  def export_to_csv(output_folder)
    FileUtils.mkdir_p(output_folder)
    
    TEXT_REGIONS.each do |region_name, text_index_range|
      output_path = File.join(output_folder, "%s.csv" % region_name)
      CSV.open(output_path, "wb", encoding: "UTF-8") do |csv|
        text_list[text_index_range].each do |text|
          csv << ["0x%03X" % text.text_id, text.decoded_string]
        end
      end
    end
  end
  
  def import_from_csv(input_folder)
    TEXT_REGIONS.each do |region_name, text_index_range|
      input_path = File.join(input_folder, "%s.csv" % region_name)
      rows = CSV.read(input_path, encoding: "UTF-8")
      rows.each do |text_id, string|
        text_id = text_id.to_i(16)
        if !text_index_range.include?(text_id)
          raise "Text ID 0x%03X does not belong in text region \"%s\"" % [text_id, region_name]
        end
        text = text_list[text_id]
        text.decoded_string = string
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
      @text_list[range].each_index do |text_id_offset|
        text_id = range.begin + text_id_offset
        @text_list[text_id] ||= Text.new(text_id, fs)
      end
      @text_list[range]
    else
      raise "Invalid argument to text list: #{text_id_or_range.inspect}"
    end
  end
  
  def each(&block)
    self[TEXT_RANGE] # Need to initialize the full text list before iterating over it.
    @text_list.each(&block)
  end
end
