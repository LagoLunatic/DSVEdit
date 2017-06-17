
class GfxWrapper
  attr_reader :gfx_pointer,
              :fs,
              :file,
              :unknown_1,
              :bpp,
              :size_in_512_chunks,
              :gfx_data_pointer
  attr_accessor :render_mode,
                :canvas_width
              
  def initialize(gfx_pointer, fs, unwrapped: false)
    @gfx_pointer = gfx_pointer
    @fs = fs
    
    if SYSTEM == :nds
      @file = fs.assets_by_pointer[gfx_pointer]
      @unknown_1, @render_mode, @canvas_width = fs.read(gfx_pointer, 4).unpack("CCv")
    else
      if unwrapped
        @gfx_data_pointer = gfx_pointer
        @render_mode = 1
        @canvas_width = 0x10
        @size_in_512_chunks = 0x10
      else
        @unknown_1, @bpp, @unknown_3, @size_in_512_chunks, @gfx_data_pointer = fs.read(gfx_pointer, 8).unpack("CCCCV")
        @render_mode = case bpp
        when 4
          1
        when 8
          2
        else
          raise "Unknown bpp: #{bpp}"
        end
        @canvas_width = 0x10
      end
    end
  end
  
  def gfx_data
    if SYSTEM == :nds
      fs.read_by_file(file[:file_path], 0, 0x2000*render_mode, allow_reading_into_next_file_in_ram: true)
    else
      @gfx_data ||= if @bpp == 4 || @bpp == 8
        fs.decompress(gfx_data_pointer)
      else
        fs.read(gfx_data_pointer+4, 512*size_in_512_chunks)
      end
    end
  end
  
  def write_gfx_data(new_gfx_data)
    if SYSTEM == :nds
      fs.write_by_file(gfx.file[:file_path], 0, gfx_data_bytes.pack("C*"))
    else
      if @bpp == 4 || @bpp == 8
        fs.compress_write(gfx_data_pointer, new_gfx_data)
      else
        if new_gfx_data.length > 0x2000
          raise "New GFX data too large"
        end
        fs.write(gfx_data_pointer+4, new_gfx_data)
      end
      
      @gfx_data = nil # Clear gfx data cache
    end
  end
  
  def write_to_rom
    if SYSTEM == :nds
      fs.write(gfx_pointer, [@unknown_1, @render_mode, @canvas_width].pack("CCv"))
      fs.write(gfx_pointer + 4, [@canvas_width].pack("v"))
    else
      raise NotImplementedError.new
    end
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
