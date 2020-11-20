module Zif
  # Designed to be used with Zif::LayeredTileMap.
  # A layer consisting of an initially empty 2D array of sprites
  # Overrides to SimpleLayer which understand this 2D array
  class TiledLayer < SimpleLayer
    def reinitialize_sprites
      @source_sprites = Array.new(@map.logical_height) { Array.new(@map.logical_width) }
    end

    # This returns an enumerator which can be used to iterate over only the tiles which are visible.
    # Only for layers which have allocated_tiles!
    def visible_sprites(given_rect=nil)
      if given_rect.nil?
        containing_sprite.view_actual_size! unless containing_sprite.source_is_set?
        compare_left   = containing_sprite.source_x
        compare_bottom = containing_sprite.source_y
        compare_w      = containing_sprite.source_w
        compare_h      = containing_sprite.source_h
      else
        compare_left   = given_rect.x
        compare_bottom = given_rect.y
        compare_w      = given_rect.w
        compare_h      = given_rect.h
      end

      logical_x = compare_left.fdiv(@map.tile_width)
      logical_y = compare_bottom.fdiv(@map.tile_height)
      x_range   = compare_w.fdiv(@map.tile_width)
      y_range   = compare_h.fdiv(@map.tile_height)

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
      Enumerator.new do |yielder|
        loop do
          yielder << @source_sprites[b][a] if @source_sprites[b][a]
          r, a = (a + 1).divmod(max_x)
          if r.positive?
            a = starting_a
            b += r
          end
          break unless @source_sprites[b] && b <= max_y
        end
      end
    end

    def intersecting_sprites(compare_left, compare_bottom, compare_right, compare_top)
      visible_sprites([compare_left, compare_bottom, compare_right - compare_left, compare_top - compare_bottom])
    end

    def add_positioned_sprite(logical_x, logical_y, tile_sprite_proto)
      @source_sprites[logical_y][logical_x] = position_sprite(tile_sprite_proto, logical_x, logical_y)
    end

    def remove_positioned_sprite(sprite)
      x = sprite.logical_x
      y = sprite.logical_y
      @source_sprites[y][x] = nil
    end

    def exclude_from_serialize
      %w[source_sprites sprites primitives]
    end
  end
end
