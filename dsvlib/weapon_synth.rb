
class WeaponSynthChain
  attr_reader :chain_index,
              :fs,
              :synth_list_pointer,
              :synths
              
  def initialize(chain_index, fs)
    @chain_index = chain_index
    @fs = fs
    read_from_rom()
  end
  
  def read_from_rom
    @synth_list_pointer = fs.read(WEAPON_SYNTH_CHAIN_LIST_START + chain_index*4, 4).unpack("V").first
    
    @synths = []
    synth_index = 0
    while true
      synth_pointer = synth_list_pointer + synth_index*4
      
      break if fs.read(synth_pointer, 1).unpack("C").first == 0
      
      synth = WeaponSynth.new(synth_pointer, fs)
      @synths << synth
      
      synth_index += 1
    end
  end
end

class WeaponSynth
  attr_accessor :synth_pointer,
                :fs,
                :required_item_id,
                :required_soul_id,
                :created_item_id,
                :unknown_1
              
  def initialize(synth_pointer, fs)
    @synth_pointer = synth_pointer
    @fs = fs
    
    read_from_rom()
  end
  
  def read_from_rom
    @required_item_id, @required_soul_id, @created_item_id, @unknown_1 = fs.read(synth_pointer, 4).unpack("CCCC")
  end
  
  def write_to_rom
    if @required_item_id == 0
      raise "Required item ID cannot be 00."
    end
    
    fs.write(synth_pointer, [@required_item_id, @required_soul_id, @created_item_id, @unknown_1].pack("CCCC"))
  end
end
