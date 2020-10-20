module Zif
  # A basic label which is aware of it's size and can be truncated
  class Label
    attr_accessor :text, :max_width, :min_width, :min_height, :size, :align

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

    def color
      COLOR
    end

    def initialize(text, size=-1, align=0)
      @text = text
      @size = size
      @align = align
      recalculate_minimums
    end

    def full_size_rect
      $gtk.calcstringbox(@text, @size, font).map(&:round)
    end

    # You should invoke this if the text is changing & you care about truncation
    def recalculate_minimums
      @min_width, @min_height = $gtk.calcstringbox(ellipsis, @size, font)
      @max_width, = full_size_rect
    end

    # Determine the largest possible portion of the text we can display
    # End the text with an ellispsis if truncation occurs
    def truncate(width)
      return @text if @max_width <= width

      (@text.length - 1).downto 0 do |i|
        truncated = "#{@text[0..i]}#{ellipsis}"
        cur_width, = $gtk.calcstringbox(truncated, @size, font)
        return truncated if cur_width <= width
      end

      ''
    end

    # For passing to .labels
    # args.outputs.labels << my_label.label_attrs
    def label_attrs
      {
        text:           @text,
        font:           font,
        size_enum:      @size,
        alignment_enum: @align
      }.merge(color)
    end
  end
end
