module Zif
  module Layers
    # A mixin to extend {Zif::Layers::Tileable} functionality.
    # Sprites are chosen via bitmasked adjacency rules on the presence data layer - otherwise known as Autotiling.
    # This is a bit opinionated!  Here is how the bitmask is calculated:
    #
    #   +-----+----+-----+
    #   | 128 | 1  |  16 |
    #   +-----+----+-----+
    #   |  8  | <> |  2  |
    #   +-----+----+-----+
    #   |  64 | 4  |  32 |
    #   +-----+----+-----+
    #
    # (Cardinal directions clockwise, then diagonal directions clockwise)
    #
    # So if a tile has a neighbor to the north, east and northeast, it'll try to load the sprite "mytiles_19" -- 1+2+16
    # from the SpriteRegistry.  See the SpriteRegistry for more info on filenames and aliasing.
    #
    # Some background (note the author uses a different numbering scheme):
    # https://gamedevelopment.tutsplus.com/tutorials/how-to-use-tile-bitmasking-to-auto-tile-your-level-layouts--cms-25673
    # @see Zif::Layers::Tileable
    module Bitmaskable
      # rubocop:disable Metrics/PerceivedComplexity

      # @return [Array<Array<Boolean>>] A 2-dimensional array of +true+ and +false+ values
      #   This array is the size of your map's logical height, containing arrays the size of the logical width.
      attr_accessor :presence_data

      # @return [Array<Array<Integer>>] A 2-dimensional array of bitmasked integers calculated from {presence_data}
      #   This array is the size of your map's logical height, containing arrays the size of the logical width.
      attr_reader   :bitmask_data

      # @return [String] The prefix to use when referencing image paths
      attr_accessor :bitmasked_sprite_name_prefix

      # ------------------
      # @!group 1. Public Interface

      # Overrides {Zif::Layers::Tileable#reinitialize_sprites}
      # Clears +@sprites+ and resets {presence_data} and {bitmask_data}
      def reinitialize_sprites
        super()
        @presence_data = Array.new(@map.logical_height) { Array.new(@map.logical_width, false) }
        @bitmask_data  = Array.new(@map.logical_height) { Array.new(@map.logical_width, nil) }
      end

      # Remove the tile / presence at this logical position, then redraw
      # @param [Integer] x logical_x position to remove
      # @param [Integer] y logical_y position to remove
      def remove_at(x, y)
        @presence_data[y][x] = false
        remove_tile(x, y)
        redraw_at(x, y)
      end

      # Add presence at this logical position, then redraw
      # @param [Integer] x logical_x position to add
      # @param [Integer] y logical_y position to add
      def add_at(x, y)
        @presence_data[y][x] = true
        redraw_at(x, y)
      end

      # Recalculates bitmask and sets sprites for the specified location and the 9 tiles surrounding it
      # @param [Integer] x Logical X location
      # @param [Integer] y Logical Y location
      def redraw_at(x, y)
        recalculate_bitmask(from_x: x - 1, from_y: y - 1, to_x: x + 1, to_y: y + 1)
        set_sprites_from_bitmask(from_x: x - 1, from_y: y - 1, to_x: x + 1, to_y: y + 1)
      end

      # This will recalculte the {bitmask_data} for a rectangle of logical positions, from {presence_data}
      # @param [Integer] from_x Lower left logical X position of the rectangle to update
      # @param [Integer] from_y Lower left logical Y position of the rectangle to update
      # @param [Integer] to_x Upper right logical X position of the rectangle to update
      # @param [Integer] to_y Upper right logical Y position of the rectangle to update
      def recalculate_bitmask(from_x: 0, from_y: 0, to_x: @map.logical_width - 1, to_y: @map.logical_height - 1)
        from_x = [from_x, 0].max
        from_y = [from_y, 0].max
        to_x   = [to_x, @map.logical_width - 1].min
        to_y   = [to_y, @map.logical_height - 1].min

        (from_y..to_y).each do |i|
          (from_x..to_x).each do |j|
            @bitmask_data[i][j] = nil
            next unless @presence_data[i][j]

            map_north = (i + 1) <= @map.logical_height
            map_south = (i - 1).positive?

            map_east  = (j + 1) <= @map.logical_width
            map_west  = (j - 1).positive?

            bitmask = 0

            # The presence of a bit in the bitmask indicates the presence of a tile relative to this one
            # Edges
            # Edges - North
            bitmask += 1 if map_north && @presence_data[i + 1][j]
            # Edges - East
            bitmask += 2 if map_east  && @presence_data[i][j + 1]
            # Edges - South
            bitmask += 4 if map_south && @presence_data[i - 1][j]
            # Edges - West
            bitmask += 8 if map_west  && @presence_data[i][j - 1]

            # Corners
            # Corners - NE
            bitmask += 16  if map_north && map_east && @presence_data[i + 1][j + 1]
            # Corners - SE
            bitmask += 32  if map_south && map_east && @presence_data[i - 1][j + 1]
            # Corners - SW
            bitmask += 64  if map_south && map_west && @presence_data[i - 1][j - 1]
            # Corners - NW
            bitmask += 128 if map_north && map_west && @presence_data[i + 1][j - 1]

            @bitmask_data[i][j] = bitmask
          end
        end
      end

      # This will reset the tiles for a rectangle, based on the {bitmask_data}
      # @param [Integer] from_x Lower left logical X position of the rectangle to update
      # @param [Integer] from_y Lower left logical Y position of the rectangle to update
      # @param [Integer] to_x Upper right logical X position of the rectangle to update
      # @param [Integer] to_y Upper right logical Y position of the rectangle to update
      def set_sprites_from_bitmask(from_x: 0, from_y: 0, to_x: @map.logical_width - 1, to_y: @map.logical_height - 1)
        raise 'BitmaskedTiledLayer: Please set @bitmasked_sprite_name_prefix' unless @bitmasked_sprite_name_prefix

        from_x = [from_x, 0].max
        from_y = [from_y, 0].max
        to_x   = [to_x, @map.logical_width - 1].min
        to_y   = [to_y, @map.logical_height - 1].min

        (from_y..to_y).each do |i|
          (from_x..to_x).each do |j|
            remove_tile(j, i)
            bitmask = @bitmask_data[i][j]
            next unless bitmask

            full_name = "#{@bitmasked_sprite_name_prefix}_#{bitmask}".to_sym
            sprite = $services[:sprite_registry].construct(full_name)

            add_positioned_sprite(sprite: sprite, logical_x: j, logical_y: i)
          end
        end
      end

      # ------------------
      # @!group 2. Private-ish methods

      # @api private
      def exclude_from_serialize
        %w[presence_data bitmask_data sprites primitives]
      end

      # rubocop:enable Metrics/PerceivedComplexity
    end
  end
end
