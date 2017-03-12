
class Text
  class TextDecodeError < StandardError ; end
  class TextEncodeError < StandardError ; end
  
  attr_reader :text_id,
              :text_ram_pointer,
              :fs
  attr_accessor :string_ram_pointer,
                :decoded_string,
                :encoded_string
  
  def initialize(text_id, fs)
    @text_id = text_id
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    if REGION == :jp
      read_from_rom_jp()
    else
      read_from_rom_usa()
    end
  end
  
  def read_from_rom_usa
    if overlay_id
      fs.load_overlay(overlay_id)
    end
    
    @text_ram_pointer = TEXT_LIST_START_OFFSET + 4*text_id
    @string_ram_pointer = fs.read(@text_ram_pointer, 4).unpack("V").first
    @encoded_string = fs.read_until_end_marker(string_ram_pointer+2, [0xEA]) # Skip the first 2 bytes which are always 01 00.
    
    @decoded_string = decode_string(@encoded_string)
  end
  
  def read_from_rom_jp
    if overlay_id
      fs.load_overlay(overlay_id)
    end
    
    @text_ram_pointer = TEXT_LIST_START_OFFSET + 4*text_id
    @string_ram_pointer = fs.read(@text_ram_pointer, 4).unpack("V").first
    @encoded_string = fs.read_until_end_marker(string_ram_pointer+2, [0x0A, 0xF0]) # Skip the first 2 bytes which are always 00 00.
    
    @decoded_string = decode_string_jp(@encoded_string)
  end
  
  def write_to_rom
    fs.write(text_ram_pointer, [string_ram_pointer].pack("V"))
    if REGION == :jp
      data = [0].pack("v") + encoded_string + [0x0A, 0xF0].pack("CC")
    else
      data = [1].pack("v") + encoded_string + [0xEA].pack("C")
    end
    fs.write(string_ram_pointer, data)
  end
  
  def overlay_id
    region_name = TEXT_REGIONS.find{|name, range| range.include?(text_id)}[0]
    TEXT_REGIONS_OVERLAYS[region_name]
  end
  
  def decoded_string=(new_str)
    @decoded_string = new_str
    @encoded_string = encode_string(new_str)
  end
  
  def encoded_string=(new_str)
    @encoded_string = new_str
    @decoded_string = decode_string(new_str)
  end
  
  def font_character_mapping_jp(index)
    offset = (((index & 0xFF00) >> 8) - 0x81) * 0xBC * 0xA
    index = index & 0x00FF
    if index > 0x7E
      index -= 1
    end
    offset += (index - 0x40) * 0xA
    file_path = "/font/LD937728.DAT"
    char_number = fs.read_by_file(file_path, offset, 2).unpack("n").first # big endian
    return char_number
  end
  
  def reverse_font_character_mapping_jp(shift_jis)
    offset = 0
    file_path = "/font/LD937728.DAT"
    file_size = fs.files_by_path[file_path][:size]
    found_offset = nil
    while offset < file_size
      char_number = fs.read_by_file(file_path, offset, 2).unpack("n").first # big endian
      
      if char_number == shift_jis
        found_offset = offset
        break
      end
      
      offset += 0xA
    end
    
    if found_offset.nil?
      raise TextEncodeError.new("Invalid shift jis character: %04X" % shift_jis)
    end
    
    index = offset / 0xA
    
    high_byte = ((index / 0xBC) + 0x81) << 8
    low_byte = (index % 0xBC) + 0x40
    if low_byte >= 0x7D
      low_byte += 1
    end
    halfword = high_byte | low_byte
    
    return halfword
  end
  
  def decode_string(string)
    if REGION == :jp
      decode_string_jp(string)
    else
      decode_string_usa(string)
    end
  end
  
  def encode_string(string)
    string.force_encoding("UTF-8")
    
    encoded_string = string.scan(/(?<!\\){(?:(?!}).|\\})+(?<!\\)}|\\{|\\}|./m).map do |str|
      if str.length > 1
        str =~ /{([A-Z0-9]+)(?: (?:0x)?([^}]+))?}/
        
        if REGION == :jp
          encode_command_jp($1, $2)
        else
          encode_command_usa($1, $2)
        end
      else
        if REGION == :jp
          encode_char_jp(str)
        else
          byte = str.unpack("C").first
          encode_char_usa(byte)
        end
      end
    end.join
    
    return encoded_string
  end
  
  def decode_string_usa(string)
    previous_byte = nil
    multipart = false
    decoded_string = string.each_char.map do |char|
      byte = char.unpack("C").first
      
      char = if multipart
        multipart = false
        command_number = previous_byte - 0xE0
        decode_multipart_command(command_number, byte)
      elsif byte >= 0xE0
        command_number = byte - 0xE0
        command = decode_command(command_number)
        if command == :multipart
          multipart = true
          ""
        else
          command
        end
      else
        case byte
        when 0x00..0x5E # Ascii text
          char = [byte + 0x20].pack("C")
          if char == "{" || char == "}"
            char = "\\" + char
          end
          char
        when 0x5F
          "・"
        when 0x60..0xBF
          "¡¢£¨©®°±´¸¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýŒœ"[byte-0x60]
        when 0xAF
          "'"
        when 0xB1
          '"'
        else
          puts "text id %04X" % text_id
          "{RAW 0x%02X}" % byte
        end
      end
      
      previous_byte = byte
      
      char
    end.join
    
    return decoded_string
  end
  
  def decode_string_jp(string)
    previous_halfword = nil
    multipart = false
    decoded_string = string.unpack("v*").map do |char|
      halfword = char
      
      char = if multipart
        multipart = false
        command_number = previous_halfword & 0x00FF
        decode_multipart_command(command_number, halfword)
      elsif halfword & 0xFF00 == 0xF000
        command_number = halfword & 0x00FF
        command = decode_command(command_number)
        if command == :multipart
          multipart = true
          ""
        else
          command
        end
      elsif halfword >= 0x8140
        shift_jis = font_character_mapping_jp(halfword)
        shift_jis.chr(Encoding::SHIFT_JIS).encode("UTF-8")
      else
        puts "text id %04X" % text_id
        "{RAW 0x%04X}" % halfword
      end
      
      previous_halfword = halfword
      
      char
    end.join
    
    return decoded_string
  end
  
  def decode_command(command_number)
    case command_number
    when 0x00
      puts "text id %04X" % text_id
      "{RAW 0x%04X}" % command_number
    when 0x02, 0x03, 0x07, 0x08
      :multipart
    when 0x04
      "{NEWCHAR}"
    when 0x05
      "{WAITINPUT}"
    when 0x06
      "\n"
    when 0x09
      "{SAMECHAR}"
    when 0x0B..0x14
      button = %w(L R A B X Y LEFT RIGHT UP DOWN)[command_number-0x0B]
      "{BUTTON #{button}}"
    when 0x15..0x1A
      "{BUTTON 0x%04X}" % command_number
    else
      puts "text id %04X" % text_id
      "{RAW 0x%04X}" % command_number
    end
  end
  
  def decode_multipart_command(command_number, data)
    case command_number
    when 0x02
      case data
      when 0x01
        "{NEXTACTION}"
      else
        "{COMMAND2 0x%04X}" % data
      end
    when 0x03
      "{PORTRAIT 0x%04X}" % data
    when 0x07
      "{NAME 0x%04X}" % data
    when 0x08
      color_name = TEXT_COLOR_NAMES[data]
      if color_name.nil?
        "{TEXTCOLOR %04X}" % data
      else
        "{TEXTCOLOR %s}" % color_name
      end
    else
      raise TextDecodeError.new("Failed to decode command: %02X %02X" % [command_number, data])
    end
  end
  
  def encode_char_usa(byte)
    char = case byte
    when 0x20..0x7A # Ascii text
      [byte - 0x20].pack("C")
    when 0x0A # Newline
      [0xE6].pack("C")
    end
    
    char
  end
  
  def encode_command_usa(command, data)
    case command
    when "RAW"
      byte = data.to_i(16)
      [byte].pack("C")
    when "BUTTON"
      button_index = %w(L R A B X Y LEFT RIGHT UP DOWN).index(data)
      [0xEB + button_index].pack("C")
    when "PORTRAIT"
      byte = data.to_i(16)
      [0xE3, byte].pack("CC")
    when "NEWCHAR"
      [0xE4].pack("C")
    when "SAMECHAR"
      [0xE9].pack("C")
    when "WAITINPUT"
      [0xE5].pack("v")
    when "NAME"
      byte = data.to_i(16)
      [0xE7, byte].pack("CC")
    when "NEXTACTION"
      [0xE2, 0x01].pack("CC")
    when "TEXTCOLOR"
      color_name = data
      byte = TEXT_COLOR_NAMES.key(color_name)
      if byte
        [0xE8, byte].pack("CC")
      else
        [0xE8, data.to_i(16)].pack("CC")
      end
    else
      raise TextEncodeError.new("Failed to encode command: #{command} #{data}")
    end
  end
  
  def encode_char_jp(input_char)
    shift_jis = input_char.encode("SHIFT_JIS").ord
    index = reverse_font_character_mapping_jp(shift_jis)
    return [index].pack("v")
  end
  
  def encode_command_jp(command, data)
    case command
    when "RAW"
      halfword = data.to_i(16)
      [halfword].pack("v")
    when "BUTTON"
      button_index = %w(L R A B X Y LEFT RIGHT UP DOWN).index(data)
      if button_index
        [0xF00B + button_index].pack("v")
      elsif (0x15..0x1A).include?(data.to_i(16))
        [0xF000 + data.to_i(16)].pack("v")
      else
        raise TextEncodeError.new("Failed to encode command: #{command} #{data}")
      end
    when "PORTRAIT"
      halfword = data.to_i(16)
      [0xF003, halfword].pack("vv")
    when "NEWCHAR"
      [0xF004].pack("v")
    when "SAMECHAR"
      [0xF009].pack("v")
    when "WAITINPUT"
      [0xF005].pack("v")
    when "NAME"
      halfword = data.to_i(16)
      [0xF007, halfword].pack("vv")
    when "NEXTACTION"
      [0xF002, 0x0001].pack("vv")
    when "TEXTCOLOR"
      color_name = data
      halfword = TEXT_COLOR_NAMES.key(color_name)
      if halfword
        [0xF008, halfword].pack("vv")
      else
        [0xF008, data.to_i(16)].pack("vv")
      end
    else
      raise TextEncodeError.new("Failed to encode command: #{command} #{data}")
    end
  end
end
