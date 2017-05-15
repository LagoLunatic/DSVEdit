
class ShopItemPool
  attr_reader :pool_id,
              :fs
  attr_accessor :item_ids,
                :requirement
  
  def initialize(pool_id, fs)
    @pool_id = pool_id
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    @item_pool_pointer = fs.read(SHOP_ITEM_POOL_LIST + pool_id*4, 4).unpack("V").first
    
    @item_ids = []
    
    return if @item_pool_pointer == 0
    
    case GAME
    when "aos"
      @requirement = nil
      
      num_items = fs.read(@item_pool_pointer, 1).unpack("C").first
      @item_ids = fs.read(@item_pool_pointer+1, num_items).unpack("C*")
    when "dos"
      num_items_location = SHOP_ITEM_POOL_LENGTH_HARDCODED_LOCATIONS[pool_id]
      num_items = fs.read(num_items_location, 1).unpack("C").first
      @item_ids = fs.read(@item_pool_pointer, num_items).unpack("C*")
      
      required_flag_location = SHOP_ITEM_POOL_REQUIRED_EVENT_FLAG_HARDCODED_LOCATIONS[pool_id]
      if required_flag_location.nil?
        @requirement = nil
      else
        constant, constant_shift = fs.read(required_flag_location, 2).unpack("CC")
        constant_shift &= 0xF
        unless constant_shift == 0
          constant_shift = (0x10 - constant_shift)*2
        end
        required_event_flag_bit = constant << constant_shift
        if required_event_flag_bit == 0
          @requirement = 0
        else
          # Get the number of bits this was shifted by.
          # This is so we can get the event flag index instead of the bit.
          # For example, instead of bit 0x200, we want index 9.
          # We do this by converting to a string and counting the number of 0s in it.
          binary_string = "%b" % required_event_flag_bit
          @requirement = binary_string.count("0")
          if binary_string.count("1") != 1
            # There's more than 1 bit set. This shouldn't happen since there's only supposed to be one required event.
            # So just default to flag 0.
            @requirement = 0
          end
        end
      end
    when "por"
      @requirement = fs.read(@item_pool_pointer, 2).unpack("v").first
      
      offset = 2
      while true
        item_id = fs.read(@item_pool_pointer + offset, 2).unpack("v").first
        if item_id == 0xFFFF
          break
        end
        @item_ids << item_id
        offset += 2
      end
    when "ooe"
      @requirement = nil
      
      num_items = fs.read(@item_pool_pointer, 2).unpack("v").first
      @item_ids = fs.read(@item_pool_pointer+2, num_items*2).unpack("v*")
    end
  end
  
  def write_to_rom
    case GAME
    when "aos"
    when "dos"
      fs.write(@item_pool_pointer, @item_ids.pack("C*"))
      
      required_flag_location = SHOP_ITEM_POOL_REQUIRED_EVENT_FLAG_HARDCODED_LOCATIONS[pool_id]
      if !required_flag_location.nil?
        if !(0..0x1F).include?(@requirement)
          raise "Invalid requirement, must be between 0x00 and 0x1F."
        end
        
        if @requirement.even?
          constant = 1
        else
          constant = 2
        end
        if @requirement == 0
          constant_shift = @requirement
        else
          constant_shift = (0x10 - @requirement/2)
        end
        
        # The upper nibble of the constant shift byte is some other code we don't want to overwrite.
        old_constant_shift_byte = fs.read(required_flag_location+1, 1).unpack("C").first
        old_constant_shift_byte &= 0xF0
        constant_shift |= old_constant_shift_byte
        fs.write(required_flag_location, [constant, constant_shift].pack("CC"))
      end
    when "por"
      data = [@requirement] + @item_ids + [0xFFFF]
      fs.write(@item_pool_pointer, data.pack("v*"))
    when "ooe"
      return if @item_pool_pointer == 0
      data = [@item_ids.length] + @item_ids
      fs.write(@item_pool_pointer, data.pack("v*"))
    end
  end
end

class ShopPointItemPool
  attr_reader :fs
  attr_accessor :item_ids,
                :required_shop_points
  
  def initialize(fs)
    if GAME != "por"
      raise "Only PoR has a shop point unlock pool."
    end
    
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    @item_pool_pointer = SHOP_POINT_ITEM_POOL
    
    @item_ids = []
    @required_shop_points = []
    
    offset = 0
    while true
      requirement, item_id = fs.read(@item_pool_pointer + offset, 4).unpack("vv")
      if requirement == 0xFFFF && item_id == 0xFFFF
        break
      end
      @item_ids << item_id
      @required_shop_points << requirement
      offset += 4
    end
  end
  
  def write_to_rom
    data = []
    @item_ids.zip(@required_shop_points).each do |item_id, required_shop_points|
      data << required_shop_points
      data << item_id
    end
    data += [0xFFFF, 0xFFFF]
    fs.write(@item_pool_pointer, data.pack("v*"))
  end
end
