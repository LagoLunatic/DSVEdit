
class ItemPool
  attr_reader :pool_id,
              :fs
  attr_accessor :item_ids
  
  def initialize(pool_id, fs)
    @pool_id = pool_id
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    @item_pool_pointer = ITEM_POOLS_LIST_POINTER + 8*pool_id
    
    @item_ids = fs.read(@item_pool_pointer, 8).unpack("v*")
  end
  
  def write_to_rom
    fs.write(@item_pool_pointer, @item_ids[0..3].pack("v*"))
  end
end

class ItemPoolIndexForArea
  attr_reader :area_index,
              :fs
  attr_accessor :item_pool_index
              
  def initialize(area_index, fs)
    @area_index = area_index
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    if area_index < 0x13
      @item_pool_index = fs.read(ITEM_POOL_INDEXES_FOR_AREAS_LIST_POINTER + area_index, 1).unpack("C").first
    else
      @item_pool_index = 0 # Hardcoded
    end
  end
  
  def write_to_rom
    if area_index < 0x13
      fs.write(ITEM_POOL_INDEXES_FOR_AREAS_LIST_POINTER + area_index, [@item_pool_index].pack("C"))
    else
      # Hardcoded, do nothing
    end
  end
end
