module Zif
  # Designed to be used with Zif::Camera.
  # Creates a set of overlapping play area layers (RenderTargets - RTs) and handles redrawing them.
  #
  # Has a concept of "logical" position as a multiple of "tile" width/height.
  #  (If your tiles are 16px wide, the 4th tile is at @logical_x==4 but @x==64)
  #
  # Of all things in the Zif library, this is probably the most opinionated - It's for a 2d game made of rectangular,
  # non-overlapping tiles where the play area is larger than the screen.  As always YMMV
  #
  # As an example, you can have a "tiles" layer which gets redrawn only at the start of the game, an "interactive
  # objects" layer which gets redrawn whenever objects appear or disappear, and then an "avatar" layer which gets
  # redrawn every time the avatar moves.  The advantage of using RenderTargets here is to keep the positioning
  # consistent across all of the layers.  You can just pass all of the RT containing sprites to Camera and it will
  # pan them all in unison.
  #
  # You setup and configure these layers via #new_simple_layer and #new_tiled_layer.
  #
  # Performance notes:
  #  - Since the memory requirements here are based on the number of layers * area of each layer, consider other
  #    approaches if you have a lot of layers with few sprites in them (maybe use sprites directly but with more math to
  #    keep positions in sync)
  #  - It is *expensive* to redraw a RT with thousands of sprites.  Consider - 1280x720 / 16x16 -> 80*45 = 3600 tiles.
  #    Of course it's more expensive to draw these every tick (not using render_target), but you will see noticable
  #    hiccups if you do this often.  Try not to redraw RTs with lots of sprites while action is happening.
  class LayeredTileMap
    include Zif::Traceable
    attr_accessor :target_name
    attr_accessor :tile_width, :tile_height, :logical_width, :logical_height, :z_index
    attr_accessor :layers

    # logical_ refers to integer multiples of tiles
    # Setup vars, setup render_targets
    def initialize(target_name='map',
                   tile_width=64,
                   tile_height=64,
                   logical_width=100,
                   logical_height=100)
      @target_name    = target_name
      @tile_width     = tile_width
      @tile_height    = tile_height
      @logical_width  = logical_width
      @logical_height = logical_height
      @z_index        = 0

      @layers = {}

      @tracer_service_name = :tracer
    end

    def new_simple_layer(name, render_only_visible=false, clear_sprites_after_draw=false)
      @layers[name] = Zif::SimpleLayer.new(self, name, @z_index, render_only_visible, clear_sprites_after_draw)
      @z_index += 1
      return @layers[name]
    end

    # You really don't want clear_sprites_after_draw
    def new_tiled_layer(name, render_only_visible=false)
      @layers[name] = Zif::TiledLayer.new(self, name, @z_index, render_only_visible)
      @z_index += 1
      return @layers[name]
    end

    def max_width
      @tile_width * @logical_width
    end

    def max_height
      @tile_height * @logical_height
    end

    def natural_rect(logical_x, logical_y, x_range, y_range)
      [
        logical_x * @tile_width,
        logical_y * @tile_width,
        x_range * @tile_width,
        y_range * @tile_width
      ]
    end

    # Convert pixel x/y to logical x/y
    def logical_pos(x, y)
      [
        (x / @tile_width).floor,
        (y / @tile_height).floor
      ]
    end

    # Useful for first-time setup of render targets, during init
    def force_refresh
      @layers.each do |_name, layer|
        render_setting = layer.should_render
        layer.should_render = true
        layer.rerender
        layer.should_render = render_setting
      end
    end

    def layer_names
      @layers.keys
    end

    def layer_containing_sprites
      @layers.values.map(&:containing_sprite)
    end

    def refresh
      @layers.each do |layer_name, layer|
        mark("#refresh: Rerendering #{layer_name} at #{layer.containing_sprite.source_rect}")
        layer.rerender
        mark("#refresh: Rerendered #{layer_name}")
      end

      mark('#refresh: Rerendered all layers')
    end

    def serialize
      {
        target_name:    target_name,
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
