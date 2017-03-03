
class Text
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
  
  def decode_string(string)
    if REGION == :jp
      decode_string_jp(string)
    else
      decode_string_usa(string)
    end
  end
  
  def encode_string(string)
    if REGION == :jp
      encode_string_jp(string)
    else
      encode_string_usa(string)
    end
  end
  
  def decode_string_usa(string)
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
  
  def encode_string_usa(string)
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
  
  def decode_string_jp(string)
    decoded_string = string.unpack("v*").map do |char|
      halfword = char
      
      char = case halfword
      when 0x8142..0x8157
        "。．・：？！々ー／～…’（）「」＋―＄％＆＊"[halfword-0x8142]
      when 0x8158..0x8161
        "0123456789"[halfword-0x8158]
      when 0x8162..0x8191
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwx"[halfword-0x8162]
      when 0x8192..0x81DF
        "ぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞただちっつてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽまみむめもゃやゅゆょよらりるれろわをん"[halfword-0x8192]
      when 0x81E0..0x81FF
        "ァアィイゥウェエォオカガキギクグケゲコゴサザシジスズセゼソゾタダ"[halfword-0x81E0]
      when 0x8240..0x8271
        "ゾタダチッツテデトドナニヌネノハバパヒビピフブプヘベペホボポマミムメモャヤュユョヨラリルレロワヲンヴ"[halfword-0x8240]
      #when 0x848B # Kanji.
      #  #(halfword+0x92B).chr(Encoding::SHIFT_JIS).encode("UTF-8")
      #  (halfword-0x26A5).chr(Encoding::UTF_8)
      else
        "{RAW 0x%04X}" % halfword
      end
      
      char
    end.join
    
    return decoded_string
  end
  
  def encode_string_jp(string)
    string = string.force_encoding("UTF-8")
    
    encoded_string = string.scan(/\{[^\}]+\}|./mu).map do |str|
      if str.length > 1
        str =~ /\{([A-Z0-9]+)(?: (?:0x)?([^\}]+))?\}/
        
        case $1
        when "RAW"
          halfword = $2.to_i(16)
          [halfword].pack("v")
        else
          ""
        end
      else
        str = str.encode("UTF-8")
        
        if index = "。．・：？！々ー／～…’（）「」＋―＄％＆＊".index(str)
          [index+0x8142].pack("v")
        elsif index = "0123456789".index(str)
          [index+0x8158].pack("v")
        elsif index = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwx".index(str)
          [index+0x8162].pack("v")
        elsif index = "ぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞただちっつてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽまみむめもゃやゅゆょよらりるれろわをん".index(str)
          [index+0x8192].pack("v")
        elsif index = "ァアィイゥウェエォオカガキギクグケゲコゴサザシジスズセゼソゾタダ".index(str)
          [index+0x81E0].pack("v")
        elsif index = "ゾタダチッツテデトドナニヌネノハバパヒビピフブプヘベペホボポマミムメモャヤュユョヨラリルレロワヲンヴ".index(str)
          [index+0x8240].pack("v")
        end
      end
    end.join
    
    return encoded_string
  end
end
