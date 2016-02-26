
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
    
    @string = @string.each_char.map do |char|
      byte = char.unpack("C").first
      case byte
      when 0x00..0x5A
        [byte + 0x20].pack("C")
      when 0xE6
        "\n"
      when 0xE5
        "[ENDPAGE]\n"
      when 0xE9
        "[NEWPAGE]"
      else
        "[RAW 0x%02X]" % byte
      end
    end.join
  end
end
