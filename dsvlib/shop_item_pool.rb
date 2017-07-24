
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
    fs.load_overlay(AREAS_OVERLAY) if AREAS_OVERLAY # In OoE this overlay also has shop data
    
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
        @requirement = fs.read_hardcoded_bit_constant(required_flag_location)
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
        fs.replace_hardcoded_bit_constant(required_flag_location, @requirement)
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

class OoEHardcodedShopItemPool
  attr_reader :pool_id,
              :fs
  attr_accessor :item_ids,
                :requirement
  
  def initialize(pool_id, fs)
    if GAME != "ooe"
      raise "Only OoE has hardcoded shop item pools."
    end
    
    @pool_id = pool_id
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    @item_ids = []
    @requirement = nil
    
    hardcoded_pool_data = SHOP_HARDCODED_ITEM_POOLS[pool_id]
    if hardcoded_pool_data[:requirement].nil?
      @requirement = nil
    else
      @requirement = fs.read_hardcoded_bit_constant(hardcoded_pool_data[:requirement])
    end
    
    hardcoded_pool_data[:items].each do |item_id_pointer, type|
      if type == :arm_shifted_immediate
        item_id = fs.read_arm_shifted_immediate_integer(item_id_pointer)
      elsif type == :word
        item_id = fs.read(item_id_pointer, 4).unpack("V").first
      end
      @item_ids << item_id
    end
  end
  
  def write_to_rom
    hardcoded_pool_data = SHOP_HARDCODED_ITEM_POOLS[pool_id]
    
    hardcoded_pool_data[:items].each_with_index do |(item_id_pointer, type), i|
      item_id = @item_ids[i]
      if type == :arm_shifted_immediate
        fs.replace_arm_shifted_immediate_integer(item_id_pointer, item_id)
      elsif type == :word
        fs.write(item_id_pointer, [item_id].pack("V"))
      end
    end
    
    if !hardcoded_pool_data[:requirement].nil?
      fs.replace_hardcoded_bit_constant(hardcoded_pool_data[:requirement], @requirement)
    end
  end
  
  def slot_is_arm_shifted_immediate?(item_index)
    item_slot_type = SHOP_HARDCODED_ITEM_POOLS[pool_id][:items].values[item_index]
    return item_slot_type == :arm_shifted_immediate
  end
  
  def slot_can_have_item_id?(item_index, item_id)
    item_slot_type = SHOP_HARDCODED_ITEM_POOLS[pool_id][:items].values[item_index]
    if item_slot_type == :arm_shifted_immediate
      begin
        fs.convert_integer_to_arm_shifted_immediate(item_id)
        return true
      rescue NDSFileSystem::ArmShiftedImmediateError
        return false
      end
    else
      true
    end
  end
end
