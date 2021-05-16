module Zif
  module UI
    # A basic label which is aware of it's size and can be truncated
    class Label
      include Zif::Actions::Actionable

      MAGIC_NEWLINE_DELIMITER = '+newline+'.freeze

      ALIGNMENT = {
        left:   0,
        center: 1,
        right:  2
      }.freeze

      VERTICAL_ALIGNMENT = {
        bottom: 0,
        center: 1,
        top:    2
      }.freeze

      # @return [Numeric] X axis position
      attr_accessor :x
      # @return [Numeric] Y axis position
      attr_accessor :y
      # @return [Numeric] Red color (+0-255+)
      attr_accessor :r
      # @return [Numeric] Green color (+0-255+)
      attr_accessor :g
      # @return [Numeric] Blue color (+0-255+)
      attr_accessor :b
      # @return [Numeric] Alpha channel (Transparency) (+0-255+)
      attr_accessor :a
      # @return [String] The complete text of the label before truncation
      attr_accessor :full_text
      # @return [String] The current visible text of the label
      attr_reader :text
      # @return [Integer] The maximum width of the full text
      attr_reader :max_width
      # @return [Integer] The minimum width of the text truncated down to just the ellipsis
      attr_reader :min_width
      # @return [Integer] The minimum height of the text truncated down to just the ellipsis
      attr_reader :min_height
      # @return [Integer] The size value to render the text at
      attr_accessor :size
      # @return [String] A character to use to indicate the text has been truncated
      attr_accessor :ellipsis
      # @return [String] Path to the font file
      attr_accessor :font

      alias size_enum size

      # @param [String] text {full_text}
      # @param [Integer] size {size}
      # @param [Symbol, Integer] alignment {align} +:left+, +:center+, +:right+ or +0+, +1+, +2+. See {ALIGNMENT}
      # @param [Symbol, Integer] vertical_alignment {vertical_align} +:bottom+, +:center+, +:top+ or +0+, +1+, +2+. See {VERTICAL_ALIGNMENT}
      # @param [String] font {font}
      # @param [String] ellipsis {ellipsis}
      # @param [Integer] r {r}
      # @param [Integer] g {g}
      # @param [Integer] b {b}
      # @param [Integer] a {a}
      def initialize(
        text='',
        size:               -1,
        alignment:          :left,
        vertical_alignment: :top,
        font:               'font.tff',
        ellipsis:           '…',
        r:                  51,
        g:                  51,
        b:                  51,
        a:                  255
      )
        @text               = text
        @full_text          = text
        @size               = size
        @alignment          = ALIGNMENT.fetch(alignment, alignment)
        @vertical_alignment = VERTICAL_ALIGNMENT.fetch(vertical_alignment, vertical_alignment)
        @ellipsis           = ellipsis
        @font               = font
        @r                  = r
        @g                  = g
        @b                  = b
        @a                  = a
        recalculate_minimums
      end

      def text=(new_text)
        @full_text = new_text
        @text = new_text
      end

      # Set alignment using either symbol names or the enum integer values.
      # @param [Symbol, Integer] new_alignment {align} +:left+, +:center+, +:right+ or +0+, +1+, +2+. See {ALIGNMENT}
      # @return [Integer] The integer value for the specified alignment
      def align=(new_alignment)
        @alignment = ALIGNMENT.fetch(new_alignment, new_alignment)
      end

      # @return [Integer] The integer value for the specified alignment.  See {ALIGNMENT}
      # @example This always returns an integer, even if you set it using a symbol
      #   mylabel.align = :center # => 1
      #   mylabel.align           # => 1
      def align
        @alignment
      end

      def vertical_align=(new_alignment)
        @vertical_alignment = VERTICAL_ALIGNMENT.fetch(new_alignment, new_alignment)
      end

      def vertical_align
        @vertical_alignment
      end

      # These are required to satisfy draw_ffi
      alias alignment_enum align
      alias vertical_alignment_enum vertical_align

      # @return [Array<Integer>] 2-element array [+w+, +h+] of the current text
      def rect
        $gtk.calcstringbox(@text, @size, @font).map(&:round)
      end

      # @return [Array<Integer>] 2-element array [+w+, +h+] of the full sized text
      def full_size_rect
        $gtk.calcstringbox(@full_text, @size, @font).map(&:round)
      end

      # Recalculate {min_width} {max_width} {min_height}
      # You should invoke this if the text is changing & you care about truncation
      def recalculate_minimums
        @min_width, @min_height = $gtk.calcstringbox(@ellipsis, @size, @font)
        @max_width, = full_size_rect
      end

      # Determine the largest possible portion of the text we can display
      # End the text with an ellispsis if truncation occurs
      # @param [Integer] width The allowable width of the text, will be truncated until it fits
      def truncate(width)
        if @max_width <= width
          @text = @full_text
          return
        end

        (@full_text.length - 1).downto 0 do |i|
          truncated = "#{@full_text[0..i]}#{@ellipsis}"
          cur_width, = $gtk.calcstringbox(truncated, @size, @font)
          if cur_width <= width
            @text = truncated
            return # rubocop:disable Lint/NonLocalExitFromIterator
          end
        end

        @text = ''
      end

      # Recalculate minimums and then truncate
      def retruncate(width)
        recalculate_minimums
        truncate(width)
      end

      # Reposition {x} and {y} to center the text
      # @param [Integer] w Width
      # @param [Integer] h Height
      # @param [Integer] offset Y-Offset
      def recenter_in(w, h, offset: 0)
        @x = w.idiv(2)
        @y = (h + min_height).idiv(2) + offset
      end

      # @return [Hash<Symbol, Numeric>] r: {r}, g: {g}, b: {b}, a: {a}
      def color
        {
          r: @r,
          g: @g,
          b: @b,
          a: @a
        }
      end

      # @note Use +#assign+ if you want to assign with a hash.  This works with positional array.
      # @param [Array<Numeric>] rgba_array +[r, g, b, a]+.  If any entry is nil, assignment is skipped.
      def color=(rgba_array=[])
        @r = rgba_array[0] if rgba_array[0]
        @g = rgba_array[1] if rgba_array[1]
        @b = rgba_array[2] if rgba_array[2]
        @a = rgba_array[3] if rgba_array[3]
      end

      # Converts this label into a list of new labels for individual lines which can fit inside the given width.
      # @param [Integer] width The maximum width per line
      # @return [Array<Zif::UI::Label] An array of new labels for this text
      def wrap(width, indent: '')
        return [self] unless @full_text.length.positive?

        words = @full_text.gsub('\\', '').gsub("\n", MAGIC_NEWLINE_DELIMITER).split(' ')
        new_labels = []
        cur_label = dup
        cur_label.text = ''

        while words.any?
          finish_line = false
          cur_word = words.shift

          # If this word contains newlines, split into new words and add the extras back to 'words'
          cur_word, remainder = cur_word.split(MAGIC_NEWLINE_DELIMITER, 2)
          if remainder
            finish_line = true
            words.unshift(remainder)
          end

          existing_text = cur_label.text
          cur_label.text = existing_text + (existing_text == '' ? '' : ' ') + cur_word unless cur_word.nil?
          cur_label.recalculate_minimums
          cur_rect = cur_label.rect
          if cur_rect[0] > width
            if existing_text == ''
              cur_label.truncate(width)
            else
              old_label, cur_label = split_labels(cur_label, existing_text, indent + cur_word, width, cur_rect[1])
              new_labels << old_label
            end
          end
          if finish_line
            old_label, cur_label = split_labels(cur_label, cur_label.text, '', width, cur_rect[1])
            new_labels << old_label
          end
        end

        cur_label.recalculate_minimums
        cur_label.truncate(width)
        new_labels << cur_label

        new_labels
      end

      # @return [Integer] Returns right edge of the label's current size
      def right
        x + rect[0]
      end

      # @api private
      def split_labels(label, a, b, width, height)
        label.text = a
        label.recalculate_minimums
        label.truncate(width)

        old_y = label.y

        b_label = dup
        b_label.text = b
        b_label.recalculate_minimums
        b_label.truncate(width)
        b_label.y = old_y - height
        [label, b_label]
      end

      # @api private
      def primitive_marker
        :label
      end
    end
  end
end
