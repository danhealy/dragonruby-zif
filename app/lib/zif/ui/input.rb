module Zif
  module UI
    # A basic input field that can accept keystrokes and record and display changes
    # to have it recieve key strokes it needs to be registered
    #    $game.services[:input_service].register_key_pressable(@input)
    #
    # to be able to update the display in response to those, you should to add it as a label every tick
    #    perform tick args
    #      ...
    #      $gtk.args.outputs.labels << [@input]
    #      ...
    #
    class Input < Label
      include Zif::KeyPressable
      include Zif::Serializable

      attr_rect
      attr_accessor :max_length
      attr_accessor :desired_keys, :special_keys, :map_keys
      attr_accessor :has_focus

      @desired_keys = nil
      @special_keys = nil
      @map_keys     = nil

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
        :backspace, :delete, :enter,
        :home, :end, :pageup, :pagedown,
        :left, :right
      ].freeze

      def initialize(text='', size: -1, alignment: :left, font: 'font.tff', ellipsis: '…', r: 51, g: 51, b: 51, a: 255)
        # super # calling super without args should have worked and passed the args up, but apparently only text??
        # https://github.com/DragonRuby/dragonruby-game-toolkit-contrib/issues/78
        super(text, size: size, alignment: alignment, font: font, ellipsis: ellipsis, r: r, g: g, b: b, a: a)

        default_key_mappings
        @on_key_down = ->(key) { handle_input(key) }
      end

      def default_key_mappings
        @desired_keys = DEFAULT_DESIRED_KEYS
        @special_keys = DEFAULT_SPECIAL_KEYS

        @map_keys = {}
        GTK::KeyboardKeys.char_to_method_hash.each do |k, v|
          @map_keys[v[0]] = k if @desired_keys.include?(v[0]) || @special_keys.include?(v[0])
        end
      end

      def handle_input(key)
        return false unless has_focus
        return false unless key == :backspace || key == :delete || @desired_keys.include?(key)
        return false if max_length.positive? && key != :backspace && text.length >= max_length

        if key == :backspace || key == :delete
          self.text = text.chop
        else
          text.concat(@map_keys[key])
        end
        true
      end
    end
  end
end
