module Zif
  # Registers assets by name and allocates sprites
  # Use when setting up the game, like:
  # $services[:sprite_registry].register_basic_sprite("my_64x64_image", 64, 64)
  class SpriteRegistry
    def initialize
      reset_registry
    end

    def reset_registry
      @registry = {}
    end

    def add_sprite(name, sprite)
      @registry[name] = sprite
    end

    # Convenience method to initialize a Sprite, expects the asset to be in sprites as a png.
    # You can, of course, modify the prototype after creation
    def register_basic_sprite(name, w, h)
      sprite = Zif::Sprite.new(name)
      sprite.assign(
        {
          w:        w,
          h:        h,
          path:     "sprites/#{name}.png",
          angle:    0,
          a:        255,
          r:        255,
          g:        255,
          b:        255,
          source_x: 0,
          source_y: 0,
          source_w: w,
          source_h: h
        }
      )

      add_sprite(name, sprite)
    end

    def construct(name)
      raise "SpriteRegistry: No sprite named #{name.inspect} in the registry" unless @registry[name]
      raise "Invalid sprite in registry: #{name.inspect}" unless @registry[name].respond_to?(:dup)

      @registry[name].dup
    end
  end
end
