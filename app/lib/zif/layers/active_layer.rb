module Zif
  module Layers
    # Designed to be used with {Zif::Layers::LayerGroup}.
    #
    # This layer is based on {Zif::CompoundSprite} and therefore each component sprite is rendered every tick.
    # Use this for layers that need to be updated frequently, but have a small sprite count.
    #
    # In contrast, {Zif::Layers::SimpleLayer} is built on {Zif::Layers::RenderTarget} and therefore incurs a little
    # performance hit every time it is redrawn, but balances that by being able to cheaply display those sprites once
    # rendered.
    #
    # Deciding between {Zif::Layers::SimpleLayer} and {Zif::Layers::ActiveLayer} depends on your application.  Try
    # organizing your layers into those that don't change at all, or only change when action (like camera movement)
    # isn't happening, and put those sprites into a {Zif::Layers::SimpleLayer}.  Then take all of the sprites which do
    # need to change often, or are necessary for action, and put those in {Zif::Layers::ActiveLayer}s.
    #
    # You can use this or {Zif::Layers::SimpleLayer} directly when the sprites contained don't need to snap to the tile
    # grid set up in the {Zif::Layers::LayerGroup}.  Otherwise, you should use {Zif::Layers::TiledLayer} or
    # {Zif::Layers::ActiveTiledLayer}
    class ActiveLayer < CompoundSprite
      include Layerable

      # @param [Zif::Layers::LayerGroup] map
      # @param [Symbol] name The name of the layer
      # @param [Integer] z_index The z-index of the layer.
      def initialize(map, name, z_index: 0)
        super(name)
        @map           = map
        @layer_name    = name
        @z_index       = z_index
        @should_render = true # This does not control anything in this context since we are always rendering.
        reinitialize_sprites

        @x = 0
        @y = 0
        @w = @map.max_width
        @h = @map.max_height
        @source_x = 0
        @source_y = 0
        @source_w = @w
        @source_h = @h
      end

      # This is not based on {Zif::RenderTarget} so we don't have a "containing sprite" here.
      # This is for compatibility with {Zif::Layers::SimpleLayer#containing_sprite}
      # @return [Zif::Layers::ActiveLayer] Returns this object
      def containing_sprite
        self
      end

      # @param [Integer] logical_x The logical X value of the given +sprite+
      # @param [Integer] logical_y The logical Y value of the given +sprite+
      # @param [Zif::Sprite] sprite The sprite to add to this layer.
      def add_positioned_sprite(sprite:, logical_x:, logical_y:)
        # puts "ActiveLayer#add_positioned_sprite: #{logical_x} #{logical_y}"
        @sprites << position_sprite(sprite: sprite, logical_x: logical_x, logical_y: logical_y)
      end

      # @param [Zif::Sprite] sprite The sprite to remove from this layer.
      def remove_sprite(sprite)
        @sprites.delete(sprite)
      end

      # This is for compatibility with {Zif::Layers::SimpleLayer#source_sprites}
      # @return [Array<Zif::Sprite>] The list of sprites on this layer.
      def source_sprites
        @sprites
      end

      # This will clear the sprites array.
      def reinitialize_sprites
        @sprites = []
      end

      # No-op - {Zif::ActiveLayer} is always rendering!
      # @return [Boolean] true
      def rerender
        true
      end
    end
  end
end
