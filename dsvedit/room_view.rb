
class RoomView < Qt::GraphicsView
  def initialize(parent)
    super(parent)
    
    # We want to receive mouseMoveEvents even when the user is not clicking any mouse buttons.
    setMouseTracking(true)
  end
  
  def keyPressEvent(event)
    if event.key == Qt::Key_Space && !event.isAutoRepeat
      set_panning(true)
    end
  end
  
  def keyReleaseEvent(event)
    if event.key == Qt::Key_Space && !event.isAutoRepeat
      set_panning(false)
    end
  end
  
  def set_panning(is_panning)
    return if is_panning == @is_panning
    
    @is_panning = is_panning
    
    setInteractive(!is_panning)
    
    if is_panning
      @orig_mouse_pose = Qt::Cursor.pos
      Qt::Application.setOverrideCursor(Qt::Cursor.new(Qt::ClosedHandCursor))
      #viewport.grabMouse()
    else
      #viewport.releaseMouse()
      Qt::Application.restoreOverrideCursor()
    end
  end
  
  def mouseMoveEvent(event)
    if @is_panning
      diff = event.globalPos - @orig_mouse_pose

      horizontalValue = horizontalScrollBar.value - diff.x
      verticalValue = verticalScrollBar.value - diff.y

      horizontalScrollBar.setValue(horizontalValue)
      verticalScrollBar.setValue(verticalValue)

      @orig_mouse_pose = event.globalPos
    else
      super(event)
      @orig_mouse_pose = event.globalPos
    end
  end
  
  def mousePressEvent(event)
    if event.button == Qt::MiddleButton
      set_panning(true)
      return
    end
    
    super(event)
  end
  
  def mouseReleaseEvent(event)
    if event.button == Qt::MiddleButton
      set_panning(false)
      return
    end
    
    super(event)
  end
end
