
require_relative 'ui_shop_editor'

class ShopEditor < Qt::Dialog
  slots "pool_index_changed(int)"
  slots "item_index_changed(int)"
  slots "item_id_changed(int)"
  slots "requirement_changed()"
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
      @pools << ShopItemPool.new(i, game.fs)
      pool_name = "%02X" % i
      
      if GAME == "ooe"
        quest_name = Text.new(TEXT_REGIONS["Quest Names"].begin + i, game.fs).decoded_string
        pool_name << " #{quest_name}"
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
    @game.items[@available_shop_item_range].zip(@available_shop_item_range).each do |item, item_id|
      item_name = "%03X %s" % [item_id+1, item.name]
      @ui.item_id.addItem(item_name)
    end
    
    connect(@ui.pool_index, SIGNAL("currentRowChanged(int)"), self, SLOT("pool_index_changed(int)"))
    connect(@ui.item_index, SIGNAL("currentRowChanged(int)"), self, SLOT("item_index_changed(int)"))
    connect(@ui.item_id, SIGNAL("currentRowChanged(int)"), self, SLOT("item_id_changed(int)"))
    connect(@ui.requirement, SIGNAL("editingFinished()"), self, SLOT("requirement_changed()"))
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    if GAME == "por"
      @ui.label.text = "Required boss death flag"
    end
    
    pool_index_changed(0)
    item_index_changed(0)
    
    self.show()
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
    elsif GAME == "por" || @pool.is_a?(OoEHardcodedShopItemPool)
      @ui.label.text = "Required boss death flag"
    else
      @ui.label.text = "Requirement"
    end
    
    @ui.item_index.clear()
    @pool.item_ids.each_with_index do |global_id, item_index|
      item = @game.items[global_id-1]
      slot_name = "%03X %s" % [global_id, item.name]
      if @pool.slot_is_arm_shifted_immediate?(item_index)
        slot_name = "(!) #{slot_name}"
      end
      @ui.item_index.addItem(slot_name)
    end
  end
  
  def item_index_changed(item_index)
    item_id = @pool.item_ids[item_index]
    return if item_id.nil?
    
    row_index = item_id - @available_shop_item_range.first - 1
    @ui.item_id.setCurrentRow(row_index)
    
    if @pool.is_a?(ShopPointItemPool)
      required_shop_points = @pool.required_shop_points[item_index]
      @ui.requirement.text = "%04X" % required_shop_points
      @ui.requirement.enabled = true
    end
  end
  
  def item_id_changed(row_index)
    item_index = @ui.item_index.currentRow
    return if item_index == -1
    
    item_id = row_index + @available_shop_item_range.first
    
    if @pool.is_a?(OoEHardcodedShopItemPool) && !@pool.slot_can_have_item_id?(item_index, item_id+1)
      message = "This particular hardcoded item slot is coded as an ARM shifted immediate.\n"
      message += "This item's ID (#{"%03X" % (item_id+1)}) cannot be represented as an ARM shifted immediate.\n\n"
      message += "Basically: This slot needs to have an item ID that is less than 0x100, or an item ID that is a multiple of 4 (e.g. 7D or 14C).\n\n"
      message += "This limitation only applies to slots with the (!) at the front of them, so you can put this item in one of the ones without the (!) instead."
      Qt::MessageBox.warning(self, "Cannot put this item in this slot", message)
      return
    end
    
    @pool.item_ids[item_index] = item_id+1
    
    item = @game.items[item_id]
    slot_name = "%03X %s" % [item_id+1, item.name]
    if @pool.slot_is_arm_shifted_immediate?(item_index)
      slot_name = "(!) #{slot_name}"
    end
    @ui.item_index.currentItem.text = slot_name
  end
  
  def requirement_changed
    if @pool.is_a?(ShopPointItemPool)
      item_index = @ui.item_index.currentRow
      @pool.required_shop_points[item_index] = @ui.requirement.text.to_i(16)
    else
      @pool.requirement = @ui.requirement.text.to_i(16)
    end
  end
  
  def save_changes
    @pool.write_to_rom()
  rescue NDSFileSystem::ArmShiftedImmediateError => e
    Qt::MessageBox.warning(self, "Error changing requirement", e.message)
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
end
