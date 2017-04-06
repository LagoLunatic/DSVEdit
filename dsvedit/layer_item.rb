
class LayerItem < Qt::GraphicsRectItem
  attr_reader :layer
  
  def initialize(layer, tileset_filename)
    super()
    
    @layer = layer
    @tileset = Qt::Pixmap.new(tileset_filename)
    
    setZValue(-layer.z_index)
    setOpacity(layer.opacity/31.0)
    
    render_layer()
  end
  
  def render_layer
    @layer.tiles.each_with_index do |tile, index_on_level|
      next if tile.index_on_tileset == 0
      
      x_on_tileset = tile.index_on_tileset % 16
      y_on_tileset = tile.index_on_tileset / 16
      x_on_level = index_on_level % (@layer.width*16)
      y_on_level = index_on_level / (@layer.width*16)
      
      if (0..@tileset.width-1).include?(x_on_tileset*16) && (0..@tileset.height-1).include?(y_on_tileset*16)
        tile_gfx = @tileset.copy(x_on_tileset*16, y_on_tileset*16, 16, 16)
      else
        # Coordinates are outside the bounds of the tileset, put a red tile there instead.
        tile_gfx = Qt::Pixmap.new(16, 16)
        tile_gfx.fill(Qt::Color.new(Qt::red))
      end
      
      tile_item = Qt::GraphicsPixmapItem.new(tile_gfx, self)
      tile_item.setPos(x_on_level*16, y_on_level*16)
      if tile.horizontal_flip && tile.vertical_flip
        tile_item.setTransform(Qt::Transform::fromScale(-1, -1))
        tile_item.x += 16
        tile_item.y += 16
      elsif tile.horizontal_flip
        tile_item.setTransform(Qt::Transform::fromScale(-1, 1))
        tile_item.x += 16
      elsif tile.vertical_flip
        tile_item.setTransform(Qt::Transform::fromScale(1, -1))
        tile_item.y += 16
      end
    end
  end
end
