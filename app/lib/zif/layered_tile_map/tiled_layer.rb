module Zif
  # Designed to be used with Zif::LayeredTileMap.
  # A layer consisting of an initially empty 2D array of sprites
  # Overrides to SimpleLayer which understand this 2D array
  # Built on top of a RenderTarget
  class TiledLayer < SimpleLayer
    include Tileable
  end

  # Tileable, built on top of a CompoundSprite
  class ActiveTiledLayer < ActiveLayer
    include Tileable
  end
end
