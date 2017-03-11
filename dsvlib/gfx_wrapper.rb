
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
end
