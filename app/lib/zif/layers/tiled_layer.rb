module Zif
  module Layers
    # Designed to be used with {Zif::Layers::LayerGroup}.
    # A layer consisting of an initially empty 2D array of sprites
    # Overrides to {Zif::Layers::SimpleLayer} which understand this 2D array
    # {Zif::Layers::Tileable}, built on top of a {Zif::RenderTarget}
    # @see Zif::Layers::ActiveTiledLayer
    # @see Zif::Layers::Tileable
    class TiledLayer < SimpleLayer
      include Tileable
    end
  end
end
