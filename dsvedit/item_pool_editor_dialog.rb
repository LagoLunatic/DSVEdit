
require_relative 'ui_item_pool_editor'

class ItemPoolEditor < Qt::Dialog
  slots "item_pool_changed(int)"
  slots "area_changed(int)"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, game)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_ItemPoolEditor.new
    @ui.setup_ui(self)
    
    if GAME != "ooe"
      self.close()
      return
    end
    
    @game = game
    
    @item_pools = []
    (0..NUMBER_OF_ITEM_POOLS-1).each do |common_pool_id|
      @item_pools << ItemPool.new(common_pool_id, @game.fs)
      @ui.item_pool_index.addItem("Common %02X" % common_pool_id)
    end
    (0..NUMBER_OF_ITEM_POOLS-1).each do |rare_pool_id|
      @item_pools << ItemPool.new(NUMBER_OF_ITEM_POOLS+rare_pool_id, @game.fs)
      @ui.item_pool_index.addItem("Rare %02X" % rare_pool_id)
    end
    connect(@ui.item_pool_index, SIGNAL("activated(int)"), self, SLOT("item_pool_changed(int)"))
    
    @ui.item_1.addItem("0000")
    @ui.item_2.addItem("0000")
    @ui.item_3.addItem("0000")
    @ui.item_4.addItem("0000")
    @game.items.each_with_index do |item, item_id|
      @ui.item_1.addItem("%04X %s" % [item_id+1, item.name.decoded_string])
      @ui.item_2.addItem("%04X %s" % [item_id+1, item.name.decoded_string])
      @ui.item_3.addItem("%04X %s" % [item_id+1, item.name.decoded_string])
      @ui.item_4.addItem("%04X %s" % [item_id+1, item.name.decoded_string])
    end
    
    @pool_indexes_for_areas = []
    AREA_INDEX_TO_OVERLAY_INDEX.keys.each do |area_index|
      @pool_indexes_for_areas << ItemPoolIndexForArea.new(area_index, @game.fs)
      
      area_name = AREA_INDEX_TO_AREA_NAME[area_index]
      @ui.area_index.addItem("%02X %s" % [area_index, area_name])
    end
    (0..NUMBER_OF_ITEM_POOLS-1).each do |pool_id|
      @ui.pools_for_area.addItem("Common %02X & Rare %02X" % [pool_id, pool_id])
    end
    connect(@ui.area_index, SIGNAL("activated(int)"), self, SLOT("area_changed(int)"))
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    area_changed(0)
    item_pool_changed(0)
    
    self.show()
  end
  
  def item_pool_changed(item_pool_index)
    item_pool = @item_pools[item_pool_index]
    
    @ui.item_1.setCurrentIndex(item_pool.item_ids[0])
    @ui.item_2.setCurrentIndex(item_pool.item_ids[1])
    @ui.item_3.setCurrentIndex(item_pool.item_ids[2])
    @ui.item_4.setCurrentIndex(item_pool.item_ids[3])
  end
  
  def area_changed(area_index)
    if area_index >= 0x13
      # Hardcoded
      @ui.pools_for_area.setCurrentIndex(0)
      @ui.pools_for_area.setEnabled(false)
      return
    end
    @ui.pools_for_area.setEnabled(true)
    
    pool_index_for_area = @pool_indexes_for_areas[area_index]
    
    @ui.pools_for_area.setCurrentIndex(pool_index_for_area.item_pool_index)
  end
  
  def save_changes
    item_pool = @item_pools[@ui.item_pool_index.currentIndex]
    item_pool.item_ids = [
      @ui.item_1.currentIndex,
      @ui.item_2.currentIndex,
      @ui.item_3.currentIndex,
      @ui.item_4.currentIndex,
    ]
    item_pool.write_to_rom()
    
    pool_index_for_area = @pool_indexes_for_areas[@ui.area_index.currentIndex]
    pool_index_for_area.item_pool_index = @ui.pools_for_area.currentIndex
    pool_index_for_area.write_to_rom()
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_changes()
      parent.load_room()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_changes()
      parent.load_room()
    end
  end
end
