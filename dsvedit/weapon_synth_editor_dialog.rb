
require_relative 'ui_weapon_synth_editor'

class WeaponSynthEditor < Qt::Dialog
  slots "chain_changed(int)"
  slots "synth_changed(int)"
  slots "button_box_clicked(QAbstractButton*)"
  
  def initialize(main_window, game)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_WeaponSynthEditor.new
    @ui.setup_ui(self)
    
    if GAME != "dos"
      self.close()
      return
    end
    
    @game = game
    
    @chains = []
    WEAPON_SYNTH_CHAIN_NAMES.each_with_index do |name, index|
      @chains << WeaponSynthChain.new(index, @game.fs)
      @ui.chain_index.addItem("%02X #{name}" % index)
    end
    connect(@ui.chain_index, SIGNAL("activated(int)"), self, SLOT("chain_changed(int)"))
    connect(@ui.synth_index, SIGNAL("activated(int)"), self, SLOT("synth_changed(int)"))
    
    ITEM_GLOBAL_ID_RANGE.each do |global_id|
      item = @game.items[global_id]
      @ui.required_item_id.addItem("%02X #{item.name}" % (global_id+1))
      @ui.created_item_id.addItem("%02X #{item.name}" % (global_id+1))
    end
    SKILL_LOCAL_ID_RANGE.each do |local_id|
      item = @game.items[SKILL_GLOBAL_ID_RANGE.begin + local_id]
      @ui.required_soul_id.addItem("%02X #{item.name}" % local_id)
    end
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_box_clicked(QAbstractButton*)"))
    
    chain_changed(0)
    
    self.show()
  end
  
  def chain_changed(chain_index)
    chain = @chains[chain_index]
    
    @synths = chain.synths
    @ui.synth_index.clear()
    chain.synths.each_with_index do |synth, index|
      @ui.synth_index.addItem("%02X" % index)
    end
    
    synth_changed(0)
    
    @ui.chain_index.setCurrentIndex(chain_index)
  end
  
  def synth_changed(synth_index)
    @synth = @synths[synth_index]
    
    @ui.required_item_id.setCurrentIndex(@synth.required_item_id - 1)
    @ui.required_soul_id.setCurrentIndex(@synth.required_soul_id)
    @ui.created_item_id.setCurrentIndex(@synth.created_item_id - 1)
    
    @ui.synth_index.setCurrentIndex(synth_index)
  end
  
  def save_changes
    @synth.required_item_id = @ui.required_item_id.currentIndex + 1
    @synth.required_soul_id = @ui.required_soul_id.currentIndex
    @synth.created_item_id = @ui.created_item_id.currentIndex + 1
    @synth.write_to_rom()
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
