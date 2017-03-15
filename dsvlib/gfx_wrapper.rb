
class GfxWrapper
  attr_reader :gfx_pointer,
              :fs,
              :file,
              :unknown_1,
              :render_mode,
              :canvas_width,
              :unknown_2
              
  def initialize(gfx_pointer, fs)
    @gfx_pointer = gfx_pointer
    @fs = fs
    
    @file = fs.find_file_by_ram_start_offset(gfx_pointer)
    @unknown_1, @render_mode, @canvas_width, @unknown_2 = fs.read(gfx_pointer, 4).unpack("C*")
  end
  
  def colors_per_palette
    case render_mode
    when 1
      16
    when 2
      256
    else
      raise "Unknown render mode: %02X" % render_mode
    end
  end
  
  def self.from_gfx_list_pointer(gfx_list_pointer, fs)
    offset = gfx_list_pointer
    gfx_wrappers = []
    while true
      gfx_pointer, unknown = fs.read(offset, 8).unpack("VV")
      break if gfx_pointer == 0
      
      gfx_wrappers << GfxWrapper.new(gfx_pointer, fs)
      
      offset += 8
    end
    
    return gfx_wrappers
  end
end
