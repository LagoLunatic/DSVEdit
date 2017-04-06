
class ClickableGraphicsScene < Qt::GraphicsScene
  signals "clicked(int, int, const Qt::MouseButton&)"
  signals "moved(int, int, const Qt::MouseButton&)"
  signals "released(int, int, const Qt::MouseButton&)"
  
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
    emit released(x, y, event.buttons)
    
    super(event)
  end
end
