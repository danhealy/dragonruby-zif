module Zif
  # A TiledLayer where the sprites are chosen via bitmasked adjacency rules on the presence data layer - otherwise
  # known as Autotiling.
  # This is a bit opinionated!  Here is how the bitmask is calculated:
  #
  # +-----+----+-----+
  # | 128 | 1  |  16 |
  # +-----+----+-----+
  # |  8  | <> |  2  |
  # +-----+----+-----+
  # |  64 | 4  |  32 |
  # +-----+----+-----+
  #
  # (Cardinal directions clockwise, then diagonal directions clockwise)
  #
  # So if a tile has a neighbor to the north, east and northeast, it'll try to load the sprite "mytiles_19" -- 1+2+16
  # from the SpriteRegistry.  See the SpriteRegistry for more info on filenames and aliasing.
  #
  # Some background (note the author uses a different numbering scheme):
  # https://gamedevelopment.tutsplus.com/tutorials/how-to-use-tile-bitmasking-to-auto-tile-your-level-layouts--cms-25673
  class BitmaskedTiledLayer < TiledLayer
    attr_accessor :presence_data, :bitmask_data, :bitmasked_sprite_name_prefix

    def reinitialize_sprites
      super()
      @presence_data = Array.new(@map.logical_height) { Array.new(@map.logical_width, false) }
      @bitmask_data  = Array.new(@map.logical_height) { Array.new(@map.logical_width, nil) }
    end

    def remove_at(x, y)
      # puts "#remove_at: #{x}, #{y}: was #{@source_sprites[y][x]}"
      @presence_data[y][x] = false
      @source_sprites[y][x] = nil
      # puts "#remove_at: #{x}, #{y}: now #{@source_sprites[y][x]}"
      redraw_at(x, y)
    end

    def add_at(x, y)
      # TODO
    end

    def redraw_at(x, y)
      recalculate_bitmask(x - 1, y - 1, x + 1, y + 1)
      set_sprites_from_bitmask(x - 1, y - 1, x + 1, y + 1)
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def recalculate_bitmask(from_x=0, from_y=0, to_x=@map.logical_width - 1, to_y=@map.logical_height - 1)
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
    # rubocop:enable Metrics/PerceivedComplexity

    def set_sprites_from_bitmask(from_x=0, from_y=0, to_x=@map.logical_width - 1, to_y=@map.logical_height - 1)
      raise 'BitmaskedTiledLayer: Please set @bitmasked_sprite_name_prefix' unless @bitmasked_sprite_name_prefix

      from_x = [from_x, 0].max
      from_y = [from_y, 0].max
      to_x   = [to_x, @map.logical_width - 1].min
      to_y   = [to_y, @map.logical_height - 1].min

      (from_y..to_y).each do |i|
        (from_x..to_x).each do |j|
          @source_sprites[i][j] = nil
          bitmask = @bitmask_data[i][j]
          next unless bitmask

          full_name = "#{@bitmasked_sprite_name_prefix}_#{bitmask}".to_sym
          sprite = $services[:sprite_registry].construct(full_name)

          @source_sprites[i][j] = position_sprite(sprite, j, i)
        end
      end
    end

    def exclude_from_serialize
      %w[presence_data bitmask_data source_sprites sprites primitives]
    end
  end
end
