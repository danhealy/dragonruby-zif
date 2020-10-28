module Zif
  # Functionality shared between SimpleLayer & ActiveLayer
  module Layerable
    attr_accessor :map, :layer_name, :z, :should_render

    def add_positioned_sprite(sprite)
      source_sprites << position_sprite(sprite, logical_x, logical_y)
    end

    def position_sprite(sprite, logical_x, logical_y)
      # Skip Sprite#assign, this is perf critical
      sprite.x         = logical_x * @map.tile_width
      sprite.y         = logical_y * @map.tile_height
      sprite.logical_x = logical_x
      sprite.logical_y = logical_y
      sprite
    end

    # This only removes it from the data layer, you'll need to redraw to remove it visually
    def remove_sprite(tile)
      source_sprites.delete(tile)
    end

    def target_layer_name
      "#{@map.target_name}_#{@layer_name}"
    end

    # This is not very performant with lots of sprites!  Consider using TiledLayer instead.
    def visible_sprites(rect=containing_sprite.source_rect)
      source_sprites.select do |sprite|
        sprite.intersect_rect? rect
      end
    end

    # Returns an array of colliding sprites, and non-colliding sprites that were within the visible area
    def collisions(rect)
      remain = visible_sprites(rect).to_a
      coll   = remain.select { |item| item.intersect_rect? rect }
      [coll, coll - remain]
    end

    def clicked?(point, kind=:up)
      relative_point = Zif.add_positions(
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
      visible_sprites(
        relative_point + [1, 1]
      ).reverse_each.find do |sprite|
        sprite.respond_to?(:clicked?) && sprite.clicked?(relative_point, kind)
      end
    end

    def exclude_from_serialize
      %w[source_sprites sprites primitives]
    end
  end
end
