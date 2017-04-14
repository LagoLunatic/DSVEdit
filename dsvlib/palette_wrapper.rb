
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
    
    @palette_list_pointer, @palette_load_offset, @palette_index, @num_palettes, @unknown_2 = fs.read(palette_wrapper_pointer, 8).unpack("VCCCC")
  end
  
  def self.from_palette_wrapper_pointer(palette_wrapper_list_pointer, fs)
    offset = palette_wrapper_list_pointer
    palette_wrappers = []
    while true
      palette_list_pointer = fs.read(offset, 4).unpack("V").first
      break if palette_list_pointer == 0
      
      palette_wrappers << PaletteWrapper.new(offset, fs)
      
      offset += 8
    end
    
    return palette_wrappers
  end
end
