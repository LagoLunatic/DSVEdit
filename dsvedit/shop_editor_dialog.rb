
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
      item_name = "%02X %s" % [item_id+1, item.name]
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
    elsif GAME == "por"
      @ui.label.text = "Required boss death flag"
    else
      @ui.label.text = "Requirement"
    end
    
    @ui.item_index.clear()
    @pool.item_ids.each do |global_id|
      item = @game.items[global_id-1]
      @ui.item_index.addItem("%02X %s" % [global_id, item.name])
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
    @pool.item_ids[item_index] = item_id+1
    
    item = @game.items[item_id]
    @ui.item_index.currentItem.text = "%02X %s" % [item_id+1, item.name]
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
