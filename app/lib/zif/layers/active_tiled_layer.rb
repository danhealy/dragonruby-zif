module Zif
  module Layers
    # Designed to be used with {Zif::Layers::LayerGroup}.
    # A layer consisting of an initially empty 2D array of sprites
    # Overrides to {Zif::Layers::ActiveLayer} which understand this 2D array
    # {Zif::Layers::Tileable}, built on top of a {Zif::CompoundSprite}
    # @see Zif::Layers::TiledLayer
    # @see Zif::Layers::Tileable
    class ActiveTiledLayer < ActiveLayer
      include Tileable
    end
  end
end
