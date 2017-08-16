
class LayerItem < Qt::GraphicsRectItem
  attr_reader :layer
  
  def initialize(layer, tileset_filename, collision=false)
    super()
    
    @layer = layer
    @tileset = Qt::Pixmap.new(tileset_filename)
    
    if !collision
      setZValue(-layer.z_index)
      setOpacity(layer.opacity/31.0)
    end
    
    render_layer()
  end
  
  def render_layer
    @layer.tiles.each_with_index do |tile, index_on_level|
      next if tile.index_on_tileset == 0
      
      x_on_tileset = tile.index_on_tileset % TILESET_WIDTH_IN_TILES
      y_on_tileset = tile.index_on_tileset / TILESET_WIDTH_IN_TILES
      x_on_level = index_on_level % (@layer.width*SCREEN_WIDTH_IN_TILES)
      y_on_level = index_on_level / (@layer.width*SCREEN_WIDTH_IN_TILES)
      
      if (0..@tileset.width-1).include?(x_on_tileset*TILE_WIDTH) && (0..@tileset.height-1).include?(y_on_tileset*TILE_HEIGHT)
        tile_gfx = @tileset.copy(x_on_tileset*TILE_WIDTH, y_on_tileset*TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)
      else
        # Coordinates are outside the bounds of the tileset, put a red tile there instead.
        tile_gfx = Qt::Pixmap.new(TILE_WIDTH, TILE_HEIGHT)
        tile_gfx.fill(Qt::Color.new(Qt::red))
      end
      
      tile_item = Qt::GraphicsPixmapItem.new(tile_gfx, self)
      tile_item.setPos(x_on_level*TILE_WIDTH, y_on_level*TILE_HEIGHT)
      if tile.horizontal_flip && tile.vertical_flip
        tile_item.setTransform(Qt::Transform::fromScale(-1, -1))
        tile_item.x += TILE_WIDTH
        tile_item.y += TILE_HEIGHT
      elsif tile.horizontal_flip
        tile_item.setTransform(Qt::Transform::fromScale(-1, 1))
        tile_item.x += TILE_WIDTH
      elsif tile.vertical_flip
        tile_item.setTransform(Qt::Transform::fromScale(1, -1))
        tile_item.y += TILE_HEIGHT
      end
    end
  end
end
