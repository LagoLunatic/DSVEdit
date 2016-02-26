
class Text
  attr_reader :text_id,
              :string_ram_pointer,
              :string,
              :fs
  
  def initialize(text_id, fs)
    @text_id = text_id
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    region_name = STRING_REGIONS.find{|name, range| range.include?(text_id)}[0]
    if STRING_REGIONS_OVERLAYS[region_name]
      fs.load_overlay(STRING_REGIONS_OVERLAYS[region_name])
    end
    
    @string_ram_pointer = fs.read(STRING_LIST_START_OFFSET + 4*text_id, 4).unpack("V").first
    @string = fs.read_until_end_marker(string_ram_pointer+2, 0xEA) # Skip the first 2 bytes which are always 01 00.
    
    @string = decode_string(@string)
  end
  
  def decode_string(string)
    previous_byte = nil
    string = string.each_char.map do |char|
      byte = char.unpack("C").first
      
      char = case previous_byte
      when 0xE3
        "{PORTRAIT 0x%02X}" % byte
      when 0xE5
        case byte
        when 0xE4
          "{NEXTPAGE SAMECHAR}\n"
        when 0xE9
          "{NEXTPAGE NEWCHAR}\n"
        else
          "{NEXTPAGE 0x%02X}\n" % byte
        end
      when 0xE7
        "{CHARACTER 0x%02X}" % byte
      when 0xE2
        case byte
        when 0x01
          "{NEXTACTION}"
        else
          "{E2 0x%02X}" % byte
        end
      else
        case byte
        when 0x00..0x5A # Ascii text
          [byte + 0x20].pack("C")
        when 0xAF
          "'"
        when 0xB1
          '"'
        when 0xE6
          "\n"
        when 0xEB..0xF4
          button_index = byte - 0xEB
          button = %w(L R A B X Y LEFT RIGHT UP DOWN)[button_index]
          "{BUTTON #{button}}"
        when 0xE2, 0xE3, 0xE5, 0xE7
          ""
        else
          "{RAW 0x%02X}" % byte
        end
      end
      
      previous_byte = byte
      
      char
    end.join
    
    return string
  end
end
