module Zif
  module Layers
    # Functionality shared between {Zif::Layers::SimpleLayer} & {Zif::Layers::ActiveLayer}
    module Layerable
      # @return [Zif::Layers::LayerGroup] The LayerGroup this layer belongs to
      attr_accessor :map
      # @return [Symbol] The name of the layer, used for indexing
      attr_accessor :layer_name
      # @return [Integer] Where this layer is in the top to bottom sort order (+0+ is bottom)
      attr_accessor :z_index
      # @return [Boolean] (For {Zif::Layers::SimpleLayer} only) Should this layer rerender this tick?
      attr_accessor :should_render

      # Removes a sprite from its logical x / y position on the layer.
      # @param [Zif::Sprite] sprite The sprite to remove
      def remove_positioned_sprite(sprite)
        remove_sprite(sprite)
      end

      # Removes a sprite from its logical x / y position on the layer.
      # @param [Zif::Sprite] sprite The sprite to add
      # @param [Integer] logical_x Where to place the +sprite+ in terms of logical X position
      # @param [Integer] logical_y Where to place the +sprite+ in terms of logical Y position
      def position_sprite(sprite:, logical_x:, logical_y:)
        # Skip Sprite#assign, this is perf critical
        sprite.x         = logical_x * @map.tile_width
        sprite.y         = logical_y * @map.tile_height
        sprite.logical_x = logical_x
        sprite.logical_y = logical_y
        sprite
      end

      # @return [String] The combination of name of the map plus the name of the layer
      def target_layer_name
        "#{@map.name}_#{@layer_name}"
      end

      # This is not very performant with lots of sprites!  Consider using {Zif::Layers::TiledLayer} instead.
      # @param [Array<Integer>] given_rect The +[x, y, w, h]+ rectangle we want to check for sprites
      #   Natural rectangle, not logical
      #   If not provided, it will use the +source+ settings for the containing sprite
      # @return [Array<Zif::Sprite>] The sprites on this layer which are within +given_rect+
      def visible_sprites(given_rect=nil)
        if given_rect.nil?
          containing_sprite.view_actual_size! unless containing_sprite.source_is_set?
          left   = containing_sprite.source_x
          bottom = containing_sprite.source_y
          right  = left   + containing_sprite.source_w
          top    = bottom + containing_sprite.source_h
        else
          left   = given_rect.x
          bottom = given_rect.y
          right  = left   + given_rect.w
          top    = bottom + given_rect.h
        end

        intersecting_sprites(left: left, bottom: bottom, right: right, top: top)
      end

      # @param [Integer] left Look for sprites to the right of this value
      # @param [Integer] bottom Look for sprites above this value
      # @param [Integer] right Look for sprites to the left of this value
      # @param [Integer] top Look for sprites below this value
      # @return [Array<Zif::Sprite>] The sprites on this layer which are within the bounds of the +compare+ params
      def intersecting_sprites(left:, bottom:, right:, top:)
        # puts "Layerable#intersecting_sprites: #{@layer_name} #{source_sprites.length}"
        source_sprites.reject do |sprite|
          x = sprite.x
          y = sprite.y
          w = sprite.w
          h = sprite.h
          # puts "Layerable#intersecting_sprites: #{x} #{y} #{w} #{h}"
          (
            (x     > right)  ||
            (y     > top)    ||
            (x + w < left)   ||
            (y + h < bottom)
          )
        end
      end

      # Converts the given screen +point+ into coordinates within the layer, then passes this point to each sprite
      # on this layer.
      # @param [Array<Integer>] point +[x, y]+ position Array of the current mouse click with respect to the screen.
      # @param [Symbol] kind The kind of click coming through, one of +[:up, :down, :changed]+
      # @return [Object, nil] The result of +sprite.clicked?+ for any sprite intersecting the translated point
      # @see Zif::Clickable#clicked?
      def clicked?(point, kind=:up)
        x, y = Zif.add_positions(
          Zif.position_math(
            :mult,
            point,
            Zif.position_math(
              :fdiv,
              containing_sprite.source_wh,
              containing_sprite.wh
            )
          ),
          containing_sprite.source_xy
        )

        # puts "Layerable#clicked?(#{point}): #{@layer_name} #{x} #{y}"
        intersecting_sprites(left: x, bottom: y, right: x, top: y).reverse_each.find do |sprite|
          # puts "  clicked? -> #{sprite}"
          sprite.respond_to?(:clicked?) && sprite.clicked?([x, y], kind)
        end
      end

      def exclude_from_serialize
        %w[sprites primitives]
      end
    end
  end
end
