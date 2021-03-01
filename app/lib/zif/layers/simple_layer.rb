module Zif
  module Layers
    # Designed to be used with {Zif::Layers::LayerGroup}.
    #
    # This layer is based on {Zif::RenderTarget} and therefore the component sprites will not be rendered until
    # {Zif::RenderTarget#redraw} or {Zif::RenderTarget#redraw_from_buffer} is called - typically via {rerender}.
    #
    # In contrast, {Zif::Layers::ActiveLayer} is built on {Zif::CompoundSprite} and therefore must rerender every sprite
    # on every tick.  This is balanced by not incurring a performance / memory penalty by rendering a sprite the size
    # of the entire {Zif::Layers::LayerGroup} width times height.
    #
    # Deciding between {Zif::Layers::SimpleLayer} and {Zif::Layers::ActiveLayer} depends on your application.  Try
    # organizing your layers into those that don't change at all, or only change when action (like camera movement)
    # isn't happening, and put those sprites into a {Zif::Layers::SimpleLayer}.  Then take all of the sprites which do
    # need to change often, or are necessary for action, and put those in {Zif::Layers::ActiveLayer}s.
    #
    # You can use this or {Zif::Layers::SimpleLayer} directly when the sprites contained don't need to snap to the tile
    # grid set up in the {Zif::Layers::LayerGroup}.  Otherwise, you should use {Zif::Layers::TiledLayer} or
    # {Zif::Layers::ActiveTiledLayer}
    class SimpleLayer < Zif::RenderTarget
      include Layerable

      # @return [Array<Zif::Sprite>] The array of sprites used as a source for the render target when being {rerender}ed
      attr_accessor :source_sprites
      # @return [Boolean] Should {rerender} only consider {Zif::Layers::Layerable#visible_sprites}?
      attr_accessor :render_only_visible
      # @return [Boolean] Should {rerender} clear {source_sprites} after render?
      attr_accessor :clear_sprites_after_draw
      # @return [Array<Integer>] A rectangle +[x, y, w, h]+ defining the extent of {rerender}.
      #   This is used to implement the double buffering technique described at {Zif::RenderTarget}.
      attr_accessor :rerender_rect

      def initialize(map, name, z_index: 0, render_only_visible: false, clear_sprites_after_draw: false)
        @map                      = map
        @layer_name               = name
        @z_index                  = z_index
        @render_only_visible      = render_only_visible
        @clear_sprites_after_draw = clear_sprites_after_draw
        @should_render            = true
        @rerender_rect            = nil
        reinitialize_sprites

        super(target_layer_name, bg_color: :black, width: @map.max_width, height: @map.max_height, z_index: @z_index)
      end

      # This will clear the +@sprites+ and {source_sprites} arrays.
      def reinitialize_sprites
        @source_sprites = []
        @sprites = []
      end

      # @param [Integer] logical_x The logical X value of the given +sprite+
      # @param [Integer] logical_y The logical Y value of the given +sprite+
      # @param [Zif::Sprite] sprite The sprite to add to this layer.
      def add_positioned_sprite(sprite:, logical_x:, logical_y:)
        # puts "SimpleLayer#add_positioned_sprite: #{logical_x} #{logical_y}"
        @source_sprites << position_sprite(sprite: sprite, logical_x: logical_x, logical_y: logical_y)
      end

      # This only removes it from the data layer, you'll need to redraw to remove it visually
      # @param [Zif::Sprite] sprite The sprite to remove from this layer.
      def remove_sprite(sprite)
        @source_sprites.delete(sprite)
      end

      # First this checks {should_render} and returns early if that is +false+.
      #
      # Then it checks for the presence of a {rerender_rect}, if it exists it will use that to
      # {Zif::RenderTarget#redraw_from_buffer}
      #
      # Otherwise it decides whether or not only visible sprites should be rendered - {render_only_visible} - and then
      # calls {Zif::RenderTarget#redraw}
      #
      # Finally, it may clear {source_sprites} if {clear_sprites_after_draw} is +true+.
      # @return [Boolean] Did this layer rerender?
      def rerender
        return false unless @should_render

        if @rerender_rect
          redraw_from_buffer(sprites: visible_sprites(@rerender_rect).to_a, cut_rect: @rerender_rect)
        else
          @sprites = if @render_only_visible
                       visible_sprites.to_a
                     else
                       source_sprites
                     end

          redraw
        end

        reinitialize_sprites if @clear_sprites_after_draw

        true
      end
    end
  end
end
