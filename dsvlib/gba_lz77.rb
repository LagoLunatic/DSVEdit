
class GBALZ77
  class DecompressionError < StandardError ; end
  class CompressionError < StandardError ; end
  
  def self.decompress(compr)
    header = compr[0,4].unpack("V").first
    compression_type = header & 0xFF
    uncompressed_size = (header & 0xFFFFFF00) >> 8
    
    if compression_type != 0x10
      raise DecompressionError.new("Not LZ77 compressed: %1X" % compression_type)
    end
    
    decomp = []
    read_bytes = 4
    
    while true
      type_flags_for_next_8_subblocks = compr[read_bytes].unpack("C").first
      read_bytes += 1
      
      (0..7).each do |subblock_index|
        break if decomp.length == uncompressed_size
        
        block_type = (type_flags_for_next_8_subblocks >> (7 - subblock_index)) & 1
        
        if block_type == 0 # uncompressed byte
          byte = compr[read_bytes].unpack("C").first
          decomp << byte
          read_bytes += 1
        else # compressed
          subblock = compr[read_bytes,2].unpack("n").first
          read_bytes += 2
          
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
    compr_length = read_bytes
    return [decomp, compr_length]
  end
  
  # Data header (32bit)
  #   Bit 0-3   Reserved
  #   Bit 4-7   Compressed type (must be 1 for LZ77)
  #   Bit 8-31  Size of decompressed data
  # Repeat below. Each Flag Byte followed by eight Blocks.
  # Flag data (8bit)
  #   Bit 0-7   Type Flags for next 8 Blocks, MSB first
  # Block Type 0 - Uncompressed - Copy 1 Byte from Source to Dest
  #   Bit 0-7   One data byte to be copied to dest
  # Block Type 1 - Compressed - Copy N+3 Bytes from Dest-Disp-1 to Dest
  #   Bit 0-3   Disp MSBs
  #   Bit 4-7   Number of bytes to copy (minus 3)
  #   Bit 8-15  Disp LSBs
  def self.compress(data)
    # https://github.com/Barubary/dsdecmp/blob/master/CSharp/DSDecmp/Formats/Nitro/LZ10.cs
    
    data_length = data.size
    if data_length > 0xFFFFFF
      raise "Data size is too large: 0x%06X bytes long" % data.size
    end
    
    if true
      return compress_lookahead(data)
    end
    
    data = data.unpack("C*")
    
    comp = []
    comp << 0x10
    comp <<  (data_length & 0x0000FF)
    comp << ((data_length & 0x00FF00) >> 8)
    comp << ((data_length & 0xFF0000) >> 16)
    
    outbuffer = []
    outbuffer << 0
    buffered_blocks = 0
    read_bytes = 0
    while read_bytes < data_length
      if buffered_blocks == 8
        # Reached number of blocks to buffer, so write them.
        comp += outbuffer
        
        outbuffer = []
        outbuffer << 0
        buffered_blocks = 0
      end
      
      old_length = [read_bytes, 0x1000].min
      occ_length, disp = get_occurrence_length_and_disp(data[read_bytes..-1], [data[read_bytes..-1].size, 0x12].min, data[read_bytes-old_length..-1], old_length)
      
      if occ_length < 3
        # If length is less than 3 it should be uncompressed data.
        outbuffer << data[read_bytes]
        read_bytes += 1
      else
        read_bytes += occ_length
        
        outbuffer[0] |= (1 << (7-buffered_blocks))
        
        outbuffer     << (((disp-1) >> 8) & 0x0F) # disp MSBs
        outbuffer[-1] |= (((occ_length-3) << 4) & 0xF0) # number of bytes to copy
        outbuffer     << ((disp-1) & 0xFF) # disp LSBs
      end
      
      buffered_blocks += 1
    end
    
    if buffered_blocks > 0
      # Still have some leftovers in the buffer, so write them.
      comp += outbuffer
    end
    
    comp = comp.pack("C*")
    return comp
  end
  
  def self.compress_lookahead(data)
    data = data.unpack("C*")
    
    data_length = data.size
    if data_length > 0xFFFFFF
      raise CompressionError.new("Data size is too large: 0x%06X bytes long" % data.size)
    end
    
    comp = []
    comp << 0x10
    comp <<  (data_length & 0x0000FF)
    comp << ((data_length & 0x00FF00) >> 8)
    comp << ((data_length & 0xFF0000) >> 16)
    
    outbuffer = []
    outbuffer << 0
    buffered_blocks = 0
    read_bytes = 0
    
    lengths, disps = get_optimal_compression_lengths(data)
    
    while read_bytes < data_length
      if buffered_blocks == 8
        # Reached number of blocks to buffer, so write them.
        comp += outbuffer
        
        outbuffer = []
        outbuffer << 0
        buffered_blocks = 0
      end
      
      if lengths[read_bytes] == 1
        outbuffer << data[read_bytes]
        read_bytes += 1
      else
        outbuffer[0] |= (1 << (7-buffered_blocks))
        
        outbuffer     << (((disps[read_bytes]-1) >> 8) & 0x0F) # disp MSBs
        outbuffer[-1] |= (((lengths[read_bytes]-3) << 4) & 0xF0) # number of bytes to copy
        outbuffer     << ((disps[read_bytes]-1) & 0xFF) # disp LSBs
        
        read_bytes += lengths[read_bytes]
      end
      
      buffered_blocks += 1
    end
    
    if buffered_blocks > 0
      # Still have some leftovers in the buffer, so write them.
      comp += outbuffer
    end
    
    comp = comp.pack("C*")
    return comp
  end
  
  def self.get_occurrence_length_and_disp(new_data, new_length, old_data, old_length)
    if new_length == 0
      return [0, 0]
    end
    
    disp = 0
    max_length = 0
    
    # Try every possible offset in the already compressed data
    (0..old_length-1).each do |i|
      current_old_start = i
      
      # Figure out how many bytes can be copied at this offset.
      current_copyable_length = 0
      new_length.times do |j|
        if old_data[current_old_start + j] != new_data[j]
          break
        end
        current_copyable_length += 1
      end
      
      if current_copyable_length > max_length
        max_length = current_copyable_length
        disp = old_length - i
        
        if max_length == new_length
          break
        end
      end
    end
    
    return [max_length, disp]
  end
  
  def self.get_optimal_compression_lengths(data)
    lengths = Array.new(data.size)
    disps = Array.new(data.size)
    min_lengths = Array.new(data.size)
    
    fixnum_max_value = (2**(0.size * 8 -2) - 1)
    
    (0..data.size-1).reverse_each do |i|
      min_lengths[i] = fixnum_max_value
      lengths[i] = 1
      if i + 1 >= data.size
        min_lengths[i] = 1
      else
        min_lengths[i] = 1 + min_lengths[i + 1]
      end
      
      old_length = [i, 0x1000].min
      max_len, disps[i] = get_occurrence_length_and_disp(data[i..-1], [data[i..-1].size, 0x12].min, data[i-old_length..-1], old_length)
      
      if disps[i] > i
        raise CompressionError.new("Disp is too large")
      end
      
      (3..max_len).each do |j|
        if i + j >= data.size
          new_comp_len = 2
        else
          new_comp_len = 2 + min_lengths[i+j]
        end
        if new_comp_len < min_lengths[i]
          lengths[i] = j
          min_lengths[i] = new_comp_len
        end
      end
    end
    
    return [lengths, disps]
  end
end
