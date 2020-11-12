module Zif
  # A CompoundSprite is a collection of sprites which can be positioned as a group.
  class CompoundSprite < Sprite
    attr_accessor :sprites, :labels

    def initialize(name=:unknown)
      super(name)
      @sprites     = []
      @labels      = []
    end

    def view_actual_size!
      @source_x = 0
      @source_y = 0
      @source_w = @w
      @source_h = @h
    end

    # We must set source if it hasn't been set yet.  Assume full size.
    def source_rect
      cur_rect = super
      view_actual_size! if cur_rect.any?(&:nil?)
      cur_rect
    end

    def draw_override(ffi_draw)
      x_zoom, y_zoom = zoom_factor
      cur_source_rect = source_rect

      # Since this "sprite" itself won't actually be drawn, we can use the positioning attributes to control the
      # contained sprites.
      # x/y: linear offset
      # w/h: used for #zoom_factor, derived with comparison to source_w/h (Sprite method)
      # source_x/y: position of visible window
      # source_w/h: extent of visible window.  Unfortunately we can't clip sprites in half using this method.
      #             Therefore, anything even *partially* visible will be *fully* drawn.

      # puts "#{@name}: Begin drawing"
      @sprites.each do |sprite|
        cur_rect = sprite.rect

        # puts "#{@name}: #{sprite.name} #{cur_rect} #{cur_source_rect}"
        next unless cur_rect.intersect_rect?(cur_source_rect, 0.1)

        x, y, w, h = cur_rect

        ffi_draw.draw_sprite_3(
          ((x - @source_x) * x_zoom) + @x,
          ((y - @source_y) * y_zoom) + @y,
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
      # puts "#{@name}: Drew sprites"
      @labels.each do |label|
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
      # puts "#{@name}: Drew labels"
    end
  end
end
