
class Text
  attr_reader :text_id,
              :text_ram_pointer,
              :fs
  attr_accessor :string_ram_pointer,
                :string
  
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
    
    @text_ram_pointer = STRING_LIST_START_OFFSET + 4*text_id
    @string_ram_pointer = fs.read(@text_ram_pointer, 4).unpack("V").first
    @string = fs.read_until_end_marker(string_ram_pointer+2, 0xEA) # Skip the first 2 bytes which are always 01 00.
    
    @string = decode_string(@string)
  end
  
  def write_to_rom
    fs.write(text_ram_pointer, [string_ram_pointer].pack("V"))
    fs.write(string_ram_pointer, [1].pack("v"))
    
    encoded_string = encode_string(@string)
    fs.write(string_ram_pointer+2, encoded_string)
    fs.write(string_ram_pointer+2+encoded_string.length, [0xEA].pack("C"))
  end
  
  def decode_string(string)
    previous_byte = nil
    decoded_string = string.each_char.map do |char|
      byte = char.unpack("C").first
      
      char = case previous_byte
      when 0xE3
        "{PORTRAIT 0x%02X}" % byte
      when 0xE5
        case byte
        when 0xE4
          "{NEXTPAGE NEWCHAR}"
        when 0xE9
          "{NEXTPAGE SAMECHAR}"
        else
          "{NEXTPAGE 0x%02X}" % byte
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
    
    return decoded_string
  end
  
  def encode_string(string)
    encoded_string = string.scan(/\{[^\}]+\}|./m).map do |str|
      if str.length > 1
        str =~ /\{([A-Z0-9]+)(?: (?:0x)?([^\}]+))?\}/
        
        case $1
        when "RAW"
          byte = $2.to_i(16)
          [byte].pack("C")
        when "BUTTON"
          button_index = %w(L R A B X Y LEFT RIGHT UP DOWN).index($2)
          [0xEB + button_index].pack("C")
        when "PORTRAIT"
          byte = $2.to_i(16)
          [0xE3, byte].pack("CC")
        when "NEXTPAGE"
          byte = case $2
          when "NEWCHAR"
            0xE4
          when "SAMECHAR"
            0xE9
          else
            $2.to_i(16)
          end
          [0xE5, byte].pack("CC")
        when "CHARACTER"
          byte = $2.to_i(16)
          [0xE7, byte].pack("CC")
        when "NEXTACTION"
          [0xE2, 0x01].pack("CC")
        when "E2"
          byte = $2.to_i(16)
          [0xE2, byte].pack("CC")
        else
          raise "Failed to encode: #{str.inspect}"
        end
      else
        byte = str.unpack("C").first
        
        char = case byte
        when 0x20..0x7A # Ascii text
          [byte - 0x20].pack("C")
        when 0x0A # Newline
          [0xE6].pack("C")
        end
        
        char
      end
    end.join
    
    return encoded_string
  end
end
