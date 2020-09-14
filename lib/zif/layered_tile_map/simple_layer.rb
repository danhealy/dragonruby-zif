module Zif
  # Designed to be used with Zif::LayeredTileMap.
  # A simple layer consisting of an initially empty array of sprites.
  class SimpleLayer < RenderTarget
    attr_accessor :map, :layer_name, :z_index, :source_sprites
    attr_accessor :should_render, :render_only_visible, :clear_sprites_after_draw

    def initialize(map, name, z_index=0, render_only_visible=false, clear_sprites_after_draw=false)
      @map                      = map
      @layer_name               = name
      @z_index                  = z_index
      @render_only_visible      = render_only_visible
      @clear_sprites_after_draw = clear_sprites_after_draw
      @should_render            = true
      reinitialize_sprites

      super(target_layer_name, :black, @map.max_width, @map.max_height)
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

    # FIXME: Default screen height / width should be dynamic or at least based on @map
    # TODO: Untested, the Tiled version is tested though
    def visible_sprites(rect=containing_sprite.source_rect)
      @source_sprites.select do |sprite|
        sprite.intersect_rect? rect
      end
    end

    def position_sprite(sprite, logical_x, logical_y)
      sprite.assign(
        x:         logical_x * @map.tile_width,
        y:         logical_y * @map.tile_height,
        logical_x: logical_x,
        logical_y: logical_y
      )
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

      @sprites = if @render_only_visible
                   visible_sprites.to_a
                 else
                   @source_sprites
                 end

      redraw

      reinitialize_sprites if @clear_sprites_after_draw

      true
    end

    def clicked?(point, kind=:up)
      visible_sprites.reverse_each.find { |sprite| sprite.respond_to?(:clicked?) && sprite.clicked?(point, kind) }
    end
  end
end
