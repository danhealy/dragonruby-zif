module Zif
  # Functionality shared between SimpleLayer & ActiveLayer
  module Layerable
    attr_accessor :map, :layer_name, :z, :should_render

    def remove_positioned_sprite(sprite)
      remove_sprite(sprite)
    end

    def position_sprite(sprite, logical_x, logical_y)
      # Skip Sprite#assign, this is perf critical
      sprite.x         = logical_x * @map.tile_width
      sprite.y         = logical_y * @map.tile_height
      sprite.logical_x = logical_x
      sprite.logical_y = logical_y
      sprite
    end

    def target_layer_name
      "#{@map.target_name}_#{@layer_name}"
    end

    # This is not very performant with lots of sprites!  Consider using TiledLayer instead.
    def visible_sprites(given_rect)
      if given_rect.nil?
        containing_sprite.view_actual_size! unless containing_sprite.source_is_set?
        compare_left   = containing_sprite.source_x
        compare_bottom = containing_sprite.source_y
        compare_right  = compare_left   + containing_sprite.source_w
        compare_top    = compare_bottom + containing_sprite.source_h
      else
        compare_left   = given_rect.x
        compare_bottom = given_rect.y
        compare_right  = compare_left   + given_rect.w
        compare_top    = compare_bottom + given_rect.h
      end

      intersecting_sprites(compare_left, compare_bottom, compare_right, compare_top)
    end

    def intersecting_sprites(compare_left, compare_bottom, compare_right, compare_top)
      # puts "Layerable#intersecting_sprites: #{@layer_name} #{source_sprites.length}"
      source_sprites.select do |sprite|
        x = sprite.x
        y = sprite.y
        w = sprite.w
        h = sprite.h
        # puts "Layerable#intersecting_sprites: #{x} #{y} #{w} #{h}"
        !(
          (x     > compare_right)  ||
          (y     > compare_top)    ||
          (x + w < compare_left)   ||
          (y + h < compare_bottom)
        )
      end
    end

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
      intersecting_sprites(x, y, x, y).reverse_each.find do |sprite|
        # puts "  clicked? -> #{sprite}"
        sprite.respond_to?(:clicked?) && sprite.clicked?([x, y], kind)
      end
    end

    def exclude_from_serialize
      %w[sprites primitives]
    end
  end
end
