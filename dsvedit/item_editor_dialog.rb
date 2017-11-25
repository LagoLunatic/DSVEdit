
require_relative 'generic_editor_widget'

require_relative 'ui_item_editor'

class ItemEditor < Qt::Dialog
  slots "button_pressed(QAbstractButton*)"
  
  def initialize(main_window, game)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_ItemEditor.new
    @ui.setup_ui(self)
    
    @game = game
    @fs = game.fs
    
    ITEM_TYPES.each do |item_type|
      doc_name = case item_type[:name]
      when "Consumables"
        "Consumable format"
      when "Weapons", "Weapons (Unused)"
        "Weapon format"
      when "Skills"
        "Skill format"
      when "Skills (extra data)"
        "Extra skill data format"
      when "Relics"
        "Relic format"
      when "Arm Glyphs"
        "Arm glyph format"
      when "Back Glyphs"
        "Back glyph format"
      when "Glyph Unions"
        "Glyph union format"
      when "Armor"
        "Body armor and Accessory format"
      when "Body Armor", "Head Armor", "Leg Armor", "Accessories"
        "Armor format"
      when "Souls"
        "Soul format"
      when "Souls (extra data)"
        "Extra soul data format"
      when "Red Souls"
        "Red soul format"
      when "Blue Souls"
        "Blue soul format"
      when "Yellow Souls"
        "Yellow soul format"
      else
        ""
      end
      doc = main_window.game.item_format_docs[doc_name]
      
      tab = GenericEditorWidget.new(game.fs, game, item_type, doc)
      name = item_type[:name]
      @ui.tabWidget.addTab(tab, name)
    end
    
    connect(@ui.buttonBox, SIGNAL("clicked(QAbstractButton*)"), self, SLOT("button_pressed(QAbstractButton*)"))
    
    self.show()
  end
  
  def button_pressed(button)
    if @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Ok
      @ui.tabWidget.currentWidget.save_current_item()
      @game.clear_items_cache()
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Cancel
      self.close()
    elsif @ui.buttonBox.standardButton(button) == Qt::DialogButtonBox::Apply
      @ui.tabWidget.currentWidget.save_current_item()
      @game.clear_items_cache()
    end
  end
end
