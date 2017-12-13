
class ClickableGraphicsScene < Qt::GraphicsScene
  BACKGROUND_BRUSH = Qt::Brush.new(Qt::Color.new(240, 240, 240, 255))
  
  signals "clicked(int, int, const Qt::MouseButton&)"
  signals "moved(int, int, const Qt::MouseButton&)"
  signals "released(int, int, const Qt::MouseButton&)"
  
  def initialize
    super
    
    self.setBackgroundBrush(BACKGROUND_BRUSH)
  end
  
  def mousePressEvent(event)
    x = event.scenePos().x.to_i
    y = event.scenePos().y.to_i
    emit clicked(x, y, event.buttons)
    
    super(event)
  end
  
  def mouseMoveEvent(event)
    x = event.scenePos().x.to_i
    y = event.scenePos().y.to_i
    emit moved(x, y, event.buttons)
    
    super(event)
  end
  
  def mouseReleaseEvent(event)
    x = event.scenePos().x.to_i
    y = event.scenePos().y.to_i
    emit released(x, y, event.button)
    
    super(event)
  end
end
