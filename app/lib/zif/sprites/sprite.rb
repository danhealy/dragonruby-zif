module Zif
  # A basic sprite which has assignable and serializable functionality
  # The foundation for most of the Zif library
  class Sprite
    include Zif::Assignable
    include Zif::Serializable
    include Zif::Actionable
    include Zif::Animatable
    attr_sprite

    attr_accessor :name

    # Used for unit positioning (tile map addressing, for example - See Zif::LayeredTileMap)
    attr_accessor :logical_x, :logical_y, :z

    # If this sprite is a parent *container* for a Render Target, reference it here
    # Not for sprites which are *children* of a Render Target!
    attr_accessor :render_target

    attr_accessor :on_mouse_down, :on_mouse_up, :on_mouse_changed

    def initialize(name=:unknown)
      @name      = name
      @logical_x = 0
      @logical_y = 0
      @x         = 0
      @y         = 0
      @z         = 0
      @w         = 0
      @h         = 0
      @a         = 255
      @r         = 255
      @g         = 255
      @b         = 255
      @angle     = 0
    end

    def dup_and_assign(sprite)
      dup.assign(sprite)
    end

    def show
      @a = 255
    end

    def hide
      @a = 0
    end

    def absorb_click?
      on_mouse_up || on_mouse_down || on_mouse_changed
    end

    def clicked?(point, kind=:up)
      # puts "Sprite:#{@name}: clicked? #{kind} #{kind.class} #{point} -> #{rect} = #{point.inside_rect?(rect)}"
      return nil if (kind == :down) && !point.inside_rect?(rect)

      click_handler = case kind
                      when :up
                        on_mouse_up
                      when :down
                        on_mouse_down
                      when :changed
                        on_mouse_changed
                      end

      # puts "Sprite:#{@name}: click handler: #{kind} #{click_handler}"

      click_handler&.call(self, point)
      return self unless @render_target && !absorb_click?

      @render_target.clicked?(point, kind)
    end

    # Experimenting with draw_override, please ignore
    #
    # def primitive_marker
    #   :sprite
    # end
    #
    # def sprite
    #   self
    # end
    #
    # def draw_override(ffi_draw)
    #   ffi_draw.draw_sprite_3 @x, @y, @w, @h,
    #                               @path.s_or_default,
    #                               @angle,
    #                               @a, @r, @g, @b,
    #                               nil, nil, nil, nil,
    #                               !!@flip_horizontally, !!@flip_vertically,
    #                               0.5, 0.5,
    #                               @source_x, @source_y, @source_w, @source_h
    # end

    # ------------------------
    # Some convenience methods

    def self.rect_array_to_hash(arr=[])
      {
        x: arr[0],
        y: arr[1],
        w: arr[2],
        h: arr[3]
      }
    end

    def self.rect_array_to_source_hash(arr=[])
      {
        source_x: arr[0],
        source_y: arr[1],
        source_w: arr[2],
        source_h: arr[3]
      }
    end

    # {x: ..., y: ...} -> {source_x: ..., source_y: ...}
    def self.rect_hash_to_source_hash(rect={})
      rect.transform_keys { |key| key.include?('source_') ? key : "source_#{key}".to_sym }
    end

    def xy
      [@x, @y]
    end

    def wh
      [@w, @h]
    end

    def center
      [(@x + @w.idiv(2)).to_i, (@y + @h.idiv(2)).to_i]
    end

    def rect
      [@x, @y, @w, @h]
    end

    def rect_hash
      Sprite.rect_array_to_hash(rect)
    end

    def source_xy
      [@source_x, @source_y]
    end

    def source_wh
      [@source_w, @source_h]
    end

    def source_rect
      [@source_x, @source_y, @source_w, @source_h]
    end

    def source_center
      [(@source_x + @source_w.idiv(2)).to_i, (@source_y + @source_h.idiv(2)).to_i]
    end

    def source_rect_hash
      Sprite.rect_array_to_source_hash(source_rect)
    end

    # If for some reason you want source_ attrs without "source_"
    # Like using RenderTarget#project_from
    def source_as_rect_hash
      Sprite.rect_array_to_hash(source_rect)
    end

    def color
      {
        r: @r,
        g: @g,
        b: @b,
        a: @a
      }
    end

    def to_h
      {path: @path}.merge(source_rect_hash).merge(rect_hash).merge(color)
    end
  end
end
