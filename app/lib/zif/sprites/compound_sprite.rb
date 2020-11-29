module Zif
  # A CompoundSprite is a collection of sprites which can be positioned as a group.
  class CompoundSprite < Sprite
    attr_accessor :sprites, :labels

    def initialize(name=Zif.random_name('compound_sprite'))
      super(name)
      @sprites     = []
      @labels      = []
    end

    def source_rect
      view_actual_size! unless source_is_set?
      super
    end

    def draw_override(ffi_draw)
      # $services&.named(:tracer)&.mark("CompoundSprite(#{@name})#draw_override: begin")
      # Treat an alpha setting of 0 as an indication that it should be hidden, to match Sprite behavior
      return if @a.zero?

      view_actual_size! unless source_is_set?

      x_zoom, y_zoom = zoom_factor
      cur_source_right = @source_x + @source_w
      cur_source_top   = @source_y + @source_h

      # Since this "sprite" itself won't actually be drawn, we can use the positioning attributes to control the
      # contained sprites.
      # x/y: linear offset
      # w/h: used for #zoom_factor, derived with comparison to source_w/h (Sprite method)
      # source_x/y: position of visible window
      # source_w/h: extent of visible window.  Unfortunately we can't clip sprites in half using this method.
      #             Therefore, anything even *partially* visible will be *fully* drawn.

      # $services&.named(:tracer)&.mark("CompoundSprite(#{@name})#draw_override: Sprite drawing begin")
      # puts "CompoundSprite(#{@name})#draw_override: Sprite drawing begin"

      # Throwback to the days before Enumerable, for performance reasons
      cur_sprite_idx = 0
      total_sprite_length = sprites.count
      while cur_sprite_idx < total_sprite_length
        sprite = @sprites[cur_sprite_idx]
        cur_sprite_idx += 1
        next if sprite.nil?

        x = sprite.x
        y = sprite.y
        w = sprite.w
        h = sprite.h

        # This performs a little better than calling intersect_rect?
        next if (
          (x     > cur_source_right) ||
          (y     > cur_source_top)   ||
          (x + w < @source_x)        ||
          (y + h < @source_y)
        )

        ffi_draw.draw_sprite_3(
          (x - @source_x) * x_zoom + @x,
          (y - @source_y) * y_zoom + @y,
          w * x_zoom,
          h * y_zoom,
          sprite.path.s_or_default,
          sprite.angle,
          sprite.a,
          sprite.r,
          sprite.g,
          sprite.b,
          nil, nil, nil, nil, # Don't use tile_*
          sprite.flip_horizontally,
          sprite.flip_vertically,
          sprite.angle_anchor_x,
          sprite.angle_anchor_y,
          sprite.source_x,
          sprite.source_y,
          sprite.source_w,
          sprite.source_h
        )
      end
      # $services&.named(:tracer)&.mark("CompoundSprite(#{@name})#draw_override: Sprite drawing complete")
      # puts "CompoundSprite(#{@name})#draw_override: Sprite drawing complete"

      labels.each do |label|
        # TODO: Skip if not in visible window
        ffi_draw.draw_label(
          ((label.x - @source_x) * x_zoom) + @x,
          ((label.y - @source_y) * y_zoom) + @y,
          label.text.s_or_default,
          label.size_enum,
          label.alignment_enum,
          label.r,
          label.g,
          label.b,
          label.a,
          label.font.s_or_default(nil)
        )
      end
      # $services&.named(:tracer)&.mark("CompoundSprite(#{@name})#draw_override: Label drawing complete")
    end
  end
end
