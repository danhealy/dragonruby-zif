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
      attr_accessor :desired_keys

      # @return [Array<Symbol>] List of additional symbols to process, but not to append to the field. Defaults to [:delete, :backspace] and handles those.
      attr_accessor :special_keys

      # @return [Boolean] Input fields only record key strokes when it has focus, set to +true+ when you want to capture keys. Defaults to +false+
      attr_accessor :has_focus

      DEFAULT_DESIRED_KEYS = [
        :exclamation_point, :space, :plus, :at,
        :period, :comma, :underscore, :hyphen,
        :zero, :one, :two, :three, :four,
        :five, :six, :seven, :eight, :nine,
        :a, :b, :c, :d, :e, :f, :g, :h,
        :i, :j, :k, :l, :m, :n, :o, :p,
        :q, :r, :s, :t, :u, :v, :w, :x,
        :y, :z
      ].freeze

      DEFAULT_SPECIAL_KEYS = [
        :backspace, :delete
      ].freeze

      def initialize(text='', size: -1, alignment: :left, font: 'font.tff', ellipsis: '…', r: 51, g: 51, b: 51, a: 255)
        # super # calling super without args should have worked and passed the args up, but apparently only text??
        # https://github.com/DragonRuby/dragonruby-game-toolkit-contrib/issues/78
        super(text, size: size, alignment: alignment, font: font, ellipsis: ellipsis, r: r, g: g, b: b, a: a)

        default_key_mappings
        @on_key_down = ->(key) { handle_input(key) }
      end

      # @api private
      def default_key_mappings
        @desired_keys = nil
        @special_keys = DEFAULT_SPECIAL_KEYS
      end

      # @api private
      def handle_input(key)
        return false unless has_focus

        unless @special_keys.include?(key) || @desired_keys.nil?
          return false unless @desired_keys.include?(key.to_s)
        end

        return false if max_length.positive? && key != :backspace && key != :delete && text.length >= max_length

        if key == :backspace || key == :delete
          self.text = text.chop
        else
          text.concat(key)
        end
        true
      end
    end
  end
end
