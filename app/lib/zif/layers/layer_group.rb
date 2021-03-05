module Zif
  module Layers
    # Designed to be used with {Zif::Layers::Camera}.
    #
    # Creates a set of overlapping play area layers based on {Zif::Layers::SimpleLayer} ({Zif::RenderTarget}) or
    # {Zif::Layers::ActiveLayer} ({Zif::CompoundSprite}) and handles redrawing them.
    #
    # Has a concept of +logical+ position as a multiple of +tile+ width/height, applicable to any
    # {Zif::Layers::Tileable} layers. For example, if your tiles are 16px wide, the 5th tile is at +@logical_x==4+ but
    # at +@x==64+ on the layer.
    #
    # Of all things in the Zif library, this is probably the most opinionated - It's for a 2d game made of rectangular,
    # non-overlapping tiles where the play area is larger than the screen.  As always YMMV
    #
    # As an example, you can have a "tiles" layer which gets redrawn only at the start of the game, an "interactive
    # objects" layer which gets redrawn whenever objects appear or disappear, and then an "avatar" layer which gets
    # redrawn constantly.  The advantage of using {Zif::RenderTarget}s and {Zif::CompoundSprite}s here is to keep the
    # positioning consistent across all of the layers.  You can just pass all of the containing sprites to
    # {Zif::Layers::Camera} and it will pan them all in unison.
    #
    # You setup and configure these layers via {new_simple_layer}, {new_tiled_layer}, etc.
    #
    # Performance notes:
    # - The memory requirements for anything based on {Zif::Layers::SimpleLayer} is the number of layers times the area
    #   of each layer.  Consider using {Zif::Layers::ActiveLayer} if you have a lot of layers with few sprites in them.
    # - It is *expensive* to redraw a {Zif::RenderTarget} ({Zif::Layers::SimpleLayer}) with thousands of sprites.
    #   Consider: 1280x720 (screen size) / 16x16 (a small tile) -> 80*45 tiles = 3600 tiles.
    #   Of course it's more expensive to draw every tile every tick (using {Zif::Layers::ActiveLayer}), but you will see
    #   noticable hiccups if you redraw the render target often.  Try not to redraw {Zif::RenderTarget}s with lots of
    #   sprites while action is happening.
    # - The takeaway is this: try to organize your layers between things that change often, and things that can be
    #   prerendered or need few updates duing play. Then choose between {Zif::Layers::SimpleLayer} and
    #   {Zif::Layers::ActiveLayer} as appropriate.
    #
    # @example Setting up a group of 2 layers
    #   tile_width_and_height         = 64  # Each tile is 64x64 pixels
    #   map_width_and_height_in_tiles = 100 # 64 * 100 = 6400x6400 pixels, 10000 tiles total
    #
    #   @map = Zif::Layers::LayerGroup.new(
    #     tile_width:     tile_width_and_height,
    #     tile_height:    tile_width_and_height,
    #     logical_width:  map_width_and_height_in_tiles,
    #     logical_height: map_width_and_height_in_tiles
    #   )
    #
    #   # This example is only using Zif::Layers::ActiveLayer because they are easier to set up,
    #   # and it is a good place to start in terms of performance.
    #   @map.new_active_tiled_layer(:tiles)
    #   @map.new_active_layer(:avatar)
    #
    #   @map.layers[:avatar].source_sprites = [@dragon]
    #
    #   # Add a bunch of tiles
    #   a_new_tile = Zif::Sprite.new....
    #   @map.layers[:tiles].add_positioned_sprite(sprite: a_new_tile, logical_x: x, logical_y: y)
    #
    #   # Set up a camera
    #   @camera = Zif::Camera.new(
    #     layer_sprites: @map.layer_containing_sprites,
    #     initial_x: 1800,
    #     initial_y: 1200
    #   )
    #
    #   $gtk.args.outputs.static_sprites << @camera.layers
    #
    #   # All set!  You can move your sprites (like @dragon) around.  You can control the Camera using actions.
    #   # Most or all of the above code could be placed in a Zif::Scene#prepare_scene method.
    class LayerGroup
      include Zif::Traceable

      # @return [Symbol, String] The name of the layer group
      attr_accessor :name
      # @return [Integer] Pixel width of each tile
      attr_accessor :tile_width
      # @return [Integer] Pixel height of each tile
      attr_accessor :tile_height
      # @return [Integer] Integer multiple of tiles.  How many tiles wide is the whole map?
      attr_accessor :logical_width
      # @return [Integer] Integer multiple of tiles.  How many tiles high is the whole map?
      attr_accessor :logical_height
      # @return [Integer] The current stacking layer index.  Starts at +0+ and is incremented for every new layer
      attr_reader :z_index
      # @return [Hash<(Symbol, String), Zif::Layers::Layerable>] All of the layers in this group, indexed by their name
      attr_accessor :layers

      # @param [Symbol, String] name {name} The name of the layer group
      # @param [Integer] tile_width {tile_width} Pixel width of each tile
      # @param [Integer] tile_height {tile_height} Pixel height of each tile
      # @param [Integer] logical_width {logical_width} Integer multiple of tiles.
      # @param [Integer] logical_height {logical_height} Integer multiple of tiles.
      def initialize(name: 'map',
                     tile_width: 64,
                     tile_height: 64,
                     logical_width: 100,
                     logical_height: 100)
        @name           = name
        @tile_width     = tile_width
        @tile_height    = tile_height
        @logical_width  = logical_width
        @logical_height = logical_height
        @z_index        = 0

        @layers = {}

        @tracer_service_name = :tracer
      end

      # Adds a layer to the layer group.  Registers it in {layers} and increments {z_index}.
      # @return [Zif::Layers::Layerable]
      def add_layer(name, layer)
        @layers[name] = layer
        @z_index += 1
        return @layers[name]
      end

      # Creates a new {Zif::Layers::ActiveLayer} and sends it through {add_layer}
      # @param [Symbol, String] name The name of the new layer
      # @return [Zif::Layers::ActiveLayer] The new layer
      def new_active_layer(name)
        add_layer(name, Zif::Layers::ActiveLayer.new(self, name, z_index: @z_index))
      end

      # Creates a new {Zif::Layers::SimpleLayer} and sends it through {add_layer}
      # @param [Symbol, String] name The name of the layer
      # @param [Boolean] render_only_visible When rerendering, should this layer use +#visible_sprites+?
      # @param [Boolean] clear_sprites_after_draw When rerendering, should this layer clear the +@sprites+ array?
      # @return [Zif::Layers::SimpleLayer] The new layer
      def new_simple_layer(name, render_only_visible: false, clear_sprites_after_draw: false)
        add_layer(
          name,
          Zif::Layers::SimpleLayer.new(
            self,
            name,
            z_index: @z_index,
            render_only_visible: render_only_visible,
            clear_sprites_after_draw: clear_sprites_after_draw
          )
        )
      end

      # Creates a new {Zif::Layers::TiledLayer} and sends it through {add_layer}
      # @param [Symbol, String] name The name of the new layer
      # @param [Boolean] render_only_visible When rerendering, should this layer use +#visible_sprites+?
      # @return [Zif::Layers::TiledLayer] The new layer
      def new_tiled_layer(name, render_only_visible: false)
        add_layer(
          name,
          Zif::Layers::TiledLayer.new(self, name, z_index: @z_index, render_only_visible: render_only_visible)
        )
      end

      # Creates a new {Zif::Layers::ActiveTiledLayer} and sends it through {add_layer}
      # @param [Symbol, String] name The name of the new layer
      # @return [Zif::Layers::ActiveTiledLayer] The new layer
      def new_active_tiled_layer(name)
        add_layer(name, Zif::Layers::ActiveTiledLayer.new(self, name, z_index: @z_index))
      end

      # Creates a new {Zif::Layers::BitmaskedTiledLayer} and sends it through {add_layer}
      # @param [Symbol, String] name The name of the new layer
      # @param [Boolean] render_only_visible When rerendering, should this layer use +#visible_sprites+?
      # @return [Zif::Layers::BitmaskedTiledLayer] The new layer
      def new_bitmasked_tiled_layer(name, render_only_visible: false)
        add_layer(
          name,
          Zif::Layers::BitmaskedTiledLayer.new(self, name, z_index: @z_index, render_only_visible: render_only_visible)
        )
      end

      # Creates a new {Zif::Layers::ActiveBitmaskedTiledLayer} and sends it through {add_layer}
      # @param [Symbol, String] name The name of the new layer
      # @return [Zif::Layers::ActiveBitmaskedTiledLayer] The new layer
      def new_active_bitmasked_tiled_layer(name)
        add_layer(name, Zif::Layers::ActiveBitmaskedTiledLayer.new(self, name, z_index: @z_index))
      end

      # @return [Integer] {tile_width} times {logical_width}
      def max_width
        @tile_width * @logical_width
      end

      # @return [Integer] {tile_height} times {logical_height}
      def max_height
        @tile_height * @logical_height
      end

      # Converts a +logical+ rect to a natural one
      # @example With 16x16 tiles
      #   natural_rect(10, 10, 1, 1) # => [160, 160, 16, 16]
      # @param [Integer] logical_x The logical x position to start the rect at
      # @param [Integer] logical_y The logical y position to start the rect at
      # @param [Integer] x_range The number of tiles wide the rect contains
      # @param [Integer] y_range The number of tiles high the rect contains
      # @return [Array<Integer>] The resulting natural rect +[x, y, w, h]+
      def natural_rect(logical_x, logical_y, x_range, y_range)
        [
          logical_x * @tile_width,
          logical_y * @tile_width,
          x_range * @tile_width,
          y_range * @tile_width
        ]
      end

      # Converts pixel x/y to logical x/y (rounded down)
      # @example With 16x16 tiles
      #   logical_pos(20, 20) # => [1, 1]
      # @param [Integer] x The x position to convert to logical
      # @param [Integer] y The y position to convert to logical
      # @return [Array<Integer>] The resulting logical point +[logical_x, logical_y]+
      def logical_pos(x, y)
        [
          (x / @tile_width).floor,
          (y / @tile_height).floor
        ]
      end

      # Iterate through each in {layers}, set +should_render+ to true, rerender, and set it back to what it was
      # Useful for first-time setup of render targets, during init
      def force_refresh
        @layers.each do |_name, layer|
          render_setting = layer.should_render
          layer.should_render = true
          layer.rerender
          layer.should_render = render_setting
        end
      end

      # @return [Array<Symbol, String>] The names of each registered layer
      def layer_names
        @layers.keys
      end

      # @return [Array<Zif::Sprite>] The containing sprite for each layer.
      #   For active layers this returns the layer itself
      #   For simple layers it returns the render target containing_sprite
      def layer_containing_sprites
        @layers.values.map(&:containing_sprite)
      end

      # Calls +#rerender+ on each in {layers}
      def refresh
        @layers.each do |layer_name, layer|
          mark("#refresh: Rerendering #{layer_name}")
          layer.rerender
          mark("#refresh: Rerendered #{layer_name}")
        end

        mark('#refresh: Rerendered all layers')
      end

      def serialize
        {
          name:           name,
          tile_width:     tile_width,
          tile_height:    tile_height,
          logical_width:  logical_width,
          logical_height: logical_height,
          z_index:        z_index,
          layers:         layers.keys
        }
      end

      def inspect
        serialize.to_s
      end

      def to_s
        serialize.to_s
      end
    end
  end
end
