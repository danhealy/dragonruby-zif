module Zif
  module Services
    # This service is for registering your sprite assets once, and assists in creating new {Zif::Sprite} instances from
    # the parameters described when registering.
    #
    # @example Creating 20 copies of a basic sprite
    #   $services[:sprite_registry].register_basic_sprite(:dragon_1, width: 82, height: 66)
    #   my_dragons = 20.times.map { $services[:sprite_registry].construct(:dragon_1) }
    #   # Every dragon in the above array will have path, w, h, source_w, source_h all set to sensible defaults.
    #
    # @example Creating 20 copies of a customized sprite
    #   # Starting from above
    #   giant_dragon_prototype = $services[:sprite_registry].construct(:dragon_1)
    #   giant_dragon_prototype.w = giant_dragon_prototype.w * 10
    #   giant_dragon_prototype.h = giant_dragon_prototype.h * 10
    #
    #   $services[:sprite_registry].add_sprite(:giant_dragon, my_giant_dragon)
    #   my_giant_dragons = 20.times.map { $services[:sprite_registry].construct(:giant_dragon) }
    #
    #   # We've just added another sprite we can create by name.  :dragon_1 is still there if we want the basic version.
    class SpriteRegistry
      # @return [Hash<(Symbol, String), Zif::Sprite>] The registry of your sprites
      attr_reader :registry

      # ------------------
      # @!group 1. Public Interface

      def initialize
        reset_registry
      end

      # Clears {registry}
      def reset_registry
        @registry = {}
      end

      # Add an already created sprite object to the registry
      # @param [Symbol, String] name The name of your sprite, used with {construct}.
      # @param [Zif::Sprite, Object] sprite The sprite object to register.
      def add_sprite(name, sprite)
        @registry[name] = sprite
      end

      # @param [Symbol, String] name The name of the sprite to check for.
      # @return [Boolean] Does the registry have a sprite object with this name?
      def sprite_registered?(name)
        @registry.key?(name)
      end

      # @param [Symbol, String] name The name of an existing entry in the registry
      # @param [Symbol, String] alias_to Another name to use for this sprite, with {construct}
      def alias_sprite(name, alias_to)
        raise "SpriteRegistry: No sprite named #{name.inspect} in the registry" unless @registry[name]

        # puts "SpriteRegistry#alias_sprite: #{alias_to} is now an alias for #{name}"

        @registry[alias_to] = @registry[name]
      end

      # Creates a new {Zif::Sprite} which by convention is named the same as it's +path+, in "app/sprites/<name>.png"
      # You can, of course, modify the prototype after creation
      # @example Registering a basic sprite in some nested location within app/sprites
      #    # The sprite image is at "app/sprites/assets/from_dragonrubygtk/the_ones_i_like_the_best/dragon_1.png"
      #    $services[:sprite_registry].register_basic_sprite(
      #      "assets/from_dragonrubygtk/the_ones_i_like_the_best/dragon_1",
      #      width: 82,
      #      height: 66
      #     )
      #    $services[:sprite_registry].alias_sprite(
      #      "assets/from_dragonrubygtk/the_ones_i_like_the_best/dragon_1",
      #      :dragon_1
      #    )
      #    # Now you can construct(:dragon_1) but it still has the very long path
      # @param [Symbol, String] name The name of your sprite, used with {construct}, and the relative +path+.
      # @param [Integer] width The width of the sprite.  Used for +w+ and +source_w+
      # @param [Integer] height The height of the sprite.  Used for +h+ and +source_h+
      def register_basic_sprite(name, width:, height:, &block)
        sprite = Zif::Sprite.new(name)
        sprite.assign(
          {
            w:        width,
            h:        height,
            path:     "sprites/#{name}.png",
            angle:    0,
            a:        255,
            r:        255,
            g:        255,
            b:        255,
            source_x: 0,
            source_y: 0,
            source_w: width,
            source_h: height
          }
        )

        sprite.on_mouse_up = block if block_given?

        add_sprite(name, sprite)
      end

      # Some background on autotiling (note the author uses a different numbering scheme - NEWS instead of NESW)
      # https://gamedevelopment.tutsplus.com/tutorials/cms-25673
      #
      # This method will automatically register all of the tiles for autotiling with {Zif::BitmaskedTiledLayer}.
      # It'll register every possible direction, aliasing the ones that don't actually exist to the ones that do,
      # depending on the number of edges specified (16 for cardinal directions only, 48 for inside corners, or 256 for
      # every possibility). This expects that the actual filenames are using cardinal directions & diagonal directions,
      # separated by underscores, in the following order:
      #
      # _north _east _south _west _ne _se _sw _nw
      #
      # It will also alias these to the raw bitmask value.
      #
      # Let's work through an example so this is clearer.  You are using a 48-tile set, so you have two different
      # versions of the tile that has an adjacent tile to the north and east, either the corner is cut or not.
      # The one where the corner is not cut - the only adjacent tiles are north, northeast and east - looks like |_
      # You need to have the file for this at "sprites/name_north_east_ne.png"
      # From that one file, it will generate the following aliases:
      # - name_north_east_ne (the actual sprite)
      # - All of the corner cases that don't actually exist because this is just the 48-set and not the full 256
      #   name_north_east_ne_se, name_north_east_ne_sw, name_north_east_ne_nw, name_north_east_ne_se_sw, ...
      # - Both of the above, but using the raw bitmask integer instead of the cardinal directions:
      #   1+2+16= name_19, 1+2+16+32= name_51, ...
      #
      # @param [Symbol, String] name The prefix name of your autotiles, used with {construct}, and the relative +path+.
      # @param [Integer] width The width of a tile.  Used for +w+ and +source_w+
      # @param [Integer] height The height of a tile.  Used for +h+ and +source_h+
      # @param [Integer] edges The type of autotiling you are doing, must be +16+, +48+ or +256+
      #   16 for cardinal directions only
      #   48 for inside corners
      #   256 for every possibility
      # @param [Proc] block Passed to each {register_basic_sprite} constructor to set +@on_mouse_down+ on each sprite.
      # rubocop:disable Metrics/PerceivedComplexity
      def register_autotiles(name, width:, height:, edges: 48, &block)
        # No edges:
        register_basic_sprite(name.to_sym, width: width, height: height, &block)
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
            register_basic_sprite(cur_tile_name, width: width, height: height, &block)
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

      # Create a new copy of a sprite which has been previously registered, using +#dup+
      # @param [Symbol, String] name The name of an existing entry in the registry
      # @return [Zif::Sprite, Object] The retrieved sprite
      def construct(name)
        raise "SpriteRegistry: No sprite named #{name.inspect} in the registry" unless @registry[name]
        raise "Invalid sprite in registry: #{name.inspect}" unless @registry[name].respond_to?(:dup)

        @registry[name].dup
      end

      # ------------------
      # @!group 2. Private-ish methods

      # @api private
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
end
