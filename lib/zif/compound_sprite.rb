module Zif
  # A CompoundSprite is a collection of sprites which can be positioned as a group, and are drawn using {draw_override}
  #
  # This class acts like a (inherits from) {Zif::spriteSprite} but can itself accept a list of {sprites} and {labels},
  # like +$gtk.args.outputs+.  Sprites and labels added to these arrays will be drawn using the {draw_override} method,
  # which is checked by DragonRuby GTK during the draw cycle.
  #
  # You can use +CompoundSprite+ to draw several sprites which need to move together or relative to each other.  You can
  # move the entire collection by changing the +CompoundSprite+'s +x+ and +y+ values, and you can move the component
  # sprites relative to each other individually.
  # This is because this object itself is not drawn directly, per se (+@path+ is ignored), but has +x+, +y+, +w+, +h+,
  # +source_x+, +source_y+, +source_w+, +source_h+ values which act as modifiers to the contents of {sprites} it is
  # drawing.
  #
  # @example The CompoundSprite position causes translation on the sprites it contains
  #   alduin = Zif::Sprite.new.tap do |s|
  #     s.x = 0
  #     s.y = 100
  #     s.w = 82
  #     s.h = 66
  #     s.path = "sprites/dragon_1.png"
  #   end
  #   bahamut = Zif::Sprite.new.tap do |s|
  #     s.x = 200
  #     s.y = 0
  #     s.w = 82
  #     s.h = 66
  #     s.flip_horizontally = true
  #     s.path = "sprites/dragon_1.png"
  #   end
  #
  #   # Now we have 2 dragons facing each other, but we are not adding these to args.outputs.sprites individually.
  #   # They are on a battlefield and can be moved in unison!
  #
  #   battlefield = Zif::CompoundSprite.new.tap do |cs|
  #     cs.sprites = [alduin, bahamut]
  #     cs.x = 130 # This causes bahamut to appear at x == 330 on screen
  #     cs.y = 20  # This causes alduin to appear at y == 120 on screen
  #     cs.w = 300 # To show everything, should be at least as wide as the farthest x value + width (200+82)
  #     cs.h = 200 # To show everything, should be at least as high as the largest y value + height (100+66)
  #     # No path is defined, CompoundSprite is for organization only and does not display directly.
  #   end
  #
  #   # Add the battlefield to outputs.
  #   $gtk.args.outputs.sprites << battlefield
  #
  # A sprite which has been added to the {sprites} array will be drawn in the following way:
  # - The +CompoundSprite+'s +x+, +y+, +w+, +h+ act as a viewable rectangle on the main screen and are absolute values
  #   compared to the game resolution.  Sprites which would be drawn completely outside of this rect will be ignored.
  #   **Important!** This is unlike Render Targets or regular sprites, which cut off the image cleanly at these
  #   boundaries.  The +CompoundSprite+ is a virtual effect which can't slice a sprite in half.  Therefore, the entire
  #   sprite is rendered if even a portion is visible in the viewable rect.
  # - The +CompoundSprite+'s +source_x+, +source_y+, +source_w+, +source_h+ act like these attributes would if
  #   displaying a normal image instead of a collection of sprites.  They are relative values of the {sprites} it is
  #   drawing.
  #   - +source_x+, +source_y+ reposition the origin of the viewport into the {sprites} array.
  #     E.g. If you have a sprite @ +0x/0y+ with +10w/10h+ it will not be drawn if the +CompoundSprite+'s +source_x+
  #     and +source_y+ exceeds +10/10+
  #   - +source_w+, +source_h+ describe the extent of the viewport into the {sprites} array.
  #     E.g. If the +CompoundSprite+ has +0x, 0y, 20w, 20h+, and +0 source_x, 0 source_y, 10 source_w, 10 source_h+,
  #     the example +0x, 0y, 10w, 10h+ sprite will be displayed twice as large as normal.
  #   - **Important!** As above, unlike a normal sprite, changing the +source_x+, +source_y+, +source_w+, +source_h+
  #     will not cause sprites drawn this way to be sliced in any way.  It will simply zoom and pan the complete
  #     sprites, and possibly ignore them if they exceed the extent of the viewable rectangle or the source viewport.
  #
  # This class is the basis for {Zif::Layers::ActiveLayer} and many of the UI elements ({Zif::UI::TwoStageButton},
  # {Zif::UI::NinePanel}, etc).
  #
  # @see ExampleApp::CompoundSpriteTest
  class CompoundSprite < Sprite
    # @return [Array<Zif::Sprite>] The list of sprites this CompoundSprite is rendering.
    attr_accessor :sprites

    # @return [Array<Zif::UI::Label>] The list of labels this CompoundSprite is rendering.
    attr_accessor :labels

    # ------------------
    # @!group 1. Public Interface

    # @param [String] name The name of this compound sprite, mostly used for debugging purposes
    def initialize(name=Zif.unique_name('compound_sprite'))
      super(name)
      @sprites = []
      @labels  = []
    end

    # Calls {Zif::Sprite#source_rect} after ensuring the +source_x+ etc attrs are set to something.
    # @see Zif::Sprite#source_rect
    # @return [Array<Numeric>]
    #   [{Zif::Sprite#source_x}, {Zif::Sprite#source_y}, {Zif::Sprite#source_w}, {Zif::Sprite#source_h}]
    def source_rect
      view_actual_size! unless source_is_set?
      super
    end

    # ------------------
    # @!group 2. Private-ish methods

    # This class defines #draw_override, which is used by DragonRuby GTK internals.
    # This method contains the logic for grouping the {sprites} and {labels} together.
    #
    # You should not need to call this directly.
    # DRGTK docs on #draw_override:
    # http://docs.dragonruby.org/#----performance---static-sprites-as-classes-with-custom-drawing---main.rb
    # @api private
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
        next if
          (x     > cur_source_right) ||
          (y     > cur_source_top)   ||
          (x + w < @source_x)        ||
          (y + h < @source_y)

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
