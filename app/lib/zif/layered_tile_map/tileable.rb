module Zif
  # Functionality shared between TiledLayer & BitmaskedTiledLayer
  # Modifies the layer to be based on a 2d source_sprites array.
  module Tileable
    attr_accessor :source_sprites

    # Because @source_sprites is a 2d array, and the CompoundSprite version of this class expects to be able to iterate
    # over a 1d @sprites array, we need to update the references in @sprites whenever we change @source_sprites
    # I thought about implementing this as some magic on source_sprites, but [][] is hard to fake out. PR welcome
    def sync_sprites_at(logical_x, logical_y)
      puts "a: #{logical_y} #{logical_x} #{@sprites[0].class.to_s} #{@source_sprites[logical_y].class.to_s}"
      sprite = @source_sprites[logical_y][logical_x]
      puts "b: #{sprite.class.to_s}: #{(logical_y*@map.logical_width)+logical_x}"
      @sprites[(logical_y*@map.logical_width)+logical_x] = sprite
      puts "c: #{@sprites.length} #{@sprites[0].class.to_s} #{@source_sprites[logical_y].class.to_s}"
      raise "dammit" if @sprites[0].is_a?(Array)
    end

    def reinitialize_sprites
      puts "#{@layer_name}: Tileable#reinitialize_sprites #{@map.logical_height} #{@map.logical_width}"
      @source_sprites = Array.new(@map.logical_height) { Array.new(@map.logical_width) }
      # @sprites = Array.new(@map.logical_height * @map.logical_width)
      @sprites = []
      @source_sprites.each_with_index do |col, c_idx|
        col.each_with_index do |row, r_idx|
          @sprites << row
        end
      end
      # @sprites = @source_sprites.flatten
      puts "="*80
      puts "i: #{@map.logical_height*@map.logical_width} #{@sprites.length}"
      puts "j: #{@sprites[0].class.to_s} #{@source_sprites[0].class.to_s}"
      raise "dammit" if @sprites[0].is_a?(Array)
    end

    def add_positioned_sprite(logical_x, logical_y, tile_sprite_proto)
      puts "#{@layer_name}: Tileable#add_positioned_sprite #{logical_x} #{logical_y}"
      puts "  #{source_sprites.nil?} #{source_sprites[logical_y].class.to_s}"
      self.source_sprites[logical_y][logical_x] = position_sprite(tile_sprite_proto, logical_x, logical_y)
      sync_sprites_at(logical_x, logical_y)
        puts "-"*80
        puts @source_sprites[0].class.to_s
    end

    def remove_positioned_sprite(sprite)
      x = sprite.logical_x
      y = sprite.logical_y
      self.source_sprites[y][x] = nil
      sync_sprites_at(x, y)
    end

    # This returns an enumerator which can be used to iterate over only the tiles which are visible.
    # Only for layers which have allocated_tiles!
    def visible_sprites(given_rect=nil)
      if given_rect.nil?
        containing_sprite.view_actual_size! unless containing_sprite.source_is_set?
        compare_left   = containing_sprite.source_x
        compare_bottom = containing_sprite.source_y
        compare_w      = containing_sprite.source_w
        compare_h      = containing_sprite.source_h
      else
        compare_left   = given_rect.x
        compare_bottom = given_rect.y
        compare_w      = given_rect.w
        compare_h      = given_rect.h
      end

      logical_x = compare_left.fdiv(@map.tile_width)
      logical_y = compare_bottom.fdiv(@map.tile_height)
      x_range   = compare_w.fdiv(@map.tile_width)
      y_range   = compare_h.fdiv(@map.tile_height)

      max_y = [logical_y + y_range.ceil + 1, @map.logical_height].min
      max_x = [logical_x + x_range.ceil + 1, @map.logical_width].min

      # This enumerator is basically the equivalent of:
      #
      # @floor_tiles[logical_y..max_y].map do |x_tiles|
      #   x_tiles[logical_x..max_x]
      # end.flatten.to_enum
      #
      # The benefit of doing this instead is that we avoid some extraneous iteration and allocation if we call
      # #visible_tiles more than once per tick.  This definitely feels faster, but I haven't benchmarked.

      starting_a = [logical_x, 0].max
      starting_b = [logical_y, 0].max
      a = starting_a
      b = starting_b
      Enumerator.new do |yielder|
        loop do
          yielder << source_sprites[b][a] if source_sprites[b][a]
          r, a = (a + 1).divmod(max_x)
          if r.positive?
            a = starting_a
            b += r
          end
          break unless source_sprites[b] && b <= max_y
        end
      end
    end

    def intersecting_sprites(compare_left, compare_bottom, compare_right, compare_top)
      visible_sprites([compare_left, compare_bottom, compare_right - compare_left, compare_top - compare_bottom])
    end

    def exclude_from_serialize
      %w[source_sprites sprites primitives]
    end
  end
end
