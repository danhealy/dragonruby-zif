module Zif
  # Expects to be included in classes which are sprites (using attr_sprite, or a subclass of Zif::Sprite for example)
  # A mixin to allow assignment of sprite ivars using a hash
  # rubocop:disable Metrics/PerceivedComplexity
  module Assignable
    def assign(sprite)
      @name          = sprite[:name]          if sprite[:name]
      @logical_x     = sprite[:logical_x]     if sprite[:logical_x]
      @logical_y     = sprite[:logical_y]     if sprite[:logical_y]
      @render_target = sprite[:render_target] if sprite[:render_target]
      @x             = sprite[:x]             if sprite[:x]
      @y             = sprite[:y]             if sprite[:y]
      @z             = sprite[:z]             if sprite[:z]
      @w             = sprite[:w]             if sprite[:w]
      @h             = sprite[:h]             if sprite[:h]
      @path          = sprite[:path]          if sprite[:path]
      @angle         = sprite[:angle]         if sprite[:angle]
      @a             = sprite[:a]             if sprite[:a]
      @r             = sprite[:r]             if sprite[:r]
      @g             = sprite[:g]             if sprite[:g]
      @b             = sprite[:b]             if sprite[:b]
      @tile_x        = sprite[:tile_x]        if sprite[:tile_x]
      @tile_y        = sprite[:tile_y]        if sprite[:tile_y]
      @tile_w        = sprite[:tile_w]        if sprite[:tile_w]
      @tile_h        = sprite[:tile_h]        if sprite[:tile_h]
      @source_x      = sprite[:source_x]      if sprite[:source_x]
      @source_y      = sprite[:source_y]      if sprite[:source_y]
      @source_w      = sprite[:source_w]      if sprite[:source_w]
      @source_h      = sprite[:source_h]      if sprite[:source_h]
      @on_mouse_down = sprite[:on_mouse_down] if sprite[:on_mouse_down]
      @on_mouse_up   = sprite[:on_mouse_up]   if sprite[:on_mouse_up]

      self
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
end
