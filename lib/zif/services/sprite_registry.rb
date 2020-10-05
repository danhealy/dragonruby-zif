module Zif
  # Registers assets by name and allocates sprites
  # Use when setting up the game, like:
  # $services[:sprite_registry].register_basic_sprite("my_64x64_image", 64, 64)
  class SpriteRegistry
    attr_accessor :registry

    def initialize
      reset_registry
    end

    def reset_registry
      @registry = {}
    end

    def add_sprite(name, sprite)
      @registry[name] = sprite
    end

    def sprite_registered?(name)
      @registry.key?(name)
    end

    def alias_sprite(name, alias_to)
      raise "SpriteRegistry: No sprite named #{name.inspect} in the registry" unless @registry[name]

      # puts "SpriteRegistry#alias_sprite: #{alias_to} is now an alias for #{name}"

      @registry[alias_to] = @registry[name]
    end

    # Convenience method to initialize a Sprite, expects the asset to be in sprites as a png.
    # You can, of course, modify the prototype after creation
    def register_basic_sprite(name, w, h, &block)
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

      sprite.on_mouse_up = block if block_given?

      add_sprite(name, sprite)
    end

    # Some background on autotiling (note the author uses a different numbering scheme - NEWS instead of NESW)
    # https://gamedevelopment.tutsplus.com/tutorials/cms-25673
    #
    # This method will automatically register all of the tiles necessary for autotiling with BitmaskedTiledLayer.
    # It'll register every possible direction, aliasing the ones that don't actually exist to the ones that do,
    # depending on the number of edges specified (16 for cardinal directions only, 48 for inside corners, or 256 for
    # every possibility). This expects that the actual filenames are using cardinal directions & diagonal directions,
    # separated by underscores, in the following order:
    #
    # _north _east _south _west _ne _se _sw _nw
    #
    # It will also alias these to the raw bitmask value.
    #
    # Let's work through an example so this is clearer.  You are using a 48-tile set, so you have two different versions
    # of the tile that has an adjacent tile to the north and east, either the corner is cut or not.
    # The one where the corner is not cut - the only adjacent tiles are north, northeast and east - looks like |_
    # You need to have the file for this at "sprites/name_north_east_ne.png"
    # From that one file, it will generate the following aliases:
    # - name_north_east_ne (the actual sprite)
    # - All of the corner cases that don't actually exist because this is just the 48-set and not the full 256
    #   name_north_east_ne_se, name_north_east_ne_sw, name_north_east_ne_nw, name_north_east_ne_se_sw, ...
    # - Both of the above, but using the raw bitmask integer instead of the cardinal directions:
    #   1+2+16= name_19, 1+2+16+32= name_51, ...
    #
    # Block is passed to each register_basic_sprite constructor and used for @on_mouse_down on each sprite.
    # rubocop:disable Metrics/PerceivedComplexity
    def register_autotiles(name, w, h, edges=48, &block)
      # No edges:
      register_basic_sprite(name.to_sym, w, h, &block)
      alias_sprite(name.to_sym, "#{name}_0".to_sym)

      aliases_to_create = []
      1.upto 255 do |i|
        north = (i & 1).positive?
        east  = (i & 2).positive?
        south = (i & 4).positive?
        west  = (i & 8).positive?
        ne    = (i & 16).positive?
        se    = (i & 32).positive?
        sw    = (i & 64).positive?
        nw    = (i & 128).positive?

        cur_tile_name   = "#{name}#{autotile_name_from_bits(i)}".to_sym
        actual_i        = nil

        case edges
        when 16
          actual_i = i & 31
        when 48
          actual_i = i
          actual_i -= 16  if ne && (!north || !east)
          actual_i -= 32  if se && (!south || !east)
          actual_i -= 64  if sw && (!south || !west)
          actual_i -= 128 if nw && (!north || !west)
        else
          actual_i = i
        end

        actual_tile_name = "#{name}#{autotile_name_from_bits(actual_i)}".to_sym
        # puts "#{i} -> #{actual_i}: #{cur_tile_name} -> #{actual_tile_name}"

        bits_alias = "#{name}_#{i}".to_sym

        if actual_i == i
          register_basic_sprite(cur_tile_name, w, h, &block)
          alias_sprite(cur_tile_name, bits_alias)
        else
          aliases_to_create << [cur_tile_name, bits_alias, actual_tile_name]
        end
      end

      aliases_to_create.each do |(cur_tile_name, bits_alias, alias_tile_from)|
        alias_sprite(alias_tile_from, cur_tile_name)
        alias_sprite(alias_tile_from, bits_alias)
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def construct(name)
      raise "SpriteRegistry: No sprite named #{name.inspect} in the registry" unless @registry[name]
      raise "Invalid sprite in registry: #{name.inspect}" unless @registry[name].respond_to?(:dup)

      @registry[name].dup
    end

    # private

    def autotile_name_from_bits(bits)
      direction_name = ''
      direction_name += '_north' if (bits & 1).positive?
      direction_name += '_east'  if (bits & 2).positive?
      direction_name += '_south' if (bits & 4).positive?
      direction_name += '_west'  if (bits & 8).positive?
      direction_name += '_ne'    if (bits & 16).positive?
      direction_name += '_se'    if (bits & 32).positive?
      direction_name += '_sw'    if (bits & 64).positive?
      direction_name += '_nw'    if (bits & 128).positive?

      direction_name
    end
  end
end
