module Zif
  # Functionality shared between TiledLayer & BitmaskedTiledLayer
  # Modifies the layer to be based on a 2d source_sprites array.
  module Tileable
    def tile_pos_to_sprite_index(logical_y, logical_x)
      (logical_y * @map.logical_width) + logical_x
    end

    def tile(logical_y, logical_x)
      @sprites[tile_pos_to_sprite_index(logical_y, logical_x)]
    end

    def reinitialize_sprites
      super
      # puts "#{@layer_name}: Tileable#reinitialize_sprites #{@map.logical_height} #{@map.logical_width}"
      @sprites = Array.new(@map.logical_height * @map.logical_width)
    end

    def add_positioned_sprite(logical_x, logical_y, sprite)
      # puts "#{@layer_name}: Tileable#add_positioned_sprite #{logical_x} #{logical_y}"
      # puts "#{@sprites.class.to_s}"
      @sprites[tile_pos_to_sprite_index(logical_y, logical_x)] = position_sprite(sprite, logical_x, logical_y)
    end

    def remove_positioned_sprite(sprite)
      x = sprite.logical_x
      y = sprite.logical_y
      @sprites[tile_pos_to_sprite_index(y, x)] = nil
    end

    def remove_tile(logical_y, logical_x)
      @sprites[tile_pos_to_sprite_index(logical_y, logical_x)] = nil
    end

    # This returns an enumerator which can be used to iterate over only the tiles which are visible.
    # Only for layers which have allocated_tiles!
    def visible_sprites(given_rect=nil)
      # puts "Tileable#visible_sprites: #{@layer_name} '#{given_rect}'"
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

      logical_x = compare_left.idiv(@map.tile_width)
      logical_y = compare_bottom.idiv(@map.tile_height)
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

      # puts " -> #{logical_x} #{logical_y} #{x_range} #{y_range} #{max_y} #{max_x} #{starting_a} #{starting_b} "

      Enumerator.new do |yielder|
        loop do
          next_tile = tile(b, a)
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

    def intersecting_sprites(compare_left, compare_bottom, compare_right, compare_top)
      visible_sprites([compare_left, compare_bottom, compare_right - compare_left, compare_top - compare_bottom])
    end

    def exclude_from_serialize
      %w[sprites primitives]
    end
  end
end
