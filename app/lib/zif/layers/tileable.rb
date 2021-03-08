module Zif
  module Layers
    # Functionality shared between {Zif::Layers::TiledLayer} & {Zif::Layers::BitmaskedTiledLayer}
    #
    # Modifies the layer to be based around the concept of a "logical" position.  This is used to
    # differentiate between the "natural" +x, y+ position on the screen.  The "logical" position is instead the
    # natural position divided by the tile size, and is used to index the sprites array.
    #
    # For performance reasons, the sprites array is still implemented as one-dimensional array, but the idea is that it
    # could have been implemented as a two-dimensional array of rows (+logical_x+) and columns (+logical_y+).
    #
    # Add sprites to the layer using {add_positioned_sprite} which sets the logical position on the sprite.
    module Tileable
      # Convert logical_x and logical_y to the index of the sprite in the +@sprites+ array.
      # @return [Integer] Index of the sprite in the +@sprites+ array.
      def tile_pos_to_sprite_index(logical_x, logical_y)
        (logical_y * @map.logical_width) + logical_x
      end

      # Uses {tile_pos_to_sprite_index} and returns the sprite at that position in +@sprites+
      # @return [Zif::Sprite] The sprite in +@sprites+ at the position indicated by +logical_x+ & +logical_y+
      def tile(logical_x, logical_y)
        @sprites[tile_pos_to_sprite_index(logical_x, logical_y)]
      end

      # Overrides {Zif::Layers::SimpleLayer#reinitialize_sprites} or {Zif::Layers::ActiveLayer#reinitialize_sprites}
      # Clears the +@sprites+ array, based on the logical_height and logical_width of the {Zif::Layers::LayerGroup}
      def reinitialize_sprites
        super
        # puts "#{@layer_name}: Tileable#reinitialize_sprites #{@map.logical_height} #{@map.logical_width}"
        @sprites = Array.new(@map.logical_height * @map.logical_width)
      end

      # Overrides {Zif::Layers::SimpleLayer#add_positioned_sprite} or {Zif::Layers::ActiveLayer#add_positioned_sprite}
      # Adds +sprite+ to the +@sprites+ array at the position indicated by +logical_x+ and +logical_y+.  Ensures the
      # logical position is saved on the +sprite+.
      # @param [Zif::Sprite] sprite The sprite to add to +@sprites+
      # @param [Integer] logical_x The logical x position of +sprite+
      # @param [Integer] logical_y The logical y position of +sprite+
      def add_positioned_sprite(sprite:, logical_x:, logical_y:)
        # puts "#{@layer_name}: Tileable#add_positioned_sprite #{logical_x} #{logical_y}"
        # puts "#{@sprites.class.to_s}"
        @sprites[tile_pos_to_sprite_index(logical_x, logical_y)] = position_sprite(
          sprite: sprite,
          logical_x: logical_x,
          logical_y: logical_y
        )
      end

      # Overrides {Zif::Layers::Layerable#remove_positioned_sprite}
      # Remove a sprite which has already been added.  Finds the sprite by calculating its position in the +@sprites+
      # array using {tile_pos_to_sprite_index} and the +sprite+'s logical position.
      # @param [Zif::Sprite] sprite The sprite to remove from +@sprites+
      def remove_positioned_sprite(sprite)
        @sprites[tile_pos_to_sprite_index(sprite.logical_x, sprite.logical_y)] = nil
      end

      # Clears the element in the +@sprites+ array indicated by the logical position.
      # @param [Integer] logical_x The logical x position to clear.
      # @param [Integer] logical_y The logical y position to clear.
      def remove_tile(logical_x, logical_y)
        @sprites[tile_pos_to_sprite_index(logical_x, logical_y)] = nil
      end

      # Overrides {Zif::Layers::Layerable#visible_sprites}
      # This returns an enumerator which can be used to iterate over only the tiles which are visible.
      # Only for layers which have allocated_tiles!
      # @param [Array<Integer>] given_rect +[x, y, w, h]+ array to check for sprites in +@sprites+
      # @return [Enumerator] An Enumerator to use to iterate over the {Zif::Sprite}s selected by +given_rect+
      def visible_sprites(given_rect=nil)
        # puts "Tileable#visible_sprites: #{@layer_name} '#{given_rect}'"
        if given_rect.nil?
          containing_sprite.view_actual_size! unless containing_sprite.source_is_set?
          left   = containing_sprite.source_x
          bottom = containing_sprite.source_y
          w      = containing_sprite.source_w
          h      = containing_sprite.source_h
        else
          left   = given_rect.x
          bottom = given_rect.y
          w      = given_rect.w
          h      = given_rect.h
        end

        logical_x = left.idiv(@map.tile_width)
        logical_y = bottom.idiv(@map.tile_height)
        x_range   = w.fdiv(@map.tile_width)
        y_range   = h.fdiv(@map.tile_height)

        max_y = [logical_y + y_range.ceil + 1, @map.logical_height].min
        max_x = [logical_x + x_range.ceil + 1, @map.logical_width].min

        # This enumerator is basically the equivalent of:
        #
        # @floor_tiles[logical_y..max_y].map do |x_tiles|
        #   x_tiles[logical_x..max_x]
        # end.flatten.to_enum
        #
        # The benefit of doing this instead is that we avoid some extraneous iteration and allocation if we call
        # #visible_tiles more than once per tick.  This definitely feels faster, but I haven't benchmarked.

        starting_a = [logical_x, 0].max
        starting_b = [logical_y, 0].max
        a = starting_a
        b = starting_b

        # puts " -> #{logical_x} #{logical_y} #{x_range} #{y_range} #{max_y} #{max_x} #{starting_a} #{starting_b} "

        Enumerator.new do |yielder|
          loop do
            next_tile = tile(a, b)
            yielder << next_tile if next_tile
            r, a = (a + 1).divmod(max_x)
            if r.positive?
              a = starting_a
              b += r
            end
            break if b > max_y
          end
        end
      end

      # Overrides {Zif::Layers::Layerable#intersecting_sprites}
      # A convenience to calling {visible_sprites} with boundary values instead of a +[x,y,w,h]+ rect.
      # @param [Integer] left Look for sprites to the right of this value
      # @param [Integer] bottom Look for sprites above this value
      # @param [Integer] right Look for sprites to the left of this value
      # @param [Integer] top Look for sprites below this value
      def intersecting_sprites(left:, bottom:, right:, top:)
        visible_sprites([left, bottom, right - left, top - bottom])
      end

      def exclude_from_serialize
        %w[sprites primitives]
      end
    end
  end
end
