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

      # @return [Integer] Constrain input to max_length number of characters. Defaults to zero to allow any number of characters.
      attr_accessor :max_length

      # @return [Array<String>] List of characters to accept as valid input. Defaults to nil to allow all characters.
      attr_accessor :filter_keys

      # @return [Array<Symbol>] List of additional symbols to process, but not to append to the field. Defaults to [:delete, :backspace] and handles those.
      attr_accessor :special_keys

      # @return [Boolean] Input fields only record key strokes when it has focus, set to +true+ when you want to capture keys. Defaults to +false+
      attr_accessor :has_focus

      # convience values for @filter_keys
      FILTER_NUMERIC = ('0'..'9').to_a.freeze
      FILTER_ALPHA_LOWERCASE = ('a'..'z').to_a.freeze
      FILTER_ALPHA = (FILTER_ALPHA_LOWERCASE + FILTER_ALPHA_LOWERCASE.map(&:upcase)).freeze
      FILTER_ALPHA_NUMERIC = (FILTER_NUMERIC + FILTER_ALPHA).freeze
      FILTER_ALPHA_NUMERIC_UPPERCASE = (FILTER_NUMERIC + FILTER_ALPHA).map(&:upcase).freeze

      def initialize(text='', size: -1, alignment: :left, font: 'font.tff', ellipsis: '…', r: 51, g: 51, b: 51, a: 255)
        # super # calling super without args should have worked and passed the args up, but apparently only text??
        # https://github.com/DragonRuby/dragonruby-game-toolkit-contrib/issues/78
        super(text, size: size, alignment: alignment, font: font, ellipsis: ellipsis, r: r, g: g, b: b, a: a)

        @on_key_down = ->(text_key, all_keys) { handle_input(text_key, all_keys) }
        @filter_keys = nil
      end

      # @api private
      def handle_input(text_key, all_keys)
        return false unless has_focus

        delete = (all_keys & %i[delete backspace]).any?
        unless delete || @filter_keys.nil?
          return false unless @filter_keys.include?(text_key)
        end

        return false if max_length.positive? && !delete && text.length >= max_length

        if delete
          self.text = text.chop
        else
          text.concat(text_key) unless text_key.nil?
        end
        true
      end
    end
  end
end
