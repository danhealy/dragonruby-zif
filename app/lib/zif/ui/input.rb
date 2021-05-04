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
      include Zif::Clickable
      include Zif::KeyPressable
      include Zif::Serializable

      attr_rect
      attr_accessor :max_length, :border_color
      attr_accessor :desired_keys, :special_keys, :map_keys
      attr_accessor :has_focus

      # @return [Array<Integer>] 7-element array [+x+, +y+, +w+, +h+, +r+, +g+, +b+] suitable for passing into gtk.borders
      # it's expanded 5 pixels in every dimension from the true size of the underlying label
      attr_accessor :focus_border

      # @return [Lambda] Called when the focus changes, good place to draw a focus border if you need.  Called with +input+ arg.
      attr_accessor :on_focus_changed

      @desired_keys = nil
      @special_keys = nil
      @map_keys     = nil

      def initialize(text='', size: -1, alignment: :left, font: 'font.tff', ellipsis: '…', r: 51, g: 51, b: 51, a: 255)
        # super # calling super without args should have worked and passed the args up, but apparently only text??
        # https://github.com/DragonRuby/dragonruby-game-toolkit-contrib/issues/78
        super(text, size: size, alignment: alignment, font: font, ellipsis: ellipsis, r: r, g: g, b: b, a: a)

        default_key_mappings
        @on_key_down = ->(key) { handle_input(key) }
        self.border_color = [0, 0, 0]
        update_border
      end

      def default_key_mappings
        @desired_keys = [
          :exclamation_point, :space, :plus, :at,
          :period, :comma, :underscore, :hyphen,
          :zero, :one, :two, :three, :four,
          :five, :six, :seven, :eight, :nine,
          :a, :b, :c, :d, :e, :f, :g, :h,
          :i, :j, :k, :l, :m, :n, :o, :p,
          :q, :r, :s, :t, :u, :v, :w, :x,
          :y, :z
        ]

        @special_keys = [
          :backspace, :delete, :enter,
          :home, :end, :pageup, :pagedown,
          :left, :right
        ]

        @map_keys = {}
        GTK::KeyboardKeys.char_to_method_hash.each do |k, v|
          @map_keys[v[0]] = k if @desired_keys.include?(v[0]) || @special_keys.include?(v[0])
        end
      end

      def clicked?(point, kind=:up)
        return nil if kind != :down

        old_focus = has_focus
        self.has_focus = point.inside_rect?(input_rect)

        update_border
        on_focus_changed&.call(self) if has_focus != old_focus
        nil
      end

      # for inside_rect?
      def w
        rect[0]
      end

      # for inside_rect?
      def h
        rect[1]
      end

      def input_rect(adj=5)
        [ x       - adj,
          y - h   - adj,
          w + adj + adj,
          h + adj + adj ]
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
        update_border
        true
      end

      def update_border
        # use .replace to that deleting an old focus border works better, for instance:
        #    $gtk.args.outputs.static_borders.delete(input.focus_border) unless input.focus_border.nil?
        focus_border.replace(input_rect + border_color) unless focus_border.nil?
        self.focus_border = input_rect + border_color   if focus_border.nil?
      end

      # here's a sample lambda to use on the on_focus_changed event, but you might do something different
      #
      # def update_input_focus_border(input)
      #   $gtk.args.outputs.static_borders.delete(input.focus_border) unless input.focus_border.nil?
      #   return unless input.has_focus

      #   $gtk.args.outputs.static_borders << input.focus_border
      # end

    end
  end
end
