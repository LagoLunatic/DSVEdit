
class RoomView < Qt::GraphicsView
  ZOOM_SCALES = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.5,
    2.0,
    2.5,
    3.0,
    4.0,
  ]
  
  def initialize(parent)
    super(parent)
    
    @curr_zoom_index = ZOOM_SCALES.index(1.0)
    
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
  
  def wheelEvent(event)
    if Qt::Application.keyboardModifiers() & Qt::ControlModifier == 0
      super(event)
      return
    end
    
    orig_view_pos = event.pos()
    orig_scene_pos = mapToScene(orig_view_pos)
    
    y_change = event.delta()
    
    old_zoom_scale = ZOOM_SCALES[@curr_zoom_index]
    if y_change > 0
      if @curr_zoom_index == ZOOM_SCALES.size - 1
        return
      end
      @curr_zoom_index += 1
    elsif y_change < 0
      if @curr_zoom_index == 0
        return
      end
      @curr_zoom_index -= 1
    else
      return
    end
    
    curr_zoom_scale = ZOOM_SCALES[@curr_zoom_index]
    scale_mult = curr_zoom_scale / old_zoom_scale
    
    scale(scale_mult, scale_mult)
    
    updateSceneRect(scene().sceneRect())
  end
end
