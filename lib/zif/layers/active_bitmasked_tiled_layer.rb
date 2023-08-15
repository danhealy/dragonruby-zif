module Zif
  module Layers
    # Designed to be used with {Zif::Layers::LayerGroup}.
    # Knits together a lot of functionality:
    # {Zif::Layers::Bitmaskable} + {Zif::Layers::Tileable}
    # built on top of a {Zif::CompoundSprite} via {Zif::Layers::ActiveLayer}
    # @see Zif::Layers::BitmaskedTiledLayer
    # @see Zif::Layers::Tileable
    # @see Zif::Layers::Bitmaskable
    class ActiveBitmaskedTiledLayer < ActiveLayer
      include Tileable
      include Bitmaskable
    end
  end
end
