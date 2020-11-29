module Zif
  # Designed to be used with Zif::LayeredTileMap.
  # A layer consisting of an initially empty 2D array of sprites
  # Overrides to SimpleLayer which understand this 2D array
  class TiledLayer < SimpleLayer
    include Tileable
  end

  class ActiveTiledLayer < ActiveLayer
    include Tileable
  end
end
