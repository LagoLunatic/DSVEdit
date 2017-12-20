
require_relative 'ui_shop_editor'

class ShopEditor < Qt::Dialog
  slots "pool_index_changed(int)"
  slots "item_index_changed(int)"
  slots "item_id_changed(int)"
  slots "requirement_changed()"
  slots "available_item_slot_changed(int)"
  slots "available_item_id_changed(int)"
  slots "price_changed()"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, game)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_ShopEditor.new
    @ui.setup_ui(self)
    
    @game = game
    
    @pools = []
    if GAME == "ooe"
      SHOP_HARDCODED_ITEM_POOL_COUNT.times do |i|
        @pools << OoEHardcodedShopItemPool.new(i, game.fs)
        pool_name = "%02X (Hardcoded)" % i
        @ui.pool_index.addItem(pool_name)
      end
    end
    SHOP_ITEM_POOL_COUNT.times do |i|
      @pools << ShopItemPool.new(i, game)
      pool_name = "%02X" % i
      
      if GAME == "ooe"
        quest_name = Text.new(TEXT_REGIONS["Quest Names"].begin + i, game.fs).decoded_string
        pool_name << " #{quest_name}"
      elsif GAME == "hod"
        # Display the merchant's Var A needed as well as Castle A/B.
        pool_name << " (%02X" % (i/2)
        if i.even?
          pool_name << "-A)"
        else
          pool_name << "-B)"
        end
      end
      
      @ui.pool_index.addItem(pool_name)
    end
    if GAME == "por"
      @pools << ShopPointItemPool.new(game.fs)
      pool_name = "Shop point unlocks"
      @ui.pool_index.addItem(pool_name)
    end
    
    if GAME == "por"
      @available_shop_item_range = PICKUP_GLOBAL_ID_RANGE
    else
      @available_shop_item_range = ITEM_GLOBAL_ID_RANGE
    end
    if GAME == "hod"
      @allowable_items = []
      SHOP_NUM_ALLOWABLE_ITEMS.times do |i|
        @allowable_items << ShopAllowableItem.new(i, @game.fs)
      end
      
      @allowable_items.each_with_index do |allowable_item, slot_index|
        item_id = @game.get_item_global_id_by_type_and_index(allowable_item.item_type, allowable_item.item_index)
        item = game.items[item_id]
        item_name = "%03X %s" % [item_id+1, item.name]
        @ui.item_id.addItem(item_name)
      end
    else
      @game.items[@available_shop_item_range].zip(@available_shop_item_range).each do |item, item_id|
        item_name = "%03X %s" % [item_id+1, item.name]
        @ui.item_id.addItem(item_name)
      end
    end
    
    if GAME == "hod"
      @game.items[@available_shop_item_range].zip(@available_shop_item_range).each do |item, item_id|
        item_name = "%03X %s" % [item_id+1, item.name]
        @ui.available_item_id.addItem(item_name)
      end
      used_items = []
      @allowable_items.each_with_index do |allowable_item, slot_index|
        item = game.get_item_by_type_and_index(allowable_item.item_type, allowable_item.item_index)
        item_name = "%02X %s" % [slot_index, item.name]
        @ui.available_item_slot.addItem(item_name)
      end
    else
      @ui.tabWidget.removeTab(1)
    end
    
    connect(@ui.pool_index, SIGNAL("currentRowChanged(int)"), self, SLOT("pool_index_changed(int)"))
    connect(@ui.item_index, SIGNAL("currentRowChanged(int)"), self, SLOT("item_index_changed(int)"))
    connect(@ui.item_id, SIGNAL("currentRowChanged(int)"), self, SLOT("item_id_changed(int)"))
    connect(@ui.requirement, SIGNAL("editingFinished()"), self, SLOT("requirement_changed()"))
    connect(@ui.available_item_slot, SIGNAL("currentRowChanged(int)"), self, SLOT("available_item_slot_changed(int)"))
    connect(@ui.available_item_id, SIGNAL("currentRowChanged(int)"), self, SLOT("available_item_id_changed(int)"))
    connect(@ui.price, SIGNAL("editingFinished()"), self, SLOT("price_changed()"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    if GAME == "por"
      @ui.label.text = "Required boss death flag"
    end
    
    pool_index_changed(0)
    item_index_changed(0)
    
    self.show()
  end
  
  def hod_reload_shop_pools_tab
    @ui.pool_index.clear()
    SHOP_ITEM_POOL_COUNT.times do |i|
      pool_name = "%02X" % i
      
      # Display the merchant's Var A needed as well as Castle A/B.
      pool_name << " (%02X" % (i/2)
      if i.even?
        pool_name << "-A)"
      else
        pool_name << "-B)"
      end
      
      @ui.pool_index.addItem(pool_name)
    end
    
    @ui.item_id.clear()
    @allowable_items.each_with_index do |allowable_item, slot_index|
      item_id = @game.get_item_global_id_by_type_and_index(allowable_item.item_type, allowable_item.item_index)
      item = @game.items[item_id]
      item_name = "%03X %s" % [item_id, item.name]
      @ui.item_id.addItem(item_name)
    end
    
    pool_index_changed(0)
    item_index_changed(0)
  end
  
  def pool_index_changed(pool_index)
    @pool = @pools[pool_index]
    
    if @pool.is_a?(ShopPointItemPool)
      @ui.requirement.text = ""
      @ui.requirement.enabled = true
    elsif @pool.requirement.nil?
      @ui.requirement.text = ""
      @ui.requirement.enabled = false
    else
      @ui.requirement.text = "%04X" % @pool.requirement
      @ui.requirement.enabled = true
    end
    if GAME == "dos"
      @ui.label.text = "Required event flag"
    elsif GAME == "por" && @pool.is_a?(ShopPointItemPool)
      @ui.label.text = "Required shop points (1000P)"
    elsif GAME == "por" || @pool.is_a?(OoEHardcodedShopItemPool) || GAME == "aos"
      @ui.label.text = "Required boss death flag"
    else
      @ui.label.text = "Requirement"
    end
    
    @ui.item_index.clear()
    if GAME == "hod"
      @pool.allowable_item_indexes.each do |available_item_index|
        allowable_item = @allowable_items[available_item_index]
        item_id = @game.get_item_global_id_by_type_and_index(allowable_item.item_type, allowable_item.item_index)
        item = @game.items[item_id]
        slot_name = "%03X %s" % [item_id+1, item.name]
        @ui.item_index.addItem(slot_name)
      end
    else
      @pool.item_ids.each_with_index do |global_id, item_index|
        item = @game.items[global_id-1]
        slot_name = "%03X %s" % [global_id, item.name]
        if @pool.slot_is_arm_shifted_immediate?(item_index)
          slot_name = "(!) #{slot_name}"
        end
        @ui.item_index.addItem(slot_name)
      end
    end
  end
  
  def item_index_changed(item_index)
    if GAME == "hod"
      allowable_item_index = @pool.allowable_item_indexes[item_index]
      return if allowable_item_index.nil?
      
      row_index = allowable_item_index
      @ui.item_id.setCurrentRow(row_index)
    else
      item_id = @pool.item_ids[item_index]
      return if item_id.nil?
      
      row_index = item_id - @available_shop_item_range.first - 1
      @ui.item_id.setCurrentRow(row_index)
    end
    
    if @pool.is_a?(ShopPointItemPool)
      required_shop_points = @pool.required_shop_points[item_index]
      @ui.requirement.text = "%04X" % required_shop_points
      @ui.requirement.enabled = true
    end
  end
  
  def item_id_changed(row_index)
    item_index = @ui.item_index.currentRow
    return if item_index == -1
    
    if GAME == "hod"
      available_item_index = row_index
      allowable_item = @allowable_items[available_item_index]
      item_id = @game.get_item_global_id_by_type_and_index(allowable_item.item_type, allowable_item.item_index)
    else
      item_id = row_index + @available_shop_item_range.first
    end
    
    if @pool.is_a?(OoEHardcodedShopItemPool) && !@pool.slot_can_have_item_id?(item_index, item_id+1)
      message = "This particular hardcoded item slot is coded as an ARM shifted immediate.\n"
      message += "This item's ID (#{"%03X" % (item_id+1)}) cannot be represented as an ARM shifted immediate.\n\n"
      message += "Basically: This slot needs to have an item ID that is less than 0x100, or an item ID that is a multiple of 4 (e.g. 7D or 14C).\n\n"
      message += "This limitation only applies to slots with the (!) at the front of them, so you can put this item in one of the ones without the (!) instead."
      Qt::MessageBox.warning(self, "Cannot put this item in this slot", message)
      return
    end
    
    if GAME == "hod"
      @pool.allowable_item_indexes[item_index] = available_item_index
    else
      @pool.item_ids[item_index] = item_id+1
    end
    
    item = @game.items[item_id]
    slot_name = "%03X %s" % [item_id+1, item.name]
    if @pool.slot_is_arm_shifted_immediate?(item_index)
      slot_name = "(!) #{slot_name}"
    end
    @ui.item_index.currentItem.text = slot_name
  end
  
  def requirement_changed
    if @pool.is_a?(ShopPointItemPool)
      if @ui.item_index.currentRow != -1
        item_index = @ui.item_index.currentRow
        @pool.required_shop_points[item_index] = @ui.requirement.text.to_i(16)
      end
    else
      @pool.requirement = @ui.requirement.text.to_i(16)
    end
  end
  
  def available_item_slot_changed(available_item_slot_index)
    available_item = @allowable_items[available_item_slot_index]
    item_id = @game.get_item_global_id_by_type_and_index(available_item.item_type, available_item.item_index)
    
    @ui.price.text = "%04X" % available_item.price
    
    row_index = item_id - @available_shop_item_range.first
    @ui.available_item_id.setCurrentRow(row_index)
  end
  
  def available_item_id_changed(row_index)
    slot_index = @ui.available_item_slot.currentRow
    return if slot_index == -1
    
    item_id = row_index + @available_shop_item_range.first
    item = @game.items[item_id]
    
    available_item = @allowable_items[slot_index]
    item_type, item_index = @game.get_item_type_and_index_by_global_id(item_id)
    available_item.item_type = item_type
    available_item.item_index = item_index
    
    slot_name = "%02X %s" % [slot_index, item.name]
    @ui.available_item_slot.currentItem.text = slot_name
  end
  
  def price_changed
    slot_index = @ui.available_item_slot.currentRow
    
    if slot_index == -1
      @ui.price.text = ""
    else
      available_item = @allowable_items[slot_index]
      
      price = @ui.price.text.to_i(16)
      available_item.price = price
      
      @ui.price.text = "%04X" % price
    end
  end
  
  def save_changes
    if @ui.tabWidget.currentIndex == 0 # Main tab
      if GAME == "aos"
        @game.autogenerate_shop_allowable_items_list(@pools)
      end
      
      @pools.each do |pool|
        pool.write_to_rom()
      end
    else # Available items tab
      @allowable_items.each do |allowable_item|
        allowable_item.write_to_rom()
      end
      @game.clear_shop_allowable_items_cache()
      hod_reload_shop_pools_tab()
    end
  rescue NDSFileSystem::ArmShiftedImmediateError => e
    Qt::MessageBox.warning(self, "Error changing requirement", e.message)
  rescue Game::ShopAllowableItemPoolTooLargeError => e
    Qt::MessageBox.warning(self, "Too many unique items", e.message)
  end
  
  def button_box_clicked(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      save_changes()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      save_changes()
    end
  end
  
  def inspect; to_s; end
end
