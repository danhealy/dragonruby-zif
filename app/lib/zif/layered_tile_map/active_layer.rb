module Zif
  # Designed to be used with Zif::LayeredTileMap.
  # This layer is based on CompoundSprite and therefore all of the component sprites must be rendered every tick.
  # Use this for layers with a small sprite count.
  # The other layer classes are built on RenderTarget and therefore incur a little performance hit every time they are
  # redrawn, but balance that by being able to cheaply display those sprites once rendered.
  class ActiveLayer < CompoundSprite
    include Layerable

    def initialize(map, name, z=0)
      super(name)
      @map           = map
      @layer_name    = name
      @z             = z
      @should_render = true # This does not control anything in this context since we are always rendering.
      reinitialize_sprites

      @x = 0
      @y = 0
      @w = @map.max_width
      @h = @map.max_height
      @source_x = 0
      @source_y = 0
      @source_w = @w
      @source_h = @h
    end

    def containing_sprite
      self
    end

    def source_sprites
      @sprites
    end

    def source_sprites=(new_sprites)
      @sprites = new_sprites
    end

    def reinitialize_sprites
      # puts "#{@layer_name}: ActiveLayer reinitialize_sprites"
      @sprites = []
    end

    # No-op
    def rerender
      true
    end
  end
end
