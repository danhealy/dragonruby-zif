module Zif
  # Designed to be used with Zif::LayeredTileMap.
  # A simple layer consisting of an initially empty array of sprites.
  class SimpleLayer < RenderTarget
    include Layerable
    attr_accessor :source_sprites, :render_only_visible, :clear_sprites_after_draw, :rerender_rect

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
  end
end
