module Zif
  # Designed to be used with Zif::LayeredTileMap.
  # A simple layer consisting of an initially empty array of sprites.
  class SimpleLayer < RenderTarget
    attr_accessor :map, :layer_name, :z, :source_sprites
    attr_accessor :should_render, :render_only_visible, :clear_sprites_after_draw, :rerender_rect

    def initialize(map, name, z=0, render_only_visible=false, clear_sprites_after_draw=false)
      @map                      = map
      @layer_name               = name
      @z                        = z
      @render_only_visible      = render_only_visible
      @clear_sprites_after_draw = clear_sprites_after_draw
      @should_render            = true
      @rerender_rect            = nil
      reinitialize_sprites

      super(target_layer_name, :black, @map.max_width, @map.max_height, @z)
    end

    def reinitialize_sprites
      @source_sprites = []
    end

    def target_layer_name
      "#{@map.target_name}_#{@layer_name}"
    end

    # Returns an array of colliding sprites, and non-colliding sprites that were within the visible area
    def collisions(rect)
      remain = visible_sprites(rect).to_a
      coll   = remain.select { |item| item.intersect_rect? rect }
      [coll, coll - remain]
    end

    # This is not very performant with lots of sprites!  Consider using TiledLayer instead.
    def visible_sprites(rect=containing_sprite.source_rect)
      @source_sprites.select do |sprite|
        sprite.intersect_rect? rect
      end
    end

    def position_sprite(sprite, logical_x, logical_y)
      # Skip Sprite#assign, this is perf critical
      sprite.x         = logical_x * @map.tile_width
      sprite.y         = logical_y * @map.tile_height
      sprite.logical_x = logical_x
      sprite.logical_y = logical_y
      sprite
    end

    def add_positioned_sprite(sprite)
      @source_sprites << position_sprite(sprite, logical_x, logical_y)
    end

    # This only removes it from the data layer, you'll need to redraw to remove it visually
    def remove_sprite(tile)
      @source_sprites.delete(tile)
    end

    def rerender
      return unless @should_render

      if @rerender_rect
        redraw_from_buffer(visible_sprites(@rerender_rect).to_a, @rerender_rect)
      else
        @sprites = if @render_only_visible
                     visible_sprites.to_a
                   else
                     @source_sprites
                   end

        redraw
      end

      reinitialize_sprites if @clear_sprites_after_draw

      true
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
