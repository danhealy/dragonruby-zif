module Zif
  # A basic label which is aware of it's size and can be truncated
  class Label
    include Zif::Actionable

    attr_accessor :x, :y, :r, :g, :b, :a
    attr_accessor :text, :max_width, :min_width, :min_height, :size, :align, :full_text

    alias alignment_enum align
    alias size_enum size

    FONT = 'font.tff'.freeze
    ELLIPSIS = '…'.freeze
    COLOR = {
      r: 51,
      g: 51,
      b: 51,
      a: 255
    }.freeze

    # These are expected to be redefined
    def font
      FONT
    end

    def ellipsis
      ELLIPSIS
    end

    def default_color
      COLOR
    end

    def primitive_marker
      :label
    end

    def initialize(text, size=-1, align=0)
      @text = text
      @full_text = text
      @size = size
      @align = align
      @r = default_color[:r]
      @g = default_color[:g]
      @b = default_color[:b]
      @a = default_color[:a]
      recalculate_minimums
    end

    def rect
      $gtk.calcstringbox(@text, @size, font).map(&:round)
    end

    def full_size_rect
      $gtk.calcstringbox(@full_text, @size, font).map(&:round)
    end

    # You should invoke this if the text is changing & you care about truncation
    def recalculate_minimums
      @min_width, @min_height = $gtk.calcstringbox(ellipsis, @size, font)
      @max_width, = full_size_rect
    end

    # Determine the largest possible portion of the text we can display
    # End the text with an ellispsis if truncation occurs
    def truncate(width)
      if @max_width <= width
        @text = @full_text
        return
      end

      (@full_text.length - 1).downto 0 do |i|
        truncated = "#{@full_text[0..i]}#{ellipsis}"
        cur_width, = $gtk.calcstringbox(truncated, @size, font)
        if cur_width <= width
          @text = truncated
          return
        end
      end

      @text = ''
    end

    def retruncate(width)
      recalculate_minimums
      truncate(width)
    end

    def recenter_in(w, h, offset)
      @x = w.idiv(2)
      @y = (h + min_height).idiv(2) + offset
    end
  end
end
