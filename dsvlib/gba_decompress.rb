
class GBADecompress
  class DecompressionError < StandardError ; end
  
  def initialize(file, offset)
    @file = file
    @file.seek(offset)
  end
  
  def decompress
    compr = @file
    decomp = []
    
    header = compr.read(4).unpack("V").first
    compression_type = header & 0xFF
    uncompressed_size = (header & 0xFFFFFF00) >> 8
    
    if compression_type != 0x10
      raise DecompressionError.new("Not LZ77 compressed: %1X" % compression_type)
    end
    
    while true
      type_flags_for_next_8_subblocks = compr.read(1).unpack("C").first
      
      (0..7).each do |subblock_index|
        break if decomp.length == uncompressed_size
        
        block_type = (type_flags_for_next_8_subblocks >> (7 - subblock_index)) & 1
        
        if block_type == 0 # uncompressed byte
          byte = compr.read(1).unpack("C").first
          decomp << byte
        else # compressed
          subblock = compr.read(2).unpack("n").first
          
          backwards_offset  =  subblock & 0b00001111_11111111
          num_bytes_to_copy = (subblock & 0b11110000_00000000) >> 12
          num_bytes_to_copy += 3
          
          pointer = decomp.length - backwards_offset - 1
          (0..num_bytes_to_copy-1).each do |i|
            byte = decomp[pointer+i]
            decomp << byte
          end
        end
      end
      
      break if decomp.length == uncompressed_size
    end
    
    decomp = decomp.pack("C*")
    return decomp
  end
end
