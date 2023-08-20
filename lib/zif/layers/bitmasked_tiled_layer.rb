module Zif
  module Layers
    # Designed to be used with {Zif::Layers::LayerGroup}.
    # Knits together a lot of functionality:
    # {Zif::Layers::Bitmaskable} + {Zif::Layers::Tileable}
    # built on top of a {Zif::RenderTarget} via {Zif::Layers::SimpleLayer}
    # @see Zif::Layers::ActiveBitmaskedTiledLayer
    # @see Zif::Layers::Tileable
    # @see Zif::Layers::Bitmaskable
    class BitmaskedTiledLayer < SimpleLayer
      include Tileable
      include Bitmaskable
    end
  end
end
