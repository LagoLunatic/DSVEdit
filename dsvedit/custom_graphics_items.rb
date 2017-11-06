
class GraphicsChunkyItem < Qt::GraphicsPixmapItem
  def initialize(chunky_image)
    pixmap = Qt::Pixmap.new
    blob = chunky_image.to_blob
    pixmap.loadFromData(blob, blob.length)
    super(pixmap)
  end
end

class EntityChunkyItem < GraphicsChunkyItem
  attr_reader :entity
  
  def initialize(chunky_image, entity, main_window)
    super(chunky_image)
    
    @main_window = main_window
    @entity = entity
    
    setFlag(Qt::GraphicsItem::ItemIsMovable)
    setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges)
    
    setCursor(Qt::Cursor.new(Qt::SizeAllCursor))
  end
  
  def itemChange(change, value)
    if change == ItemPositionChange && scene()
      new_pos = value.toPointF()
      x = new_pos.x
      y = new_pos.y
      
      if $qApp.keyboardModifiers & Qt::ControlModifier == 0
        x = (x / 16).round * 16
        y = (y / 16).round * 16
        new_pos.setX(x)
        new_pos.setY(y)
      end
      
      @entity.x_pos = x
      @entity.y_pos = y
      @entity.write_to_rom()
      
      return super(change, Qt::Variant.new(new_pos))
    end
    
    return super(change, value)
  end

  def mouseReleaseEvent(event)
    @main_window.update_room_bounding_rect()
    super(event)
  end
end

class EntityRectItem < Qt::GraphicsRectItem
  NOTHING_BRUSH        = Qt::Brush.new(Qt::Color.new(200, 200, 200, 150))
  ENEMY_BRUSH          = Qt::Brush.new(Qt::Color.new(200, 0, 0, 150))
  SPECIAL_OBJECT_BRUSH = Qt::Brush.new(Qt::Color.new(0, 0, 200, 150))
  CANDLE_BRUSH         = Qt::Brush.new(Qt::Color.new(200, 200, 0, 150))
  OTHER_BRUSH          = Qt::Brush.new(Qt::Color.new(200, 0, 200, 150))
  
  attr_reader :entity
  
  def initialize(entity, main_window)
    super(-8, -8, 16, 16)
    setPos(entity.x_pos, entity.y_pos)
    
    @main_window = main_window
    
    setFlag(Qt::GraphicsItem::ItemIsMovable)
    setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges)
    
    setCursor(Qt::Cursor.new(Qt::SizeAllCursor))
    
    case entity.type
    when NOTHING_ENTITY_TYPE
      self.setBrush(NOTHING_BRUSH)
    when ENEMY_ENTITY_TYPE
      self.setBrush(ENEMY_BRUSH)
    when SPECIAL_OBJECT_ENTITY_TYPE
      self.setBrush(SPECIAL_OBJECT_BRUSH)
    when CANDLE_ENTITY_TYPE
      self.setBrush(CANDLE_BRUSH)
    else
      self.setBrush(OTHER_BRUSH)
    end
    @entity = entity
  end
  
  def itemChange(change, value)
    if change == ItemPositionChange && scene()
      new_pos = value.toPointF()
      x = new_pos.x
      y = new_pos.y
      
      if $qApp.keyboardModifiers & Qt::ControlModifier == 0
        # Snap to 16x16 grid unless Ctrl is held down.
        x = (x / 16).round * 16
        y = (y / 16).round * 16
        new_pos.setX(x)
        new_pos.setY(y)
      end
      
      @entity.x_pos = x
      @entity.y_pos = y
      @entity.write_to_rom()
      
      return super(change, Qt::Variant.new(new_pos))
    end
    
    return super(change, value)
  end

  def mouseReleaseEvent(event)
    @main_window.update_room_bounding_rect()
    super(event)
  end
end

class DoorItem < Qt::GraphicsRectItem
  BRUSH = Qt::Brush.new(Qt::Color.new(200, 0, 200, 50))
  
  attr_reader :door
  
  def initialize(door, door_index, main_window)
    super(0, 0, SCREEN_WIDTH_IN_PIXELS, SCREEN_HEIGHT_IN_PIXELS)
    
    x = door.x_pos
    y = door.y_pos
    x = -1 if x == 0xFF
    y = -1 if y == 0xFF
    x *= SCREEN_WIDTH_IN_PIXELS
    y *= SCREEN_HEIGHT_IN_PIXELS
    setPos(x, y)
    
    @main_window = main_window
    @door = door
    @door_index = door_index
    
    setToolTip("Door %02X" % door_index)
    
    self.setBrush(BRUSH)
    
    setFlag(Qt::GraphicsItem::ItemIsMovable)
    setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges)
    
    setCursor(Qt::Cursor.new(Qt::SizeAllCursor))
  end
  
  def itemChange(change, value)
    if change == ItemPositionChange && scene()
      new_pos = value.toPointF()
      x = (new_pos.x / SCREEN_WIDTH_IN_PIXELS).round
      y = (new_pos.y / SCREEN_HEIGHT_IN_PIXELS).round
      x = [x, 0x7F].min
      x = [x, -1].max
      y = [y, 0x7F].min
      y = [y, -1].max
      new_pos.setX(x*SCREEN_WIDTH_IN_PIXELS)
      new_pos.setY(y*SCREEN_HEIGHT_IN_PIXELS)
      
      @door.x_pos = x
      @door.y_pos = y
      @door.write_to_rom()
      
      return super(change, Qt::Variant.new(new_pos))
    end
    
    return super(change, value)
  end

  def mouseReleaseEvent(event)
    @main_window.update_room_bounding_rect()
    super(event)
  end
end

class DoorDestinationMarkerItem < Qt::GraphicsRectItem
  BRUSH = Qt::Brush.new(Qt::Color.new(255, 127, 0, 120))
  
  attr_reader :door
  
  def initialize(door, door_editor)
    @width = SCREEN_WIDTH_IN_PIXELS
    @height = SCREEN_HEIGHT_IN_PIXELS
    if GAME == "hod"
      @height -= 0x60
    end
    super(0, 0, @width, @height)
    
    x = door.dest_x
    y = door.dest_y
    setPos(x, y)
    
    @door_editor = door_editor
    @door = door
    @dest_room_width = door.destination_room.width*SCREEN_WIDTH_IN_PIXELS
    @dest_room_height = door.destination_room.height*SCREEN_HEIGHT_IN_PIXELS
    
    self.setBrush(BRUSH)
    
    setFlag(Qt::GraphicsItem::ItemIsMovable)
    setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges)
    
    setCursor(Qt::Cursor.new(Qt::SizeAllCursor))
  end
  
  def itemChange(change, value)
    if change == ItemPositionChange && scene()
      new_pos = value.toPointF()
      x = (new_pos.x / 0x10).round
      y = (new_pos.y / 0x10).round
      x = x * 0x10
      y = y * 0x10
      #x = [x, 0x7FFF].min
      #x = [x, -0x7FFF].max
      #y = [y, 0x7FFF].min
      #y = [y, -0x7FFF].max
      x = [x, @dest_room_width-@width].min
      x = [x, 0].max
      y = [y, @dest_room_height-@height].min
      y = [y, 0].max
      new_pos.setX(x)
      new_pos.setY(y)
      
      @door_editor.update_dest_x_and_y_fields(x, y)
      
      return super(change, Qt::Variant.new(new_pos))
    end
    
    return super(change, value)
  end

  #def mouseReleaseEvent(event)
  #  @main_window.update_room_bounding_rect()
  #  super(event)
  #end
end
