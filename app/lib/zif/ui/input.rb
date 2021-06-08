module Zif
  module UI
    # A basic input field that can accept keystrokes and record and display changes
    #
    # to have it receive key strokes it needs to be registered
    #    $game.services[:input_service].register_key_pressable(@input)
    #
    # and added to the static_labels so that it draws on the screen.
    #      $gtk.args.outputs.static_labels << [@input]
    #
    class Input < Label
      include Zif::KeyPressable
      include Zif::Serializable

      attr_rect

      # @return [Lambda] Called when character input is detected.  Called with +text+ and should return +text+ to be added to the input. Allows you to reject a keystroke or convert the display to something else.
      attr_accessor :transform

      # @return [Boolean] Input fields only record key strokes when it has focus, set to +true+ when you want to capture keys. Defaults to +false+
      attr_accessor :has_focus

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
        # super # calling super without args should have worked and passed the args up, but apparently only text??
        # https://github.com/DragonRuby/dragonruby-game-toolkit-contrib/issues/78
        super(
          text,
          size:               size,
          alignment:          alignment,
          vertical_alignment: vertical_alignment,
          font:               font,
          ellipsis:           ellipsis,
          r:                  r,
          g:                  g,
          b:                  b,
          a:                  a
        )

        @on_key_down = ->(text_key, all_keys) { handle_input(text_key, all_keys) }
        @transform = nil
      end

      # @return [Boolean] Is the text field focused?
      def focused?
        @has_focus
      end

      # @api private
      def handle_input(text_key, all_keys)
        return false unless focused?

        if (all_keys & %i[delete backspace]).any?
          self.text = text.chop
          return true
        end

        transformed_key = transform ? transform.call(text_key) : text_key
        return false unless transformed_key

        text.concat(transformed_key)
        true
      end
    end
  end
end
