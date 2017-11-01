
class PaletteWrapper
  attr_reader :palette_wrapper_pointer,
              :palette_list_pointer,
              :fs,
              :palette_index,
              :num_palettes,
              :palette_load_offset,
              :unknown_2
              
  def initialize(palette_wrapper_pointer, fs)
    @palette_wrapper_pointer = palette_wrapper_pointer
    @fs = fs
    
    if GAME == "hod"
      @type, @palette_wrapper_info, @palette_list_pointer = fs.read(palette_wrapper_pointer, 8).unpack("vvV")
      if @type == 0
        @palette_load_offset = 0
        @palette_index = 0
        @num_palettes = 0xD
      else
        @num_palettes = 2
        @palette_index = (@palette_wrapper_info & 0xFF00) >> 8
        @palette_index += 1
        @palette_load_offset = @palette_wrapper_info & 0xF
        @palette_load_offset += 1
      end
    else
      @palette_list_pointer, @palette_load_offset, @palette_index, @num_palettes, @unknown_2 = fs.read(palette_wrapper_pointer, 8).unpack("VCCCC")
    end
  end
  
  def self.from_palette_wrapper_pointer(palette_wrapper_list_pointer, fs)
    offset = palette_wrapper_list_pointer
    palette_wrappers = []
    while true
      if GAME == "hod"
        palette_list_pointer = fs.read(offset+4, 4).unpack("V").first
      else
        palette_list_pointer = fs.read(offset, 4).unpack("V").first
      end
      break if palette_list_pointer == 0
      
      palette_wrappers << PaletteWrapper.new(offset, fs)
      
      offset += 8
    end
    
    return palette_wrappers
  end
end
